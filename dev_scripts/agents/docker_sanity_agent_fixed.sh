#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
export DOCKER_API_VERSION="1.41"

# --- EARLY EXIT FOR QUICK HEALTH SUMMARY MODE ---
if [[ "${1:-}" == "quick_health_summary" ]]; then
    echo "\n==== DOCKER QUICK HEALTH SUMMARY ====\n"
    printf "%-30s | %-10s | %-15s\n" "CONTAINER" "STATE" "HEALTH"
    printf '%s\n' "$(printf '=%.0s' {1..60})"
    docker ps --format '{{.Names}}' | while read -r name; do
        state=$(docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null || echo "unknown")
        health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$name" 2>/dev/null || echo "unknown")
        printf "%-30s | %-10s | %-15s\n" "$name" "$state" "$health"
    done
    echo "====================================\n"
    exit 0
fi

# List of expected services in our Pure Bliss stack
EXPECTED_SERVICES=("vault" "vault-agent" "postgres" "keycloak" "nginx" "plane" "redis" "grafana" "loki" "prometheus" "codeserver" "vikunja")

# Service-specific health check timeouts (in seconds)
declare -A HEALTH_TIMEOUTS=(
    ["vault"]="30"
    ["vault-agent"]="20"
    ["postgres"]="25"
    ["keycloak"]="45"
    ["nginx"]="15"
    ["plane"]="40"
    ["redis"]="10"
    ["grafana"]="30"
    ["loki"]="25"
    ["prometheus"]="30"
    ["codeserver"]="35"
    ["vikunja"]="30"
)

# Service-specific restart strategies
declare -A RESTART_STRATEGIES=(
    ["vault"]="graceful"
    ["vault-agent"]="immediate"
    ["postgres"]="graceful"
    ["keycloak"]="immediate"
    ["nginx"]="reload"
    ["plane"]="immediate"
    ["redis"]="graceful"
    ["grafana"]="immediate"
    ["loki"]="immediate"
    ["prometheus"]="graceful"
    ["codeserver"]="immediate"
    ["vikunja"]="immediate"
)

# Maximum retry attempts for container operations
MAX_RETRIES=3
RETRY_DELAY=5
MAX_EXECUTION_TIME=1800  # 30 minutes maximum execution time

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if Docker daemon is running
check_docker_daemon() {
    log "INFO: Checking Docker daemon status..."

    if ! docker info > /dev/null 2>&1; then
        log "CRITICAL: Docker daemon is not running or accessible. Cannot proceed."
        return 1
    fi

    log "SUCCESS: Docker daemon is running."
    return 0
}

# Function to discover all running containers
discover_containers() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -v '^$' || true
}

# Function to get container name (simplified since we're already getting container names)
get_container_name() {
    local service="$1"
    echo "$service"
}

