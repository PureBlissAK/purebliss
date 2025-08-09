#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# INDEPENDENT_SERVICE_TESTING_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="independent-service-testing.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced health-validation script for monitoring operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="health-validation"
SCRIPT_TAGS="enhancement,automation,auto-commit,monitoring,testing,validation"
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
independent_service_testing_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
independent_service_testing_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
independent_service_testing_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
independent_service_testing_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    independent_service_testing_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        independent_service_testing_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            independent_service_testing_log_success "Validation passed - proceeding with auto-commit"
        else
            independent_service_testing_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        independent_service_testing_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        independent_service_testing_log_info "Auto-commit system not available - manual commit required"
        independent_service_testing_log_info "Recommended commit message: $commit_message"
        independent_service_testing_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
independent_service_testing_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    independent_service_testing_log_success "$final_message"
    
    # Execute auto-commit wrapper
    independent_service_testing_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    independent_service_testing_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Independent Service Testing Framework
# Ensures each service is tested in complete isolation for accurate health validation
# Date: 2025-08-06
# Purpose: Test services independently without interference from other running services


# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INDEPENDENT_TESTING [$1]: $2" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Service dependency mapping (only direct dependencies)
declare -A SERVICE_DEPENDENCIES=(
    ["vault"]=""
    ["vault-agent"]="vault"
    ["postgres"]=""
    ["redis"]=""
    ["nginx"]="vault"
    ["keycloak"]="postgres"  # Test with postgres only, not redis simultaneously
    ["plane"]="postgres"     # Test with postgres only, not redis simultaneously
    ["prometheus"]=""
    ["grafana"]="prometheus"
    ["loki"]=""
    ["codeserver"]="keycloak"
)

# Service test isolation requirements
declare -A SERVICE_ISOLATION=(
    ["vault"]="standalone"           # Test completely alone
    ["vault-agent"]="with_vault"     # Test with vault only
    ["postgres"]="standalone"        # Test completely alone
    ["redis"]="standalone"           # Test completely alone
    ["nginx"]="with_vault"          # Test with vault only initially
    ["keycloak"]="with_postgres"     # Test with postgres only, not redis
    ["plane"]="with_postgres"        # Test with postgres only, not redis
    ["prometheus"]="standalone"      # Test completely alone initially
    ["grafana"]="with_prometheus"    # Test with prometheus only
    ["loki"]="standalone"           # Test completely alone
    ["codeserver"]="with_keycloak"   # Test with keycloak (and its deps) only
)

# Function to stop all non-essential services
stop_non_essential_services() {
    local service_to_test=$1
    local required_deps="${SERVICE_DEPENDENCIES[$service_to_test]}"

    log_action "INFO" "Stopping all services except dependencies for $service_to_test"

    # Get list of all purebliss containers
    local all_containers=$(docker ps -q --filter "name=purebliss-" | xargs -r docker inspect --format '{{.Name}}' | sed 's|/purebliss-||')

    # Stop containers that are not required for this test
    for container in $all_containers; do
        local should_keep=false

        # Keep the service we're testing
        if [[ "$container" == "$service_to_test" ]]; then
            should_keep=true
        fi

        # Keep required dependencies
        for dep in $required_deps; do
            if [[ "$container" == "$dep" ]]; then
                should_keep=true
                break
            fi
        done

        # Stop unnecessary containers
        if [[ "$should_keep" == "false" ]]; then
            log_action "INFO" "Stopping unnecessary service for isolated test: $container"
            docker stop "purebliss-$container" 2>/dev/null || true
        else
            log_action "INFO" "Keeping required service for test: $container"
        fi
    done
}

