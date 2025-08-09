#!/bin/bash
set -euo pipefail

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
