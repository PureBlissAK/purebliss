#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_APPROLE_SETUP_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-approle-setup.sh"
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
vault_approle_setup_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_approle_setup_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_approle_setup_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
vault_approle_setup_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_approle_setup_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_approle_setup_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_approle_setup_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_approle_setup_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_approle_setup_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_approle_setup_log_info "Auto-commit system not available - manual commit required"
        vault_approle_setup_log_info "Recommended commit message: $commit_message"
        vault_approle_setup_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_approle_setup_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_approle_setup_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_approle_setup_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_approle_setup_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="https://127.0.0.1:8200"
POSTGRES_SERVICE_DIR="/opt/dev-purebliss/services/postgres"

function log_action() {
    echo "[$(date)] VAULT_POSTGRES_SETUP: $1" | tee -a "$LOG_FILE"
}

log_action "Checking Vault status..."
if ! curl -sk "$VAULT_ADDR/v1/sys/health" | grep '"sealed":false' >/dev/null; then
    log_action "ERROR: Vault is sealed or unavailable. Unseal Vault before running this script."
    exit 1
fi

log_action "Enabling database secrets engine..."
VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault/vault-root-token 2>/dev/null || echo "")
if [[ -z "$VAULT_TOKEN" ]]; then
    log_action "ERROR: Vault root token not found. Place it at /opt/my-secure-ha-stack/secrets/vault/vault-root-token."
    exit 1
fi

export VAULT_ADDR
export VAULT_TOKEN

vault secrets enable -path=database database || log_action "Database secrets engine already enabled."

log_action "Configuring Postgres plugin and connection..."
vault write database/config/postgres-app \
    plugin_name=postgresql-database-plugin \
    allowed_roles="postgres-app" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/postgres?sslmode=disable" \
    username="vaultadmin" \
    password="vaultadminpassword"

log_action "Creating Postgres role for dynamic credentials..."
vault write database/roles/postgres-app \
    db_name=postgres-app \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE postgres TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

log_action "Creating Vault policy for Postgres dynamic secrets..."
cat > "$POSTGRES_SERVICE_DIR/postgres-approle-policy.hcl" <<EOF
path "database/creds/postgres-app" {
  capabilities = ["read"]
}
EOF
vault policy write postgres-approle "$POSTGRES_SERVICE_DIR/postgres-approle-policy.hcl"

log_action "Creating AppRole for Postgres..."
vault auth enable approle || log_action "AppRole already enabled."
vault write auth/approle/role/postgres-role \
    token_policies="postgres-approle" \
    secret_id_ttl="24h" \
    token_ttl="1h" \
    token_max_ttl="24h"

log_action "Fetching AppRole credentials..."
vault read -field=role_id auth/approle/role/postgres-role/role_id > "$POSTGRES_SERVICE_DIR/role_id"
vault write -f -field=secret_id auth/approle/role/postgres-role/secret_id > "$POSTGRES_SERVICE_DIR/secret_id"
chmod 600 "$POSTGRES_SERVICE_DIR/role_id" "$POSTGRES_SERVICE_DIR/secret_id"

log_action "Vault AppRole setup for Postgres complete."

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