# Function to start only required dependencies
start_required_dependencies() {
    local service_to_test=$1
    local required_deps="${SERVICE_DEPENDENCIES[$service_to_test]}"

    if [[ -z "$required_deps" ]]; then
        log_action "INFO" "No dependencies required for $service_to_test"
        return 0
    fi

    log_action "INFO" "Starting required dependencies for $service_to_test: $required_deps"

    for dep in $required_deps; do
        log_action "INFO" "Starting dependency: $dep"

        # Start the dependency if not running
        if ! docker ps -q --filter "name=purebliss-$dep" | grep -q .; then
            case $dep in
                "vault")
                    docker start purebliss-vault
                    ;;
                "postgres")
                    docker start purebliss-postgres
                    ;;
                "redis")
                    docker start purebliss-redis
                    ;;
                "prometheus")
                    docker start purebliss-prometheus
                    ;;
                "keycloak")
                    # Keycloak needs postgres, so start postgres first
                    docker start purebliss-postgres
                    sleep 10
                    docker start purebliss-keycloak
                    ;;
                *)
                    docker start "purebliss-$dep"
                    ;;
            esac
        fi

        # Wait for dependency to be healthy
        wait_for_service_health "$dep" 60
    done
}

# Function to wait for service health
wait_for_service_health() {
    local service=$1
    local timeout=${2:-60}
    local container_name="purebliss-$service"

    log_action "INFO" "Waiting for $service to become healthy (timeout: ${timeout}s)"

    local elapsed=0
    local check_interval=5

    while [ $elapsed -lt $timeout ]; do
        # Check if container exists and is running
        if docker ps -q -f name="$container_name" | grep -q .; then
            # Check health status
            local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-healthcheck")

            if [ "$health_status" = "healthy" ]; then
                log_action "SUCCESS" "$service is healthy"
                return 0
            elif [ "$health_status" = "no-healthcheck" ]; then
                # For services without health checks, check if running
                if docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null | grep -q "true"; then
                    log_action "SUCCESS" "$service is running (no health check)"
                    return 0
                fi
            else
                log_action "INFO" "$service health status: $health_status"
            fi
        else
            log_action "WARNING" "$service container not found or not running"
        fi

        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        log_action "INFO" "Waiting for $service... (${elapsed}s/${timeout}s)"
    done

    log_action "ERROR" "$service failed to become healthy within ${timeout}s"
    return 1
}

# Function to test service in isolation
test_service_independently() {
    local service=$1

    log_action "INFO" "Starting independent test for service: $service"

    # Step 1: Stop all non-essential services
    stop_non_essential_services "$service"

    # Step 2: Start only required dependencies
    start_required_dependencies "$service"

    # Step 3: Start the service we're testing
    log_action "INFO" "Starting service under test: $service"

    # Stop the service first if it's running
    docker stop "purebliss-$service" 2>/dev/null || true
    sleep 2

    # Start the service
    case $service in
        "keycloak")
            # Use our enhanced keycloak compose file
            cd /opt/dev-purebliss/services/keycloak
            docker-compose -f docker-compose.fixed.yml up -d
            ;;
        "postgres")
            docker start purebliss-postgres
            ;;
        "redis")
            docker start purebliss-redis
            ;;
        "vault")
            docker start purebliss-vault
            ;;
        "vault-agent")
            docker start purebliss-vault-agent
            ;;
        "nginx")
            docker start purebliss-nginx
            ;;
        *)
            docker start "purebliss-$service" 2>/dev/null || {
                log_action "WARNING" "Could not start $service with docker start, may need compose"
                return 1
            }
            ;;
    esac

    # Step 4: Wait for service to become healthy
    if wait_for_service_health "$service" 120; then
        log_action "SUCCESS" "$service started successfully in isolation"
    else
        log_action "ERROR" "$service failed to start in isolation"

        # Get logs for debugging
        log_action "INFO" "Container logs for debugging:"
        docker logs "purebliss-$service" --tail 20 | while read -r line; do
            log_action "DEBUG" "Container log: $line"
        done

        return 1
    fi

    # Step 5: Run service-specific health validation
    log_action "INFO" "Running comprehensive health validation for $service"
    if /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$service" "independent-test"; then
        log_action "SUCCESS" "$service passed independent health validation"
        return 0
    else
        log_action "ERROR" "$service failed independent health validation"
        return 1
    fi
}

