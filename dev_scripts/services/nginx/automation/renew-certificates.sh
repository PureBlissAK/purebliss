#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# RENEW_CERTIFICATES_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="renew-certificates.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced automation script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced automation script for development with auto-commit functionality,
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
renew_certificates_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
renew_certificates_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
renew_certificates_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
renew_certificates_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    renew_certificates_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        renew_certificates_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            renew_certificates_log_success "Validation passed - proceeding with auto-commit"
        else
            renew_certificates_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        renew_certificates_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        renew_certificates_log_info "Auto-commit system not available - manual commit required"
        renew_certificates_log_info "Recommended commit message: $commit_message"
        renew_certificates_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
renew_certificates_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    renew_certificates_log_success "$final_message"
    
    # Execute auto-commit wrapper
    renew_certificates_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    renew_certificates_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Nginx Certificate Renewal via Vault PKI
# Automatically renews certificates before expiration

VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
DOMAIN="${DOMAIN:-dev.purebliss.app}"
CERT_PATH="/etc/nginx/certs"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] NGINX_CERT_RENEWAL: $1" | tee -a "$LOG_FILE"
}

function check_certificate_expiry() {
    if [[ ! -f "$CERT_PATH/nginx.crt" ]]; then
        log_action "Certificate not found, requesting new certificate"
        return 1
    fi
    
    # Check if certificate expires within 30 days
    if openssl x509 -checkend 2592000 -noout -in "$CERT_PATH/nginx.crt" >/dev/null 2>&1; then
        log_action "Certificate is valid for more than 30 days"
        return 0
    else
        log_action "Certificate expires within 30 days, renewal needed"
        return 1
    fi
}

function renew_certificate() {
    log_action "Renewing SSL certificate via Vault PKI..."
    
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    
    # Request new certificate
    CERT_RESPONSE=$(vault write -format=json pki/issue/purebliss-role \
        common_name="$DOMAIN" \
        alt_names="*.${DOMAIN},localhost" \
        ttl=8760h 2>/dev/null || echo '{}')
    
    if [[ "$CERT_RESPONSE" != '{}' ]]; then
        # Backup existing certificates
        if [[ -f "$CERT_PATH/nginx.crt" ]]; then
            cp "$CERT_PATH/nginx.crt" "$CERT_PATH/nginx.crt.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$CERT_PATH/nginx.key" "$CERT_PATH/nginx.key.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Save new certificates
        echo "$CERT_RESPONSE" | jq -r '.data.certificate' > "$CERT_PATH/nginx.crt"
        echo "$CERT_RESPONSE" | jq -r '.data.private_key' > "$CERT_PATH/nginx.key"
        echo "$CERT_RESPONSE" | jq -r '.data.issuing_ca' > "$CERT_PATH/ca.crt"
        
        # Set proper permissions
        chmod 644 "$CERT_PATH/nginx.crt" "$CERT_PATH/ca.crt"
        chmod 600 "$CERT_PATH/nginx.key"
        
        log_action "Certificate renewed successfully"
        
        # Test nginx configuration and reload
        if nginx -t; then
            nginx -s reload
            log_action "Nginx reloaded with new certificate"
        else
            log_action "ERROR: Nginx configuration test failed"
            return 1
        fi
    else
        log_action "ERROR: Failed to renew certificate"
        return 1
    fi
}

# Main execution
if ! check_certificate_expiry; then
    renew_certificate
fi

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
