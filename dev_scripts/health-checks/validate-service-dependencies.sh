#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VALIDATE_SERVICE_DEPENDENCIES_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="validate-service-dependencies.sh"
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
validate_service_dependencies_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
validate_service_dependencies_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
validate_service_dependencies_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
validate_service_dependencies_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    validate_service_dependencies_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        validate_service_dependencies_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            validate_service_dependencies_log_success "Validation passed - proceeding with auto-commit"
        else
            validate_service_dependencies_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        validate_service_dependencies_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        validate_service_dependencies_log_info "Auto-commit system not available - manual commit required"
        validate_service_dependencies_log_info "Recommended commit message: $commit_message"
        validate_service_dependencies_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
validate_service_dependencies_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    validate_service_dependencies_log_success "$final_message"
    
    # Execute auto-commit wrapper
    validate_service_dependencies_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    validate_service_dependencies_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Enhanced Service Dependency Validation
# Addresses dependency connection failures found in logs


# Service dependency validation functions
validate_postgres_connection() {
    local host=${1:-purebliss-postgres}
    local port=${2:-5432}
    local user=${3:-$POSTGRES_USER}
    local db=${4:-$POSTGRES_DB}

    echo "Validating PostgreSQL connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to PostgreSQL at $host:$port"
        return 1
    fi

    # PostgreSQL specific readiness check
    if ! docker exec purebliss-postgres pg_isready -U "$user" -d "$db" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL not ready for connections"
        return 1
    fi

    # Connection test
    if ! docker exec purebliss-postgres psql -U "$user" -d "$db" -c "SELECT 1;" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL connection test failed"
        return 1
    fi

    echo "PostgreSQL connection validated successfully"
    return 0
}

validate_redis_connection() {
    local host=${1:-purebliss-redis}
    local port=${2:-6379}

    echo "Validating Redis connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to Redis at $host:$port"
        return 1
    fi

    # Redis ping test
    if ! docker exec purebliss-redis redis-cli ping > /dev/null 2>&1; then
        echo "ERROR: Redis ping failed"
        return 1
    fi

    echo "Redis connection validated successfully"
    return 0
}

validate_vault_connection() {
    local host=${1:-purebliss-vault}
    local port=${2:-8200}

    echo "Validating Vault connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to Vault at $host:$port"
        return 1
    fi

    # Vault status check
    local vault_status=$(docker exec purebliss-vault vault status -format=json 2>/dev/null | jq -r '.initialized // false' 2>/dev/null || echo "false")

    if [ "$vault_status" != "true" ]; then
        echo "ERROR: Vault not initialized"
        return 1
    fi

    echo "Vault connection validated successfully"
    return 0
}

# Main validation function
validate_service_dependencies() {
    local service=$1

    echo "Validating dependencies for $service..."

    case $service in
        "keycloak")
            validate_postgres_connection && validate_redis_connection
            ;;
        "plane")
            validate_postgres_connection && validate_redis_connection
            ;;
        "nginx")
            validate_vault_connection
            ;;
        "vault-agent")
            validate_vault_connection
            ;;
        *)
            echo "No specific dependency validation for $service"
            return 0
            ;;
    esac
}

# Main execution
main() {
    local service=${1:-"all"}

    if [ "$service" = "all" ]; then
        echo "Validating all service dependencies..."
        for svc in keycloak plane nginx vault-agent; do
            echo "=== Validating $svc dependencies ==="
            validate_service_dependencies "$svc"
            echo
        done
    else
        validate_service_dependencies "$service"
    fi
}

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
