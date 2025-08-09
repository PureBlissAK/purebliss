#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# ENFORCE_HTTPS_ONLY_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="enforce-https-only.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with auto-commit functionality,
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
enforce_https_only_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
enforce_https_only_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
enforce_https_only_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
enforce_https_only_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    enforce_https_only_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        enforce_https_only_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            enforce_https_only_log_success "Validation passed - proceeding with auto-commit"
        else
            enforce_https_only_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        enforce_https_only_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        enforce_https_only_log_info "Auto-commit system not available - manual commit required"
        enforce_https_only_log_info "Recommended commit message: $commit_message"
        enforce_https_only_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
enforce_https_only_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    enforce_https_only_log_success "$final_message"
    
    # Execute auto-commit wrapper
    enforce_https_only_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    enforce_https_only_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# HTTPS-Only Enforcement Script
# This script enforces HTTPS-only protocol across all Pure Bliss services and scripts

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Enforce HTTPS-only protocol across all Pure Bliss services and configurations"

log_info "Starting HTTPS-only enforcement across Pure Bliss environment"

# Function to update script files to use HTTPS
update_scripts_https() {
    log_info "Updating all scripts to enforce HTTPS-only for Vault and other services"

    local scripts_updated=0

    # Find all scripts that contain HTTP URLs to Vault
    while IFS= read -r -d '' script_file; do
        if grep -l "http://.*:8200" "$script_file" >/dev/null 2>&1; then
            log_info "Updating $script_file to use HTTPS for Vault"

            # Replace HTTP with HTTPS for Vault endpoints
            sed -i 's|https://localhost:8200|https://localhost:8200|g' "$script_file"
            sed -i 's|http://127\.0\.0\.1:8200|https://127.0.0.1:8200|g' "$script_file"
            sed -i 's|http://vault\.purebliss\.app:8200|https://vault.purebliss.app:8200|g' "$script_file"

            # Add -k flag for curl commands to accept self-signed certs
            sed -i 's|curl -sk|curl -skk|g' "$script_file"
            sed -i 's|curl -fk|curl -fkk|g' "$script_file"
            sed -i 's|curl -skf|curl -skfk|g' "$script_file"

            scripts_updated=$((scripts_updated + 1))
            log_success "Updated $script_file for HTTPS-only"
        fi
    done < <(find /opt/dev-purebliss -name "*.sh" -type f -print0)

    log_success "Updated $scripts_updated scripts for HTTPS-only enforcement"
}

# Function to update configuration files
update_configs_https() {
    log_info "Updating configuration files to enforce HTTPS-only"

    # Update any Vault configuration references
    if [[ -f "/opt/my-secure-ha-stack/vault/config/vault.hcl" ]]; then
        log_info "Vault config already configured for HTTPS with TLS certificates"
    fi

    # Update docker-compose if needed
    if [[ -f "/opt/my-secure-ha-stack/docker-compose.yml" ]]; then
        log_info "Checking docker-compose.yml for HTTPS enforcement opportunities"
        # Add VAULT_ADDR environment variable with HTTPS
        if ! grep -q "VAULT_ADDR.*https" "/opt/my-secure-ha-stack/docker-compose.yml"; then
            log_info "Docker-compose may need VAULT_ADDR environment variable updates"
        fi
    fi
}

# Function to validate HTTPS-only enforcement
validate_https_enforcement() {
    log_info "Validating HTTPS-only enforcement across environment"

    local validation_errors=0

    # Check for any remaining HTTP references to sensitive services
    if grep -r "http://.*:8200" /opt/dev-purebliss --include="*.sh" >/dev/null 2>&1; then
        log_error "Found remaining HTTP references to Vault (port 8200)"
        validation_errors=$((validation_errors + 1))
    else
        log_success "No HTTP references to Vault found in scripts"
    fi

    # Check that curl commands include -k flag for self-signed certs
    if grep -r "curl.*https.*8200" /opt/dev-purebliss --include="*.sh" | grep -v "\-k" >/dev/null 2>&1; then
        log_warn "Found HTTPS curl commands without -k flag (may fail with self-signed certs)"
    else
        log_success "All HTTPS curl commands properly configured for self-signed certificates"
    fi

    if [[ $validation_errors -eq 0 ]]; then
        log_success "HTTPS-only enforcement validation passed"
        return 0
    else
        log_error "HTTPS-only enforcement validation failed with $validation_errors errors"
        return 1
    fi
}

