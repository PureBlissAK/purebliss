#!/bin/bash
set -euo pipefail

# Docker Container Sanity Check Agent v2
# Simplified version focused on methodical one-by-one container checking

# Global variables
readonly LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
readonly TIMEOUT_GENERAL=30

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Container health endpoints mapping
declare -A HEALTH_ENDPOINTS=(
    ["codeserver"]="https://dev.purebliss.app/code-server"
    ["keycloak"]="https://dev.purebliss.app/keycloak"
    ["nginx"]="https://dev.purebliss.app"
    ["grafana"]="http://dev.purebliss.app:3001/api/health"
    ["prometheus"]="http://dev.purebliss.app:9090/-/healthy"
    ["loki"]="http://dev.purebliss.app:3100/ready"
    ["vault"]="https://dev.purebliss.app/vault/v1/sys/health"
    ["postgres"]="internal"
    ["redis"]="internal"
    ["vault-agent"]="internal"
    ["vikunja"]="https://dev.purebliss.app/vikunja"
    ["website"]="https://dev.purebliss.app/website"
    ["letsencrypt"]="internal"
)

# Check if container exists and is running
check_container_exists() {
    local container_name="$1"
    if ! docker ps -q -f name="^${container_name}$" | grep -q .; then
        log "❌ Container $container_name not found or not running"
        return 1
    fi
    return 0
}

# Get container basic info
get_container_info() {
    local container_name="$1"
    local state status health uptime restarts

    state=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
    status=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null || echo "false")

    # Try to get health status
    health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container_name" 2>/dev/null || echo "no_healthcheck")

    # Get uptime
    local start_time=$(docker inspect --format='{{.State.StartedAt}}' "$container_name" 2>/dev/null || echo "")
    if [[ -n "$start_time" ]]; then
        uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container_name" | xargs -I {} date -d {} +%s 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local uptime_seconds=$((current_time - uptime))
        if [[ $uptime_seconds -gt 3600 ]]; then
            uptime="$((uptime_seconds / 3600))h"
        elif [[ $uptime_seconds -gt 60 ]]; then
            uptime="$((uptime_seconds / 60))m"
        else
            uptime="${uptime_seconds}s"
        fi
    else
        uptime="unknown"
    fi

    # Get restart count
    restarts=$(docker inspect --format='{{.RestartCount}}' "$container_name" 2>/dev/null || echo "0")

    printf "State: %s | Running: %s | Health: %s | Uptime: %s | Restarts: %s\n" \
        "$state" "$status" "$health" "$uptime" "$restarts"
}

# Test endpoint connectivity
test_endpoint() {
    local service="$1"
    local endpoint="${HEALTH_ENDPOINTS[$service]:-}"

    if [[ "$endpoint" == "internal" ]]; then
        log "  ✓ $service: Internal service, assuming healthy if container is running"
        return 0
    elif [[ -n "$endpoint" ]]; then
        log "  🔍 Testing endpoint: $endpoint"
        if timeout 10 curl -sf "$endpoint" >/dev/null 2>&1; then
            log "  ✅ Endpoint responding correctly"
            return 0
        else
            log "  ❌ Endpoint not responding or unhealthy"
            return 1
        fi
    else
        log "  ⚠️ No endpoint configured for $service"
        return 0
    fi
}

