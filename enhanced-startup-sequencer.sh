#!/bin/bash

# Enhanced Container Startup Sequencer
# Addresses dependency timing issues found in logs

set -euo pipefail

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
