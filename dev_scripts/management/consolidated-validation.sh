#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# CONSOLIDATED_VALIDATION_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="consolidated-validation.sh"
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
consolidated_validation_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
consolidated_validation_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
consolidated_validation_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
consolidated_validation_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    consolidated_validation_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        consolidated_validation_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            consolidated_validation_log_success "Validation passed - proceeding with auto-commit"
        else
            consolidated_validation_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        consolidated_validation_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        consolidated_validation_log_info "Auto-commit system not available - manual commit required"
        consolidated_validation_log_info "Recommended commit message: $commit_message"
        consolidated_validation_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
consolidated_validation_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    consolidated_validation_log_success "$final_message"
    
    # Execute auto-commit wrapper
    consolidated_validation_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    consolidated_validation_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Configuration (must be set before sourcing utilities)
VALIDATION_LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
LOG_FILE="$VALIDATION_LOG"

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"


# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Consolidated validation script - comprehensive health checks and validation procedures"


# Additional configuration
CONFIG_ENV="/opt/my-secure-ha-stack/config.env"

# Load configuration
if [[ -f "$CONFIG_ENV" ]]; then
    source "$CONFIG_ENV"
fi

# Service validation functions
validate_vault_health() {
    local phase="${1:-health-check}"

    log_info "🔒 Validating Vault health - Phase: $phase"

    # Check if Vault container is running
    if ! docker ps -q -f name=purebliss-vault > /dev/null 2>&1; then
        log_error "Vault container is not running"
        return 1
    fi

    # Check Vault health endpoint
    local vault_health_url="http://127.0.0.1:18200/v1/sys/health"

    log_info "Checking Vault health endpoint: $vault_health_url"

    # Use curl with insecure flag for self-signed certificates in development
    if curl -k -s --connect-timeout 10 "$vault_health_url" | grep -q '"initialized":true'; then
        log_success "✅ Vault health check passed - Vault is initialized and responding"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_HEALTH_CHECK_SUCCESS: Vault responding correctly on port 8200" >> "$VALIDATION_LOG"
        return 0
    else
        log_error "❌ Vault health check failed - Vault not responding or not initialized"

        # Additional diagnostics
        log_info "Running additional Vault diagnostics..."

        # Check container logs
        log_info "Recent Vault container logs:"
        docker logs --tail 20 purebliss-vault || true

        # Check if Vault is listening on port 8200
        if docker exec purebliss-vault netstat -tuln 2>/dev/null | grep -q ":8200"; then
            log_info "✅ Vault is listening on port 8200"
        else
            log_error "❌ Vault is not listening on port 8200"
        fi

        # Check Vault process
        if docker exec purebliss-vault pgrep vault > /dev/null 2>&1; then
            log_info "✅ Vault process is running"
        else
            log_error "❌ Vault process is not running"
        fi

        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_HEALTH_CHECK_FAILED: Vault health validation failed - manual intervention required" >> "$VALIDATION_LOG"
        return 1
    fi
}

validate_postgres_health() {
    local phase="${1:-raid-validation}"

    log_info "🐘 Validating PostgreSQL health - Phase: $phase"

    # Check if PostgreSQL container is running
    if ! docker ps -q -f name=purebliss-postgres > /dev/null 2>&1; then
        log_error "PostgreSQL container is not running"
        return 1
    fi

    # Check PostgreSQL connection
    log_info "Testing PostgreSQL connection on RAID storage"

    if docker exec purebliss-postgres pg_isready -h localhost -p 5432 -U postgres > /dev/null 2>&1; then
        log_success "✅ PostgreSQL is ready and accepting connections"

        # Check actual data directory path
        local data_dir="/var/lib/postgresql/data/pgdata"
        if docker exec purebliss-postgres test -d "$data_dir"; then
            log_success "✅ PostgreSQL data directory exists: $data_dir"

            # Check if PostgreSQL is actually using the data directory
            if docker exec purebliss-postgres pg_controldata "$data_dir" > /dev/null 2>&1; then
                log_success "✅ PostgreSQL control data validates - database is properly configured"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - POSTGRES_VALIDATION_SUCCESS: PostgreSQL healthy and operational" >> "$VALIDATION_LOG"
                return 0
            else
                log_error "❌ PostgreSQL control data validation failed"
            fi
        else
            log_error "❌ PostgreSQL data directory not found: $data_dir"
        fi
    else
        log_error "❌ PostgreSQL is not ready or not accepting connections"
    fi

    # Additional diagnostics
    log_info "Running additional PostgreSQL diagnostics..."

    # Check container logs
    log_info "Recent PostgreSQL container logs:"
    docker logs --tail 20 purebliss-postgres || true

    # Check PostgreSQL processes
    if docker exec purebliss-postgres pgrep postgres > /dev/null 2>&1; then
        log_info "✅ PostgreSQL processes are running"
    else
        log_error "❌ PostgreSQL processes are not running"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - POSTGRES_RAID_VALIDATION_FAILED: PostgreSQL validation failed - manual intervention required" >> "$VALIDATION_LOG"
    return 1
}

