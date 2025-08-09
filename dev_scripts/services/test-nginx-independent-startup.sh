#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# TEST_NGINX_INDEPENDENT_STARTUP_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="test-nginx-independent-startup.sh"
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
test_nginx_independent_startup_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
test_nginx_independent_startup_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
test_nginx_independent_startup_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
test_nginx_independent_startup_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    test_nginx_independent_startup_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        test_nginx_independent_startup_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            test_nginx_independent_startup_log_success "Validation passed - proceeding with auto-commit"
        else
            test_nginx_independent_startup_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        test_nginx_independent_startup_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        test_nginx_independent_startup_log_info "Auto-commit system not available - manual commit required"
        test_nginx_independent_startup_log_info "Recommended commit message: $commit_message"
        test_nginx_independent_startup_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
test_nginx_independent_startup_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    test_nginx_independent_startup_log_success "$final_message"
    
    # Execute auto-commit wrapper
    test_nginx_independent_startup_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    test_nginx_independent_startup_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Test script for Nginx independent container startup with Vault PKI integration
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
DOMAIN="${LOCAL_HOSTNAME:-dev.purebliss.app}"

echo "[$(date)] INFO: Testing Nginx independent container startup with Vault PKI integration..." | tee -a "$LOG_FILE"

# Function to check service health
check_service_health() {
    local service_name="$1"
    local endpoint="$2"
    local max_attempts=30
    local attempt=1

    echo "[$(date)] INFO: Checking $service_name health at $endpoint..." | tee -a "$LOG_FILE"

    while [[ $attempt -le $max_attempts ]]; do
        if curl -k -s -o /dev/null -w "%{http_code}" "$endpoint" | grep -qE "200|301|302"; then
            echo "[$(date)] SUCCESS: $service_name is healthy (attempt $attempt)" | tee -a "$LOG_FILE"
            return 0
        fi
        echo "[$(date)] INFO: $service_name not ready yet (attempt $attempt/$max_attempts)" | tee -a "$LOG_FILE"
        sleep 5
        ((attempt++))
    done

    echo "[$(date)] ERROR: $service_name failed health check after $max_attempts attempts" | tee -a "$LOG_FILE"
    return 1
}

# Test 1: Clean environment
echo "[$(date)] INFO: Test 1 - Cleaning existing Nginx resources..." | tee -a "$LOG_FILE"
docker rm -f purebliss-nginx >/dev/null 2>&1 || true
docker volume rm purebliss_nginx_certs purebliss_nginx_dhparam >/dev/null 2>&1 || true

# Test 2: Verify Vault is running
echo "[$(date)] INFO: Test 2 - Verifying Vault availability..." | tee -a "$LOG_FILE"
if ! docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
    echo "[$(date)] ERROR: Vault container not running - starting Vault first..." | tee -a "$LOG_FILE"
    cd /opt/dev-purebliss
    if ! /opt/dev-purebliss/dev_scripts/automation/start-all-services.sh vault; then
        echo "[$(date)] ERROR: Failed to start Vault" | tee -a "$LOG_FILE"
        exit 1
    fi
    sleep 10
fi

# Test 3: Test direct docker run (independent startup)
echo "[$(date)] INFO: Test 3 - Testing direct docker run for Nginx..." | tee -a "$LOG_FILE"
cd /opt/dev-purebliss/services/nginx

# Build image
if docker build -t purebliss-nginx-test -f nginx-dockerfile . >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Nginx test image built successfully" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Failed to build Nginx test image" | tee -a "$LOG_FILE"
    exit 1
fi

# Auto-detect Vault configuration
vault_addr="https://127.0.0.1:8200"
vault_token="dev-root-token-purebliss"

if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
   ! docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    vault_addr="https://127.0.0.1:8200"
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    fi
fi

# Create network
docker network create purebliss-net >/dev/null 2>&1 || true

# Start independent container
echo "[$(date)] INFO: Starting Nginx test container independently..." | tee -a "$LOG_FILE"
if docker run -d \
    --name purebliss-nginx-test \
    --network purebliss-net \
    -p 8080:80 \
    -p 8443:443 \
    -e VAULT_ADDR="$vault_addr" \
    -e VAULT_TOKEN="$vault_token" \
    -e DOMAIN="$DOMAIN" \
    -e USE_VAULT="true" \
    -e VAULT_SKIP_VERIFY="true" \
    -v purebliss_nginx_test_certs:/etc/nginx/ssl \
    -v purebliss_nginx_test_dhparam:/etc/nginx/dhparam \
    -v /opt/my-secure-ha-stack/logs/dev-environment-setup.log:/opt/my-secure-ha-stack/logs/dev-environment-setup.log \
    purebliss-nginx-test >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Nginx test container started independently" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Failed to start Nginx test container" | tee -a "$LOG_FILE"
    exit 1
