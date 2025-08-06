#!/bin/bash
set -euo pipefail

# PostgreSQL Vault Integration Entrypoint
# Fetches secrets from Vault before starting PostgreSQL
# Ensures zero hardcoded passwords and dynamic secret management
# Pure Bliss Elite Standards: Security, Zero-Trust, Dynamic Secrets

LOG_FILE="/opt/logs/dev-environment-setup.log"

function log_info() {
    echo "[$(date)] POSTGRES_VAULT: $1" | tee -a "$LOG_FILE"
}

function log_error() {
    echo "[$(date)] POSTGRES_VAULT: ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ POSTGRES: $1" >&2
}

function log_success() {
    echo "[$(date)] POSTGRES_VAULT: SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ POSTGRES: $1"
}

function log_warning() {
    echo "[$(date)] POSTGRES_VAULT: WARNING: $1" | tee -a "$LOG_FILE"
    echo "⚠️  POSTGRES: $1"
}

# Wait for Vault to be ready with enhanced checks
function wait_for_vault() {
    local max_attempts=60
    local attempt=1

    log_info "Waiting for Vault to be ready and unsealed..."

    while [[ $attempt -le $max_attempts ]]; do
    # Check if Vault is accessible (try both hostname and direct IP)
    local vault_accessible=false

    # Install curl if not available
    if ! command -v curl >/dev/null 2>&1; then
        log_info "Installing curl for Vault connectivity checks..."
        apt-get update >/dev/null 2>&1 && apt-get install -y curl >/dev/null 2>&1
    fi

    # Install wget and unzip for Vault CLI installation
    if ! command -v wget >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
        log_info "Installing wget and unzip for Vault CLI..."
        apt-get update >/dev/null 2>&1 && apt-get install -y wget unzip >/dev/null 2>&1
    fi

    # Try hostname first
    if curl -s http://purebliss-vault:8200/v1/sys/health >/dev/null 2>&1; then
        vault_accessible=true
        log_info "Vault accessible via hostname"
    # Try direct IP as fallback
    elif curl -s http://172.32.0.4:8200/v1/sys/health >/dev/null 2>&1; then
        vault_accessible=true
        log_info "Vault accessible via IP address"
        # Update environment to use IP
        export VAULT_ADDR="http://172.32.0.4:8200"
    fi

    if [[ "$vault_accessible" == "true" ]]; then
        local vault_status
        if [[ "$VAULT_ADDR" == *"172.32.0.4"* ]]; then
            vault_status=$(curl -s http://172.32.0.4:8200/v1/sys/health 2>/dev/null)
        else
            vault_status=$(curl -s http://purebliss-vault:8200/v1/sys/health 2>/dev/null)
        fi            # Check if Vault is unsealed
            if echo "$vault_status" | grep -q '"sealed":false'; then
                log_success "Vault is ready and unsealed"
                return 0
            else
                log_info "Vault is sealed, waiting for auto-unseal (attempt $attempt/$max_attempts)"
            fi
        else
            log_info "Waiting for Vault endpoint to be accessible (attempt $attempt/$max_attempts)"
        fi

        sleep 3
        ((attempt++))
    done

    log_error "Vault not ready after $max_attempts attempts"
    return 1
}

# Fetch secrets from Vault using service token with enhanced error handling
function fetch_postgres_secrets() {
    log_info "Fetching PostgreSQL secrets from Vault..."

    # Check for Vault token with fallback strategy
    local vault_token=""

    # Priority 1: Service-specific token
    if [[ -f "/vault/secrets/postgres_vault_token" ]]; then
        vault_token=$(cat /vault/secrets/postgres_vault_token)
        log_info "Using PostgreSQL service-specific token"
    # Priority 2: Generic Vault token
    elif [[ -f "/vault/secrets/vault_token" ]]; then
        vault_token=$(cat /vault/secrets/vault_token)
        log_info "Using root Vault token"
    # Priority 3: Check alternative locations
    elif [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
        log_info "Using Vault token from alternative location"
    else
        log_error "No Vault token available in any expected location"
        return 1
    fi

    # Set Vault environment
    export VAULT_ADDR="http://purebliss-vault:8200"
    export VAULT_SKIP_VERIFY=1
    export VAULT_TOKEN="$vault_token"

    # Install Vault CLI if not available
    if ! command -v vault >/dev/null 2>&1; then
        log_info "Installing Vault CLI for secret management..."
        cd /tmp
        curl -s -L -o vault.zip https://releases.hashicorp.com/vault/1.17.3/vault_1.17.3_linux_amd64.zip
        unzip -q vault.zip
        mv vault /usr/local/bin/vault
        chmod +x /usr/local/bin/vault
        rm -f vault.zip
        cd /
        log_success "Vault CLI installed successfully"
    fi

    # Create secure secrets directory
    mkdir -p /run/secrets
    chmod 700 /run/secrets

    # Test Vault connectivity before fetching secrets
    if ! vault token lookup >/dev/null 2>&1; then
        log_error "Vault token authentication failed"
        return 1
    fi

    log_success "Vault authentication successful"

    # Fetch PostgreSQL bootstrap password from Vault
    local bootstrap_password
    if bootstrap_password=$(vault kv get -field=bootstrap_password secret/postgres 2>/dev/null); then
        echo "$bootstrap_password" > /run/secrets/postgres_bootstrap_password
        chmod 600 /run/secrets/postgres_bootstrap_password
        log_success "PostgreSQL bootstrap password fetched from Vault"
    else
        # Generate and store a new secure password
        log_info "Bootstrap password not found in Vault, generating secure password..."
        bootstrap_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

        # Store in Vault for future use
        vault kv put secret/postgres \
            bootstrap_password="$bootstrap_password" \
            vault_admin_password="$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)" \
            description="PostgreSQL bootstrap credentials - auto-generated $(date)" \
            service="purebliss-postgres" \
            environment="development"

        echo "$bootstrap_password" > /run/secrets/postgres_bootstrap_password
        chmod 600 /run/secrets/postgres_bootstrap_password
        log_success "Generated and stored new PostgreSQL bootstrap password in Vault"
    fi

    # Fetch Vault admin password for database integration
    local vault_admin_password
    if vault_admin_password=$(vault kv get -field=vault_admin_password secret/postgres 2>/dev/null); then
        echo "$vault_admin_password" > /run/secrets/vault_admin_password
        chmod 600 /run/secrets/vault_admin_password
        log_success "Vault admin password fetched from Vault"
    else
        log_warning "Vault admin password not found, using generated password"
        vault_admin_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

        # Update Vault with new admin password
        vault kv patch secret/postgres vault_admin_password="$vault_admin_password"

        echo "$vault_admin_password" > /run/secrets/vault_admin_password
        chmod 600 /run/secrets/vault_admin_password
        log_success "Generated and stored new Vault admin password"
    fi

    # Store database connection info for Vault integration
    cat > /run/secrets/vault_integration_config << EOF
VAULT_DB_HOST=purebliss-postgres
VAULT_DB_PORT=5432
VAULT_DB_NAME=postgres
VAULT_DB_ADMIN_USER=vault_admin
VAULT_DB_SSL_MODE=disable
VAULT_BOOTSTRAP_USER=postgres
EOF
    chmod 600 /run/secrets/vault_integration_config

    # Create service credentials for other applications
    log_info "Creating service-specific credentials..."

    # Keycloak credentials
    local keycloak_password
    keycloak_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo "$keycloak_password" > /run/secrets/keycloak_db_password
    chmod 600 /run/secrets/keycloak_db_password

    # Plane credentials
    local plane_password
    plane_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo "$plane_password" > /run/secrets/plane_db_password
    chmod 600 /run/secrets/plane_db_password

    log_success "All PostgreSQL secrets fetched and configured securely"
}

# Setup Vault database integration with enhanced error handling
function setup_vault_database_integration() {
    log_info "Setting up Vault database integration..."

    # Wait for PostgreSQL to be fully ready
    local max_wait=60
    local wait_count=0

    while [[ $wait_count -lt $max_wait ]]; do
        if pg_isready -U postgres -d postgres -h localhost -p 5432 >/dev/null 2>&1; then
            log_success "PostgreSQL is ready for Vault integration"
            break
        fi
        sleep 2
        ((wait_count++))
    done

    if [[ $wait_count -ge $max_wait ]]; then
        log_error "PostgreSQL not ready for Vault integration"
        return 1
    fi

    # Create vault_admin user for database secrets engine
    log_info "Creating vault_admin user for Vault integration..."

    local vault_admin_password
    vault_admin_password=$(cat /run/secrets/vault_admin_password)

    local keycloak_password plane_password
    keycloak_password=$(cat /run/secrets/keycloak_db_password)
    plane_password=$(cat /run/secrets/plane_db_password)

    PGPASSWORD="$(cat /run/secrets/postgres_bootstrap_password)" psql -U postgres -d postgres << EOF
-- Create vault_admin user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vault_admin') THEN
        CREATE ROLE vault_admin WITH LOGIN PASSWORD '$vault_admin_password';
        ALTER ROLE vault_admin CREATEROLE CREATEDB;
        GRANT ALL PRIVILEGES ON DATABASE postgres TO vault_admin;
        -- Grant additional permissions for dynamic user management
        ALTER ROLE vault_admin WITH SUPERUSER;
    ELSE
        -- Update password if user exists
        ALTER ROLE vault_admin WITH PASSWORD '$vault_admin_password';
    END IF;
END
\$\$;

-- Create service databases with proper permissions
CREATE DATABASE IF NOT EXISTS keycloak OWNER vault_admin;
CREATE DATABASE IF NOT EXISTS plane OWNER vault_admin;
CREATE DATABASE IF NOT EXISTS vikunja OWNER vault_admin;
CREATE DATABASE IF NOT EXISTS vault_managed OWNER vault_admin;

-- Create service users with initial passwords
DO \$\$
BEGIN
    -- Keycloak user
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'keycloak') THEN
        CREATE ROLE keycloak WITH LOGIN PASSWORD '$keycloak_password';
        GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
    ELSE
        ALTER ROLE keycloak WITH PASSWORD '$keycloak_password';
    END IF;

    -- Plane user
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'plane') THEN
        CREATE ROLE plane WITH LOGIN PASSWORD '$plane_password';
        GRANT ALL PRIVILEGES ON DATABASE plane TO plane;
    ELSE
        ALTER ROLE plane WITH PASSWORD '$plane_password';
    END IF;

    -- Vikunja user
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vikunja') THEN
        CREATE ROLE vikunja WITH LOGIN PASSWORD 'vikunja_temp_password_$(openssl rand -hex 8)';
        GRANT ALL PRIVILEGES ON DATABASE vikunja TO vikunja;
    END IF;
END
\$\$;

-- Grant permissions to keycloak database
\c keycloak;
GRANT USAGE, CREATE ON SCHEMA public TO keycloak;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO keycloak;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO keycloak;

-- Grant permissions to plane database
\c plane;
GRANT USAGE, CREATE ON SCHEMA public TO plane;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO plane;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO plane;

-- Return to postgres database
\c postgres;

-- Log successful setup
SELECT 'Vault database integration setup completed successfully' as status;
EOF

    if [[ $? -eq 0 ]]; then
        log_success "Vault database integration setup completed successfully"

        # Store service credentials in Vault for other services
        log_info "Storing service credentials in Vault..."

        # Store Keycloak database credentials
        vault kv put secret/keycloak \
            db_host="purebliss-postgres" \
            db_port="5432" \
            db_name="keycloak" \
            db_user="keycloak" \
            db_password="$keycloak_password" \
            admin_user="admin" \
            admin_password="$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)" \
            service="keycloak" \
            environment="development"

        # Store Plane database credentials
        vault kv put secret/plane \
            db_host="purebliss-postgres" \
            db_port="5432" \
            db_name="plane" \
            db_user="plane" \
            db_password="$plane_password" \
            service="plane" \
            environment="development"

        log_success "Service credentials stored in Vault successfully"
    else
        log_error "Failed to setup Vault database integration"
        return 1
    fi
}

# Configure Vault database secrets engine
function configure_vault_database_engine() {
    log_info "Configuring Vault database secrets engine..."

    # Wait a bit more for PostgreSQL to stabilize
    sleep 10

    local vault_admin_password
    vault_admin_password=$(cat /run/secrets/vault_admin_password)

    # Test Vault connectivity first
    if ! vault token lookup >/dev/null 2>&1; then
        log_error "Vault token invalid for database configuration"
        return 1
    fi

    # Enable database secrets engine (idempotent)
    vault secrets enable -path=database database 2>/dev/null || {
        log_info "Database secrets engine already enabled"
    }

    # Configure PostgreSQL connection for Vault
    if vault write database/config/postgres-app \
        plugin_name=postgresql-database-plugin \
        allowed_roles="postgres-role,postgres-app" \
        connection_url="postgresql://{{username}}:{{password}}@purebliss-postgres:5432/postgres?sslmode=disable" \
        username="vault_admin" \
        password="$vault_admin_password" \
        max_open_connections=5 \
        max_idle_connections=2 \
        max_connection_lifetime=1h; then

        log_success "Vault database connection configured successfully"
    else
        log_error "Failed to configure Vault database connection"
        return 1
    fi

    # Create database role for dynamic credentials
    if vault write database/roles/postgres-role \
        db_name=postgres-app \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT CONNECT ON DATABASE postgres TO \"{{name}}\"; GRANT USAGE ON SCHEMA public TO \"{{name}}\"; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h"; then

        log_success "Vault database role configured successfully"
    else
        log_error "Failed to configure Vault database role"
        return 1
    fi

    # Test dynamic credential generation
    log_info "Testing dynamic credential generation..."
    if vault read database/creds/postgres-role >/dev/null 2>&1; then
        log_success "Dynamic credential generation is working"
    else
        log_warning "Dynamic credential generation test failed - check Vault logs"
    fi

    log_success "Vault database secrets engine configuration completed"
}

# Main entrypoint logic with comprehensive error handling
function main() {
    log_info "Starting PostgreSQL with Vault integration (Pure Bliss Elite Standards)..."

    # Step 1: Wait for Vault to be ready
    if ! wait_for_vault; then
        log_error "Vault is not ready - cannot start PostgreSQL with secure credentials"
        log_error "This violates Pure Bliss Elite Zero-Trust principles"
        exit 1
    fi

    # Step 2: Fetch secrets from Vault
    if ! fetch_postgres_secrets; then
        log_error "Failed to fetch secrets from Vault - cannot proceed"
        log_error "Pure Bliss Elite: No hardcoded secrets allowed"
        exit 1
    fi

    # Step 3: Set environment variable for PostgreSQL to use the secret file
    export POSTGRES_PASSWORD_FILE=/run/secrets/postgres_bootstrap_password

    # Step 4: Start PostgreSQL with Vault-managed credentials
    log_info "Starting PostgreSQL with Vault-managed credentials..."

    # Start PostgreSQL in background
    "$@" &
    local postgres_pid=$!

    # Step 5: Wait for PostgreSQL to be ready and then setup Vault integration
    log_info "Waiting for PostgreSQL to be ready for Vault integration..."
    sleep 30

    # Step 6: Setup Vault integration
    if ! setup_vault_database_integration; then
        log_error "Failed to setup Vault database integration"
        # Don't kill PostgreSQL, but log the issue
        log_warning "PostgreSQL is running but Vault integration incomplete"
    else
        # Step 7: Configure Vault database secrets engine
        if ! configure_vault_database_engine; then
            log_error "Failed to configure Vault database secrets engine"
            log_warning "PostgreSQL is running but dynamic secrets not available"
        else
            log_success "PostgreSQL fully integrated with Vault for dynamic secrets"
        fi
    fi

    # Wait for PostgreSQL process
    log_info "PostgreSQL startup complete - monitoring process..."
    wait $postgres_pid
}

# Signal handling for graceful shutdown
function cleanup() {
    log_info "Received termination signal, shutting down PostgreSQL gracefully..."
    if [[ -n "${postgres_pid:-}" ]]; then
        kill -TERM "$postgres_pid" 2>/dev/null || true
        wait "$postgres_pid" 2>/dev/null || true
    fi
    log_info "PostgreSQL shutdown complete"
}

trap cleanup TERM INT

# Execute main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
