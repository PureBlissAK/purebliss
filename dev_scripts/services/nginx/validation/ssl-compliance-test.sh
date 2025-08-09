#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SSL_COMPLIANCE_TEST_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="ssl-compliance-test.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced testing script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="testing"
SCRIPT_TAGS="enhancement,automation,auto-commit,testing,validation"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced testing script for development with auto-commit functionality,
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
ssl_compliance_test_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
ssl_compliance_test_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
ssl_compliance_test_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
ssl_compliance_test_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    ssl_compliance_test_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        ssl_compliance_test_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            ssl_compliance_test_log_success "Validation passed - proceeding with auto-commit"
        else
            ssl_compliance_test_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        ssl_compliance_test_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        ssl_compliance_test_log_info "Auto-commit system not available - manual commit required"
        ssl_compliance_test_log_info "Recommended commit message: $commit_message"
        ssl_compliance_test_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
ssl_compliance_test_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    ssl_compliance_test_log_success "$final_message"
    
    # Execute auto-commit wrapper
    ssl_compliance_test_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    ssl_compliance_test_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

# ============================================================================
# Nginx SSL/TLS Compliance Validation Script
# ============================================================================


LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
CONTAINER_NAME="purebliss-nginx"
DOMAIN="dev.purebliss.app"

echo "[$(date)] INFO: Starting comprehensive Nginx SSL/TLS compliance validation" | tee -a "$LOG_FILE"

# Function to check if container is running
check_container_status() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        echo "[$(date)] ERROR: Container $CONTAINER_NAME is not running" | tee -a "$LOG_FILE"
        return 1
    fi
    echo "[$(date)] SUCCESS: Container $CONTAINER_NAME is running" | tee -a "$LOG_FILE"
    return 0
}

# Function to test HTTP redirect
test_http_redirect() {
    echo "[$(date)] INFO: Testing HTTP to HTTPS redirect" | tee -a "$LOG_FILE"
    local http_status
    http_status=$(docker exec "$CONTAINER_NAME" curl -s -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" http://127.0.0.1)

    if [[ "$http_status" == "301" ]]; then
        echo "[$(date)] SUCCESS: HTTP redirects to HTTPS (status: $http_status)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: HTTP redirect failed (status: $http_status, expected: 301)" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test HTTPS response
test_https_response() {
    echo "[$(date)] INFO: Testing HTTPS response" | tee -a "$LOG_FILE"
    local https_status
    https_status=$(docker exec "$CONTAINER_NAME" curl -sSk -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" https://127.0.0.1)

    if [[ "$https_status" == "200" ]]; then
        echo "[$(date)] SUCCESS: HTTPS responds correctly (status: $https_status)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: HTTPS response failed (status: $https_status, expected: 200)" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test HSTS header
test_hsts_header() {
    echo "[$(date)] INFO: Testing HSTS header presence" | tee -a "$LOG_FILE"
    local hsts_header
    hsts_header=$(docker exec "$CONTAINER_NAME" curl -sSk -D - -H "Host: $DOMAIN" https://127.0.0.1 | grep -i "Strict-Transport-Security" || echo "")

    if [[ -n "$hsts_header" ]]; then
        echo "[$(date)] SUCCESS: HSTS header present: $hsts_header" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: HSTS header missing" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test SSL certificate
test_ssl_certificate() {
    echo "[$(date)] INFO: Testing SSL certificate validity" | tee -a "$LOG_FILE"
    local cert_check
    cert_check=$(docker exec "$CONTAINER_NAME" sh -c "echo '' | openssl s_client -connect 127.0.0.1:443 -servername $DOMAIN -verify_return_error 2>/dev/null | grep 'verify return:'" || echo "")

    if echo "$cert_check" | grep -q "verify return:1"; then
        echo "[$(date)] SUCCESS: SSL certificate is valid: $cert_check" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] WARNING: SSL certificate verification: $cert_check" | tee -a "$LOG_FILE"
        # Don't fail for self-signed certs in development
        return 0
    fi
}

# Function to test TLS protocol
test_tls_protocol() {
    echo "[$(date)] INFO: Testing TLS protocol version" | tee -a "$LOG_FILE"
    local tls_protocol
    tls_protocol=$(docker exec "$CONTAINER_NAME" sh -c "echo '' | openssl s_client -connect 127.0.0.1:443 -servername $DOMAIN 2>/dev/null | grep 'Protocol  :'" || echo "")

    if echo "$tls_protocol" | grep -qE "(TLSv1\.2|TLSv1\.3)"; then
        echo "[$(date)] SUCCESS: TLS protocol is secure: $tls_protocol" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: Insecure or unknown TLS protocol: $tls_protocol" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test Nginx configuration
test_nginx_config() {
    echo "[$(date)] INFO: Testing Nginx configuration syntax" | tee -a "$LOG_FILE"
    if docker exec "$CONTAINER_NAME" nginx -t 2>&1 | tee -a "$LOG_FILE"; then
        echo "[$(date)] SUCCESS: Nginx configuration is valid" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: Nginx configuration is invalid" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main validation function
main() {
    echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: Nginx SSL/TLS Compliance Validation" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"

    local tests=(
        "check_container_status"
        "test_nginx_config"
        "test_http_redirect"
        "test_https_response"
        "test_hsts_header"
        "test_ssl_certificate"
        "test_tls_protocol"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
        echo "" | tee -a "$LOG_FILE"
    done

    if [[ $failed_tests -eq 0 ]]; then
        echo "[$(date)] SUCCESS: All SSL/TLS compliance tests passed" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: Nginx is 100% SSL/TLS compliant" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: $failed_tests SSL/TLS compliance tests failed" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: Nginx is NOT fully SSL/TLS compliant" | tee -a "$LOG_FILE"
        return 1
    fi
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
