#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_SECRETS_FILE="/opt/my-secure-ha-stack/secrets/vault-init.json"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
VAULT_AUTO_UNSEAL_SCRIPT="/vault/config/vault-auto-unseal.sh"

# Logging functions
function log_info() {
    echo "[$(date)] [Vault Entrypoint] INFO: $1" | tee -a "$LOG_FILE"
}

function log_error() {
    echo "[$(date)] [Vault Entrypoint] ERROR: $1" | tee -a "$LOG_FILE"
}

function log_success() {
    echo "[$(date)] [Vault Entrypoint] SUCCESS: $1" | tee -a "$LOG_FILE"
}

# 1. Wait for Vault to be available
function wait_for_vault() {
    log_info "Waiting for Vault to become available at ${VAULT_ADDR}..."
    local retries=30
    local count=0
    
    while [[ $count -lt $retries ]]; do
        if curl -s -k "${VAULT_ADDR}/v1/sys/health" &> /dev/null; then
            log_success "Vault is available."
            return 0
        fi
        count=$((count + 1))
        log_info "Vault not ready, waiting... (attempt $count/$retries)"
        sleep 2
    done
    
    log_error "Vault did not become available after $retries attempts."
    return 1
}

# 2. Initialize Vault if not already initialized
function initialize_vault() {
    log_info "Checking Vault initialization status..."
    local initialized
    initialized=$(vault status -format=json | jq -r .initialized)

    if [[ "$initialized" == "true" ]]; then
        log_info "Vault is already initialized."
        return 0
    fi

    log_info "Vault is not initialized. Initializing..."
    local init_output
    init_output=$(vault operator init -key-shares=1 -key-threshold=1 -format=json)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to initialize Vault."
        return 1
    fi

    echo "$init_output" > "$VAULT_SECRETS_FILE"
    chmod 600 "$VAULT_SECRETS_FILE"
    log_success "Vault initialized. Unseal keys and root token saved to $VAULT_SECRETS_FILE"
}

# 3. Unseal Vault
function unseal_vault() {
    log_info "Checking Vault seal status..."
    if ! vault status -format=json | jq -e .sealed; then
        log_success "Vault is already unsealed."
        return 0
    fi

    log_info "Vault is sealed. Attempting auto-unseal..."
    if [[ -x "$VAULT_AUTO_UNSEAL_SCRIPT" ]]; then
        if "$VAULT_AUTO_UNSEAL_SCRIPT"; then
            log_success "Vault unsealed successfully via auto-unseal script."
            return 0
        else
            log_error "Auto-unseal script failed. Manual intervention may be required."
            return 1
        fi
    else
        log_error "Auto-unseal script not found or not executable at $VAULT_AUTO_UNSEAL_SCRIPT"
        return 1
    fi
}

# 4. Log in and store root token
function login_and_store_token() {
    log_info "Logging into Vault to store root token..."
    local root_token
    root_token=$(jq -r .root_token < "$VAULT_SECRETS_FILE")

    if [[ -z "$root_token" ]]; then
        log_error "Could not find root token in $VAULT_SECRETS_FILE"
        return 1
    fi

    export VAULT_TOKEN="$root_token"
    echo "$VAULT_TOKEN" > "$VAULT_TOKEN_FILE"
    chmod 600 "$VAULT_TOKEN_FILE"

    log_success "Logged in with root token and stored it in $VAULT_TOKEN_FILE"
}

# 5. Keep Vault running in the foreground
function start_vault_server() {
    log_info "Starting Vault server..."
    exec vault server -config=/vault/config/vault.hcl
}

# Main execution
function main() {
    log_info "Vault container entrypoint started."
    
    # Start Vault in the background to initialize
    vault server -config=/vault/config/vault.hcl &
    VAULT_PID=$!

    wait_for_vault
    initialize_vault
    unseal_vault
    login_and_store_token

    log_success "Vault is initialized, unsealed, and ready for use."
    
    # Bring the Vault server process to the foreground
    log_info "Bringing Vault server to the foreground."
    wait $VAULT_PID
}

trap 'log_error "Vault entrypoint script failed at line $LINENO"' ERR

main "$@"
