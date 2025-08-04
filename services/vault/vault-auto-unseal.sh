#!/bin/bash
set -euo pipefail

# Automated Vault Unseal Script for Startup
# Part of Pure Bliss automated infrastructure

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_KEYS_DIR="/opt/my-secure-ha-stack/secrets/vault"
VAULT_KEYS_FILE="$VAULT_KEYS_DIR/vault-keys.enc"
VAULT_ADDR="https://127.0.0.1:8200"

# Function to decrypt data with master password from file
decrypt_with_stored_password() {
    local encrypted_file="$1"
    local password_file="$VAULT_KEYS_DIR/.master_password"
    
    if [[ ! -f "$password_file" ]]; then
        echo "❌ Master password file not found. Run vault-init-automation.sh first."
        return 1
    fi
    
    local password
    password=$(cat "$password_file")
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt -in "$encrypted_file" -pass pass:"$password" 2>/dev/null
}

# Function to check if Vault needs unsealing
needs_unsealing() {
    local status_json
    status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo '{"sealed":true}')
    echo "$status_json" | grep -q '"sealed":true'
}

# Function to wait for Vault to be available
wait_for_vault() {
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for Vault to become available..."
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
            echo "✅ Vault is available"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts - Vault not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    echo "❌ Vault did not become available after $max_attempts attempts"
    return 1
}

# Main unseal function
auto_unseal() {
    echo "[$(date)] INFO: Starting automated Vault unseal process" >> "$LOG_FILE"
    
    # Wait for Vault to be available
    if ! wait_for_vault; then
        echo "[$(date)] ERROR: Vault not available for unsealing" >> "$LOG_FILE"
        exit 1
    fi
    
    # Check if unsealing is needed
    if ! needs_unsealing; then
        echo "✅ Vault is already unsealed"
        echo "[$(date)] INFO: Vault already unsealed, no action needed" >> "$LOG_FILE"
        exit 0
    fi
    
    echo "🔓 Vault is sealed, proceeding with automatic unseal..."
    
    # Check if keys file exists
    if [[ ! -f "$VAULT_KEYS_FILE" ]]; then
        echo "❌ Vault keys file not found: $VAULT_KEYS_FILE"
        echo "Please run vault-init-automation.sh first to initialize Vault."
        echo "[$(date)] ERROR: Vault keys file not found for unsealing" >> "$LOG_FILE"
        exit 1
    fi
    
    # Decrypt and use unseal keys
    local unseal_keys_raw unseal_keys_array
    unseal_keys_raw=$(decrypt_with_stored_password "$VAULT_KEYS_FILE" || {
        echo "❌ Failed to decrypt Vault keys for automated unseal"
        echo "[$(date)] ERROR: Failed to decrypt Vault keys for unsealing" >> "$LOG_FILE"
        exit 1
    })
    
    IFS='|' read -ra unseal_keys_array <<< "$unseal_keys_raw"
    
    # Unseal with first 3 keys (threshold)
    echo "🔐 Applying unseal keys..."
    for i in {0..2}; do
        if [[ -n "${unseal_keys_array[$i]:-}" ]]; then
            echo "Applying unseal key $((i+1))/3..."
            curl -sk -X POST -d "{\"key\": \"${unseal_keys_array[$i]}\"}" "$VAULT_ADDR/v1/sys/unseal" >/dev/null 2>&1
            sleep 1
        fi
    done
    
    # Verify unsealing
    if ! needs_unsealing; then
        echo "✅ Vault unsealed successfully!"
        echo "[$(date)] SUCCESS: Vault unsealed automatically during startup" >> "$LOG_FILE"
        
        # Set up environment for automation
        if [[ -f "$VAULT_KEYS_DIR/vault-env.sh" ]]; then
            source "$VAULT_KEYS_DIR/vault-env.sh"
            echo "🔧 Vault environment loaded for automation"
        fi
        
        exit 0
    else
        echo "❌ Vault unseal failed"
        echo "[$(date)] ERROR: Automatic Vault unseal failed" >> "$LOG_FILE"
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    auto_unseal "$@"
fi
