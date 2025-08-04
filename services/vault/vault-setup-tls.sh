#!/bin/bash
set -euo pipefail

# Vault AppRole Setup for Services with TLS Support
# Creates database secrets engine and AppRole for secure service authentication

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="https://127.0.0.1:8200"
VAULT_ROOT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault/vault-root-token"
VAULT_ENV_FILE="/opt/my-secure-ha-stack/secrets/vault/vault-env.sh"

# Enable TLS skip verify for development with self-signed certificates
export VAULT_SKIP_VERIFY=true

echo "[$(date)] VAULT_SETUP: Starting Vault AppRole and secrets engine setup with TLS..." | tee -a "$LOG_FILE"

# Function to check if Vault is ready
check_vault_status() {
    echo "[$(date)] VAULT_SETUP: Checking Vault status..." | tee -a "$LOG_FILE"
    
    local status_response
    status_response=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo '{"sealed":true}')
    
    if echo "$status_response" | grep -q '"sealed":false'; then
        echo "[$(date)] VAULT_SETUP: Vault is unsealed and ready" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Vault is sealed or not accessible" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to get Vault token
get_vault_token() {
    if [[ -f "$VAULT_ENV_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$VAULT_ENV_FILE"
        echo "[$(date)] VAULT_SETUP: Using Vault token from $VAULT_ENV_FILE" | tee -a "$LOG_FILE"
        return 0
    elif [[ -f "$VAULT_ROOT_TOKEN_FILE" ]]; then
        export VAULT_TOKEN=$(cat "$VAULT_ROOT_TOKEN_FILE")
        echo "[$(date)] VAULT_SETUP: Using Vault token from $VAULT_ROOT_TOKEN_FILE" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] VAULT_SETUP: ERROR: No Vault token found" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to enable database secrets engine
enable_database_engine() {
    echo "[$(date)] VAULT_SETUP: Enabling database secrets engine..." | tee -a "$LOG_FILE"
    
    vault secrets enable -path=database database 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: Database secrets engine already enabled or error occurred" | tee -a "$LOG_FILE"
    }
}

# Function to configure PostgreSQL connection
configure_postgres_connection() {
    echo "[$(date)] VAULT_SETUP: Configuring PostgreSQL database connection..." | tee -a "$LOG_FILE"
    
    vault write database/config/postgres-app \
        plugin_name=postgresql-database-plugin \
        connection_url="postgresql://{{username}}:{{password}}@postgres:5432/postgres?sslmode=disable" \
        allowed_roles="postgres-role" \
        username="postgres" \
        password="postgres_password" 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: PostgreSQL connection configuration failed or already exists" | tee -a "$LOG_FILE"
    }
}

# Function to create database role
create_database_role() {
    echo "[$(date)] VAULT_SETUP: Creating PostgreSQL database role..." | tee -a "$LOG_FILE"
    
    vault write database/roles/postgres-role \
        db_name=postgres-app \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h" 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: Database role creation failed or already exists" | tee -a "$LOG_FILE"
    }
}

# Function to enable AppRole authentication
enable_approle_auth() {
    echo "[$(date)] VAULT_SETUP: Enabling AppRole authentication..." | tee -a "$LOG_FILE"
    
    vault auth enable approle 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: AppRole auth already enabled or error occurred" | tee -a "$LOG_FILE"
    }
}

# Function to create AppRole policy
create_approle_policy() {
    echo "[$(date)] VAULT_SETUP: Creating AppRole policy for database access..." | tee -a "$LOG_FILE"
    
    cat > /tmp/postgres-policy.hcl << EOF
# Allow reading database credentials
path "database/creds/postgres-role" {
  capabilities = ["read"]
}

# Allow reading static secrets (if needed)
path "secret/data/postgres/*" {
  capabilities = ["read"]
}
EOF

    vault policy write postgres-policy /tmp/postgres-policy.hcl 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: Policy creation failed or already exists" | tee -a "$LOG_FILE"
    }
    
    rm -f /tmp/postgres-policy.hcl
}

# Function to create AppRole
create_approle() {
    echo "[$(date)] VAULT_SETUP: Creating AppRole for PostgreSQL service..." | tee -a "$LOG_FILE"
    
    vault write auth/approle/role/postgres-app \
        token_policies="postgres-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true \
        secret_id_ttl=10m \
        secret_id_num_uses=0 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: AppRole creation failed or already exists" | tee -a "$LOG_FILE"
    }
}

# Function to generate and save AppRole credentials
generate_approle_credentials() {
    echo "[$(date)] VAULT_SETUP: Generating AppRole credentials..." | tee -a "$LOG_FILE"
    
    # Get role ID
    local role_id
    role_id=$(vault read -field=role_id auth/approle/role/postgres-app/role-id 2>/dev/null || echo "")
    
    if [[ -n "$role_id" ]]; then
        echo "[$(date)] VAULT_SETUP: Role ID: $role_id" | tee -a "$LOG_FILE"
        echo "$role_id" > "/opt/my-secure-ha-stack/secrets/vault-agent-role-id/role_id"
        chmod 600 "/opt/my-secure-ha-stack/secrets/vault-agent-role-id/role_id"
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Failed to get role ID" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Generate secret ID
    local secret_id
    secret_id=$(vault write -force -field=secret_id auth/approle/role/postgres-app/secret-id 2>/dev/null || echo "")
    
    if [[ -n "$secret_id" ]]; then
        echo "[$(date)] VAULT_SETUP: Secret ID generated successfully" | tee -a "$LOG_FILE"
        echo "$secret_id" > "/opt/my-secure-ha-stack/secrets/vault-agent-secret-id/secret_id"
        chmod 600 "/opt/my-secure-ha-stack/secrets/vault-agent-secret-id/secret_id"
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Failed to generate secret ID" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "[$(date)] VAULT_SETUP: AppRole credentials saved successfully" | tee -a "$LOG_FILE"
    return 0
}

# Function to test database credential generation
test_database_credentials() {
    echo "[$(date)] VAULT_SETUP: Testing database credential generation..." | tee -a "$LOG_FILE"
    
    local test_creds
    test_creds=$(vault read database/creds/postgres-role 2>/dev/null || echo "")
    
    if [[ -n "$test_creds" ]]; then
        echo "[$(date)] VAULT_SETUP: Database credential generation test successful" | tee -a "$LOG_FILE"
        echo "$test_creds" | grep -E "(username|password)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Database credential generation test failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main execution
main() {
    # Check Vault status
    if ! check_vault_status; then
        echo "[$(date)] VAULT_SETUP: ERROR: Vault is not ready" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    # Get Vault token
    if ! get_vault_token; then
        echo "[$(date)] VAULT_SETUP: ERROR: Cannot authenticate with Vault" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    # Set up database secrets engine
    enable_database_engine
    configure_postgres_connection
    create_database_role
    
    # Set up AppRole authentication
    enable_approle_auth
    create_approle_policy
    create_approle
    
    # Generate credentials
    if generate_approle_credentials; then
        echo "[$(date)] VAULT_SETUP: SUCCESS: AppRole setup completed" | tee -a "$LOG_FILE"
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Failed to generate AppRole credentials" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    # Test the setup
    if test_database_credentials; then
        echo "[$(date)] VAULT_SETUP: SUCCESS: All tests passed" | tee -a "$LOG_FILE"
    else
        echo "[$(date)] VAULT_SETUP: WARNING: Database credential test failed" | tee -a "$LOG_FILE"
    fi
    
    echo "[$(date)] VAULT_SETUP: Vault AppRole and database secrets engine setup completed successfully" | tee -a "$LOG_FILE"
}

# Run main function
main "$@"
