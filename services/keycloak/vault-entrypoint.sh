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

# Check if Vault is available and credentials can be fetched
fetch_keycloak_credentials() {
    local vault_addr="${VAULT_ADDR:-http://vault:8200}"
    local vault_token="${VAULT_TOKEN:-}"
    
    if [[ -z "$vault_token" ]]; then
        log_warn "VAULT_TOKEN not set, using fallback credentials"
        return 1
    fi
    
    log_info "Attempting to fetch Keycloak credentials from Vault"
    
    # Check if vault CLI is available
    if ! command -v vault >/dev/null 2>&1; then
        log_warn "Vault CLI not available, using fallback credentials"
        return 1
    fi
    
    # Check Vault connectivity
    if ! vault status >/dev/null 2>&1; then
        log_warn "Cannot connect to Vault at $vault_addr, using fallback credentials"
        return 1
    fi
    
    # Attempt to read Keycloak credentials from Vault
    local vault_secret
    if vault_secret=$(vault kv get -format=json secret/keycloak 2>/dev/null); then
        local admin_password postgres_password
        admin_password=$(echo "$vault_secret" | jq -r '.data.data.admin_password // empty')
        postgres_password=$(echo "$vault_secret" | jq -r '.data.data.postgres_password // empty')
        
        if [[ -n "$admin_password" && "$admin_password" != "null" ]]; then
            log_info "Successfully retrieved Keycloak admin password from Vault"
            export KEYCLOAK_ADMIN_PASSWORD="$admin_password"
        else
            log_warn "Keycloak admin password not found in Vault secret"
        fi
        
        if [[ -n "$postgres_password" && "$postgres_password" != "null" ]]; then
            log_info "Successfully retrieved Postgres password from Vault for Keycloak"
            export POSTGRES_PASSWORD="$postgres_password"
        else
            log_warn "Postgres password not found in Vault secret for Keycloak"
        fi
        
        return 0
    else
        log_warn "Failed to read secret/keycloak from Vault, using fallback"
        return 1
    fi
}

# Set default credentials if not provided
setup_default_credentials() {
    if [[ -z "${KEYCLOAK_ADMIN_PASSWORD:-}" ]]; then
        log_info "Setting default Keycloak admin password"
        export KEYCLOAK_ADMIN_PASSWORD="keycloak_admin_changeme"
    fi
    
    if [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
        log_info "Setting default Postgres password for Keycloak"
        export POSTGRES_PASSWORD="postgres_changeme"
    fi
    
    log_info "Default Keycloak credentials configured"
}

# Wait for database to be ready
wait_for_database() {
    local max_attempts=30
    local attempt=1
    local postgres_host="${POSTGRES_HOST:-purebliss-postgres}"
    local postgres_port="${POSTGRES_PORT:-5432}"
    
    log_info "Waiting for PostgreSQL to be ready at $postgres_host:$postgres_port"
    
    while [[ $attempt -le $max_attempts ]]; do
        if timeout 5 bash -c "</dev/tcp/$postgres_host/$postgres_port" 2>/dev/null; then
            log_info "PostgreSQL is ready after $attempt attempts"
            return 0
        fi
        
        log_info "Waiting for PostgreSQL... attempt $attempt/$max_attempts"
        sleep 2
        ((attempt++))
    done
    
    log_error "PostgreSQL is not ready after $max_attempts attempts"
    exit 1
}

# Main execution
main() {
    log_info "Starting Keycloak with Vault integration"
    
    # Try to fetch credentials from Vault, fall back to defaults if unavailable
    if ! fetch_keycloak_credentials; then
        setup_default_credentials
    fi
    
    # Wait for PostgreSQL to be available
    wait_for_database
    
    # Set required Keycloak startup environment variables
    export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN_USER:-admin}"
    
    log_info "Starting Keycloak server"
    log_info "Database: ${KC_DB:-postgres} at ${KC_DB_URL_HOST:-$POSTGRES_HOST}:${KC_DB_URL_PORT:-$POSTGRES_PORT}"
    log_info "Database name: ${KC_DB_URL_DATABASE:-$POSTGRES_DB}"
    log_info "Hostname: ${KC_HOSTNAME:-localhost}"
    
    # Start Keycloak with the provided arguments
    exec /opt/keycloak/bin/kc.sh "$@"
}

# Execute main function with all provided arguments
main "$@"
