#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_INTEGRATION_TEST_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-integration-test.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced vault-integration script for vault operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="vault-integration"
SCRIPT_TAGS="enhancement,automation,auto-commit,vault,security,testing,validation"
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
vault_integration_test_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_integration_test_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_integration_test_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
vault_integration_test_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_integration_test_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_integration_test_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_integration_test_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_integration_test_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_integration_test_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_integration_test_log_info "Auto-commit system not available - manual commit required"
        vault_integration_test_log_info "Recommended commit message: $commit_message"
        vault_integration_test_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_integration_test_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_integration_test_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_integration_test_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_integration_test_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# nginx Vault Integration Validation Script
# Validates all aspects of nginx Vault integration
# Integration Type: pki_certificates

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE_NAME="nginx"
INTEGRATION_TYPE="pki_certificates"

function log_check() {
    echo "🔍 $1"
    echo "[$(date)] NGINX_VALIDATION: $1" >> "$LOG_FILE"
}

function log_success() {
    echo "✅ $1"
    echo "[$(date)] NGINX_VALIDATION: ✅ SUCCESS: $1" >> "$LOG_FILE"
}

function log_error() {
    echo "❌ $1"
    echo "[$(date)] NGINX_VALIDATION: ❌ ERROR: $1" >> "$LOG_FILE"
}

function validate_container_health() {
    log_check "Validating $SERVICE_NAME container health..."

    if docker ps | grep -q purebliss-$SERVICE_NAME; then
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-$SERVICE_NAME 2>/dev/null || echo "no_healthcheck")

        case "$health_status" in
            "healthy")
                log_success "$SERVICE_NAME container is healthy"
                return 0
                ;;
            "unhealthy")
                log_error "$SERVICE_NAME container is unhealthy"
                return 1
                ;;
            "starting")
                log_check "$SERVICE_NAME container is starting..."
                return 1
                ;;
            "no_healthcheck")
                if docker inspect --format='{{.State.Status}}' purebliss-$SERVICE_NAME | grep -q running; then
                    log_success "$SERVICE_NAME container is running (no health check)"
                    return 0
                else
                    log_error "$SERVICE_NAME container is not running"
                    return 1
                fi
                ;;
        esac
    else
        log_error "$SERVICE_NAME container is not running"
        return 1
    fi
}

function validate_vault_integration() {
    log_check "Validating $SERVICE_NAME Vault integration..."

    # Auto-detect Vault protocol (HTTP/HTTPS) and validate endpoint
    VAULT_ADDR_CANDIDATES=("https://127.0.0.1:8200" "https://127.0.0.1:8200")
    export VAULT_SKIP_VERIFY=1
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
        for addr in "${VAULT_ADDR_CANDIDATES[@]}"; do
            export VAULT_ADDR="$addr"
            if vault status >/dev/null 2>&1; then
                log_check "Detected working Vault endpoint: $VAULT_ADDR"
                break
            else
                log_check "Vault endpoint $VAULT_ADDR not responding, trying next..."
            fi
        done
        if ! vault status >/dev/null 2>&1; then
            log_error "No working Vault endpoint detected (HTTP/HTTPS). Aborting validation."
            return 1
        fi
        case "$INTEGRATION_TYPE" in
            "kv_secrets")
                validate_kv_secrets_integration
                ;;
            "database_dynamic")
                validate_database_integration
                ;;
            "pki_certificates")
                validate_pki_integration
                ;;
            "monitoring_config")
                validate_monitoring_integration
                ;;
        esac
    else
        log_error "Vault token not found"
        return 1
    fi
}

function validate_kv_secrets_integration() {
    log_check "Validating KV secrets integration..."

    if vault kv get secret/$SERVICE_NAME >/dev/null 2>&1; then
        log_success "KV secrets accessible for $SERVICE_NAME"

        # Test secret retrieval
        local admin_password
        admin_password=$(vault kv get -field=admin_password secret/$SERVICE_NAME 2>/dev/null || echo "")
        if [[ -n "$admin_password" ]]; then
            log_success "Admin password retrieved from Vault"
        else
            log_error "Admin password not found in Vault"
            return 1
        fi
    else
        log_error "KV secrets not accessible for $SERVICE_NAME"
        return 1
    fi
}

