#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# DEPLOY_WITH_VAULT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="deploy-with-vault.sh"
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
deploy_with_vault_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
deploy_with_vault_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
deploy_with_vault_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
deploy_with_vault_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    deploy_with_vault_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        deploy_with_vault_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            deploy_with_vault_log_success "Validation passed - proceeding with auto-commit"
        else
            deploy_with_vault_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        deploy_with_vault_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        deploy_with_vault_log_info "Auto-commit system not available - manual commit required"
        deploy_with_vault_log_info "Recommended commit message: $commit_message"
        deploy_with_vault_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
deploy_with_vault_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    deploy_with_vault_log_success "$final_message"
    
    # Execute auto-commit wrapper
    deploy_with_vault_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    deploy_with_vault_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# nginx Vault Integration Startup Script
# Configures Vault integration and starts nginx with dynamic secrets
# Integration Type: pki_certificates

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE_NAME="nginx"
INTEGRATION_TYPE="pki_certificates"

function log_action() {
    echo "[$(date)] NGINX_VAULT_START: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] NGINX_VAULT_START: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] NGINX_VAULT_START: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

# Configure Vault integration based on type
function configure_vault_integration() {
    log_action "Configuring Vault $INTEGRATION_TYPE integration for $SERVICE_NAME..."


    # Auto-detect Vault protocol (HTTP/HTTPS) and validate endpoint
    VAULT_ADDR_CANDIDATES=("https://127.0.0.1:8200" "https://127.0.0.1:8200")
    export VAULT_SKIP_VERIFY=1
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    for addr in "${VAULT_ADDR_CANDIDATES[@]}"; do
        export VAULT_ADDR="$addr"
        if vault status >/dev/null 2>&1; then
            log_action "Detected working Vault endpoint: $VAULT_ADDR"
            break
        else
            log_action "Vault endpoint $VAULT_ADDR not responding, trying next..."
        fi
    done
    if ! vault status >/dev/null 2>&1; then
        log_error "No working Vault endpoint detected (HTTP/HTTPS). Aborting."
        exit 1
    fi

    case "$INTEGRATION_TYPE" in
        "kv_secrets")
            configure_kv_secrets_integration
            ;;
        "database_dynamic")
            configure_database_integration
            ;;
        "pki_certificates")
            configure_pki_integration
            ;;
        "monitoring_config")
            configure_monitoring_integration
            ;;
    esac
}

function configure_kv_secrets_integration() {
    log_action "Configuring KV v2 secrets for $SERVICE_NAME..."

    # Enable KV v2 secrets engine if not already enabled
    vault secrets enable -version=2 kv 2>/dev/null || true

    # Create default secrets for service
    if ! vault kv get secret/$SERVICE_NAME >/dev/null 2>&1; then
        log_action "Creating default secrets for $SERVICE_NAME..."
        vault kv put secret/$SERVICE_NAME \
            admin_password="$(openssl rand -base64 32)" \
            api_key="$(openssl rand -hex 32)" \
            secret_key="$(openssl rand -base64 32)"
        log_success "Default secrets created for $SERVICE_NAME"
    else
        log_success "Secrets already exist for $SERVICE_NAME"
    fi
}

function configure_database_integration() {
    log_action "Configuring database dynamic credentials for $SERVICE_NAME..."

    # Configure database role if not exists
    if ! vault read database/roles/$SERVICE_NAME-role >/dev/null 2>&1; then
        log_action "Creating database role for $SERVICE_NAME..."
        vault write database/roles/$SERVICE_NAME-role \
            db_name=postgres-app \
            creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT CONNECT ON DATABASE $SERVICE_NAME TO \"{{name}}\"; GRANT USAGE ON SCHEMA public TO \"{{name}}\"; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"{{name}}\";" \
            default_ttl="1h" \
            max_ttl="24h"
        log_success "Database role created for $SERVICE_NAME"
    else
        log_success "Database role already exists for $SERVICE_NAME"
    fi
}

function configure_pki_integration() {
    log_action "Configuring PKI certificates for $SERVICE_NAME..."

    # Enable PKI secrets engine if not exists
    vault secrets enable -path=pki-$SERVICE_NAME pki 2>/dev/null || true
    vault secrets tune -max-lease-ttl=8760h pki-$SERVICE_NAME

    # Configure PKI root CA if not exists
    if ! vault read pki-$SERVICE_NAME/cert/ca >/dev/null 2>&1; then
        log_action "Creating PKI root CA for $SERVICE_NAME..."
        vault write pki-$SERVICE_NAME/root/generate/internal \
            common_name="Pure Bliss $SERVICE_NAME CA" \
            ttl=8760h
        log_success "PKI root CA created for $SERVICE_NAME"
    fi

    # Configure PKI role if not exists
    if ! vault read pki-$SERVICE_NAME/roles/$SERVICE_NAME-role >/dev/null 2>&1; then
        log_action "Creating PKI role for $SERVICE_NAME..."
        vault write pki-$SERVICE_NAME/roles/$SERVICE_NAME-role \
            allowed_domains="dev.purebliss.app" \
            allow_subdomains=true \
            max_ttl="720h"
        log_success "PKI role created for $SERVICE_NAME"
    fi
}

function configure_monitoring_integration() {
    log_action "Configuring monitoring configuration for $SERVICE_NAME..."

    # Create monitoring configuration in Vault
    if ! vault kv get $SERVICE_NAME-config/main >/dev/null 2>&1; then
        log_action "Creating monitoring configuration for $SERVICE_NAME..."
        vault kv put $SERVICE_NAME-config/main \
            scrape_interval="15s" \
            evaluation_interval="15s" \
            retention_time="200h" \
            admin_password="$(openssl rand -base64 32)"
        log_success "Monitoring configuration created for $SERVICE_NAME"
    fi
}

function start_service() {
    log_action "Starting $SERVICE_NAME with Vault integration..."

    cd "$(dirname "$0")"
    docker-compose -f ${SERVICE_NAME}-docker-compose-vault-enhanced.yml up -d

    # Wait for service to be healthy
    for i in {1..30}; do
        if docker inspect --format='{{.State.Health.Status}}' purebliss-$SERVICE_NAME 2>/dev/null | grep -q healthy; then
            log_success "$SERVICE_NAME is healthy and ready"
            break
        fi
        if [[ $i -eq 30 ]]; then
            log_error "$SERVICE_NAME failed to start within timeout"
            return 1
        fi
        sleep 2
    done
}

function validate_integration() {
    log_action "Validating $SERVICE_NAME Vault integration..."

    if [[ -x "./validate-${SERVICE_NAME}-vault-integration.sh" ]]; then
        ./validate-${SERVICE_NAME}-vault-integration.sh
    else
        log_action "No validation script found, running basic checks..."

        # Basic health check
        if docker ps | grep -q purebliss-$SERVICE_NAME; then
            log_success "$SERVICE_NAME container is running"
        else
            log_error "$SERVICE_NAME container is not running"
            return 1
        fi
    fi
}

# Main execution
function main() {
    log_action "Starting $SERVICE_NAME with Vault $INTEGRATION_TYPE integration..."

    configure_vault_integration
    start_service
    validate_integration

    log_success "$SERVICE_NAME successfully started with Vault integration!"
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
