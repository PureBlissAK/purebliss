#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# ENHANCED_STARTUP_SEQUENCER_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="enhanced-startup-sequencer.sh"
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
enhanced_startup_sequencer_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
enhanced_startup_sequencer_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
enhanced_startup_sequencer_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
enhanced_startup_sequencer_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    enhanced_startup_sequencer_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        enhanced_startup_sequencer_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            enhanced_startup_sequencer_log_success "Validation passed - proceeding with auto-commit"
        else
            enhanced_startup_sequencer_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        enhanced_startup_sequencer_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        enhanced_startup_sequencer_log_info "Auto-commit system not available - manual commit required"
        enhanced_startup_sequencer_log_info "Recommended commit message: $commit_message"
        enhanced_startup_sequencer_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
enhanced_startup_sequencer_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    enhanced_startup_sequencer_log_success "$final_message"
    
    # Execute auto-commit wrapper
    enhanced_startup_sequencer_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    enhanced_startup_sequencer_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utilities/retry-utils.sh" 2>/dev/null || true

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="[Enhanced with centralized structure]"


# Enhanced Container Startup Sequencer
# Addresses dependency timing issues found in logs


# Service dependency map (service -> dependencies)
declare -A DEPENDENCIES=(
    ["vault"]=""
    ["vault-agent"]="vault"
    ["postgres"]=""
    ["redis"]=""
    ["nginx"]="vault"
    ["keycloak"]="postgres redis"
    ["plane"]="postgres redis"
    ["prometheus"]=""
    ["grafana"]="prometheus"
    ["loki"]=""
    ["codeserver"]="keycloak"
)

# Service startup timeout map
declare -A STARTUP_TIMEOUTS=(
    ["vault"]="60"
    ["vault-agent"]="30"
    ["postgres"]="120"
    ["redis"]="30"
    ["nginx"]="45"
    ["keycloak"]="180"
    ["plane"]="120"
    ["prometheus"]="60"
    ["grafana"]="90"
    ["loki"]="60"
    ["codeserver"]="120"
)

# Function to wait for service to be healthy
wait_for_service_health() {
    local service=$1
    local timeout=${STARTUP_TIMEOUTS[$service]:-60}
    local container_name="purebliss-${service}"
    
    echo "Waiting for $service to become healthy (timeout: ${timeout}s)..."
    
    local elapsed=0
    local check_interval=5
    
    while [ $elapsed -lt $timeout ]; do
        # Check if container exists and is running
        if docker ps -q -f name="$container_name" | grep -q .; then
            # Check health status
            local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-healthcheck")
            
            if [ "$health_status" = "healthy" ]; then
                echo "$service is healthy"
                return 0
            elif [ "$health_status" = "no-healthcheck" ]; then
                # For services without health checks, check if running
                if docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null | grep -q "true"; then
                    echo "$service is running (no health check)"
                    return 0
                fi
            fi
        fi
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "Waiting for $service... (${elapsed}s/${timeout}s)"
    done
    
    echo "ERROR: $service failed to become healthy within ${timeout}s"
    return 1
}

# Function to start service with dependency validation
start_service_with_deps() {
    local service=$1
    local deps="${DEPENDENCIES[$service]}"
    
    echo "Starting $service..."
    
    # First, validate all dependencies are healthy
    if [ -n "$deps" ]; then
        echo "Validating dependencies for $service: $deps"
        for dep in $deps; do
            if ! wait_for_service_health "$dep"; then
                echo "ERROR: Dependency $dep is not healthy, cannot start $service"
                return 1
            fi
        done
    fi
    
    # Start the service using appropriate method
    case $service in
        "keycloak")
            docker-compose -f /opt/dev-purebliss/services/keycloak/docker-compose.keycloak-postgres.yml up -d purebliss-keycloak
            ;;
        "postgres")
            docker-compose -f /opt/dev-purebliss/services/postgres/docker-compose.yml up -d purebliss-postgres
            ;;
        *)
            echo "Starting $service with docker-compose..."
            docker-compose -f /opt/my-secure-ha-stack/docker-compose.yml up -d "purebliss-$service" 2>/dev/null || echo "Service definition not found in main compose"
            ;;
    esac
    
    # Wait for the service to become healthy
    if wait_for_service_health "$service"; then
        echo "Successfully started $service"
        return 0
    else
        echo "Failed to start $service"
        return 1
    fi
}

# Function to start services in dependency order
start_services_ordered() {
    local services=("$@")
    
    echo "Starting services in dependency order: ${services[*]}"
    
    for service in "${services[@]}"; do
        echo "=== Starting $service ==="
        if ! start_service_with_deps "$service"; then
            echo "Failed to start $service, stopping deployment"
            return 1
        fi
        echo "=== $service started successfully ==="
        echo
    done
    
    echo "All services started successfully!"
}

# Main function
main() {
    local phase=${1:-"all"}
    
    case $phase in
        "core")
            start_services_ordered "vault" "vault-agent" "postgres" "redis" "nginx"
            ;;
        "auth")
            start_services_ordered "keycloak"
            ;;
        "apps")
            start_services_ordered "plane" "codeserver"
            ;;
        "monitoring")
            start_services_ordered "prometheus" "loki" "grafana"
            ;;
        "all")
            start_services_ordered "vault" "vault-agent" "postgres" "redis" "nginx" "keycloak" "plane" "codeserver" "prometheus" "loki" "grafana"
            ;;
        *)
            echo "Usage: $0 [core|auth|apps|monitoring|all]"
            exit 1
            ;;
    esac
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
