#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_DEV_INIT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-dev-init.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced vault-integration script for vault operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="vault-integration"
SCRIPT_TAGS="enhancement,automation,auto-commit,vault,security"
SCRIPT_SERVICES="vault"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced vault-integration script for vault with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
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

# Wrapper for auto-commit and push on successful execution
vault_dev_init_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_dev_init_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_dev_init_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_dev_init_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_dev_init_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_dev_init_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_dev_init_log_info "Auto-commit system not available - manual commit required"
        vault_dev_init_log_info "Recommended commit message: $commit_message"
        vault_dev_init_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_dev_init_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_dev_init_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_dev_init_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_dev_init_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════



# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.2"
SCRIPT_PURPOSE="Automated Vault initialization and unseal for development environments. Self-contained version."

# Self-contained logging functions (don't require external libraries in container)
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Vault Development Initialization - Non-Interactive
# For development environments only - uses a fixed master password

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
HEALTH_SCRIPT="/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh"
VAULT_KEYS_DIR="/opt/my-secure-ha-stack/secrets/vault"
VAULT_KEYS_FILE="$VAULT_KEYS_DIR/vault-keys.enc"
VAULT_ROOT_TOKEN_FILE="$VAULT_KEYS_DIR/vault-root-token.enc"
VAULT_ADDR="https://127.0.0.1:8200"
VAULT_UNSEAL_KEYS_ENV="/opt/my-secure-ha-stack/vault-unseal-keys.env"

# Development master password (change for production)
DEV_MASTER_PASSWORD="purebliss-dev-vault-2025"

log_info "Starting automated Vault initialization for development (script: $SCRIPT_NAME)"

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

    log_info "Initializing Vault with 5 key shares and threshold of 3..."

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
    log_info "Vault keys directory created at $VAULT_KEYS_DIR"

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

    log_success "Vault initialized successfully!"
    log_info "Unseal keys and root token encrypted and saved securely."

    return 0
}

# Function to unseal Vault
unseal_vault() {
    local master_password="$1"

    log_info "Unsealing Vault..."

    if [[ ! -f "$VAULT_KEYS_FILE" ]]; then
        log_error "Vault keys file not found: $VAULT_KEYS_FILE"
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
            log_info "Using unseal key $((i+1))/3..."
            curl -sk -X POST -d "{\"key\": \"${unseal_keys_array[$i]}\"}" "$VAULT_ADDR/v1/sys/unseal" >/dev/null
        fi
    done

    # Check if unsealed
    local status_json
    status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
    if echo "$status_json" | grep -q '"sealed":false'; then
        log_success "Vault unsealed successfully!"
        return 0
    else
        log_error "Vault unseal failed"
        exit 1
    fi
}

# Function to get root token
get_root_token() {
    local master_password="$1"

    if [[ ! -f "$VAULT_ROOT_TOKEN_FILE" ]]; then
        log_error "Vault root token file not found: $VAULT_ROOT_TOKEN_FILE"
        exit 1
    fi

    decrypt_data "$VAULT_ROOT_TOKEN_FILE" "$master_password" 2>/dev/null || {
        log_error "Failed to decrypt root token. Wrong password?"
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

    log_info "Vault environment files created."
}

# Main automation logic
main() {
    # Check if Vault is running
    if ! curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
        log_error "Vault is not running or not accessible at $VAULT_ADDR. Please ensure Vault container is running first."
        exit 1
    fi

    local master_password="$DEV_MASTER_PASSWORD"

    if is_vault_initialized; then
        log_info "Vault is already initialized."

        # Check if we have encrypted keys already
        if [[ -f "$VAULT_KEYS_FILE" ]]; then
            log_info "Found existing encrypted keys, attempting unseal..."
            # Check if Vault is sealed
            local status_json
            status_json=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
            if echo "$status_json" | grep -q '"sealed":true'; then
                unseal_vault "$master_password"
            else
                log_info "Vault is already unsealed."
            fi
        else
            log_error "Vault initialized but no encrypted keys found. Manual intervention needed."
            exit 1
        fi
    else
        log_info "Vault is not initialized. Initializing now..."
        initialize_vault "$master_password"
        unseal_vault "$master_password"
    fi

    # Setup environment files
    setup_vault_env "$master_password"

    # Display root token for reference
    log_success "Vault automation setup complete!"
    log_info "Root Token: $(get_root_token "$master_password")"
    log_info "Encrypted files saved in: $VAULT_KEYS_DIR"
    log_info "To use in scripts: source $VAULT_KEYS_DIR/vault-env.sh"

    log_success "Vault development initialization completed successfully."
}

# Run main function
main "$@"

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT USAGE EXAMPLES - PURE BLISS ELITE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════════
#
# 📚 COMPLETE GUIDE: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md
#
# BASIC AUTO-COMMIT ON SUCCESS:
# Add this at the end of your main script logic:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed successfully"
#
# AUTO-COMMIT WITH VALIDATION:
# Add validation command to ensure script worked correctly:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed with validation" "docker ps | grep -q my-service"
#
# MANUAL AUTO-COMMIT TRIGGER:
# Use auto-commit wrapper directly with custom message:
#   ${WRAPPER_PREFIX}_auto_commit_wrapper "Custom commit: Feature implemented successfully"
#
# DIRECT PURE BLISS ELITE SYSTEM (Recommended):
# Use the official auto-commit trigger system:
#   /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
#       "${SCRIPT_CATEGORY}" "Description of accomplishment" "${SCRIPT_NAME}"
#
# CONDITIONAL AUTO-COMMIT:
# Only commit if certain conditions are met:
#   if [[ \$SUCCESS_FLAG == "true" ]]; then
#       ${WRAPPER_PREFIX}_auto_commit_wrapper "Conditional commit: Success flag set"
#   fi
#
# VALIDATION COMMAND EXAMPLES:
# - Container health check: "docker ps | grep -q healthy"
# - File existence: "test -f /path/to/expected/file"
# - Service response: "curl -s http://service/health | grep -q ok"
# - Custom function: "my_validation_function"
#
# ELITE COMMIT MESSAGE FORMAT:
# The Pure Bliss Elite system automatically generates comprehensive commit messages
# following the standard format with safety guarantees, validation results, and
# proper documentation references. See the AUTO_COMMIT_SYSTEM_GUIDE.md for details.
#
# ═══════════════════════════════════════════════════════════════════════════════════