validate_redis_health() {
    local phase="${1:-initialization}"

    log_info "🔴 Validating Redis health - Phase: $phase"

    # Check if Redis container is running
    if ! docker ps -q -f name=purebliss-redis > /dev/null 2>&1; then
        log_error "Redis container is not running"
        return 1
    fi

    # Check Redis connection
    if docker exec purebliss-redis redis-cli ping | grep -q "PONG"; then
        log_success "✅ Redis is responding to ping"

        # Check AOF persistence
        if docker exec purebliss-redis redis-cli config get appendonly | grep -q "yes"; then
            log_success "✅ Redis AOF persistence is enabled"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - REDIS_HEALTH_CHECK_SUCCESS: Redis healthy with AOF persistence" >> "$VALIDATION_LOG"
            return 0
        else
            log_error "❌ Redis AOF persistence is not enabled"
        fi
    else
        log_error "❌ Redis is not responding to ping"
    fi

    # Additional diagnostics
    log_info "Running additional Redis diagnostics..."
    docker logs --tail 20 purebliss-redis || true

    echo "$(date '+%Y-%m-%d %H:%M:%S') - REDIS_HEALTH_CHECK_FAILED: Redis validation failed" >> "$VALIDATION_LOG"
    return 1
}

validate_keycloak_health() {
    local phase="${1:-database-init}"

    log_info "🔑 Validating Keycloak health - Phase: $phase"

    # Check if Keycloak container is running
    if ! docker ps -q -f name=purebliss-keycloak > /dev/null 2>&1; then
        log_error "Keycloak container is not running"
        return 1
    fi

    # Check Keycloak health endpoint
    local keycloak_health_url="http://localhost:8080/health"

    if curl -s --connect-timeout 10 "$keycloak_health_url" | grep -q '"status":"UP"'; then
        log_success "✅ Keycloak health check passed"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - KEYCLOAK_HEALTH_CHECK_SUCCESS: Keycloak responding correctly" >> "$VALIDATION_LOG"
        return 0
    else
        log_error "❌ Keycloak health check failed"
        docker logs --tail 20 purebliss-keycloak || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - KEYCLOAK_HEALTH_CHECK_FAILED: Keycloak validation failed" >> "$VALIDATION_LOG"
        return 1
    fi
}

validate_nginx_health() {
    local phase="${1:-smart-upstream}"

    log_info "🌐 Validating Nginx health - Phase: $phase"

    # Check if Nginx container is running
    if ! docker ps -q -f name=purebliss-nginx > /dev/null 2>&1; then
        log_error "Nginx container is not running"
        return 1
    fi

    # Check Nginx configuration
    if docker exec purebliss-nginx nginx -t > /dev/null 2>&1; then
        log_success "✅ Nginx configuration is valid"

        # Check if Nginx is responding
        if curl -s --connect-timeout 10 http://localhost:80 > /dev/null 2>&1; then
            log_success "✅ Nginx is responding on port 80"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - NGINX_HEALTH_CHECK_SUCCESS: Nginx healthy and responding" >> "$VALIDATION_LOG"
            return 0
        else
            log_error "❌ Nginx is not responding on port 80"
        fi
    else
        log_error "❌ Nginx configuration is invalid"
        docker exec purebliss-nginx nginx -t || true
    fi

    docker logs --tail 20 purebliss-nginx || true
    echo "$(date '+%Y-%m-%d %H:%M:%S') - NGINX_HEALTH_CHECK_FAILED: Nginx validation failed" >> "$VALIDATION_LOG"
    return 1
}

# Container status validation
validate_container_status() {
    local service="$1"

    log_info "📊 Validating container status for: $service"

    local container_name="purebliss-$service"

    # Check if container exists
    if ! docker ps -a -q -f name="$container_name" > /dev/null 2>&1; then
        log_error "Container $container_name does not exist"
        return 1
    fi

    # Check if container is running
    if docker ps -q -f name="$container_name" > /dev/null 2>&1; then
        log_success "✅ Container $container_name is running"

        # Check health status if available
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-health-check")

        case "$health_status" in
            "healthy")
                log_success "✅ Container $container_name is healthy"
                ;;
            "unhealthy")
                log_error "❌ Container $container_name is unhealthy"
                docker logs --tail 10 "$container_name" || true
                ;;
            "starting")
                log_info "🔄 Container $container_name is starting"
                ;;
            "no-health-check")
                log_info "ℹ️  Container $container_name has no health check configured"
                ;;
        esac

        return 0
    else
        log_error "❌ Container $container_name is not running"

        # Check container status
        local container_status=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" || echo "Not found")
        log_info "Container status: $container_status"

        return 1
    fi
}

# Main validation function
main() {
    local service="${1:-help}"
    local validation_type="${2:-health-check}"

    log_info "Starting consolidated validation for: $service (type: $validation_type)"

    case "$service" in
        "vault")
            validate_container_status vault
            validate_vault_health "$validation_type"
            ;;
        "postgres")
            validate_container_status postgres
            validate_postgres_health "$validation_type"
            ;;
        "redis")
            validate_container_status redis
            validate_redis_health "$validation_type"
            ;;
        "keycloak")
            validate_container_status keycloak
            validate_keycloak_health "$validation_type"
            ;;
        "nginx")
            validate_container_status nginx
            validate_nginx_health "$validation_type"
            ;;
        "all")
            log_info "Running validation for all services"
            local services=("vault" "postgres" "redis" "keycloak" "nginx")
            local overall_success=true

            for svc in "${services[@]}"; do
                if ! main "$svc" "$validation_type"; then
                    overall_success=false
                fi
            done

            if $overall_success; then
                log_success "✅ All services validation passed"
                return 0
            else
                log_error "❌ Some services validation failed"
                return 1
            fi
            ;;
        "help"|*)
            echo "Usage: $0 <service> [validation_type]"
            echo "Services: vault, postgres, redis, keycloak, nginx, all"
            echo "Validation types: health-check, raid-validation, initialization, etc."
            echo ""
            echo "Examples:"
            echo "  $0 vault health-check-phase1"
            echo "  $0 postgres raid-validation-phase1"
            echo "  $0 all comprehensive"
            exit 1
            ;;
    esac
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
