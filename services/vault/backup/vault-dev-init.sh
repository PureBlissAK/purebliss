#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_DEV_INIT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-dev-init.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi
if [[ -f "$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "$SCRIPT_DIR/utilities/retry-utils.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
vault_dev_init_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_dev_init_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_dev_init_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

set -euo pipefail

# Vault Development Initialization - Non-Interactive
# For development environments only - uses a fixed master password

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_KEYS_DIR="/opt/my-secure-ha-stack/secrets/vault"
VAULT_KEYS_FILE="$VAULT_KEYS_DIR/vault-keys.enc"
VAULT_ROOT_TOKEN_FILE="$VAULT_KEYS_DIR/vault-root-token.enc"
VAULT_ADDR="https://127.0.0.1:8200"
VAULT_UNSEAL_KEYS_ENV="/opt/my-secure-ha-stack/vault-unseal-keys.env"

# Development master password (change for production)
DEV_MASTER_PASSWORD="purebliss-dev-vault-2025"

echo "[$(date)] INFO: Starting automated Vault initialization for development" | tee -a "$LOG_FILE"

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

    echo "[$(date)] INFO: Initializing Vault with 5 key shares and threshold of 3..." | tee -a "$LOG_FILE"

    # Initialize Vault
    local init_response
    init_response=$(curl -sk -X POST -d '{"secret_shares": 5, "secret_threshold": 3}' "$VAULT_ADDR/v1/sys/init")

    if [[ $? -ne 0 ]]; then
        echo "[$(date)] ERROR: Vault initialization failed" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Extract keys and root token
    local unseal_keys root_token
    unseal_keys=$(echo "$init_response" | jq -r '.keys[]' | tr '\n' '|')
    root_token=$(echo "$init_response" | jq -r '.root_token')

    # Create secure directory
    sudo mkdir -p "$VAULT_KEYS_DIR" || mkdir -p "$VAULT_KEYS_DIR"
    sudo chown "$USER:$USER" "$VAULT_KEYS_DIR" 2>/dev/null || true
    chmod 700 "$VAULT_KEYS_DIR"

    # Encrypt and save keys
    encrypt_data "$unseal_keys" "$master_password" > "$VAULT_KEYS_FILE"
    encrypt_data "$root_token" "$master_password" > "$VAULT_ROOT_TOKEN_FILE"

    chmod 600 "$VAULT_KEYS_FILE" "$VAULT_ROOT_TOKEN_FILE"

    # Also create the legacy format for compatibility with existing scripts
    IFS='|' read -ra unseal_keys_array <<< "$unseal_keys"
    cat > "$VAULT_UNSEAL_KEYS_ENV" << EOF
export VAULT_UNSEAL_KEY_1=${unseal_keys_array[0]}
export VAULT_UNSEAL_KEY_2=${unseal_keys_array[1]}
export VAULT_UNSEAL_KEY_3=${unseal_keys_array[2]}
export VAULT_UNSEAL_KEY_4=${unseal_keys_array[3]}
export VAULT_UNSEAL_KEY_5=${unseal_keys_array[4]}
EOF
    chmod 600 "$VAULT_UNSEAL_KEYS_ENV"

    # Save master password for automation
    echo "$master_password" > "$VAULT_KEYS_DIR/.master_password"
    chmod 600 "$VAULT_KEYS_DIR/.master_password"

    echo "[$(date)] SUCCESS: Vault initialized successfully!" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: Unseal keys and root token encrypted and saved securely" | tee -a "$LOG_FILE"

    return 0
}

# Function to unseal Vault
unseal_vault() {
    local master_password="$1"

    echo "[$(date)] INFO: Unsealing Vault..." | tee -a "$LOG_FILE"

    if [[ ! -f "$VAULT_KEYS_FILE" ]]; then
        echo "[$(date)] ERROR: Vault keys file not found: $VAULT_KEYS_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Decrypt unseal keys
    local unseal_keys_raw unseal_keys_array
    unseal_keys_raw=$(decrypt_data "$VAULT_KEYS_FILE" "$master_password" 2>/dev/null || {
        echo "[$(date)] ERROR: Failed to decrypt Vault keys. Wrong password?" | tee -a "$LOG_FILE"
        exit 1
    })

    IFS='|' read -ra unseal_keys_array <<< "$unseal_keys_raw"

    # Unseal with first 3 keys (threshold)
    for i in {0..2}; do
        if [[ -n "${unseal_keys_array[$i]:-}" ]]; then
            echo "[$(date)] INFO: Using unseal key $((i+1))/3..." | tee -a "$LOG_FILE"
            curl -sk -X POST -d "{\"key\": \"${unseal_keys_array[$i]}\"}" "$VAULT_ADDR/v1/sys/unseal" >/dev/null
        fi
    done

    # Check if unsealed
    local status_json
    status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
    if echo "$status_json" | grep -q '"sealed":false'; then
        echo "[$(date)] SUCCESS: Vault unsealed successfully!" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: Vault unseal failed" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Function to get root token
get_root_token() {
    local master_password="$1"

    if [[ ! -f "$VAULT_ROOT_TOKEN_FILE" ]]; then
        echo "[$(date)] ERROR: Vault root token file not found: $VAULT_ROOT_TOKEN_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi

    decrypt_data "$VAULT_ROOT_TOKEN_FILE" "$master_password" 2>/dev/null || {
        echo "[$(date)] ERROR: Failed to decrypt root token. Wrong password?" | tee -a "$LOG_FILE"
        exit 1
    }
}

# Function to setup Vault environment file
setup_vault_env() {
    local master_password="$1"
    local root_token
    root_token=$(get_root_token "$master_password")

    # Save root token to environment for automation
    echo "export VAULT_TOKEN='$root_token'" > "$VAULT_KEYS_DIR/vault-env.sh"
    echo "export VAULT_ADDR='$VAULT_ADDR'" >> "$VAULT_KEYS_DIR/vault-env.sh"
    chmod 600 "$VAULT_KEYS_DIR/vault-env.sh"

    # Also save to legacy location
    echo "$root_token" > "/opt/my-secure-ha-stack/secrets/vault_token"
    chmod 600 "/opt/my-secure-ha-stack/secrets/vault_token"

    echo "[$(date)] INFO: Vault environment files created" | tee -a "$LOG_FILE"
}

# Main automation logic
main() {
    # Check if Vault is running
    if ! curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
        echo "[$(date)] ERROR: Vault is not running or not accessible at $VAULT_ADDR" | tee -a "$LOG_FILE"
        echo "Please ensure Vault container is running first."
        exit 1
    fi

    local master_password="$DEV_MASTER_PASSWORD"

    if is_vault_initialized; then
        echo "[$(date)] INFO: Vault is already initialized" | tee -a "$LOG_FILE"

        # Check if we have encrypted keys already
        if [[ -f "$VAULT_KEYS_FILE" ]]; then
            echo "[$(date)] INFO: Found existing encrypted keys, attempting unseal..." | tee -a "$LOG_FILE"
            # Check if Vault is sealed
            local status_json
            status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
            if echo "$status_json" | grep -q '"sealed":true'; then
                unseal_vault "$master_password"
            else
                echo "[$(date)] INFO: Vault is already unsealed" | tee -a "$LOG_FILE"
            fi
        else
            echo "[$(date)] WARNING: Vault initialized but no encrypted keys found. Manual intervention needed." | tee -a "$LOG_FILE"
            exit 1
        fi
    else
        echo "[$(date)] INFO: Vault is not initialized. Initializing now..." | tee -a "$LOG_FILE"
        initialize_vault "$master_password"
        unseal_vault "$master_password"
    fi

    # Setup environment files
    setup_vault_env "$master_password"

    # Display root token for reference
    echo ""
    echo "[$(date)] SUCCESS: Vault automation setup complete!" | tee -a "$LOG_FILE"
    echo "🔑 Root Token: $(get_root_token "$master_password")"
    echo "📁 Encrypted files saved in: $VAULT_KEYS_DIR"
    echo "🔧 To use in scripts: source $VAULT_KEYS_DIR/vault-env.sh"
    echo ""

    echo "[$(date)] SUCCESS: Vault development initialization completed successfully" | tee -a "$LOG_FILE"
}

# Run main function
main "$@"
