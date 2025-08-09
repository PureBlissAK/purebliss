#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# HTTPS_SANITY_CHECK_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="https-sanity-check.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced health-validation script for monitoring operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="health-validation"
SCRIPT_TAGS="enhancement,automation,auto-commit,monitoring"
SCRIPT_SERVICES="monitoring"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced health-validation script for monitoring with auto-commit functionality,
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
https_sanity_check_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
https_sanity_check_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
https_sanity_check_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
https_sanity_check_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    https_sanity_check_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        https_sanity_check_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            https_sanity_check_log_success "Validation passed - proceeding with auto-commit"
        else
            https_sanity_check_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        https_sanity_check_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        https_sanity_check_log_info "Auto-commit system not available - manual commit required"
        https_sanity_check_log_info "Recommended commit message: $commit_message"
        https_sanity_check_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
https_sanity_check_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    https_sanity_check_log_success "$final_message"
    
    # Execute auto-commit wrapper
    https_sanity_check_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    https_sanity_check_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# HTTPS Service Sanity Check Script
# Tests all browser-based services via HTTPS with Let's Encrypt SSL

LOG_FILE="/tmp/https_sanity_check.log"
DOMAIN="dev.purebliss.app"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_service() {
    local name="$1"
    local url="$2"
    local expected_code="${3:-200}"

    log "Testing $name at $url"

    # Test with timeout and capture both status code and any redirects
    local result=$(timeout 10 curl -s -L -o /dev/null -w "%{http_code}|%{url_effective}" "$url" 2>/dev/null || echo "TIMEOUT|$url")
    local status_code=$(echo "$result" | cut -d'|' -f1)
    local final_url=$(echo "$result" | cut -d'|' -f2)

    if [[ "$status_code" == "TIMEOUT" ]]; then
        log "❌ $name: TIMEOUT"
        return 1
    elif [[ "$status_code" =~ ^[23] ]]; then
        log "✅ $name: HTTP $status_code (${final_url})"
        return 0
    else
        log "⚠️  $name: HTTP $status_code (${final_url})"
        return 1
    fi
}

# Clear previous log
> "$LOG_FILE"

log "=== HTTPS Service Sanity Check ==="
log "Domain: $DOMAIN"
log "SSL: Let's Encrypt"
log ""

# Test main paths (browser-accessible services)
log "--- Testing Path-based Routes ---"
test_service "Keycloak Auth" "https://$DOMAIN/auth/"
test_service "Grafana Dashboard" "https://$DOMAIN/grafana/"
test_service "Vikunja Tasks" "https://$DOMAIN/vikunja/"
test_service "Vault UI" "https://$DOMAIN/vault/ui/"
test_service "Prometheus Metrics" "https://$DOMAIN/prometheus/"

log ""
log "--- Testing Port-based Routes ---"
test_service "Grafana (3001)" "https://$DOMAIN:3001/"
test_service "Keycloak (8080)" "https://$DOMAIN:8080/"
test_service "Prometheus (9090)" "https://$DOMAIN:9090/"

log ""
log "--- Testing SSL Certificate ---"
# Test SSL certificate validity
ssl_info=$(timeout 5 openssl s_client -connect $DOMAIN:443 -servername $DOMAIN </dev/null 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null || echo "SSL_ERROR")

if [[ "$ssl_info" == "SSL_ERROR" ]]; then
    log "❌ SSL Certificate: ERROR"
else
    log "✅ SSL Certificate: Valid"
    echo "$ssl_info" | while read line; do
        log "   $line"
    done
fi

log ""
log "=== Service Status Summary ==="

# Check container health
log "--- Container Health ---"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep purebliss | while read line; do
    if echo "$line" | grep -q "healthy"; then
        log "✅ $line"
    elif echo "$line" | grep -q "unhealthy"; then
        log "❌ $line"
    else
        log "⚠️  $line"
    fi
done

log ""
log "Sanity check complete. Full log: $LOG_FILE"

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