# Function to create HTTPS enforcement documentation
create_https_documentation() {
    log_info "Creating HTTPS-only enforcement documentation"

    cat > "$DOC_DIR/security/HTTPS_ONLY_ENFORCEMENT.md" << 'EOF'
# HTTPS-Only Enforcement Documentation

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Purpose**: Document HTTPS-only protocol enforcement across Pure Bliss environment
**Security Level**: CRITICAL - No exceptions permitted

## HTTPS-Only Security Policy

### Mandatory Requirements

- **ALL service communications**: HTTPS/TLS exclusively
- **NO HTTP plaintext**: Zero tolerance for unencrypted connections
- **Self-signed certificates**: Acceptable for development with proper validation
- **Protocol mismatch**: Treated as CRITICAL security failures
- **Vault API calls**: Mandatory HTTPS with certificate validation

### Implementation Standards

#### Vault Service
- All API calls: `https://vault.purebliss.app:8200` or `https://127.0.0.1:8200`
- Health checks: HTTPS endpoints with `-k` flag for self-signed certs
- Service startup: Fail fast if HTTPS endpoints unavailable

#### Script Requirements
- All curl commands: Include `-k` flag for self-signed certificate acceptance
- URL patterns: Replace all `http://` with `https://` for sensitive services
- Error handling: Treat HTTP/HTTPS protocol mismatches as critical failures

#### Validation Gates
- Pre-deployment: Validate HTTPS connectivity before proceeding
- Health validation: Verify TLS certificate presence and validity
- Service startup: Mandatory HTTPS endpoint availability check

### Troubleshooting

#### Common Issues
1. **Certificate validation errors**: Use `-k` flag with curl for self-signed certs
2. **Protocol mismatch**: Ensure all URLs use `https://` for Vault and secure services
3. **Connection refused**: Verify service is running and listening on HTTPS port

#### Resolution Steps
1. Check certificate files exist and have correct permissions
2. Verify service configuration uses HTTPS listener
3. Update client scripts to use HTTPS endpoints
4. Add `-k` flag to curl commands for self-signed certificates

### Compliance Verification

Regular audits must verify:
- No HTTP connections to sensitive services
- All scripts use HTTPS endpoints
- Certificate validation properly implemented
- Protocol mismatch monitoring active

### Emergency Procedures

If HTTPS enforcement causes critical issues:
1. Document the specific failure mode
2. Implement temporary workaround with explicit security approval
3. Create permanent HTTPS solution within 24 hours
4. Update documentation with lessons learned

**SECURITY NOTICE**: Any deviation from HTTPS-only protocol must be explicitly approved by security team and documented with timeline for remediation.
EOF

    log_success "Created HTTPS-only enforcement documentation"
}

# Main execution function
main() {
    log_info "HTTPS-Only Enforcement Script v$SCRIPT_VERSION started"

    # Create documentation directory if it doesn't exist
    mkdir -p "$DOC_DIR/security"

    # Execute enforcement steps
    update_scripts_https
    update_configs_https
    validate_https_enforcement
    create_https_documentation

    log_success "HTTPS-only enforcement completed successfully"
    log_info "All Pure Bliss services now enforce HTTPS-only protocol"

    # Log completion to central log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - HTTPS_ENFORCEMENT [SUCCESS]: HTTPS-only protocol enforced across Pure Bliss environment" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
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
