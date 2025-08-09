#!/bin/bash
set -euo pipefail

# Test Vault Initialization Script
# For testing the complete automation workflow

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_KEYS_DIR="/opt/my-secure-ha-stack/secrets/vault"
VAULT_KEYS_FILE="$VAULT_KEYS_DIR/vault-keys.enc"
VAULT_ROOT_TOKEN_FILE="$VAULT_KEYS_DIR/vault-root-token.enc"
VAULT_ADDR="https://127.0.0.1:8200"

function log_action() {
    echo "[$(date)] VAULT_INIT_TEST: $1" | tee -a "$LOG_FILE"
}

function test_vault_initialization() {
    log_action "Testing Vault initialization..."

    # Check if Vault is accessible
    if ! curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
        log_action "ERROR: Vault is not accessible at $VAULT_ADDR"
        return 1
    fi

    # Check if already initialized
    local init_status
    init_status=$(curl -sk "$VAULT_ADDR/v1/sys/init" | grep -o '"initialized":[^,]*' | cut -d: -f2)

    if [[ "$init_status" == "true" ]]; then
        log_action "Vault is already initialized"
        return 0
    fi

    log_action "Vault is not initialized, proceeding with initialization..."

    # Initialize Vault with 5 key shares, threshold of 3
    local init_response
    init_response=$(curl -sk -X POST \
        -H "Content-Type: application/json" \
        -d '{"secret_shares": 5, "secret_threshold": 3}' \
        "$VAULT_ADDR/v1/sys/init")

    if [[ $? -ne 0 ]]; then
        log_action "ERROR: Failed to initialize Vault"
        return 1
    fi

    log_action "Vault initialization successful"
    echo "$init_response"

    # Extract unseal keys and root token (for testing - normally would encrypt these)
    local unseal_keys root_token
    unseal_keys=$(echo "$init_response" | grep -o '"keys":\[[^]]*\]' | sed 's/"keys":\[//;s/\]//;s/"//g')
    root_token=$(echo "$init_response" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)

    log_action "Extracted ${#unseal_keys[@]} unseal keys and root token"

    # Test unsealing with first 3 keys
    log_action "Testing Vault unsealing..."
    local key_count=0
    for key in $(echo "$unseal_keys" | tr ',' '\n' | head -3); do
        key=$(echo "$key" | tr -d ' ')
        curl -sk -X POST \
            -H "Content-Type: application/json" \
            -d "{\"key\": \"$key\"}" \
            "$VAULT_ADDR/v1/sys/unseal" >/dev/null

        ((key_count++))
        log_action "Applied unseal key $key_count/3"
    done

    # Verify Vault is unsealed
    local sealed_status
    sealed_status=$(curl -sk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2)

    if [[ "$sealed_status" == "false" ]]; then
        log_action "SUCCESS: Vault is now unsealed and ready"
        return 0
    else
        log_action "ERROR: Vault is still sealed after unseal attempt"
        return 1
    fi
}

function main() {
    log_action "Starting Vault initialization test..."

    # Ensure directories exist
    mkdir -p "$VAULT_KEYS_DIR"
    chmod 700 "$VAULT_KEYS_DIR"

    if test_vault_initialization; then
        log_action "Test completed successfully"
        return 0
    else
        log_action "Test failed"
        return 1
    fi
}

main "$@"