# Comprehensive container check
check_container_health() {
    local container_name="$1"
    local service_name="${container_name#purebliss-}"
    local issues=()

    log "🔍 CHECKING: $container_name ($service_name)"
    log "================================================"

    # Step 1: Basic container existence and state
    log "STEP 1: Container existence and state..."
    if ! check_container_exists "$container_name"; then
        log "❌ CRITICAL: Container $container_name does not exist or is not running"
        return 1
    fi

    local container_info
    container_info=$(get_container_info "$container_name")
    log "  $container_info"

    # Step 2: Check if container is actually running
    log "STEP 2: Verifying container is running..."
    local is_running
    is_running=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null || echo "false")
    if [[ "$is_running" != "true" ]]; then
        log "❌ Container $container_name is not running (state: $is_running)"
        issues+=("not_running")
    else
        log "  ✅ Container is running"
    fi

    # Step 3: Check health status if available
    log "STEP 3: Health check status..."
    local health_status
    health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container_name" 2>/dev/null || echo "no_healthcheck")

    if [[ "$health_status" == "unhealthy" ]]; then
        log "❌ Container health check is failing"
        issues+=("unhealthy")
    elif [[ "$health_status" == "starting" ]]; then
        log "⏳ Container is still starting up"
        issues+=("starting")
    elif [[ "$health_status" == "healthy" ]]; then
        log "  ✅ Container health check is passing"
    else
        log "  ℹ️ No health check configured"
    fi

    # Step 4: Test service endpoint if configured
    log "STEP 4: Service endpoint testing..."
    if ! test_endpoint "$service_name"; then
        issues+=("endpoint_failed")
    fi

    # Step 5: Check for excessive restarts
    log "STEP 5: Restart count check..."
    local restart_count
    restart_count=$(docker inspect --format='{{.RestartCount}}' "$container_name" 2>/dev/null || echo "0")
    if [[ "$restart_count" -gt 5 ]]; then
        log "⚠️ High restart count: $restart_count"
        issues+=("high_restarts")
    else
        log "  ✅ Restart count is acceptable: $restart_count"
    fi

    # Summary
    if [[ ${#issues[@]} -eq 0 ]]; then
        log "✅ $container_name is 100% OPERATIONAL"
        return 0
    else
        log "❌ $container_name has issues: ${issues[*]}"
        return 1
    fi
}

# Fix container issues
fix_container() {
    local container_name="$1"
    local service_name="${container_name#purebliss-}"

    log "🛠️ ATTEMPTING TO FIX: $container_name"

    # Try restarting the container
    log "Restarting container..."
    if docker restart "$container_name" >/dev/null 2>&1; then
        log "Container restarted successfully"

        # Wait for container to start
        log "Waiting 30 seconds for container to stabilize..."
        sleep 30

        # Re-check health
        if check_container_health "$container_name"; then
            log "✅ Container $container_name is now operational after restart"
            return 0
        else
            log "❌ Container $container_name still has issues after restart"
            return 1
        fi
    else
        log "❌ Failed to restart container $container_name"
        return 1
    fi
}

# Main execution
main() {
    log "INFO: Starting Docker Container Sanity Check Agent v2..."
    log "INFO: Methodical one-by-one container verification starting..."

    # Discover all purebliss containers
    log "INFO: Discovering purebliss containers..."
    local containers
    containers=$(docker ps -a --format "{{.Names}}" --filter "name=purebliss-" | sort)

    if [[ -z "$containers" ]]; then
        log "ERROR: No purebliss containers found"
        exit 1
    fi

    local container_count
    container_count=$(echo "$containers" | wc -l)
    log "INFO: Found $container_count purebliss containers to check"

    # List all containers that will be checked
    log "INFO: Containers to be checked:"
    local counter=1
    while IFS= read -r container; do
        log "  $counter. $container"
        ((counter++))
    done <<< "$containers"

    echo
    log "🚀 Beginning systematic health checks..."
    log "Will check each container thoroughly before moving to the next"
    echo

    # Check each container one by one
    local failed_containers=()
    local success_count=0
    counter=1

    while IFS= read -r container; do
        echo
        log "🚀 CHECKING CONTAINER $counter OF $container_count: $container"
        log "Press Ctrl+C to stop, or continuing in 3 seconds..."
        sleep 3

        echo
        log "======================================================"
        log "🔍 DETAILED ANALYSIS FOR CONTAINER: $container"
        log "======================================================"

        if check_container_health "$container"; then
            log "✅ $container - PASSED ALL CHECKS"
            ((success_count++))
        else
            log "❌ $container - FAILED HEALTH CHECKS"
            log "🛠️ Attempting automatic fix..."

            if fix_container "$container"; then
                log "✅ $container - FIXED AND NOW OPERATIONAL"
                ((success_count++))
            else
                log "❌ $container - COULD NOT BE FIXED AUTOMATICALLY"
                failed_containers+=("$container")

                log "🛑 STOPPING FOR MANUAL INTERVENTION"
                log "Container $container requires manual attention before proceeding"
                break
            fi
        fi

        echo
        log "Status: $success_count/$counter containers verified as operational"
        ((counter++))

        if [[ $counter -le $container_count ]]; then
            log "Moving to next container in 5 seconds..."
            sleep 5
        fi

    done <<< "$containers"

    echo
    log "==============================================="
    log "DOCKER SANITY CHECK - FINAL SUMMARY"
    log "==============================================="
    log "Total containers checked: $((counter - 1))"
    log "Operational containers: $success_count"
    log "Failed containers: ${#failed_containers[@]}"

    if [[ ${#failed_containers[@]} -eq 0 ]]; then
        log "🎉 ALL CONTAINERS ARE 100% OPERATIONAL!"
        exit 0
    else
        log "❌ Failed containers requiring manual intervention:"
        for failed in "${failed_containers[@]}"; do
            log "  - $failed"
        done
        exit 1
    fi
}

# Run main function
main "$@"
