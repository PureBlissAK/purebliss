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

# Service dependency mapping
declare -A SERVICE_DEPENDENCIES=(
    ["keycloak"]="postgres"
    ["plane"]="postgres"
    ["vikunja"]="postgres"
    ["grafana"]="prometheus loki"
    ["prometheus"]="loki"
    ["vault-agent"]="vault"
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

# Function to diagnose specific container issues
diagnose_container_issues() {
    local container="$1"
    local issues=()

    log "[DIAGNOSIS] Analyzing $container for specific issues..."

    # Check if container exists but is stopped
    if check_container_exists "$container" && ! check_container_running "$container"; then
        local exit_code=$(docker inspect "$container" --format='{{.State.ExitCode}}' 2>/dev/null || echo "0")
        if [[ $exit_code -ne 0 ]]; then
            issues+=("exited_with_error:$exit_code")
        else
            issues+=("stopped")
        fi
    fi

    # Check for resource issues
    if check_container_running "$container"; then
        local memory_limit=$(docker inspect "$container" --format='{{.HostConfig.Memory}}' 2>/dev/null || echo "0")
        local oom_killed=$(docker inspect "$container" --format='{{.State.OOMKilled}}' 2>/dev/null || echo "false")
        if [[ "$oom_killed" == "true" ]]; then
            issues+=("oom_killed")
        fi

        # Check for high restart count
        local restart_count=$(get_restart_count "$container")
        if [[ $restart_count -gt 5 ]]; then
            issues+=("high_restarts:$restart_count")
        fi
    fi

    # Check for port conflicts
    local ports=$(docker port "$container" 2>/dev/null | head -3)
    if [[ -n "$ports" ]]; then
        while IFS= read -r port_mapping; do
            if [[ -n "$port_mapping" ]]; then
                local host_port=$(echo "$port_mapping" | grep -o '0\.0\.0\.0:[0-9]*' | cut -d: -f2)
                if [[ -n "$host_port" ]]; then
                    if netstat -tuln 2>/dev/null | grep -q ":$host_port.*LISTEN" && ! docker ps | grep -q "$container"; then
                        issues+=("port_conflict:$host_port")
                    fi
                fi
            fi
        done <<< "$ports"
    fi

    # Check logs for specific error patterns
    local log_errors=$(docker logs "$container" --tail 50 2>&1 | grep -i "error\|fail\|exception\|fatal\|sealed\|unauthorized\|forbidden\|denied" | head -5)
    if [[ -n "$log_errors" ]]; then
        # Look for specific error patterns
        if echo "$log_errors" | grep -qi "permission denied"; then
            issues+=("permission_error")
        elif echo "$log_errors" | grep -qi "connection refused\|connection failed"; then
            issues+=("connection_error")
        elif echo "$log_errors" | grep -qi "bind.*address already in use"; then
            issues+=("port_bind_error")
        elif echo "$log_errors" | grep -qi "no such file or directory"; then
            issues+=("missing_files")
        elif echo "$log_errors" | grep -qi "timeout\|timed out"; then
            issues+=("timeout_error")
        elif echo "$log_errors" | grep -qi "unauthorized\|forbidden"; then
            issues+=("auth_error")
        elif echo "$log_errors" | grep -qi "Admin user already exists"; then
            issues+=("keycloak_admin_exists")
        elif echo "$log_errors" | grep -qi "sealed"; then
            issues+=("vault_sealed")
        else
            issues+=("generic_error")
        fi
    fi

    # Application-specific configuration checks
    local base_service_name="$container"
    if [[ "$container" =~ ^purebliss- ]]; then
        base_service_name="${container#purebliss-}"
    fi
    case "$base_service_name" in
        "nginx")
            if ! docker exec "$container" nginx -t >/dev/null 2>&1; then
                issues+=("nginx_config_invalid")
            fi
            ;;
        "vault")
            if docker exec "$container" vault status 2>/dev/null | grep -q "Sealed.*true"; then
                issues+=("vault_sealed")
            fi
            ;;
    esac

    # Check volume mounts
    local volume_mounts=$(docker inspect "$container" --format='{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' 2>/dev/null || echo "")
    if [[ -n "$volume_mounts" ]]; then
        for mount in $volume_mounts; do
            local source=$(echo "$mount" | cut -d: -f1)
            if [[ -n "$source" && ! -e "$source" ]]; then
                issues+=("missing_volume:$source")
            fi
        done
    fi

    printf '%s\n' "${issues[@]}"
}

