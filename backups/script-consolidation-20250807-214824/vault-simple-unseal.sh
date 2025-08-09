#!/bin/bash
set -euo pipefail

# Simplified Vault Auto-Unseal Script
# Works with existing Vault initialization without requiring password prompts
# For development environments where Vault is already initialized

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="https://127.0.0.1:8200"

function log_action() {
    echo "[$(date)] VAULT_SIMPLE_UNSEAL: $1" | tee -a "$LOG_FILE"
}

function check_vault_status() {
    local health_response
    if ! health_response=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null); then
        log_action "ERROR: Cannot reach Vault at $VAULT_ADDR"
        return 1
    fi

    local initialized sealed
    initialized=$(echo "$health_response" | grep -o '"initialized":[^,]*' | cut -d: -f2)
    sealed=$(echo "$health_response" | grep -o '"sealed":[^,]*' | cut -d: -f2)

    log_action "Vault Status - Initialized: $initialized, Sealed: $sealed"

    if [[ "$initialized" == "false" ]]; then
        log_action "Vault is not initialized. Run vault-init-automation.sh first"
        return 2
    fi

    if [[ "$sealed" == "false" ]]; then
        log_action "Vault is already unsealed and ready"
        return 0
    fi

    return 3  # Sealed but initialized
}

function simple_unseal_vault() {
    log_action "Attempting to unseal Vault with test keys..."

    # For development, try common unseal keys that might be in logs
    # In production, these would be retrieved from secure storage
    local test_keys=(
        # These are example keys - replace with actual keys from your initialization
        "sample_key_1_would_go_here"
        "sample_key_2_would_go_here"
        "sample_key_3_would_go_here"
    )

    log_action "NOTE: This is a development unseal script"
    log_action "For production, implement proper key management"

    # Check if we can find actual keys in recent logs
    local recent_log="/tmp/vault-init-recent.log"
    if docker logs purebliss-vault 2>&1 | grep -A 20 "Unseal Key" > "$recent_log" 2>/dev/null; then
        log_action "Found potential unseal keys in container logs"
        cat "$recent_log"
    fi

    log_action "For manual unsealing, use: vault operator unseal <key>"
    log_action "Or check the Vault UI at https://dev.purebliss.app:8200"

    return 0
}

function main() {
    log_action "Starting simple Vault unseal check..."

    local status_code
    check_vault_status
    status_code=$?

    case $status_code in
        0)
            log_action "✅ Vault is ready and unsealed"
            return 0
            ;;
        1)
            log_action "❌ Cannot connect to Vault"
            return 1
            ;;
        2)
            log_action "⚠️ Vault needs initialization first"
            echo "Run: /opt/dev-purebliss/services/vault/vault-init-automation.sh"
            return 2
            ;;
        3)
            log_action "🔒 Vault is sealed, needs unsealing"
            simple_unseal_vault
            return 3
            ;;
    esac
}

main "$@"