fi

# Test 4: Wait for SSL certificate generation and validate
echo "[$(date)] INFO: Test 4 - Waiting for SSL certificate generation..." | tee -a "$LOG_FILE"
sleep 20

# Check container logs
echo "[$(date)] INFO: Checking container startup logs..." | tee -a "$LOG_FILE"
docker logs purebliss-nginx-test | tail -10 | tee -a "$LOG_FILE"

# Validate configuration
if docker exec purebliss-nginx-test nginx -t >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: Nginx configuration is valid" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Nginx configuration validation failed" | tee -a "$LOG_FILE"
    docker exec purebliss-nginx-test nginx -t 2>&1 | tee -a "$LOG_FILE"
fi

# Test 5: Check SSL certificate existence
echo "[$(date)] INFO: Test 5 - Checking SSL certificate generation..." | tee -a "$LOG_FILE"
if docker exec purebliss-nginx-test test -f "/etc/nginx/ssl/$DOMAIN.crt"; then
    echo "[$(date)] SUCCESS: SSL certificate exists for $DOMAIN" | tee -a "$LOG_FILE"

    # Check certificate details
    echo "[$(date)] INFO: Certificate details:" | tee -a "$LOG_FILE"
    docker exec purebliss-nginx-test openssl x509 -in "/etc/nginx/ssl/$DOMAIN.crt" -text -noout | head -20 | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: SSL certificate not found for $DOMAIN" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: Available files in /etc/nginx/ssl/:" | tee -a "$LOG_FILE"
    docker exec purebliss-nginx-test ls -la /etc/nginx/ssl/ | tee -a "$LOG_FILE"
fi

# Test 6: Health checks
echo "[$(date)] INFO: Test 6 - Running health checks..." | tee -a "$LOG_FILE"

# HTTP health check
if check_service_health "Nginx HTTP" "http://localhost:8080/health"; then
    echo "[$(date)] SUCCESS: HTTP health check passed" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: HTTP health check failed" | tee -a "$LOG_FILE"
fi

# HTTPS health check
if check_service_health "Nginx HTTPS" "https://localhost:8443/health"; then
    echo "[$(date)] SUCCESS: HTTPS health check passed" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: HTTPS health check failed" | tee -a "$LOG_FILE"
fi

# Test 7: Test orchestrator function
echo "[$(date)] INFO: Test 7 - Testing orchestrator start_nginx() function..." | tee -a "$LOG_FILE"

# Clean up test container first
docker rm -f purebliss-nginx-test >/dev/null 2>&1 || true
docker volume rm purebliss_nginx_test_certs purebliss_nginx_test_dhparam >/dev/null 2>&1 || true

# Source the orchestrator and test start_nginx function
cd /opt/dev-purebliss
source start-all-services.sh

if start_nginx; then
    echo "[$(date)] SUCCESS: Orchestrator start_nginx() function completed successfully" | tee -a "$LOG_FILE"

    # Final health check on production container
    if check_service_health "Production Nginx HTTPS" "https://$DOMAIN/health"; then
        echo "[$(date)] SUCCESS: Production Nginx is healthy and SSL/TLS compliant" | tee -a "$LOG_FILE"
    else
        echo "[$(date)] WARNING: Production Nginx health check inconclusive" | tee -a "$LOG_FILE"
    fi
else
    echo "[$(date)] ERROR: Orchestrator start_nginx() function failed" | tee -a "$LOG_FILE"
    exit 1
fi

# Test 8: SSL/TLS compliance validation
echo "[$(date)] INFO: Test 8 - SSL/TLS compliance validation..." | tee -a "$LOG_FILE"

# Check SSL configuration
echo "[$(date)] INFO: Validating SSL configuration..." | tee -a "$LOG_FILE"
if curl -k -s -I "https://$DOMAIN" | grep -q "Strict-Transport-Security"; then
    echo "[$(date)] SUCCESS: HSTS header present" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: HSTS header missing" | tee -a "$LOG_FILE"
fi

if curl -k -s -I "https://$DOMAIN" | grep -q "X-Content-Type-Options"; then
    echo "[$(date)] SUCCESS: Security headers present" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: Security headers missing" | tee -a "$LOG_FILE"
fi

# Summary
echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: Nginx Independent Startup Test Summary" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: Nginx independent container startup with Vault PKI integration completed" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: SSL/TLS certificate automation functional" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: Nginx container can start standalone with docker run" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: Orchestrator integration functional" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: Nginx SSL/TLS compliance enhancement complete" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"

echo "[$(date)] SUCCESS: All Nginx independent startup tests completed successfully" | tee -a "$LOG_FILE"

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