# Function to check container existence
check_container_exists() {
    local container="$1"

    if [[ -z "$container" ]]; then
        return 1
    fi

    if docker ps -a -q -f name="$container" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check if container is running
check_container_running() {
    local container="$1"

    if docker ps -q -f name="$container" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to get container health status
get_container_health() {
    local container="$1"

    local health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container" 2>/dev/null || echo "unknown")
    echo "$health_status"
}

# Function to get container state
get_container_state() {
    local container="$1"

    local state=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
    echo "$state"
}

# Function to get container restart count
get_restart_count() {
    local container="$1"

    local restart_count=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null || echo "0")
    echo "$restart_count"
}

# Function to check service-specific health endpoints
check_service_endpoint() {
    local service="$1"
    local container="$2"

    # Extract base service name (remove purebliss- prefix if present)
    local base_service="$service"
    if [[ "$service" =~ ^purebliss- ]]; then
        base_service="${service#purebliss-}"
    fi

    case "$base_service" in
        "nginx")
            if curl -s -f -k https://dev.purebliss.app/nginx_status > /dev/null 2>&1; then
                return 0
            elif curl -s -f http://localhost:80 > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "keycloak")
            if curl -s -f http://dev.purebliss.app:8080/health > /dev/null 2>&1; then
                return 0
            elif curl -s -f http://dev.purebliss.app:8080/auth > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "grafana")
            if curl -s -f http://dev.purebliss.app:3001/api/health > /dev/null 2>&1; then
                return 0
            elif curl -s -f http://dev.purebliss.app:3001/login > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "prometheus")
            if curl -s -f http://dev.purebliss.app:9090/-/healthy > /dev/null 2>&1; then
                return 0
            elif curl -s -f http://dev.purebliss.app:9090/graph > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "loki")
            if curl -s -f http://dev.purebliss.app:3100/ready > /dev/null 2>&1; then
                return 0
            elif curl -s -f http://dev.purebliss.app:3100/metrics > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "vault")
            # Try vault status command first
            if docker exec "$container" vault status > /dev/null 2>&1; then
                return 0
            # Fallback to HTTP health check
            elif curl -s -f http://dev.purebliss.app:18200/v1/sys/health > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "postgres"|"postgresql")
            if docker exec "$container" pg_isready -U postgres > /dev/null 2>&1; then
                return 0
            # Try alternative postgres user
            elif docker exec "$container" pg_isready -U vikunja > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "redis")
            if docker exec "$container" redis-cli ping > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "plane")
            if curl -s -f http://dev.purebliss.app:3001/api/health > /dev/null 2>&1; then
                return 0
            elif curl -s -f http://dev.purebliss.app/plane > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "vikunja")
            if curl -s -f http://dev.purebliss.app/api/v1/info > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        "codeserver")
            if curl -s -f https://dev.purebliss.app/code-server > /dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            # For unknown services, if container is running, assume it's healthy
            if check_container_running "$container"; then
                log "DEBUG: Unknown service $service - assuming healthy if container is running"
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Function to perform aggressive container fixing
fix_container_aggressively() {
    local container="$1"
    local max_attempts=15
    local attempt=1

    log "🔧 AGGRESSIVE FIX MODE for $container (up to $max_attempts attempts)"

    while [[ $attempt -le $max_attempts ]]; do
        log "[ATTEMPT $attempt/$max_attempts] Analyzing and fixing $container..."

        # Get current status
        local state=$(get_container_state "$container" 2>/dev/null || echo "unknown")
        local health=$(get_container_health "$container" 2>/dev/null || echo "unknown")

        log "[DEBUG] Current - State: $state, Health: $health"

        # Apply escalating fixes based on attempt number and current state
        if [[ $attempt -le 3 ]]; then
            # First 3 attempts: gentle fixes
            if [[ "$state" != "running" ]]; then
                log "[FIX] Starting stopped container..."
                docker start "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 10
            elif [[ "$health" == "unhealthy" || "$health" == "starting" ]]; then
                log "[FIX] Waiting for health check to stabilize..."
                sleep 20
            else
                log "[FIX] Light restart..."
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
            fi
        elif [[ $attempt -le 8 ]]; then
            # Attempts 4-8: more aggressive fixes
            log "[FIX] Performing container restart..."
            docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
            sleep 20

            # Check logs for issues
            log "[DEBUG] Checking recent logs for errors..."
            docker logs "$container" --tail 30 2>&1 | grep -i "error\|fail\|exception" | head -5 | tee -a "$LOG_FILE" || true
        else
            # Attempts 9+: nuclear option - stop and start fresh
            log "[FIX] Nuclear option - stop and start fresh..."
            docker stop "$container" --time=30 2>&1 | tee -a "$LOG_FILE" || true
            sleep 10
            docker start "$container" 2>&1 | tee -a "$LOG_FILE"
            sleep 30
        fi

        # Wait for stabilization
        log "[INFO] Waiting for container stabilization (45 seconds)..."
        sleep 45

        # Check if fix worked
        local new_state=$(get_container_state "$container" 2>/dev/null || echo "unknown")
        local new_health=$(get_container_health "$container" 2>/dev/null || echo "unknown")

        log "[DEBUG] After fix - State: $new_state, Health: $new_health"

        # Test comprehensive health
        if [[ "$new_state" == "running" ]]; then
            if [[ "$new_health" == "healthy" || "$new_health" == "no_healthcheck" ]]; then
                # Also test endpoint if possible
                if check_service_endpoint "$container" "$container"; then
                    log "✅ CONTAINER $container FULLY FIXED! (attempt $attempt)"
                    return 0
                else
                    log "[PARTIAL] Container running and healthy but endpoint not responding..."
                fi
            else
                log "[PARTIAL] Container running but health check failed: $new_health"
            fi
        else
            log "[FAILED] Container still not running: $new_state"
        fi

        attempt=$((attempt + 1))

        if [[ $attempt -le $max_attempts ]]; then
            log "[INFO] Fix attempt $((attempt-1)) failed, retrying in 20 seconds..."
            sleep 20
        fi
    done

    log "💥 FAILED to fix $container after $max_attempts aggressive attempts"
    return 1
}

# Function to perform comprehensive container health check
check_container_health() {
    local service="$1"
    local container=$(get_container_name "$service")

    log "======================================================"
    log "🔍 HEALTH CHECK FOR: $service ($container)"
    log "======================================================"

    # Step 1: Container existence check
    if ! check_container_exists "$container"; then
        log "❌ CRITICAL: Container $container does not exist"
        return 1
    fi

    # Step 2: Check if running
    if ! check_container_running "$container"; then
        log "⚠️  Container $container is not running"
        return 1
    fi

    # Step 3: Health status
    local health=$(get_container_health "$container")
    if [[ "$health" == "unhealthy" ]]; then
        log "⚠️  Container $container is unhealthy"
        return 1
    elif [[ "$health" == "starting" ]]; then
        log "⏳ Container $container is still starting"
        return 1
    fi

    # Step 4: Service endpoint check
    if ! check_service_endpoint "$service" "$container"; then
        log "⚠️  Service endpoint for $service not responding"
        return 1
    fi

    log "✅ Container $container is 100% operational!"
    return 0
}

