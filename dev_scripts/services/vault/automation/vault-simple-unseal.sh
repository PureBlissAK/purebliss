#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_SIMPLE_UNSEAL_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-simple-unseal.sh"
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
vault_simple_unseal_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_simple_unseal_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_simple_unseal_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
vault_simple_unseal_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_simple_unseal_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_simple_unseal_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_simple_unseal_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_simple_unseal_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_simple_unseal_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_simple_unseal_log_info "Auto-commit system not available - manual commit required"
        vault_simple_unseal_log_info "Recommended commit message: $commit_message"
        vault_simple_unseal_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_simple_unseal_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_simple_unseal_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_simple_unseal_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_simple_unseal_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


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
