#!/bin/bash
set -euo pipefail

# Grafana Vault Integration Entrypoint
# Fetches Grafana admin credentials from Vault before starting Grafana

LOG_PREFIX="[GRAFANA-VAULT]"

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
fetch_grafana_credentials() {
    local vault_addr="${VAULT_ADDR:-http://vault:8200}"
    local vault_token="${VAULT_TOKEN:-}"
    
    if [[ -z "$vault_token" ]]; then
        log_warn "VAULT_TOKEN not set, using fallback credentials"
        return 1
    fi
    
    log_info "Attempting to fetch Grafana credentials from Vault"
    
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
    
    # Attempt to read Grafana credentials from Vault
    local vault_secret
    if vault_secret=$(vault kv get -format=json secret/grafana 2>/dev/null); then
        local admin_password postgres_password
        admin_password=$(echo "$vault_secret" | jq -r '.data.data.admin_password // empty')
        postgres_password=$(echo "$vault_secret" | jq -r '.data.data.postgres_password // empty')
        
        if [[ -n "$admin_password" && "$admin_password" != "null" ]]; then
            log_info "Successfully retrieved Grafana admin password from Vault"
            export GF_SECURITY_ADMIN_PASSWORD="$admin_password"
        else
            log_warn "Grafana admin password not found in Vault secret"
        fi
        
        if [[ -n "$postgres_password" && "$postgres_password" != "null" ]]; then
            log_info "Successfully retrieved PostgreSQL password from Vault for Grafana"
            export GF_DATABASE_PASSWORD="$postgres_password"
        else
            log_warn "PostgreSQL password not found in Vault secret for Grafana"
        fi
        
        return 0
    else
        log_warn "Failed to read secret/grafana from Vault, using fallback"
        return 1
    fi
}

# Set default credentials if not provided
setup_default_credentials() {
    if [[ -z "${GF_SECURITY_ADMIN_PASSWORD:-}" ]]; then
        log_info "Setting default Grafana admin password"
        export GF_SECURITY_ADMIN_PASSWORD="grafana_admin_changeme"
    fi
    
    if [[ -z "${GF_DATABASE_PASSWORD:-}" ]]; then
        log_info "Setting default PostgreSQL password for Grafana"
        export GF_DATABASE_PASSWORD="postgres_changeme"
    fi
    
    log_info "Default Grafana credentials configured"
}

# Configure Grafana environment
configure_grafana() {
    # Ensure the admin user is set (default to 'admin' if not specified)
    export GF_SECURITY_ADMIN_USER="${GF_SECURITY_ADMIN_USER:-admin}"
    
    # Configure PostgreSQL database connection
    export GF_DATABASE_TYPE="${GF_DATABASE_TYPE:-postgres}"
    export GF_DATABASE_HOST="${GF_DATABASE_HOST:-purebliss-postgres}"
    export GF_DATABASE_PORT="${GF_DATABASE_PORT:-5432}"
    export GF_DATABASE_NAME="${GF_DATABASE_NAME:-grafana}"
    export GF_DATABASE_USER="${GF_DATABASE_USER:-grafana}"
    export GF_DATABASE_SSL_MODE="${GF_DATABASE_SSL_MODE:-disable}"
    
    # Set default server configuration
    export GF_SERVER_HTTP_PORT="${GF_SERVER_HTTP_PORT:-3000}"
    export GF_SERVER_PROTOCOL="${GF_SERVER_PROTOCOL:-http}"
    
    # Configure logging
    export GF_LOG_LEVEL="${GF_LOG_LEVEL:-info}"
    
    # Enable anonymous access for health checks (read-only)
    export GF_AUTH_ANONYMOUS_ENABLED="${GF_AUTH_ANONYMOUS_ENABLED:-false}"
    
    log_info "Grafana configuration completed"
    log_info "Admin user: $GF_SECURITY_ADMIN_USER"
    log_info "Database: $GF_DATABASE_TYPE at $GF_DATABASE_HOST:$GF_DATABASE_PORT"
    log_info "Database name: $GF_DATABASE_NAME"
    log_info "Server port: $GF_SERVER_HTTP_PORT"
    log_info "Log level: $GF_LOG_LEVEL"
}

# Main execution
main() {
    log_info "Starting Grafana with Vault integration"
    
    # Try to fetch credentials from Vault, fall back to defaults if unavailable
    if ! fetch_grafana_credentials; then
        setup_default_credentials
    fi
    
    # Configure Grafana environment
    configure_grafana
    
    log_info "Starting Grafana server"
    
    # Start Grafana with the original entrypoint
    exec /run.sh "$@"
}

# Execute main function with all provided arguments
main "$@"
