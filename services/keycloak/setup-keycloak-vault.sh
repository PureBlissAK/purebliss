#!/bin/bash
set -euo pipefail

# Keycloak Vault PostgreSQL Setup Script
# Comprehensive setup for Keycloak with Vault secrets management and PostgreSQL integration
# Author: PureBliss Development Team

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/opt/logs/dev-environment-setup.log"

log_info() {
    echo "[$(date)] INFO: Keycloak-Setup: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date)] ERROR: Keycloak-Setup: $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "[$(date)] WARN: Keycloak-Setup: $1" | tee -a "$LOG_FILE"
}

# Set up Vault environment
setup_vault_env() {
    log_info "Setting up Vault environment for Keycloak"

    # Detect Vault address
    if getent hosts purebliss-vault > /dev/null 2>&1; then
        export VAULT_ADDR="http://purebliss-vault:8200"
    else
        export VAULT_ADDR="http://localhost:8200"
    fi

    # Get Vault token
    if [ -n "${VAULT_TOKEN:-}" ]; then
        log_info "Using VAULT_TOKEN from environment"
    elif [ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]; then
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
        log_info "Using token from vault_token file"
    elif [ -f "/opt/my-secure-ha-stack/vault-init-output.txt" ]; then
        export VAULT_TOKEN=$(grep "Initial Root Token:" /opt/my-secure-ha-stack/vault-init-output.txt | awk '{print $NF}')
        log_info "Using root token from vault-init-output.txt"
    else
        log_error "No Vault token found"
        return 1
    fi

    log_info "Vault environment configured: $VAULT_ADDR"
}

# Setup PostgreSQL database for Keycloak
setup_postgres_database() {
    log_info "Setting up PostgreSQL database for Keycloak"

    local postgres_host="${POSTGRES_HOST:-purebliss-postgres}"
    local postgres_port="${POSTGRES_PORT:-5432}"
    local postgres_user="${POSTGRES_USER:-postgres}"
    local postgres_password="${POSTGRES_PASSWORD:-postgres}"
    local keycloak_db="${KEYCLOAK_DB_NAME:-keycloak}"
    local keycloak_user="${KEYCLOAK_DB_USER:-keycloak}"
    local keycloak_password="${KEYCLOAK_DB_PASSWORD:-keycloak_secure_password_$(date +%s)}"

    # Wait for PostgreSQL
    local retries=0
    while [ $retries -lt 30 ]; do
        if PGPASSWORD="$postgres_password" psql -h "$postgres_host" -p "$postgres_port" -U "$postgres_user" -c "SELECT 1;" > /dev/null 2>&1; then
            log_info "PostgreSQL is ready"
            break
        fi
        retries=$((retries + 1))
        log_info "Waiting for PostgreSQL... ($retries/30)"
        sleep 5
    done

    if [ $retries -eq 30 ]; then
        log_error "PostgreSQL not available"
        return 1
    fi

    # Create database and user
    log_info "Creating Keycloak database and user"

    PGPASSWORD="$postgres_password" psql -h "$postgres_host" -p "$postgres_port" -U "$postgres_user" << EOF
-- Create database if it doesn't exist
SELECT 'CREATE DATABASE $keycloak_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$keycloak_db')\\gexec

-- Create user if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$keycloak_user') THEN
        CREATE USER $keycloak_user WITH PASSWORD '$keycloak_password';
    END IF;
END
\$\$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $keycloak_db TO $keycloak_user;
GRANT USAGE ON SCHEMA public TO $keycloak_user;
GRANT CREATE ON SCHEMA public TO $keycloak_user;
EOF

    # Store credentials in Vault
    if [ -n "${VAULT_TOKEN:-}" ]; then
        log_info "Storing database credentials in Vault"

        curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
            -d "{\"data\": {
                \"username\": \"$keycloak_user\",
                \"password\": \"$keycloak_password\",
                \"database\": \"$keycloak_db\",
                \"host\": \"$postgres_host\",
                \"port\": \"$postgres_port\"
            }}" \
            "$VAULT_ADDR/v1/secret/data/keycloak/database" > /dev/null

        log_info "Database credentials stored in Vault at secret/keycloak/database"
    fi

    log_info "PostgreSQL database setup complete"
}

# Setup Keycloak admin credentials in Vault
setup_keycloak_admin() {
    if [ -z "${VAULT_TOKEN:-}" ]; then
        log_warn "No Vault token, skipping admin setup"
        return 0
    fi

    log_info "Setting up Keycloak admin credentials in Vault"

    local admin_user="${KEYCLOAK_ADMIN:-admin}"
    local admin_password="${KEYCLOAK_ADMIN_PASSWORD:-admin_secure_$(date +%s)}"

    curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
        -d "{\"data\": {
            \"username\": \"$admin_user\",
            \"password\": \"$admin_password\",
            \"realm\": \"master\"
        }}" \
        "$VAULT_ADDR/v1/secret/data/keycloak/admin" > /dev/null

    log_info "Admin credentials stored in Vault at secret/keycloak/admin"
    log_info "Admin user: $admin_user"
}

