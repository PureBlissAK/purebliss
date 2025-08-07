#!/bin/bash

# Independent Service Testing Framework
# Ensures each service is tested in complete isolation for accurate health validation
# Date: 2025-08-06
# Purpose: Test services independently without interference from other running services

set -euo pipefail

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
    if /opt/dev-purebliss/validate-container-health.sh "$service" "independent-test"; then
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
        if /opt/dev-purebliss/validate-container-health.sh "$service" "dependency-test-$dependency"; then
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
