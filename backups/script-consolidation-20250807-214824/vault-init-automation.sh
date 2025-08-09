#!/bin/bash
set -euo pipefail

# Vault Initialization and Key Management Automation
# Following Pure Bliss best practices for secure, automated setup

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_KEYS_DIR="/opt/my-secure-ha-stack/secrets/vault"
VAULT_KEYS_FILE="$VAULT_KEYS_DIR/vault-keys.enc"
VAULT_ROOT_TOKEN_FILE="$VAULT_KEYS_DIR/vault-root-token.enc"
VAULT_ADDR="https://127.0.0.1:8200"

echo "[$(date)] INFO: Starting Vault initialization automation" >> "$LOG_FILE"

# Function to prompt for master password securely
get_master_password() {
    local password
    echo "🔐 Vault Automation Setup"
    echo "Please enter a master password to encrypt Vault keys:"
    echo "(This password will be used to encrypt/decrypt Vault unseal keys and root token)"
    read -s -p "Master Password: " password
    echo
    read -s -p "Confirm Password: " password_confirm
    echo

    if [[ "$password" != "$password_confirm" ]]; then
        echo "❌ Passwords do not match. Exiting."
        exit 1
    fi

    if [[ ${#password} -lt 12 ]]; then
        echo "❌ Password must be at least 12 characters. Exiting."
        exit 1
    fi

    # Save master password securely for automation (optional)
    echo "💾 Save master password for automated unsealing? (y/N)"
    read -p "Choice: " save_password
    if [[ "$save_password" =~ ^[Yy]$ ]]; then
        sudo mkdir -p "$VAULT_KEYS_DIR"
        sudo chown "$USER:$USER" "$VAULT_KEYS_DIR"
        chmod 700 "$VAULT_KEYS_DIR"
        echo "$password" > "$VAULT_KEYS_DIR/.master_password"
        chmod 600 "$VAULT_KEYS_DIR/.master_password"
        echo "✅ Master password saved for automation"
        echo "[$(date)] INFO: Master password saved for Vault automation" >> "$LOG_FILE"
    fi

    echo "$password"
}

# Function to encrypt data with master password
encrypt_data() {
    local data="$1"
    local password="$2"
    echo "$data" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$password"
}

# Function to decrypt data with master password
decrypt_data() {
    local encrypted_file="$1"
    local password="$2"
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt -in "$encrypted_file" -pass pass:"$password"
}

# Function to check if Vault is initialized
is_vault_initialized() {
    local status_json
    status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo '{"initialized":false}')
    echo "$status_json" | grep -q '"initialized":true'
}

# Function to initialize Vault
initialize_vault() {
    local master_password="$1"

    echo "🚀 Initializing Vault with 5 key shares and threshold of 3..."

    # Initialize Vault
    local init_response
    init_response=$(curl -sk -X POST -d '{"secret_shares": 5, "secret_threshold": 3}' "$VAULT_ADDR/v1/sys/init")

    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to initialize Vault"
        echo "[$(date)] ERROR: Vault initialization failed" >> "$LOG_FILE"
        exit 1
    fi

    # Extract keys and root token
    local unseal_keys root_token
    unseal_keys=$(echo "$init_response" | jq -r '.keys[]' | tr '\n' '|')
    root_token=$(echo "$init_response" | jq -r '.root_token')

    # Create secure directory
    sudo mkdir -p "$VAULT_KEYS_DIR"
    sudo chown "$USER:$USER" "$VAULT_KEYS_DIR"
    chmod 700 "$VAULT_KEYS_DIR"

    # Encrypt and save keys
    encrypt_data "$unseal_keys" "$master_password" > "$VAULT_KEYS_FILE"
    encrypt_data "$root_token" "$master_password" > "$VAULT_ROOT_TOKEN_FILE"

    chmod 600 "$VAULT_KEYS_FILE" "$VAULT_ROOT_TOKEN_FILE"

    echo "✅ Vault initialized successfully!"
    echo "🔐 Unseal keys and root token encrypted and saved securely"
    echo "[$(date)] SUCCESS: Vault initialized and keys encrypted" >> "$LOG_FILE"

    return 0
}

# Function to unseal Vault
unseal_vault() {
    local master_password="$1"

    echo "🔓 Unsealing Vault..."

    if [[ ! -f "$VAULT_KEYS_FILE" ]]; then
        echo "❌ Vault keys file not found: $VAULT_KEYS_FILE"
        exit 1
    fi

    # Decrypt unseal keys
    local unseal_keys_raw unseal_keys_array
    unseal_keys_raw=$(decrypt_data "$VAULT_KEYS_FILE" "$master_password" 2>/dev/null || {
        echo "❌ Failed to decrypt Vault keys. Wrong password?"
        exit 1
    })

    IFS='|' read -ra unseal_keys_array <<< "$unseal_keys_raw"

    # Unseal with first 3 keys (threshold)
    for i in {0..2}; do
        if [[ -n "${unseal_keys_array[$i]:-}" ]]; then
            echo "Using unseal key $((i+1))/3..."
            curl -sk -X POST -d "{\"key\": \"${unseal_keys_array[$i]}\"}" "$VAULT_ADDR/v1/sys/unseal" >/dev/null
        fi
    done

    # Check if unsealed
    local status_json
    status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
    if echo "$status_json" | grep -q '"sealed":false'; then
        echo "✅ Vault unsealed successfully!"
        echo "[$(date)] SUCCESS: Vault unsealed automatically" >> "$LOG_FILE"
        return 0
    else
        echo "❌ Vault unseal failed"
        echo "[$(date)] ERROR: Vault unseal failed" >> "$LOG_FILE"
        exit 1
    fi
}

# Function to get root token
get_root_token() {
    local master_password="$1"

    if [[ ! -f "$VAULT_ROOT_TOKEN_FILE" ]]; then
        echo "❌ Vault root token file not found: $VAULT_ROOT_TOKEN_FILE"
        exit 1
    fi

    decrypt_data "$VAULT_ROOT_TOKEN_FILE" "$master_password" 2>/dev/null || {
        echo "❌ Failed to decrypt root token. Wrong password?"
        exit 1
    }
}

# Main automation logic
main() {
    # Check if Vault is running
    if ! curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
        echo "❌ Vault is not running or not accessible at $VAULT_ADDR"
        echo "Please ensure Vault container is running first."
        exit 1
    fi

    # Get master password
    local master_password
    master_password=$(get_master_password)

    if is_vault_initialized; then
        echo "ℹ️  Vault is already initialized"

        # Check if Vault is sealed
        local status_json
        status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
        if echo "$status_json" | grep -q '"sealed":true'; then
            unseal_vault "$master_password"
        else
            echo "✅ Vault is already unsealed"
        fi
    else
        echo "ℹ️  Vault is not initialized. Initializing now..."
        initialize_vault "$master_password"
        unseal_vault "$master_password"
    fi

    # Display root token for reference
    echo ""
    echo "🔑 Root Token (for administrative tasks):"
    get_root_token "$master_password"
    echo ""
    echo "💾 Save this token securely - it's also encrypted in: $VAULT_ROOT_TOKEN_FILE"

    # Save root token to environment for automation
    local root_token
    root_token=$(get_root_token "$master_password")
    echo "export VAULT_TOKEN='$root_token'" > "$VAULT_KEYS_DIR/vault-env.sh"
    chmod 600 "$VAULT_KEYS_DIR/vault-env.sh"

    echo ""
    echo "🎉 Vault automation setup complete!"
    echo "📁 Encrypted files saved in: $VAULT_KEYS_DIR"
    echo "🔧 To use in scripts: source $VAULT_KEYS_DIR/vault-env.sh"
    echo ""

    echo "[$(date)] SUCCESS: Vault automation setup completed successfully" >> "$LOG_FILE"
}

# Run main function
main "$@"