# Create Keycloak policy for Vault access
setup_vault_policy() {
    if [ -z "${VAULT_TOKEN:-}" ]; then
        log_warn "No Vault token, skipping policy setup"
        return 0
    fi

    log_info "Creating Vault policy for Keycloak"

    local policy='
path "secret/data/keycloak/*" {
    capabilities = ["read"]
}

path "secret/metadata/keycloak/*" {
    capabilities = ["list"]
}

path "database/creds/keycloak" {
    capabilities = ["read"]
}

path "auth/token/lookup-self" {
    capabilities = ["read"]
}
'

    curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X PUT \
        -d "{\"policy\": \"$policy\"}" \
        "$VAULT_ADDR/v1/sys/policies/acl/keycloak-policy" > /dev/null

    log_info "Vault policy 'keycloak-policy' created"
}

# Setup Vault AppRole for Keycloak
setup_vault_approle() {
    if [ -z "${VAULT_TOKEN:-}" ]; then
        log_warn "No Vault token, skipping AppRole setup"
        return 0
    fi

    log_info "Setting up Vault AppRole for Keycloak"

    # Enable AppRole auth method
    curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
        -d '{"type":"approle"}' \
        "$VAULT_ADDR/v1/sys/auth/approle" > /dev/null 2>&1 || true

    # Create AppRole
    curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
        -d '{
            "policies": ["keycloak-policy"],
            "secret_id_ttl": "24h",
            "token_ttl": "1h",
            "token_max_ttl": "4h"
        }' \
        "$VAULT_ADDR/v1/auth/approle/role/keycloak" > /dev/null

    # Get role-id and create secret-id
    local role_id
    role_id=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/auth/approle/role/keycloak/role-id" | jq -r '.data.role_id')

    local secret_id
    secret_id=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X POST "$VAULT_ADDR/v1/auth/approle/role/keycloak/secret-id" | jq -r '.data.secret_id')

    # Save AppRole credentials
    mkdir -p "$SCRIPT_DIR/vault"
    echo "VAULT_ROLE_ID=$role_id" > "$SCRIPT_DIR/vault/approle-credentials"
    echo "VAULT_SECRET_ID=$secret_id" >> "$SCRIPT_DIR/vault/approle-credentials"
    chmod 600 "$SCRIPT_DIR/vault/approle-credentials"

    log_info "Vault AppRole configured for Keycloak"
    log_info "AppRole credentials saved to: $SCRIPT_DIR/vault/approle-credentials"
}

# Setup environment file
setup_environment() {
    log_info "Setting up Keycloak environment file"

    cat > "$SCRIPT_DIR/.env" << EOF
# Keycloak Vault PostgreSQL Environment Configuration
# Generated on $(date)

# Vault Configuration
VAULT_ADDR=http://purebliss-vault:8200
VAULT_TOKEN=${VAULT_TOKEN:-}

# PostgreSQL Configuration
POSTGRES_HOST=purebliss-postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}

# Keycloak Database Configuration
KEYCLOAK_DB_NAME=keycloak
KEYCLOAK_DB_USER=keycloak
KEYCLOAK_DB_PASSWORD=keycloak_secure_password

# Keycloak Admin Configuration
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin123

# Keycloak Server Configuration
KC_HOSTNAME=dev.purebliss.app
KC_PROXY=edge
KC_HTTP_RELATIVE_PATH=/auth
KC_HTTP_ENABLED=true
KC_HOSTNAME_STRICT=false
KC_HOSTNAME_STRICT_HTTPS=false
KC_START_MODE=start-dev

# Data Paths
KEYCLOAK_DATA_PATH=/mnt/raid0/keycloak/data
KEYCLOAK_LOG_PATH=/mnt/raid0/logs/keycloak

# Logging Configuration
KC_LOG_LEVEL=INFO
KC_LOG_CONSOLE_COLOR=true

# Performance Configuration
KC_CACHE=ispn
KC_CACHE_STACK=tcp
EOF

    log_info "Environment file created: $SCRIPT_DIR/.env"
}

# Create data directories
setup_directories() {
    log_info "Setting up Keycloak data directories"

    local data_path="${KEYCLOAK_DATA_PATH:-/mnt/raid0/keycloak/data}"
    local log_path="${KEYCLOAK_LOG_PATH:-/mnt/raid0/logs}"

    sudo mkdir -p "$data_path" "$log_path"
    sudo chown -R 1000:1000 "$data_path" "$log_path" 2>/dev/null || true

    log_info "Data directories created: $data_path, $log_path"
}

