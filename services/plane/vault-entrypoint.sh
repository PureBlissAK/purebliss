#!/bin/bash
set -euo pipefail

# Plane Vault Integration Entrypoint
# Fetches Plane database credentials from Vault before starting Plane

LOG_PREFIX="[PLANE-VAULT]"

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
fetch_plane_credentials() {
    local vault_addr="${VAULT_ADDR:-http://vault:8200}"
    local vault_token="${VAULT_TOKEN:-}"
    
    if [[ -z "$vault_token" ]]; then
        log_warn "VAULT_TOKEN not set, using fallback credentials"
        return 1
    fi
    
    log_info "Attempting to fetch Plane credentials from Vault"
    
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
    
    # Attempt to read Plane credentials from Vault
    local vault_secret
    if vault_secret=$(vault kv get -format=json secret/plane 2>/dev/null); then
        local postgres_password redis_password secret_key
        postgres_password=$(echo "$vault_secret" | jq -r '.data.data.postgres_password // empty')
        redis_password=$(echo "$vault_secret" | jq -r '.data.data.redis_password // empty')
        secret_key=$(echo "$vault_secret" | jq -r '.data.data.secret_key // empty')
        
        if [[ -n "$postgres_password" && "$postgres_password" != "null" ]]; then
            log_info "Successfully retrieved PostgreSQL password from Vault for Plane"
            export PLANE_DB_PASSWORD="$postgres_password"
            # Update DATABASE_URL with new password
            export DATABASE_URL="postgres://${POSTGRES_USER:-plane}:$postgres_password@${POSTGRES_HOST:-purebliss-postgres}:${POSTGRES_PORT:-5432}/plane"
        else
            log_warn "PostgreSQL password not found in Vault secret for Plane"
        fi
        
        if [[ -n "$redis_password" && "$redis_password" != "null" ]]; then
            log_info "Successfully retrieved Redis password from Vault for Plane"
            export REDIS_URL="redis://:$redis_password@purebliss-redis:6379"
        else
            log_warn "Redis password not found in Vault secret for Plane"
        fi
        
        if [[ -n "$secret_key" && "$secret_key" != "null" ]]; then
            log_info "Successfully retrieved secret key from Vault for Plane"
            export PLANE_SECRET_KEY="$secret_key"
        else
            log_warn "Secret key not found in Vault secret for Plane"
        fi
        
        return 0
    else
        log_warn "Failed to read secret/plane from Vault, using fallback"
        return 1
    fi
}

# Set default credentials if not provided
setup_default_credentials() {
    if [[ -z "${PLANE_DB_PASSWORD:-}" ]]; then
        log_info "Setting default PostgreSQL password for Plane"
        export PLANE_DB_PASSWORD="postgres_changeme"
        export DATABASE_URL="postgres://${POSTGRES_USER:-plane}:postgres_changeme@${POSTGRES_HOST:-purebliss-postgres}:${POSTGRES_PORT:-5432}/plane"
    fi
    
    if [[ -z "${REDIS_URL:-}" ]] || [[ "$REDIS_URL" == "redis://purebliss-redis:6379" ]]; then
        log_info "Setting default Redis URL for Plane"
        export REDIS_URL="redis://purebliss-redis:6379"
    fi
    
    if [[ -z "${PLANE_SECRET_KEY:-}" ]]; then
        log_info "Setting default secret key for Plane"
        export PLANE_SECRET_KEY="plane_secret_changeme"
    fi
    
    log_info "Default Plane credentials configured"
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
    log_info "Starting Plane with Vault integration"
    
    # Try to fetch credentials from Vault, fall back to defaults if unavailable
    if ! fetch_plane_credentials; then
        setup_default_credentials
    fi
    
    # Wait for PostgreSQL to be available
    wait_for_database
    
    log_info "Starting Plane server"
    log_info "Database URL: ${DATABASE_URL}"
    log_info "Redis URL: ${REDIS_URL}"
    
    # Start Plane with the original entrypoint
    exec "$@"
}

# Execute main function with all provided arguments
main "$@"
