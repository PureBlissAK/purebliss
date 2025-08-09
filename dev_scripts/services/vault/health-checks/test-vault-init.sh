#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# TEST_VAULT_INIT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="test-vault-init.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced health-validation script for monitoring operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="health-validation"
SCRIPT_TAGS="enhancement,automation,auto-commit,monitoring,vault,security,testing,validation"
SCRIPT_SERVICES="monitoring"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced health-validation script for monitoring with auto-commit functionality,
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
test_vault_init_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
test_vault_init_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
test_vault_init_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
test_vault_init_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    test_vault_init_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        test_vault_init_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            test_vault_init_log_success "Validation passed - proceeding with auto-commit"
        else
            test_vault_init_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        test_vault_init_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        test_vault_init_log_info "Auto-commit system not available - manual commit required"
        test_vault_init_log_info "Recommended commit message: $commit_message"
        test_vault_init_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
test_vault_init_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    test_vault_init_log_success "$final_message"
    
    # Execute auto-commit wrapper
    test_vault_init_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    test_vault_init_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


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