# Main execution
main() {
    local target_service="${1:-}"

    log "INFO: Starting AGGRESSIVE Docker Container Sanity Check Agent..."
    log "INFO: This script will fix ALL issues before proceeding - NO SKIPPING!"

    # Pre-flight check: Ensure Docker daemon is running
    if ! check_docker_daemon; then
        log "CRITICAL: Cannot proceed without Docker daemon. Exiting."
        exit 1
    fi

    # Discover all containers
    local discovered_containers=($(discover_containers))

    if [[ ${#discovered_containers[@]} -eq 0 ]]; then
        log "WARNING: No containers discovered. Nothing to check."
        exit 0
    fi

    log "INFO: Discovered ${#discovered_containers[@]} containers: ${discovered_containers[*]}"

    # If specific service requested, fix only that one
    if [[ -n "$target_service" ]]; then
        log "INFO: Fixing specific service: $target_service"
        if [[ " ${discovered_containers[*]} " =~ " ${target_service} " ]]; then
            if check_container_health "$target_service"; then
                log "SUCCESS: Service $target_service is already 100% operational!"
                exit 0
            else
                log "INFO: Service $target_service needs fixing..."
                if fix_container_aggressively "$target_service"; then
                    log "SUCCESS: Service $target_service is now 100% operational!"
                    exit 0
                else
                    log "FAILED: Could not fix service $target_service"
                    exit 1
                fi
            fi
        else
            log "ERROR: Service $target_service not found"
            exit 1
        fi
    fi

    log "INFO: Starting container-by-container fixing process..."
    log "INFO: Each container MUST be 100% operational before moving to the next"

    local failed_containers=()
    local fixed_containers=()
    local already_healthy=()

    # Process each container - FIX EVERYTHING
    for container in "${discovered_containers[@]}"; do
        log ""
        log "🎯 PROCESSING CONTAINER: $container"
        log "======================================================"

        # First check if it's already healthy
        if check_container_health "$container"; then
            log "✅ Container $container is already 100% operational!"
            already_healthy+=("$container")
        else
            log "⚠️  Container $container needs fixing..."

            # AGGRESSIVE FIXING - NO GIVING UP
            if fix_container_aggressively "$container"; then
                log "✅ Container $container has been FIXED and is now 100% operational!"
                fixed_containers+=("$container")
            else
                log "💥 CRITICAL: Failed to fix container $container"
                failed_containers+=("$container")

                # Provide comprehensive diagnostics
                log ""
                log "🚨 EMERGENCY DIAGNOSTICS FOR $container:"
                log "========================================"
                log "Final state: $(get_container_state "$container" 2>/dev/null || echo "unknown")"
                log "Final health: $(get_container_health "$container" 2>/dev/null || echo "unknown")"
                log "Restart count: $(get_restart_count "$container" 2>/dev/null || echo "unknown")"
                log ""
                log "Last 50 log lines:"
                docker logs "$container" --tail 50 2>&1 | tee -a "$LOG_FILE"
                log ""
                log "Container details:"
                docker inspect "$container" --format='{{json .State}}' 2>&1 | tee -a "$LOG_FILE"

                log ""
                log "🛑 STOPPING HERE - Manual intervention required for $container"
                log "The environment cannot be considered operational until $container is fixed."
                break
            fi
        fi
    done

    # Final summary
    log ""
    log "🏁 FINAL ENVIRONMENT STATUS:"
    log "============================"
    log "Total containers: ${#discovered_containers[@]}"
    log "Already healthy: ${#already_healthy[@]} (${already_healthy[*]})"
    log "Successfully fixed: ${#fixed_containers[@]} (${fixed_containers[*]})"
    log "Failed to fix: ${#failed_containers[@]} (${failed_containers[*]})"

    if [[ ${#failed_containers[@]} -gt 0 ]]; then
        log ""
        log "❌ ENVIRONMENT NOT OPERATIONAL"
        log "Failed containers: ${failed_containers[*]}"
        log "Manual intervention required before environment can be used."
        exit 1
    else
        log ""
        log "🎉 SUCCESS! ALL CONTAINERS ARE 100% OPERATIONAL!"
        log "✅ Your Pure Bliss development environment is ready to use!"

        # Final verification by running quick health summary
        log ""
        log "Final verification:"
        "$0" quick_health_summary

        exit 0
    fi
}

# Only call main if not sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