# Function to run full independent test suite
run_independent_test_suite() {
    local services_to_test=("$@")

    if [[ ${#services_to_test[@]} -eq 0 ]]; then
        # Default test order: dependencies first
        services_to_test=("vault" "postgres" "redis" "vault-agent" "nginx" "keycloak")
    fi

    log_action "INFO" "Starting independent test suite for services: ${services_to_test[*]}"

    local failed_services=()
    local passed_services=()

    for service in "${services_to_test[@]}"; do
        log_action "INFO" "=== Independent Test: $service ==="

        if test_service_independently "$service"; then
            passed_services+=("$service")
            log_action "SUCCESS" "✅ $service passed independent testing"
        else
            failed_services+=("$service")
            log_action "ERROR" "❌ $service failed independent testing"
        fi

        # Brief pause between tests
        sleep 5

        log_action "INFO" "=== End Independent Test: $service ==="
        echo ""
    done

    # Summary
    log_action "INFO" "Independent Test Suite Summary:"
    log_action "INFO" "Passed services (${#passed_services[@]}): ${passed_services[*]}"

    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log_action "ERROR" "Failed services (${#failed_services[@]}): ${failed_services[*]}"
        return 1
    else
        log_action "SUCCESS" "All services passed independent testing!"
        return 0
    fi
}

# Function to test service with specific dependency only
test_service_with_single_dependency() {
    local service=$1
    local dependency=$2

    log_action "INFO" "Testing $service with only $dependency dependency"

    # Stop all services first
    docker stop $(docker ps -q --filter "name=purebliss-") 2>/dev/null || true

    # Start only the dependency
    log_action "INFO" "Starting dependency: $dependency"
    docker start "purebliss-$dependency"
    wait_for_service_health "$dependency" 60

    # Start the service
    log_action "INFO" "Starting service: $service"
    docker start "purebliss-$service" 2>/dev/null || {
        log_action "WARNING" "Using compose to start $service"
        case $service in
            "keycloak")
                cd /opt/dev-purebliss/services/keycloak
                docker-compose -f docker-compose.fixed.yml up -d
                ;;
        esac
    }

    # Test the service
    if wait_for_service_health "$service" 120; then
        log_action "SUCCESS" "$service works with $dependency only"

        # Run health validation
        if /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$service" "dependency-test-$dependency"; then
            log_action "SUCCESS" "$service passed health validation with $dependency"
            return 0
        else
            log_action "ERROR" "$service failed health validation with $dependency"
            return 1
        fi
    else
        log_action "ERROR" "$service failed to start with $dependency"
        return 1
    fi
}

# Main execution function
main() {
    local command=${1:-"suite"}
    local service=${2:-""}
    local dependency=${3:-""}

    log_action "INFO" "Starting Independent Service Testing Framework"

    case $command in
        "test")
            if [[ -z "$service" ]]; then
                echo "Usage: $0 test <service>"
                exit 1
            fi
            test_service_independently "$service"
            ;;
        "with-dep")
            if [[ -z "$service" || -z "$dependency" ]]; then
                echo "Usage: $0 with-dep <service> <dependency>"
                exit 1
            fi
            test_service_with_single_dependency "$service" "$dependency"
            ;;
        "suite")
            shift
            run_independent_test_suite "$@"
            ;;
        "keycloak-postgres-only")
            log_action "INFO" "Testing Keycloak with PostgreSQL only (no Redis)"
            test_service_with_single_dependency "keycloak" "postgres"
            ;;
        *)
            echo "Usage: $0 [test <service>|with-dep <service> <dependency>|suite [services...]|keycloak-postgres-only]"
            echo ""
            echo "Examples:"
            echo "  $0 test keycloak                    # Test keycloak independently"
            echo "  $0 with-dep keycloak postgres       # Test keycloak with only postgres"
            echo "  $0 suite                            # Run full independent test suite"
            echo "  $0 keycloak-postgres-only           # Test keycloak with postgres only"
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
