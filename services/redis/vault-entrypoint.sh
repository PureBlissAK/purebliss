#!/bin/bash
set -euo pipefail

# Redis Vault Integration Entrypoint
# Fetches Redis authentication password from Vault before starting Redis server

LOG_PREFIX="[REDIS-VAULT]"

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
fetch_redis_credentials() {
    local vault_addr="${VAULT_ADDR:-http://vault:8200}"
    local vault_token="${VAULT_TOKEN:-}"
    
    if [[ -z "$vault_token" ]]; then
        log_warn "VAULT_TOKEN not set, using fallback Redis password"
        return 1
    fi
    
    log_info "Attempting to fetch Redis credentials from Vault"
    
    # Check if vault CLI is available
    if ! command -v vault >/dev/null 2>&1; then
        log_warn "Vault CLI not available, using fallback Redis password"
        return 1
    fi
    
    # Check Vault connectivity
    if ! vault status >/dev/null 2>&1; then
        log_warn "Cannot connect to Vault at $vault_addr, using fallback Redis password"
        return 1
    fi
    
    # Attempt to read Redis credentials from Vault
    local vault_secret
    if vault_secret=$(vault kv get -format=json secret/redis 2>/dev/null); then
        local redis_password
        redis_password=$(echo "$vault_secret" | jq -r '.data.data.password // empty')
        
        if [[ -n "$redis_password" && "$redis_password" != "null" ]]; then
            log_info "Successfully retrieved Redis password from Vault"
            export REDIS_PASSWORD="$redis_password"
            return 0
        else
            log_warn "Redis password not found in Vault secret, using fallback"
            return 1
        fi
    else
        log_warn "Failed to read secret/redis from Vault, using fallback"
        return 1
    fi
}

# Set default Redis password if not provided
setup_redis_auth() {
    if [[ -z "${REDIS_PASSWORD:-}" ]]; then
        log_info "No Redis password set, generating default fallback"
        export REDIS_PASSWORD="redis_default_changeme"
    fi
    
    log_info "Redis authentication configured"
}

# Main execution
main() {
    log_info "Starting Redis with Vault integration"
    
    # Try to fetch credentials from Vault, fall back to defaults if unavailable
    if ! fetch_redis_credentials; then
        setup_redis_auth
    fi
    
    # Update Redis configuration to use authentication
    local redis_conf="/tmp/redis-auth.conf"
    cat > "$redis_conf" <<EOF
# Redis authentication configuration
requirepass $REDIS_PASSWORD
masterauth $REDIS_PASSWORD

# Persistence configuration
appendonly yes
appendfsync everysec

# Security configuration
protected-mode yes
bind 0.0.0.0

# Performance tuning
maxmemory-policy allkeys-lru
tcp-keepalive 300
EOF
    
    log_info "Starting Redis server with authentication"
    
    # Start Redis with the generated configuration
    exec redis-server "$redis_conf" "$@"
}

# Execute main function with all provided arguments
main "$@"
