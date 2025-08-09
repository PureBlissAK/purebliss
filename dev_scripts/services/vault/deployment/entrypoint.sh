#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# ENTRYPOINT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="entrypoint.sh"
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
entrypoint_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
entrypoint_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
entrypoint_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
entrypoint_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    entrypoint_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        entrypoint_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            entrypoint_log_success "Validation passed - proceeding with auto-commit"
        else
            entrypoint_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        entrypoint_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        entrypoint_log_info "Auto-commit system not available - manual commit required"
        entrypoint_log_info "Recommended commit message: $commit_message"
        entrypoint_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
entrypoint_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    entrypoint_log_success "$final_message"
    
    # Execute auto-commit wrapper
    entrypoint_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    entrypoint_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

#!/bin/sh

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_SECRETS_FILE="/opt/my-secure-ha-stack/secrets/vault-init.json"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

# Logging functions
function log_info() {
    echo "[$(date)] [Vault Entrypoint] INFO: $1" | tee -a "$LOG_FILE"
}

function log_error() {
    echo "[$(date)] [Vault Entrypoint] ERROR: $1" | tee -a "$LOG_FILE"
}

function log_success() {
    echo "[$(date)] [Vault Entrypoint] SUCCESS: $1" | tee -a "$LOG_FILE"
}

# 1. Wait for Vault to be available
function wait_for_vault() {
    log_info "Waiting for Vault to become available at ${VAULT_ADDR}..."
    local retries=30
    local count=0

    while [[ $count -lt $retries ]]; do
        if curl -s -k "${VAULT_ADDR}/v1/sys/health" &> /dev/null; then
            log_success "Vault is available."
            return 0
        fi
        count=$((count + 1))
        log_info "Vault not ready, waiting... (attempt $count/$retries)"
        sleep 2
    done

    log_error "Vault did not become available after $retries attempts."
    return 1
}

# 2. Initialize Vault if not already initialized
function initialize_vault() {
    log_info "Checking Vault initialization status..."
    local initialized
    initialized=$(vault status -format=json | jq -r .initialized)

    if [[ "$initialized" == "true" ]]; then
        log_info "Vault is already initialized."
        return 0
    fi

    log_info "Vault is not initialized. Initializing..."
    local init_output
    init_output=$(vault operator init -key-shares=1 -key-threshold=1 -format=json)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to initialize Vault."
        return 1
    fi

    echo "$init_output" > "$VAULT_SECRETS_FILE"
    chmod 600 "$VAULT_SECRETS_FILE"
    log_success "Vault initialized. Unseal keys and root token saved to $VAULT_SECRETS_FILE"
}

# 3. Unseal Vault
function unseal_vault() {
    log_info "Checking Vault seal status..."
    local sealed
    sealed=$(vault status -format=json | jq -r .sealed)

    if [[ "$sealed" != "true" ]]; then
        log_success "Vault is already unsealed."
        return 0
    fi

    log_info "Vault is sealed. Attempting to unseal..."
    local unseal_key
    unseal_key=$(jq -r .unseal_keys_b64[0] < "$VAULT_SECRETS_FILE")

    if [[ -z "$unseal_key" ]]; then
        log_error "Could not find unseal key in $VAULT_SECRETS_FILE"
        return 1
    fi

    if vault operator unseal "$unseal_key"; then
        log_success "Vault unsealed successfully."
        return 0
    else
        log_error "Failed to unseal Vault."
        return 1
    fi
}

# 4. Log in and store root token
function login_and_store_token() {
    log_info "Logging into Vault to store root token..."
    local root_token
    root_token=$(jq -r .root_token < "$VAULT_SECRETS_FILE")

    if [[ -z "$root_token" ]]; then
        log_error "Could not find root token in $VAULT_SECRETS_FILE"
        return 1
    fi

    export VAULT_TOKEN="$root_token"
    echo "$VAULT_TOKEN" > "$VAULT_TOKEN_FILE"
    chmod 600 "$VAULT_TOKEN_FILE"

    log_success "Logged in with root token and stored it in $VAULT_TOKEN_FILE"
}

# 5. Keep Vault running in the foreground
function start_vault_server() {
    log_info "Starting Vault server..."
    exec vault server -config=/vault/config/vault.hcl
}

# Main execution
function main() {
    log_info "Vault container entrypoint started."

    # Start Vault in the background to initialize
    vault server -config=/vault/config/vault.hcl &
    VAULT_PID=$!

    wait_for_vault
    initialize_vault
    unseal_vault
    login_and_store_token

    log_success "Vault is initialized, unsealed, and ready for use."

    # Bring the Vault server process to the foreground
    log_info "Bringing Vault server to the foreground."
    wait $VAULT_PID
}

trap 'log_error "Vault entrypoint script failed at line $LINENO"' ERR

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
