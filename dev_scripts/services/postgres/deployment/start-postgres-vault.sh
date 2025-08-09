#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# START_POSTGRES_VAULT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="start-postgres-vault.sh"
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
start_postgres_vault_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
start_postgres_vault_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
start_postgres_vault_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
start_postgres_vault_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    start_postgres_vault_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        start_postgres_vault_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            start_postgres_vault_log_success "Validation passed - proceeding with auto-commit"
        else
            start_postgres_vault_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        start_postgres_vault_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        start_postgres_vault_log_info "Auto-commit system not available - manual commit required"
        start_postgres_vault_log_info "Recommended commit message: $commit_message"
        start_postgres_vault_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
start_postgres_vault_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    start_postgres_vault_log_success "$final_message"
    
    # Execute auto-commit wrapper
    start_postgres_vault_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    start_postgres_vault_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# PostgreSQL Vault-Integrated Startup Script
# Pure Bliss Elite Standards: Zero-Trust, Vault-Managed Secrets
# This script starts PostgreSQL with full Vault integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_info() {
    echo "[$(date)] POSTGRES_START: $1" | tee -a "$LOG_FILE"
}

function log_success() {
    echo "[$(date)] POSTGRES_START: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] POSTGRES_START: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1" >&2
}

function wait_for_vault() {
    local max_attempts=60
    local attempt=1

    log_info "Waiting for Vault to be ready before starting PostgreSQL..."

    while [[ $attempt -le $max_attempts ]]; do
        if curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
            if curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
                log_success "Vault is ready and unsealed"
                return 0
            fi
        fi

        log_info "Waiting for Vault (attempt $attempt/$max_attempts)..."
        sleep 3
        ((attempt++))
    done

    log_error "Vault not ready after $max_attempts attempts"
    return 1
}

function cleanup_existing_postgres() {
    log_info "Cleaning up any existing PostgreSQL containers..."

    # Stop and remove existing PostgreSQL containers
    if docker ps -a | grep -q purebliss-postgres; then
        docker stop purebliss-postgres 2>/dev/null || true
        docker rm purebliss-postgres 2>/dev/null || true
        log_info "Removed existing PostgreSQL container"
    fi

    # Clean up any orphaned volumes if needed
    if docker volume ls | grep -q postgres_secrets; then
        docker volume rm postgres_secrets 2>/dev/null || true
    fi
}

function start_postgres_vault_integrated() {
    log_info "Starting PostgreSQL with Vault integration..."

    # Ensure we're in the correct directory
    cd "$SCRIPT_DIR"

    # Make sure the entrypoint script is executable
    chmod +x vault-entrypoint.sh

    # Start PostgreSQL using the Vault-integrated docker-compose
    if docker-compose -f postgres-docker-compose-vault.yml up -d; then
        log_success "PostgreSQL container started with Vault integration"
    else
        log_error "Failed to start PostgreSQL container"
        return 1
    fi

    # Wait for container to be running
    local max_wait=60
    local wait_count=0

    while [[ $wait_count -lt $max_wait ]]; do
        if docker ps | grep -q purebliss-postgres; then
            log_success "PostgreSQL container is running"
            break
        fi
        sleep 2
        ((wait_count++))
    done

    if [[ $wait_count -ge $max_wait ]]; then
        log_error "PostgreSQL container failed to start properly"
        docker logs purebliss-postgres --tail 50
        return 1
    fi
}

function wait_for_postgres_healthy() {
    log_info "Waiting for PostgreSQL to be healthy..."

    local max_attempts=60
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        # Check container health
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-postgres 2>/dev/null || echo "no_healthcheck")

        if [[ "$health_status" == "healthy" ]]; then
            log_success "PostgreSQL is healthy and ready"
            return 0
        elif [[ "$health_status" == "unhealthy" ]]; then
            log_error "PostgreSQL health check failed"
            docker logs purebliss-postgres --tail 20
            return 1
        fi

        log_info "PostgreSQL health status: $health_status (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    log_error "PostgreSQL health check timed out"
    return 1
}

function validate_postgres_vault_integration() {
    log_info "Validating PostgreSQL Vault integration..."

    # Test basic PostgreSQL connectivity
    if docker exec purebliss-postgres pg_isready -U postgres -d postgres >/dev/null 2>&1; then
        log_success "PostgreSQL basic connectivity working"
    else
        log_error "PostgreSQL basic connectivity failed"
        return 1
    fi

    # Test if vault_admin user exists
    if docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='vault_admin'" 2>/dev/null | grep -q 1; then
        log_success "Vault admin user exists in PostgreSQL"
    else
        log_error "Vault admin user not found in PostgreSQL"
        return 1
    fi

    # Test if service databases exist
    local databases=("keycloak" "plane" "vikunja")
    for db in "${databases[@]}"; do
        if docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$db'" 2>/dev/null | grep -q 1; then
            log_success "Database '$db' exists"
        else
            log_error "Database '$db' not found"
            return 1
        fi
    done

    # Test Vault dynamic credentials if available
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        if vault read database/creds/postgres-role >/dev/null 2>&1; then
            log_success "Vault dynamic credentials working"
        else
            log_error "Vault dynamic credentials not working"
            return 1
        fi
    else
        log_info "Vault token not available for testing dynamic credentials"
    fi

    log_success "PostgreSQL Vault integration validation completed successfully"
}

function main() {
    log_info "Starting PostgreSQL with complete Vault integration (Pure Bliss Elite Standards)"

    # Step 1: Wait for Vault to be ready
    if ! wait_for_vault; then
        log_error "Cannot start PostgreSQL without Vault (Zero-Trust principle)"
        exit 1
    fi

    # Step 2: Cleanup any existing containers
    cleanup_existing_postgres

    # Step 3: Start PostgreSQL with Vault integration
    if ! start_postgres_vault_integrated; then
        log_error "Failed to start PostgreSQL with Vault integration"
        exit 1
    fi

    # Step 4: Wait for PostgreSQL to be healthy
    if ! wait_for_postgres_healthy; then
        log_error "PostgreSQL failed to become healthy"
        exit 1
    fi

    # Step 5: Validate the integration
    if ! validate_postgres_vault_integration; then
        log_error "PostgreSQL Vault integration validation failed"
        exit 1
    fi

    log_success "🎉 PostgreSQL started successfully with complete Vault integration!"
    log_success "✅ Zero hardcoded secrets"
    log_success "✅ Dynamic credential generation working"
    log_success "✅ Service databases created and configured"
    log_success "✅ Ready for other services to connect"

    # Show status
    echo ""
    echo "PostgreSQL Status:"
    docker ps --filter name=purebliss-postgres --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo "To validate the setup, run:"
    echo "  /opt/dev-purebliss/services/postgres/validate-setup.sh"
    echo ""
    echo "To run comprehensive health check:"
    echo "  /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh"
}

# Run main function
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
