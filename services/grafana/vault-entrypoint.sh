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
        local admin_password
        admin_password=$(echo "$vault_secret" | jq -r '.data.data.admin_password // empty')
        
        if [[ -n "$admin_password" && "$admin_password" != "null" ]]; then
            log_info "Successfully retrieved Grafana admin password from Vault"
            export GF_SECURITY_ADMIN_PASSWORD="$admin_password"
            return 0
        else
            log_warn "Grafana admin password not found in Vault secret"
            return 1
        fi
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
    
    log_info "Default Grafana credentials configured"
}

# Configure Grafana environment
configure_grafana() {
    # Ensure the admin user is set (default to 'admin' if not specified)
    export GF_SECURITY_ADMIN_USER="${GF_SECURITY_ADMIN_USER:-admin}"
    
    # Set default server configuration
    export GF_SERVER_HTTP_PORT="${GF_SERVER_HTTP_PORT:-3000}"
    export GF_SERVER_PROTOCOL="${GF_SERVER_PROTOCOL:-http}"
    
    # Configure logging
    export GF_LOG_LEVEL="${GF_LOG_LEVEL:-info}"
    
    # Enable anonymous access for health checks (read-only)
    export GF_AUTH_ANONYMOUS_ENABLED="${GF_AUTH_ANONYMOUS_ENABLED:-false}"
    
    log_info "Grafana configuration completed"
    log_info "Admin user: $GF_SECURITY_ADMIN_USER"
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