# Create management scripts
create_management_scripts() {
    log_info "Creating Keycloak management scripts"

    # Start script
    cat > "$SCRIPT_DIR/start-keycloak.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Keycloak with Vault and PostgreSQL integration..."

# Load environment
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Start Keycloak
docker-compose -f "$SCRIPT_DIR/keycloak-vault-docker-compose.yml" up -d

echo "Keycloak started. Access at: http://dev.purebliss.app:8080/auth"
echo "Admin console: http://dev.purebliss.app:8080/auth/admin"
EOF

    # Stop script
    cat > "$SCRIPT_DIR/stop-keycloak.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Stopping Keycloak..."
docker-compose -f "$SCRIPT_DIR/keycloak-vault-docker-compose.yml" down

echo "Keycloak stopped."
EOF

    # Status script
    cat > "$SCRIPT_DIR/status-keycloak.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Keycloak Status:"
echo "==============="

# Container status
if docker ps | grep -q purebliss-keycloak; then
    echo "✅ Container: Running"
else
    echo "❌ Container: Not running"
fi

# Health check
if curl -s -f http://localhost:8080/auth/health/ready > /dev/null 2>&1; then
    echo "✅ Health: Ready"
else
    echo "❌ Health: Not ready"
fi

# Database connectivity
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    if PGPASSWORD="$KEYCLOAK_DB_PASSWORD" psql -h "$POSTGRES_HOST" -U "$KEYCLOAK_DB_USER" -d "$KEYCLOAK_DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ Database: Connected"
    else
        echo "❌ Database: Connection failed"
    fi
fi

# Recent logs
echo -e "\nRecent logs:"
docker logs purebliss-keycloak --tail 10 2>/dev/null || echo "No logs available"
EOF

    # Logs script
    cat > "$SCRIPT_DIR/logs-keycloak.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Keycloak Logs (press Ctrl+C to exit):"
echo "====================================="
docker logs -f purebliss-keycloak 2>/dev/null || echo "Container not running"
EOF

    # Make scripts executable
    chmod +x "$SCRIPT_DIR"/*.sh

    log_info "Management scripts created"
}

# Validate setup
validate_setup() {
    log_info "Validating Keycloak setup"

    local errors=0

    # Check required files
    local required_files=(
        "$SCRIPT_DIR/keycloak-vault-entrypoint.sh"
        "$SCRIPT_DIR/keycloak-vault-docker-compose.yml"
        "$SCRIPT_DIR/.env"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Missing file: $file"
            errors=$((errors + 1))
        fi
    done

    # Check executability
    if [ ! -x "$SCRIPT_DIR/keycloak-vault-entrypoint.sh" ]; then
        chmod +x "$SCRIPT_DIR/keycloak-vault-entrypoint.sh"
        log_info "Made entrypoint script executable"
    fi

    # Check network
    if ! docker network ls | grep -q purebliss-net; then
        log_warn "purebliss-net network not found, creating..."
        docker network create purebliss-net
    fi

    if [ $errors -eq 0 ]; then
        log_info "✅ Keycloak setup validation passed"
        return 0
    else
        log_error "❌ Keycloak setup validation failed with $errors errors"
        return 1
    fi
}

# Main setup function
main() {
    log_info "Starting comprehensive Keycloak setup with Vault and PostgreSQL"

    # Check dependencies
    for cmd in docker docker-compose curl jq psql; do
        if ! command -v "$cmd" > /dev/null; then
            log_error "Required command not found: $cmd"
            exit 1
        fi
    done

    # Setup steps
    setup_vault_env || log_warn "Vault environment setup failed"
    setup_directories
    setup_environment

    if [ -n "${VAULT_TOKEN:-}" ]; then
        setup_vault_policy
        setup_postgres_database
        setup_keycloak_admin
        setup_vault_approle
    else
        log_warn "Skipping Vault-dependent setup (no token)"
    fi

    create_management_scripts
    validate_setup

    log_info "✅ Keycloak setup complete!"
    log_info ""
    log_info "📋 Next steps:"
    log_info "  1. Start Keycloak: $SCRIPT_DIR/start-keycloak.sh"
    log_info "  2. Check status: $SCRIPT_DIR/status-keycloak.sh"
    log_info "  3. View logs: $SCRIPT_DIR/logs-keycloak.sh"
    log_info "  4. Access admin: http://dev.purebliss.app:8080/auth/admin"
    log_info ""
    log_info "🔐 Admin credentials are stored in Vault at: secret/keycloak/admin"
    log_info "🗄️ Database credentials are stored in Vault at: secret/keycloak/database"
}

# Execute main function
main "$@"
