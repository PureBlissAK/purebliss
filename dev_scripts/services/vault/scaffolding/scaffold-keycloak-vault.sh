#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SCAFFOLD_KEYCLOAK_VAULT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="scaffold-keycloak-vault.sh"
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
scaffold_keycloak_vault_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
scaffold_keycloak_vault_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
scaffold_keycloak_vault_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
scaffold_keycloak_vault_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    scaffold_keycloak_vault_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        scaffold_keycloak_vault_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            scaffold_keycloak_vault_log_success "Validation passed - proceeding with auto-commit"
        else
            scaffold_keycloak_vault_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        scaffold_keycloak_vault_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        scaffold_keycloak_vault_log_info "Auto-commit system not available - manual commit required"
        scaffold_keycloak_vault_log_info "Recommended commit message: $commit_message"
        scaffold_keycloak_vault_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
scaffold_keycloak_vault_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    scaffold_keycloak_vault_log_success "$final_message"
    
    # Execute auto-commit wrapper
    scaffold_keycloak_vault_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    scaffold_keycloak_vault_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Individual Keycloak AppRole scaffolding for Vault integration"

# Vault connection parameters
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=myroot
export VAULT_SKIP_VERIFY=true

SERVICE_NAME="keycloak"
LOG_PREFIX="SCAFFOLD_KEYCLOAK_VAULT"

log_info "Starting individual $SERVICE_NAME Vault AppRole scaffolding"

# Validate Vault is accessible
validate_vault_connection() {
    log_info "Validating Vault connection for $SERVICE_NAME"

    if ! vault status >/dev/null 2>&1; then
        log_error "Vault is not accessible. Cannot proceed with $SERVICE_NAME AppRole setup"
        return 1
    fi

    log_success "Vault connection validated for $SERVICE_NAME"
}

# Create service-specific policy
create_keycloak_policy() {
    log_info "Creating $SERVICE_NAME-specific Vault policy"

    vault policy write keycloak-policy - << 'EOL'
path "secret/data/keycloak/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/keycloak/*" {
  capabilities = ["read", "list"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOL

    if [[ $? -eq 0 ]]; then
        log_success "Keycloak policy created successfully"
    else
        log_error "Failed to create keycloak policy"
        return 1
    fi
}

# Create AppRole for Keycloak
create_keycloak_approle() {
    log_info "Creating AppRole for $SERVICE_NAME"

    vault write auth/approle/role/keycloak \
        token_policies="keycloak-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true \
        secret_id_ttl=1h

    if [[ $? -eq 0 ]]; then
        log_success "Keycloak AppRole created successfully"
    else
        log_error "Failed to create keycloak AppRole"
        return 1
    fi
}

# Generate and store credentials
generate_keycloak_credentials() {
    log_info "Generating $SERVICE_NAME AppRole credentials"

    # Get role-id
    ROLE_ID=$(vault read -field=role_id auth/approle/role/keycloak/role-id)
    if [[ -z "$ROLE_ID" ]]; then
        log_error "Failed to retrieve role_id for keycloak"
        return 1
    fi

    # Generate secret-id
    SECRET_ID=$(vault write -force -field=secret_id auth/approle/role/keycloak/secret-id)
    if [[ -z "$SECRET_ID" ]]; then
        log_error "Failed to generate secret_id for keycloak"
        return 1
    fi

    log_info "Keycloak AppRole credentials generated"
    log_info "Role ID: $ROLE_ID"
    log_info "Secret ID: [REDACTED - stored in Vault]"

    # Store credentials in Vault KV store
    vault kv put secret/keycloak/approle \
        role_id="$ROLE_ID" \
        secret_id="$SECRET_ID" \
        service="keycloak" \
        created_date="$(date -Iseconds)"

    if [[ $? -eq 0 ]]; then
        log_success "Keycloak credentials stored in Vault KV store"
    else
        log_error "Failed to store keycloak credentials"
        return 1
    fi
}

# Test AppRole authentication
test_keycloak_auth() {
    log_info "Testing $SERVICE_NAME AppRole authentication"

    # Retrieve stored credentials
    STORED_ROLE_ID=$(vault kv get -field=role_id secret/keycloak/approle)
    STORED_SECRET_ID=$(vault kv get -field=secret_id secret/keycloak/approle)

    # Test authentication
    TEST_TOKEN=$(vault write -field=token auth/approle/login \
        role_id="$STORED_ROLE_ID" \
        secret_id="$STORED_SECRET_ID")

    if [[ -n "$TEST_TOKEN" ]]; then
        log_success "Keycloak AppRole authentication test successful"

        # Test token capabilities
        VAULT_TOKEN="$TEST_TOKEN" vault token lookup-self >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            log_success "Keycloak token validation successful"
        else
            log_error "Keycloak token validation failed"
            return 1
        fi
    else
        log_error "Keycloak AppRole authentication test failed"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting $SERVICE_NAME Vault integration scaffolding"

    # Phase 1: Validation
    validate_vault_connection || return 1

    # Phase 2: Policy Creation
    create_keycloak_policy || return 1

    # Phase 3: AppRole Creation
    create_keycloak_approle || return 1

    # Phase 4: Credential Generation
    generate_keycloak_credentials || return 1

    # Phase 5: Authentication Testing
    test_keycloak_auth || return 1

    log_success "✅ $SERVICE_NAME Vault AppRole scaffolding complete"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $LOG_PREFIX: Individual scaffolding complete - ready for container integration" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

    return 0
}

# Execute main function
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
