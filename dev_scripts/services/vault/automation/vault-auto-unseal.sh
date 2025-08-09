#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_AUTO_UNSEAL_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-auto-unseal.sh"
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
vault_auto_unseal_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_auto_unseal_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_auto_unseal_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
vault_auto_unseal_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_auto_unseal_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_auto_unseal_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_auto_unseal_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_auto_unseal_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_auto_unseal_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_auto_unseal_log_info "Auto-commit system not available - manual commit required"
        vault_auto_unseal_log_info "Recommended commit message: $commit_message"
        vault_auto_unseal_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_auto_unseal_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_auto_unseal_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_auto_unseal_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_auto_unseal_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


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
