#!/bin/bash
set -euo pipefail

# Keycloak Vault Integration Entrypoint
# Fetches Keycloak admin credentials and database passwords from Vault before starting Keycloak

LOG_PREFIX="[KEYCLOAK-VAULT]"

log_info() {
    echo "$LOG_PREFIX INFO: $1" >&2
}

log_error() {
    echo "$LOG_PREFIX ERROR: $1" >&2
}

log_warn() {
    echo "$LOG_PREFIX WARN: $1" >&2
}

# Fetch secrets from Vault
if [ -n "${VAULT_TOKEN:-}" ]; then
    log_info "Attempting to fetch Keycloak credentials from Vault"
    
    # Check if vault CLI is available
    if command -v vault >/dev/null 2>&1; then
        # Attempt to read Keycloak credentials from Vault
        if KEYCLOAK_SECRETS=$(vault kv get -format=json secret/keycloak 2>/dev/null); then
            ADMIN_PASSWORD=$(echo "$KEYCLOAK_SECRETS" | jq -r '.data.data.admin_password // empty')
            POSTGRES_PASSWORD=$(echo "$KEYCLOAK_SECRETS" | jq -r '.data.data.postgres_password // empty')
            
            if [[ -n "$ADMIN_PASSWORD" && "$ADMIN_PASSWORD" != "null" ]]; then
                log_info "Successfully retrieved Keycloak admin password from Vault"
                export KEYCLOAK_ADMIN_PASSWORD="$ADMIN_PASSWORD"
            fi
            
            if [[ -n "$POSTGRES_PASSWORD" && "$POSTGRES_PASSWORD" != "null" ]]; then
                log_info "Successfully retrieved PostgreSQL password from Vault"
                export KC_DB_PASSWORD="$POSTGRES_PASSWORD"
            fi
        else
            log_warn "Failed to read secret/keycloak from Vault, using defaults"
        fi
    else
        log_warn "Vault CLI not available, using defaults"
    fi
else
    log_warn "VAULT_TOKEN not set, using defaults"
fi

# Set defaults if not retrieved from Vault
export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN_USER:-admin}"
export KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-keycloak_admin_changeme}"
export KC_DB="${KC_DB:-postgres}"
export KC_DB_URL="${KC_DB_URL:-jdbc:postgresql://purebliss-postgres:5432/keycloak}"
export KC_DB_USERNAME="${POSTGRES_USER:-keycloak}"
export KC_DB_PASSWORD="${KC_DB_PASSWORD:-keycloak_password_changeme}"

log_info "Starting Keycloak with admin user: $KEYCLOAK_ADMIN"
log_info "Database URL: $KC_DB_URL"

# Build and start Keycloak with PostgreSQL configuration
log_info "Building Keycloak with PostgreSQL configuration..."
/opt/keycloak/bin/kc.sh build --db=postgres

log_info "Starting Keycloak with PostgreSQL..."
exec /opt/keycloak/bin/kc.sh start \
    --db=postgres \
    --db-url="$KC_DB_URL" \
    --db-username="$KC_DB_USERNAME" \
    --db-password="$KC_DB_PASSWORD"