function validate_database_integration() {
    log_check "Validating database dynamic credentials integration..."

    # Test database role
    if vault read database/roles/$SERVICE_NAME-role >/dev/null 2>&1; then
        log_success "Database role configured for $SERVICE_NAME"

        # Test credential generation
        if vault read database/creds/$SERVICE_NAME-role >/dev/null 2>&1; then
            log_success "Dynamic credentials can be generated for $SERVICE_NAME"
        else
            log_error "Dynamic credential generation failed for $SERVICE_NAME"
            return 1
        fi
    else
        log_error "Database role not configured for $SERVICE_NAME"
        return 1
    fi
}

function validate_pki_integration() {
    log_check "Validating PKI certificate integration..."

    # Test PKI engine
    if vault read pki-$SERVICE_NAME/cert/ca >/dev/null 2>&1; then
        log_success "PKI CA certificate available for $SERVICE_NAME"

        # Test certificate generation
        if vault write pki-$SERVICE_NAME/issue/$SERVICE_NAME-role common_name="test.dev.purebliss.app" ttl="1h" >/dev/null 2>&1; then
            log_success "PKI certificate can be generated for $SERVICE_NAME"
        else
            log_error "PKI certificate generation failed for $SERVICE_NAME"
            return 1
        fi
    else
        log_error "PKI CA certificate not available for $SERVICE_NAME"
        return 1
    fi
}

function validate_monitoring_integration() {
    log_check "Validating monitoring configuration integration..."

    if vault kv get $SERVICE_NAME-config/main >/dev/null 2>&1; then
        log_success "Monitoring configuration accessible for $SERVICE_NAME"

        # Test configuration retrieval
        local scrape_interval
        scrape_interval=$(vault kv get -field=scrape_interval $SERVICE_NAME-config/main 2>/dev/null || echo "")
        if [[ -n "$scrape_interval" ]]; then
            log_success "Configuration parameters retrieved from Vault"
        else
            log_error "Configuration parameters not found in Vault"
            return 1
        fi
    else
        log_error "Monitoring configuration not accessible for $SERVICE_NAME"
        return 1
    fi
}

function validate_service_functionality() {
    log_check "Validating $SERVICE_NAME service functionality..."

    # Service-specific functionality tests
    case "$SERVICE_NAME" in
        "redis")
            validate_redis_functionality
            ;;
        "keycloak")
            validate_keycloak_functionality
            ;;
        "nginx")
            validate_nginx_functionality
            ;;
        "prometheus")
            validate_prometheus_functionality
            ;;
        *)
            log_check "Generic service functionality validation for $SERVICE_NAME"
            # Generic HTTP health check
            local service_port=$(docker port purebliss-$SERVICE_NAME | head -1 | cut -d: -f2)
            if [[ -n "$service_port" ]] && curl -skf "http://localhost:$service_port/health" >/dev/null 2>&1; then
                log_success "$SERVICE_NAME service endpoint responding"
            else
                log_check "$SERVICE_NAME service endpoint not responding (may be expected)"
            fi
            ;;
    esac
}

function validate_redis_functionality() {
    if docker exec purebliss-redis redis-cli ping | grep -q PONG; then
        log_success "Redis ping successful"
    else
        log_error "Redis ping failed"
        return 1
    fi
}

function validate_keycloak_functionality() {
    if curl -sk "http://localhost:8080/" | grep -qE "(Keycloak|Resource not found)"; then
        log_success "Keycloak endpoint responding"
    else
        log_error "Keycloak endpoint not responding"
        return 1
    fi
}

function validate_nginx_functionality() {
    if curl -skk "https://dev.purebliss.app" -o /dev/null -w "%{http_code}" | grep -q 200; then
        log_success "Nginx HTTPS endpoint responding"
    else
        log_error "Nginx HTTPS endpoint not responding"
        return 1
    fi
}

function validate_prometheus_functionality() {
    if curl -sk "http://localhost:9090/-/healthy" | grep -q "Prometheus is Healthy"; then
        log_success "Prometheus health endpoint responding"
    else
        log_error "Prometheus health endpoint not responding"
        return 1
    fi
}

# Main execution
function main() {
    log_check "Starting $SERVICE_NAME Vault integration validation..."

    local validation_status=0

    validate_container_health || validation_status=1
    validate_vault_integration || validation_status=1
    validate_service_functionality || validation_status=1

    if [[ $validation_status -eq 0 ]]; then
        log_success "$SERVICE_NAME Vault integration validation completed successfully!"
    else
        log_error "$SERVICE_NAME Vault integration validation failed"
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
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
