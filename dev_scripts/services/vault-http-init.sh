#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_HTTP_INIT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-http-init.sh"
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
vault_http_init_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_http_init_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_http_init_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
vault_http_init_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_http_init_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_http_init_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_http_init_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_http_init_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_http_init_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_http_init_log_info "Auto-commit system not available - manual commit required"
        vault_http_init_log_info "Recommended commit message: $commit_message"
        vault_http_init_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_http_init_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_http_init_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_http_init_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_http_init_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Vault HTTP Development Initialization
# Simple initialization for HTTP-enabled Vault in development

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="http://127.0.0.1:18200"  # Using external port mapping
VAULT_OUTPUT_FILE="/opt/my-secure-ha-stack/vault-init-output.txt"
VAULT_UNSEAL_KEYS_ENV="/opt/my-secure-ha-stack/vault-unseal-keys.env"

echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Starting Vault HTTP initialization" | tee -a "$LOG_FILE"

# Function to check if Vault is accessible
check_vault_accessibility() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Checking Vault accessibility at $VAULT_ADDR" | tee -a "$LOG_FILE"

    for i in {1..10}; do
        if curl -f "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault is accessible" | tee -a "$LOG_FILE"
            return 0
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Attempt $i/10 - Vault not accessible yet, waiting..." | tee -a "$LOG_FILE"
        sleep 2
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Vault is not accessible after 10 attempts" | tee -a "$LOG_FILE"
    return 1
}

# Function to check if Vault is initialized
is_vault_initialized() {
    local response
    response=$(curl -s "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo '{"initialized":false}')
    if echo "$response" | grep -q '"initialized":true'; then
        return 0
    else
        return 1
    fi
}

# Function to initialize Vault
initialize_vault() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Initializing Vault with 5 key shares and threshold of 3" | tee -a "$LOG_FILE"

    # Initialize Vault
    local init_response
    init_response=$(curl -s -X POST \
        -d '{"secret_shares": 5, "secret_threshold": 3}' \
        "$VAULT_ADDR/v1/sys/init")

    if [[ $? -ne 0 ]] || [[ -z "$init_response" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Failed to initialize Vault" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Save full initialization response
    echo "$init_response" > "$VAULT_OUTPUT_FILE"
    chmod 600 "$VAULT_OUTPUT_FILE"

    # Extract unseal keys and root token
    local key1 key2 key3 key4 key5 root_token
    key1=$(echo "$init_response" | jq -r '.keys[0]')
    key2=$(echo "$init_response" | jq -r '.keys[1]')
    key3=$(echo "$init_response" | jq -r '.keys[2]')
    key4=$(echo "$init_response" | jq -r '.keys[3]')
    key5=$(echo "$init_response" | jq -r '.keys[4]')
    root_token=$(echo "$init_response" | jq -r '.root_token')

    # Create unseal keys environment file
    cat > "$VAULT_UNSEAL_KEYS_ENV" << EOF
# Vault Unseal Keys - Generated $(date)
export VAULT_UNSEAL_KEY_1="$key1"
export VAULT_UNSEAL_KEY_2="$key2"
export VAULT_UNSEAL_KEY_3="$key3"
export VAULT_UNSEAL_KEY_4="$key4"
export VAULT_UNSEAL_KEY_5="$key5"
export VAULT_ROOT_TOKEN="$root_token"
export VAULT_ADDR="$VAULT_ADDR"
EOF

    chmod 600 "$VAULT_UNSEAL_KEYS_ENV"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault initialized successfully" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🔐 Keys saved to $VAULT_UNSEAL_KEYS_ENV" | tee -a "$LOG_FILE"

    return 0
}

# Function to unseal Vault
unseal_vault() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Unsealing Vault with 3 keys (threshold)" | tee -a "$LOG_FILE"

    # Source the unseal keys
    source "$VAULT_UNSEAL_KEYS_ENV"

    # Unseal with first 3 keys
    for i in 1 2 3; do
        local key_var="VAULT_UNSEAL_KEY_$i"
        local key_value="${!key_var}"

        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Using unseal key $i/3" | tee -a "$LOG_FILE"

        local unseal_response
        unseal_response=$(curl -s -X POST \
            -d "{\"key\": \"$key_value\"}" \
            "$VAULT_ADDR/v1/sys/unseal")

        # Check current seal status
        local sealed
        sealed=$(echo "$unseal_response" | jq -r '.sealed')
        if [[ "$sealed" == "false" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault unsealed after $i keys" | tee -a "$LOG_FILE"
            return 0
        fi
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Failed to unseal Vault after 3 keys" | tee -a "$LOG_FILE"
    return 1
}

# Function to verify Vault is ready
verify_vault_ready() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Verifying Vault is ready for use" | tee -a "$LOG_FILE"

    # Source the root token
    source "$VAULT_UNSEAL_KEYS_ENV"

    # Test basic Vault operation
    local test_response
    test_response=$(curl -s -H "X-Vault-Token: $VAULT_ROOT_TOKEN" \
        "$VAULT_ADDR/v1/sys/health")

    if echo "$test_response" | grep -q '"sealed":false'; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault is ready for use" | tee -a "$LOG_FILE"
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Vault verification failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main function
main() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Starting Vault HTTP initialization process" | tee -a "$LOG_FILE"

    # Check if Vault is accessible
    if ! check_vault_accessibility; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Cannot access Vault. Ensure container is running." | tee -a "$LOG_FILE"
        exit 1
    fi

    # Check if already initialized
    if is_vault_initialized; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ℹ️ Vault is already initialized" | tee -a "$LOG_FILE"

        # Check if we need to unseal
        local health_response
        health_response=$(curl -s "$VAULT_ADDR/v1/sys/health")
        if echo "$health_response" | grep -q '"sealed":true'; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🔓 Vault is sealed, attempting unseal" | tee -a "$LOG_FILE"
            if [[ -f "$VAULT_UNSEAL_KEYS_ENV" ]]; then
                unseal_vault
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ No unseal keys found. Manual intervention required." | tee -a "$LOG_FILE"
                exit 1
            fi
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault is already unsealed" | tee -a "$LOG_FILE"
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🚀 Initializing Vault for first time" | tee -a "$LOG_FILE"
        initialize_vault
        unseal_vault
    fi

    # Verify Vault is ready
    verify_vault_ready

    # Display summary
    echo ""
    echo "🎉 Vault initialization complete!"
    echo "📋 Summary:"
    echo "   - Vault Address: $VAULT_ADDR"
    echo "   - Status: Initialized and unsealed"
    echo "   - Keys saved to: $VAULT_UNSEAL_KEYS_ENV"
    echo "   - Full init output: $VAULT_OUTPUT_FILE"
    echo ""
    echo "💡 To use Vault:"
    echo "   source $VAULT_UNSEAL_KEYS_ENV"
    echo "   vault status"
    echo ""

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🎉 Vault HTTP initialization completed successfully" | tee -a "$LOG_FILE"
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
