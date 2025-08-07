#!/bin/bash
# Loki Vault Setup Script - Pure Bliss Elite Standards
# Configures Vault policies, AppRole, and secrets engine for Loki service
# Run this script after Vault is initialized and unsealed

set -e

VAULT_ENDPOINT="https://purebliss-vault:8200"
SCRIPT_DIR=$(dirname "$0")
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Starting Vault setup for Loki service" | tee -a "$LOG_FILE"

# Function to validate Vault is ready
validate_vault_ready() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Validating Vault is ready..." | tee -a "$LOG_FILE"

    for i in {1..10}; do
        if vault status &>/dev/null; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ Vault is ready" | tee -a "$LOG_FILE"
            return 0
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Attempt $i: Vault not ready, waiting..." | tee -a "$LOG_FILE"
        sleep 3
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ❌ Vault not ready after 30 seconds" | tee -a "$LOG_FILE"
    return 1
}

# Function to enable secrets engine
enable_secrets_engine() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Enabling KV secrets engine for Loki..." | tee -a "$LOG_FILE"

    if vault secrets list | grep -q "loki-secrets/"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ KV secrets engine already enabled" | tee -a "$LOG_FILE"
    else
        vault secrets enable -path=loki-secrets -version=2 kv
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ KV secrets engine enabled" | tee -a "$LOG_FILE"
    fi
}

# Function to create Loki policy
create_loki_policy() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Creating Loki Vault policy..." | tee -a "$LOG_FILE"

    cat > /tmp/loki-policy.hcl << 'EOF'
# Loki Service Vault Policy - Pure Bliss Elite Standards
# Provides minimum required permissions for Loki log storage and management

# Storage secrets access
path "loki-secrets/data/storage" {
  capabilities = ["read"]
}

path "loki-secrets/metadata/storage" {
  capabilities = ["read", "list"]
}

# Encryption key access
path "loki-secrets/data/encryption" {
  capabilities = ["read"]
}

path "loki-secrets/metadata/encryption" {
  capabilities = ["read"]
}

# Future: Cloud storage backend secrets
path "loki-secrets/data/storage-backend" {
  capabilities = ["read"]
}

# Audit logging - read only access to confirm logging
path "sys/audit" {
  capabilities = ["read"]
}

# Health check access
path "sys/health" {
  capabilities = ["read"]
}

# Token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Token self-lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

    vault policy write loki-service /tmp/loki-policy.hcl
    rm /tmp/loki-policy.hcl
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ Loki policy created" | tee -a "$LOG_FILE"
}

# Function to create AppRole
create_loki_approle() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Creating Loki AppRole..." | tee -a "$LOG_FILE"

    # Enable AppRole auth method if not already enabled
    if ! vault auth list | grep -q "approle/"; then
        vault auth enable approle
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ AppRole auth method enabled" | tee -a "$LOG_FILE"
    fi

    # Create AppRole for Loki
    vault write auth/approle/role/loki-service \
        token_policies="loki-service" \
        token_ttl=24h \
        token_max_ttl=72h \
        secret_id_ttl=24h \
        token_num_uses=0 \
        secret_id_num_uses=0

    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ Loki AppRole created" | tee -a "$LOG_FILE"
}

# Function to generate AppRole credentials
generate_approle_credentials() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Generating AppRole credentials..." | tee -a "$LOG_FILE"

    # Get role ID
    ROLE_ID=$(vault read -field=role_id auth/approle/role/loki-service/role-id)

    # Generate secret ID
    SECRET_ID=$(vault write -field=secret_id auth/approle/role/loki-service/secret-id)

    # Store credentials in environment file
    cat > "$SCRIPT_DIR/loki-vault-credentials.env" << EOF
# Loki Service Vault AppRole Credentials
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Use these environment variables in the Loki container

LOKI_VAULT_ROLE_ID="$ROLE_ID"
LOKI_VAULT_SECRET_ID="$SECRET_ID"
VAULT_ADDR="$VAULT_ENDPOINT"
VAULT_SKIP_VERIFY="false"
EOF

    chmod 600 "$SCRIPT_DIR/loki-vault-credentials.env"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ AppRole credentials generated and stored in loki-vault-credentials.env" | tee -a "$LOG_FILE"
}

# Function to create sample secrets
create_sample_secrets() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Creating sample secrets for Loki..." | tee -a "$LOG_FILE"

    # Storage configuration secrets
    vault kv put loki-secrets/storage \
        retention_days="30" \
        compression_type="gzip" \
        chunk_target_size="1048576" \
        chunk_idle_period="30m" \
        max_transfer_retries="10"

    # Encryption configuration (placeholder for future use)
    vault kv put loki-secrets/encryption \
        algorithm="AES256" \
        key_rotation_interval="30d" \
        encryption_enabled="false"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ Sample secrets created" | tee -a "$LOG_FILE"
}

# Function to test AppRole authentication
test_approle_authentication() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Testing AppRole authentication..." | tee -a "$LOG_FILE"

    source "$SCRIPT_DIR/loki-vault-credentials.env"

    # Test login
    TEST_TOKEN=$(vault write -field=token auth/approle/login \
        role_id="$LOKI_VAULT_ROLE_ID" \
        secret_id="$LOKI_VAULT_SECRET_ID")

    if [[ -n "$TEST_TOKEN" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ AppRole authentication test successful" | tee -a "$LOG_FILE"

        # Test secret access
        VAULT_TOKEN="$TEST_TOKEN" vault kv get loki-secrets/storage > /dev/null
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ Secret access test successful" | tee -a "$LOG_FILE"

        # Revoke test token
        VAULT_TOKEN="$TEST_TOKEN" vault token revoke -self
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ Test token revoked" | tee -a "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ❌ AppRole authentication test failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to display setup summary
display_setup_summary() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: === Vault Setup Summary ===" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Secrets Engine: loki-secrets (KV v2)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Policy: loki-service" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: AppRole: loki-service" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Credentials File: loki-vault-credentials.env" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: === Setup Complete ===" | tee -a "$LOG_FILE"

    echo ""
    echo "Next Steps:"
    echo "1. Source the credentials file in your Loki container:"
    echo "   source /opt/dev-purebliss/services/loki/loki-vault-credentials.env"
    echo "2. Restart Loki container with Vault integration enabled"
    echo "3. Run health validation to confirm Vault integration"
}

# Main execution
main() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: Starting Loki Vault setup..." | tee -a "$LOG_FILE"

    validate_vault_ready || exit 1
    enable_secrets_engine
    create_loki_policy
    create_loki_approle
    generate_approle_credentials
    create_sample_secrets
    test_approle_authentication
    display_setup_summary

    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ✅ Loki Vault setup completed successfully" | tee -a "$LOG_FILE"
}

# Check if Vault CLI is available
if ! command -v vault &> /dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LOKI_VAULT_SETUP: ❌ Vault CLI not found. Please install Vault CLI or run from Vault container" | tee -a "$LOG_FILE"
    exit 1
fi

# Run main function
main "$@"
