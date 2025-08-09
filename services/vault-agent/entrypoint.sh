#!/bin/bash
set -euo pipefail

# Vault Agent Entrypoint for PureBliss Development Environment
# Provides API proxy and template rendering for other services

# Logging function
log_info() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [Vault Agent] INFO: $1"
}

log_error() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [Vault Agent] ERROR: $1" >&2
}

log_success() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [Vault Agent] SUCCESS: $1"
}

# Append to dev log
append_to_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] VAULT_AGENT: $1" >> /vault/agent/logs/vault-agent.log 2>/dev/null || true
}

log_info "Vault Agent container entrypoint started."
append_to_log "Vault Agent entrypoint started"

# Wait for Vault server to be available
VAULT_ADDR="${VAULT_ADDR:-http://purebliss-vault:8200}"
MAX_ATTEMPTS=30
ATTEMPT=1

log_info "Waiting for Vault server to become available at ${VAULT_ADDR}..."

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -sk -k "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; then
        log_success "Vault server is available."
        append_to_log "Vault server available at ${VAULT_ADDR}"
        break
    fi

    log_info "Vault not ready, waiting... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    log_error "Vault server is not available after $MAX_ATTEMPTS attempts"
    append_to_log "ERROR: Vault server not available after $MAX_ATTEMPTS attempts"
    exit 1
fi

# Ensure directories exist with proper permissions
log_info "Setting up directories and permissions..."
mkdir -p /vault/agent/output /vault/agent/logs /vault/secrets /vault/templates

# Fix ownership if running as root (for development)
if [ "$(id -u)" = "0" ]; then
    chown -R vault:vault /vault/agent/output /vault/agent/logs /vault/secrets 2>/dev/null || true
    chmod -R 755 /vault/agent/output /vault/agent/logs /vault/secrets
fi

# Verify configuration file exists
if [ ! -f "/etc/vault-agent/config.hcl" ]; then
    log_error "Vault Agent configuration file not found at /etc/vault-agent/config.hcl"
    append_to_log "ERROR: Configuration file not found"
    exit 1
fi

log_info "Configuration file found, validating..."

# Test Vault connectivity before starting agent
log_info "Testing Vault connectivity..."
if ! curl -sk -k "${VAULT_ADDR}/v1/sys/health" | grep -q '"initialized":true'; then
    log_error "Vault server is not initialized or not healthy"
    append_to_log "ERROR: Vault server not initialized or unhealthy"
    exit 1
fi

log_success "Vault server is healthy and initialized."
append_to_log "Vault server health check passed"

# Start Vault Agent
log_info "Starting Vault Agent with configuration..."
append_to_log "Starting Vault Agent"

# Switch to vault user if running as root
if [ "$(id -u)" = "0" ]; then
    log_info "Switching to vault user and starting agent..."
    exec su-exec vault vault agent -config=/etc/vault-agent/config.hcl
else
    log_info "Starting agent as current user..."
    exec vault agent -config=/etc/vault-agent/config.hcl
fi
