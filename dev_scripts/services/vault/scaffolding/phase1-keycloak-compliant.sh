#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE1_KEYCLOAK_COMPLIANT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="phase1-keycloak-compliant.sh"
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
phase1_keycloak_compliant_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
phase1_keycloak_compliant_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
phase1_keycloak_compliant_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
phase1_keycloak_compliant_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    phase1_keycloak_compliant_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        phase1_keycloak_compliant_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            phase1_keycloak_compliant_log_success "Validation passed - proceeding with auto-commit"
        else
            phase1_keycloak_compliant_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        phase1_keycloak_compliant_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        phase1_keycloak_compliant_log_info "Auto-commit system not available - manual commit required"
        phase1_keycloak_compliant_log_info "Recommended commit message: $commit_message"
        phase1_keycloak_compliant_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
phase1_keycloak_compliant_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    phase1_keycloak_compliant_log_success "$final_message"
    
    # Execute auto-commit wrapper
    phase1_keycloak_compliant_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    phase1_keycloak_compliant_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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

# CONSOLIDATION COMPLIANCE: Use existing consolidated vault integration
source "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Keycloak-specific Vault integration using consolidated functions (NO DUPLICATION)"

# Service-specific parameters
SERVICE_NAME="keycloak"
VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="myroot"
export VAULT_ADDR VAULT_TOKEN VAULT_SKIP_VERIFY=true

# Code indexing compliance - log start
log_info "PHASE_1_KEYCLOAK: Using consolidated vault functions instead of creating duplicates"

# Step 1: PRE-EXECUTION COMPLIANCE CHECK (DON'T REINVENT THE WHEEL)
check_existing_functionality() {
    log_info "CONSOLIDATION_CHECK: Scanning existing keycloak vault functionality"

    # Check if we have existing functionality
    if [[ -f "/opt/dev-purebliss/services/keycloak/setup-keycloak-vault.sh" ]]; then
        log_info "FOUND: Existing keycloak vault setup script - will enhance instead of duplicate"
    fi

    # Check consolidated functions available
    if declare -f vault_approle_auth >/dev/null; then
        log_success "CONSOLIDATION_COMPLIANCE: vault_approle_auth function available from consolidated script"
    else
        log_error "Missing consolidated vault functions"
        return 1
    fi
}

# Step 2: KEYCLOAK-SPECIFIC VAULT INTEGRATION using existing functions
setup_keycloak_vault_integration() {
    log_info "KEYCLOAK_VAULT: Setting up Keycloak AppRole using consolidated vault functions"

    # Create keycloak-specific policy
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
EOL

    if [[ $? -eq 0 ]]; then
        log_success "Keycloak policy created successfully"
    else
        log_error "Failed to create keycloak policy"
        return 1
    fi

    # Create AppRole using consolidated approach
    vault write auth/approle/role/keycloak \
        token_policies="keycloak-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true

    # Use consolidated function for authentication testing
    if vault_approle_auth "keycloak" "keycloak-policy"; then
        log_success "CONSOLIDATION_SUCCESS: Keycloak AppRole authentication validated using existing function"
    else
        log_error "Keycloak AppRole authentication failed"
        return 1
    fi
}

# Step 3: HEALTH VALIDATION INTEGRATION (mandatory)
validate_keycloak_integration() {
    log_info "HEALTH_VALIDATION: Running mandatory health check for keycloak vault integration"

    # Use centralized health validation script
    if "$SCRIPT_DIR/core/validate-container-health.sh" keycloak vault-integration-phase1; then
        log_success "HEALTH_VALIDATION: Keycloak vault integration health check passed"
    else
        log_error "HEALTH_VALIDATION: Keycloak vault integration health check failed"
        return 1
    fi
}

# Step 4: CODE INDEXING COMPLIANCE - Auto-update PROJECT_PLAN
update_project_plan() {
    log_info "CODE_INDEXING: Auto-updating PROJECT_PLAN_ENHANCED.md with keycloak completion"

    # Trigger auto-commit with cascade enforcement
    if [[ -x "$SCRIPT_DIR/automation/auto-commit-trigger.sh" ]]; then
        "$SCRIPT_DIR/automation/auto-commit-trigger.sh" "vault-integration" "keycloak" "keycloak-service" "SUCCESS" "false"
        log_success "CODE_INDEXING: PROJECT_PLAN automatically updated"
    else
        log_warn "Auto-commit script not found - manual PROJECT_PLAN update required"
    fi
}

# Main execution with full compliance
main() {
    log_info "Starting PHASE_1_KEYCLOAK with full compliance integration"

    # Compliance Step 1: Check existing functionality (DON'T REINVENT THE WHEEL)
    check_existing_functionality || return 1

    # Implementation Step 2: Use consolidated functions
    setup_keycloak_vault_integration || return 1

    # Validation Step 3: Mandatory health validation
    validate_keycloak_integration || return 1

    # Code Indexing Step 4: Auto-update PROJECT_PLAN
    update_project_plan || return 1

    log_success "✅ PHASE_1_KEYCLOAK: Complete with full compliance (consolidation + automation + code indexing)"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PHASE_1_KEYCLOAK: SUCCESS - Ready for Phase 2 (postgres)" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

    return 0
}

# Execute with full compliance
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
