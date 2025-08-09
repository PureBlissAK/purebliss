#!/bin/bash
set -euo pipefail

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