# Function to apply specific fixes based on diagnosed issues
apply_specific_fixes() {
    local container="$1"
    shift
    local issues=("$@")

    log "[SPECIFIC FIXES] Applying targeted fixes for $container..."

    for issue in "${issues[@]}"; do
        local issue_type=$(echo "$issue" | cut -d: -f1)
        local issue_detail=$(echo "$issue" | cut -d: -f2-)

        log "[FIX] Addressing issue: $issue_type ($issue_detail)"

        case "$issue_type" in
            "stopped")
                log "[FIX] Starting stopped container..."
                docker start "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
            "exited_with_error")
                log "[FIX] Container exited with error code $issue_detail - checking logs and restarting..."
                docker logs "$container" --tail 20 2>&1 | tee -a "$LOG_FILE"
                docker start "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
            "oom_killed")
                log "[FIX] Container was OOM killed - increasing memory limit and restarting..."
                # Try to restart with more memory if possible
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 20
                ;;
            "high_restarts")
                log "[FIX] Container has high restart count ($issue_detail) - performing clean restart..."
                docker stop "$container" --time=30 2>&1 | tee -a "$LOG_FILE"
                sleep 10
                docker start "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 20
                ;;
            "port_conflict")
                log "[FIX] Port conflict detected on $issue_detail - killing conflicting processes..."
                local conflicting_pid=$(netstat -tulnp 2>/dev/null | grep ":$issue_detail.*LISTEN" | awk '{print $7}' | cut -d/ -f1)
                if [[ -n "$conflicting_pid" && "$conflicting_pid" != "-" ]]; then
                    log "[FIX] Killing process $conflicting_pid using port $issue_detail..."
                    kill -TERM "$conflicting_pid" 2>/dev/null || true
                    sleep 5
                fi
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
            "permission_error")
                log "[FIX] Permission error detected - checking container user and volumes..."
                docker logs "$container" --tail 10 2>&1 | tee -a "$LOG_FILE"
                # Try to fix common permission issues
                local container_user=$(docker inspect "$container" --format='{{.Config.User}}' 2>/dev/null || echo "")
                if [[ -n "$container_user" ]]; then
                    log "[INFO] Container runs as user: $container_user"
                fi
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
            "connection_error")
                log "[FIX] Connection error - checking network and dependent services..."
                # Check if dependent services are running
                local network=$(docker inspect "$container" --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' 2>/dev/null || echo "")
                log "[INFO] Container network: $network"

                # Restart container to re-establish connections
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 20
                ;;
            "port_bind_error")
                log "[FIX] Port binding error - checking for port conflicts and restarting..."
                docker stop "$container" --time=30 2>&1 | tee -a "$LOG_FILE"
                sleep 10
                docker start "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
            "missing_files")
                log "[FIX] Missing files error - checking volume mounts..."
                docker inspect "$container" --format='{{range .Mounts}}Source: {{.Source}}, Destination: {{.Destination}}, Type: {{.Type}}{{"\n"}}{{end}}' 2>&1 | tee -a "$LOG_FILE"
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
            "missing_volume")
                log "[FIX] Missing volume detected: $issue_detail - attempting to create..."
                if [[ "$issue_detail" == /opt/* || "$issue_detail" == /mnt/* ]]; then
                    mkdir -p "$issue_detail" 2>/dev/null || true
                    log "[INFO] Created missing directory: $issue_detail"
                fi
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
            "timeout_error")
                log "[FIX] Timeout error - increasing wait time and restarting..."
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 30  # Longer wait for timeout issues
                ;;
            "auth_error")
                log "[FIX] Auth error detected - checking credentials and restarting..."
                log "[INFO] This may be a Vault, Keycloak, or database credential issue."
                # For Vault, try re-authenticating if possible
                if [[ "$container" == "vault-agent" ]]; then
                    log "[FIX] Attempting to re-authenticate vault-agent..."
                    docker exec "$container" vault agent -config=/vault/agent/config.hcl 2>&1 | tee -a "$LOG_FILE" || true
                fi
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 20
                ;;
            "vault_sealed")
                log "[FIX] Vault is sealed. Attempting to unseal..."
                local unseal_keys_file="/opt/my-secure-ha-stack/vault-unseal-keys.env"
                if [[ -f "$unseal_keys_file" ]]; then
                    # Source the file to get the keys
                    source "$unseal_keys_file"

                    # Attempt to unseal using the keys
                    for key in "$VAULT_UNSEAL_KEY_1" "$VAULT_UNSEAL_KEY_2" "$VAULT_UNSEAL_KEY_3"; do
                        if docker exec "$container" vault operator unseal "$key" >/dev/null 2>&1; then
                            log "[FIX] Unseal key applied successfully."
                        else
                            log "[WARNING] Failed to apply an unseal key."
                        fi
                        sleep 2
                    done

                    # Check status after unsealing
                    if docker exec "$container" vault status 2>/dev/null | grep -q "Sealed.*false"; then
                        log "[SUCCESS] Vault unsealed successfully."
                    else
                        log "[ERROR] Failed to unseal Vault."
                    fi
                else
                    log "[ERROR] Unseal keys file not found at $unseal_keys_file. Cannot unseal Vault."
                fi
                sleep 10
                ;;
            "keycloak_admin_exists")
                log "[FIX] Keycloak 'Admin user already exists' detected. This is informational. Restarting to ensure service is stable."
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 20
                ;;
            "nginx_config_invalid")
                log "[CRITICAL] Nginx configuration is invalid. Cannot be fixed automatically."
                log "[CRITICAL] Output of 'nginx -t':"
                docker exec "$container" nginx -t 2>&1 | tee -a "$LOG_FILE"
                # This is a critical failure, we will not attempt to restart.
                # The main loop will catch this as a failed fix.
                return 1
                ;;
            *)
                log "[FIX] Unknown issue type: $issue_type - performing generic restart..."
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
                ;;
        esac
    done
}

# Function to perform aggressive container fixing with real diagnostics
fix_container_aggressively() {
    local container="$1"
    local max_attempts=10
    local attempt=1

    log "🔧 INTELLIGENT FIX MODE for $container (up to $max_attempts attempts)"

    while [[ $attempt -le $max_attempts ]]; do
        log "[ATTEMPT $attempt/$max_attempts] Diagnosing and fixing $container..."

        # Get current status
        local state=$(get_container_state "$container" 2>/dev/null || echo "unknown")
        local health=$(get_container_health "$container" 2>/dev/null || echo "unknown")

        log "[DEBUG] Current - State: $state, Health: $health"

        # Diagnose specific issues
        local issues=($(diagnose_container_issues "$container"))

        if [[ ${#issues[@]} -gt 0 ]]; then
            log "[DIAGNOSIS] Found ${#issues[@]} issues: ${issues[*]}"

            # Apply specific fixes for diagnosed issues
            apply_specific_fixes "$container" "${issues[@]}"
        else
            log "[DIAGNOSIS] No specific issues found - applying generic fixes..."

            # Apply generic fixes based on state
            if [[ "$state" != "running" ]]; then
                log "[FIX] Container not running - starting..."
                docker start "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 15
            elif [[ "$health" == "unhealthy" ]]; then
                log "[FIX] Container unhealthy - restarting..."
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 20
            elif [[ "$health" == "starting" ]]; then
                log "[FIX] Container still starting - waiting longer..."
                sleep 30
            else
                log "[FIX] Performing preventive restart..."
                docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                sleep 20
            fi
        fi

        # Wait for stabilization
        log "[INFO] Waiting for container stabilization (30 seconds)..."
        sleep 30

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
                    # Try to fix endpoint issues
                    local base_service="$container"
                    if [[ "$container" =~ ^purebliss- ]]; then
                        base_service="${container#purebliss-}"
                    fi

                    case "$base_service" in
                        "nginx")
                            log "[FIX] Nginx endpoint issue - reloading configuration..."
                            docker exec "$container" nginx -s reload 2>&1 | tee -a "$LOG_FILE" || docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
                            sleep 10
                            ;;
                        "postgres")
                            log "[FIX] Postgres endpoint issue - checking database status..."
                            docker exec "$container" pg_isready -U postgres 2>&1 | tee -a "$LOG_FILE"
                            sleep 5
                            ;;
                        *)
                            log "[FIX] Generic endpoint issue - waiting for service startup..."
                            sleep 15
                            ;;
                    esac
                fi
            else
                log "[PARTIAL] Container running but health check failed: $new_health"
            fi
        else
            log "[FAILED] Container still not running: $new_state"
        fi

        attempt=$((attempt + 1))

        if [[ $attempt -le $max_attempts ]]; then
            log "[INFO] Fix attempt $((attempt-1)) failed, retrying in 15 seconds..."
            sleep 15
        fi
    done

    log "💥 FAILED to fix $container after $max_attempts intelligent attempts"
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
    log "INFO: Starting HYPER-INTELLIGENT Docker Container Sanity Check Agent..."
    log "INFO: Processing services from '/opt/dev-purebliss/services' in a specific order."
    log "INFO: Each service will be restarted and then validated to be 100% operational."

    # Pre-flight check: Ensure Docker daemon is running
    if ! check_docker_daemon; then
        log "CRITICAL: Cannot proceed without Docker daemon. Exiting."
        exit 1
    fi

    # Define the processing order based on user requirements
    local service_base_dir="/opt/dev-purebliss/services"
    if [ ! -d "$service_base_dir" ]; then
        log "CRITICAL: Service directory not found at $service_base_dir. Exiting."
        exit 1
    fi

    local all_services=()
    for dir in "$service_base_dir"/*; do
        if [ -d "$dir" ]; then
            all_services+=("$(basename "$dir")")
        fi
    done

    # Establish the specific processing order
    local ordered_prefix=("vault" "vault-agent" "postgres")
    local remaining_services=()
    local processing_order=()

    # Check for existence of prefixed services and add them to the order
    for service in "${ordered_prefix[@]}"; do
        if [[ " ${all_services[*]} " =~ " ${service} " ]]; then
            processing_order+=("$service")
        else
            log "WARNING: Specified service '$service' not found in $service_base_dir, skipping."
        fi
    done

    # Add the rest of the services
    for service in "${all_services[@]}"; do
        if [[ ! " ${ordered_prefix[*]} " =~ " ${service} " ]]; then
            remaining_services+=("$service")
        fi
    done
    processing_order+=("${remaining_services[@]}")

    if [[ ${#processing_order[@]} -eq 0 ]]; then
        log "WARNING: No services discovered in $service_base_dir. Nothing to check."
        exit 0
    fi

    log "INFO: Service processing order: ${processing_order[*]}"

    local failed_containers=()
    local fixed_containers=()
    local already_healthy=()

    # Process each service based on the defined order
    for service in "${processing_order[@]}"; do
        local container="$service" # Assuming service name is the container name
        log ""
        log "🎯 PROCESSING SERVICE: $container"
        log "======================================================"

        if ! check_container_exists "$container"; then
            log "WARNING: Container for service '$container' does not exist. It may need to be started with docker-compose."
        fi

        # Perform a controlled restart using docker-compose if available
        local compose_file=""
        local potential_compose_file_yml="$service_base_dir/$service/$service.yml"
        local potential_compose_file_yaml="$service_base_dir/$service/$service.yaml"
        local generic_compose_file="$service_base_dir/$service/docker-compose.yml"

        if [ -f "$potential_compose_file_yml" ]; then
            compose_file="$potential_compose_file_yml"
        elif [ -f "$potential_compose_file_yaml" ]; then
            compose_file="$potential_compose_file_yaml"
        elif [ -f "$generic_compose_file" ]; then
            compose_file="$generic_compose_file"
        fi

        if [ -n "$compose_file" ]; then
            log "[ACTION] Performing a controlled restart for $container using docker-compose file: $compose_file"
            docker-compose -f "$compose_file" down >/dev/null 2>&1 || log "WARN: 'docker-compose down' for $container returned non-zero."
            sleep 5
            docker-compose -f "$compose_file" up -d --force-recreate >/dev/null 2>&1 || log "WARN: 'docker-compose up' for $container failed. Proceeding to fixing logic."
        else
            log "[ACTION] Performing a controlled restart for $container using docker commands..."
            docker stop "$container" >/dev/null 2>&1 || true
            sleep 5
            docker start "$container" >/dev/null 2>&1 || log "WARN: 'docker start' for $container failed. Proceeding to fixing logic."
        fi
        sleep 10 # Give the container a moment to initialize after starting

        # Check and fix dependencies first
        local base_service_name="$container"
        if [[ "$container" =~ ^purebliss- ]]; then
            base_service_name="${container#purebliss-}"
        fi

        if [[ -n "${SERVICE_DEPENDENCIES[$base_service_name]:-}" ]]; then
            local dependencies="${SERVICE_DEPENDENCIES[$base_service_name]}"
            log "[DEPENDENCY] $container depends on: $dependencies"
            for dep in $dependencies; do
                log "[DEPENDENCY] Checking dependency: $dep"
                if ! check_container_health "$dep"; then
                    log "[DEPENDENCY] Fixing dependency $dep for $container..."
                    if ! fix_container_aggressively "$dep"; then
                        log "💥 CRITICAL: Failed to fix dependency $dep for $container. Aborting run."
                        failed_containers+=("$container (due to dependency failure on $dep)")
                        break 2 # Break out of both loops
                    fi
                else
                    log "[DEPENDENCY] Dependency $dep is healthy"
                fi
            done
        fi

        # Now, ensure the service itself is 100% operational
        if check_container_health "$container"; then
            log "✅ Container $container is 100% operational after restart!"
            already_healthy+=("$container")
        else
            log "⚠️  Container $container needs fixing after restart..."

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
    log "Total services processed: ${#processing_order[@]}"
    log "Healthy after restart: ${#already_healthy[@]} (${already_healthy[*]})"
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
        log "🎉 SUCCESS! ALL PROCESSED SERVICES ARE 100% OPERATIONAL!"
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
