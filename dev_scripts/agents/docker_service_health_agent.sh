#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
export DOCKER_API_VERSION="1.41"

# --- EARLY EXIT FOR QUICK HEALTH SUMMARY MODE ---
if [[ "${1:-}" == "quick_health_summary" ]]; then
    echo -e "\n==== DOCKER QUICK HEALTH SUMMARY ====\n"
    printf "%-30s | %-10s | %-15s\n" "CONTAINER" "STATE" "HEALTH"
    printf '%s\n' "$(printf '=%.0s' {1..60})"
    docker ps --format '{{.Names}}' | while read -r name; do
        state=$(docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null || echo "unknown")
        health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$name" 2>/dev/null || echo "unknown")
        printf "%-30s | %-10s | %-15s\n" "$name" "$state" "$health"
    done
    echo -e "====================================\n"
    exit 0
fi

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

# Function to check container existence
check_container_exists() {
    local container="$1"
    [[ -n "$container" ]] && docker ps -a -q -f name="^${container}$" | grep -q .
}

# Function to check if container is running
check_container_running() {
    local container="$1"
    [[ -n "$container" ]] && docker ps -q -f name="^${container}$" | grep -q .
}

# Function to get container health status
get_container_health() {
    local container="$1"
    docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container" 2>/dev/null || echo "unknown"
}

# Function to get container state
get_container_state() {
    local container="$1"
    docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown"
}

# Function to get container restart count
get_restart_count() {
    local container="$1"
    docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null || echo "0"
}

# Function to check service-specific health endpoints
check_service_endpoint() {
    local service="$1"
    local container="$2"
    local base_service="${service#purebliss-}"

    case "$base_service" in
        "nginx") curl -s -f -k https://dev.purebliss.app/nginx_status > /dev/null 2>&1 || curl -s -f http://localhost:80 > /dev/null 2>&1 ;;
        "keycloak") curl -s -f http://dev.purebliss.app:8080/health > /dev/null 2>&1 || curl -s -f http://dev.purebliss.app:8080/auth > /dev/null 2>&1 ;;
        "grafana") curl -s -f http://dev.purebliss.app:3001/api/health > /dev/null 2>&1 || curl -s -f http://dev.purebliss.app:3001/login > /dev/null 2>&1 ;;
        "prometheus") curl -s -f http://dev.purebliss.app:9090/-/healthy > /dev/null 2>&1 || curl -s -f http://dev.purebliss.app:9090/graph > /dev/null 2>&1 ;;
        "loki") curl -s -f http://dev.purebliss.app:3100/ready > /dev/null 2>&1 || curl -s -f http://dev.purebliss.app:3100/metrics > /dev/null 2>&1 ;;
        "vault") docker exec "$container" vault status > /dev/null 2>&1 || curl -s -f http://dev.purebliss.app:18200/v1/sys/health > /dev/null 2>&1 ;;
        "postgres"|"postgresql") docker exec "$container" pg_isready -U postgres > /dev/null 2>&1 || docker exec "$container" pg_isready -U vikunja > /dev/null 2>&1 ;;
        "redis") docker exec "$container" redis-cli ping > /dev/null 2>&1 ;;
        "plane") curl -s -f http://dev.purebliss.app:3001/api/health > /dev/null 2>&1 || curl -s -f http://dev.purebliss.app/plane > /dev/null 2>&1 ;;
        "vikunja") curl -s -f http://dev.purebliss.app/api/v1/info > /dev/null 2>&1 ;;
        "codeserver") curl -s -f https://dev.purebliss.app/code-server > /dev/null 2>&1 ;;
        *) check_container_running "$container" ;;
    esac
}

# Function to diagnose specific container issues
diagnose_container_issues() {
    local container="$1"
    local service_dir="$2"
    local issues=()

    log "[DIAGNOSIS] Analyzing $container (from $service_dir) for specific issues..."

    if ! check_container_running "$container"; then
        local exit_code=$(docker inspect "$container" --format='{{.State.ExitCode}}' 2>/dev/null || echo "0")
        issues+=("exited_with_error:$exit_code")
    fi

    if [[ "$(docker inspect "$container" --format='{{.State.OOMKilled}}' 2>/dev/null)" == "true" ]]; then
        issues+=("oom_killed")
    fi

    local log_errors
    log_errors=$(docker logs "$container" --tail 50 2>&1 | grep -i "error\|fail\|exception\|fatal\|sealed\|unauthorized\|forbidden\|denied" | head -5 || true)
    if [[ -n "$log_errors" ]]; then
        if echo "$log_errors" | grep -qi "permission denied"; then issues+=("permission_error"); fi
        if echo "$log_errors" | grep -qi "connection refused\|connection failed"; then issues+=("connection_error"); fi
        if echo "$log_errors" | grep -qi "bind.*address already in use"; then issues+=("port_bind_error"); fi
        if echo "$log_errors" | grep -qi "no such file or directory"; then issues+=("missing_files"); fi
        if echo "$log_errors" | grep -qi "unauthorized\|forbidden"; then issues+=("auth_error"); fi
        if echo "$log_errors" | grep -qi "Admin user already exists"; then issues+=("keycloak_admin_exists"); fi
        if echo "$log_errors" | grep -qi "sealed"; then issues+=("vault_sealed"); fi
    fi

    if [[ "$service_dir" == "nginx" ]] && ! docker exec "$container" nginx -t >/dev/null 2>&1; then
        issues+=("nginx_config_invalid")
    fi

    printf '%s
' "${issues[@]}"
}

# Function to apply specific fixes based on diagnosed issues
apply_specific_fixes() {
    local container="$1"
    local service_dir="$2"
    shift 2
    local issues=("$@")

    log "[FIX] Applying targeted fixes for $container (from $service_dir)..."

    for issue in "${issues[@]}"; do
        local issue_type=${issue%%:*}
        local issue_detail=${issue#*:}

        log "[FIX] Addressing issue: $issue_type ($issue_detail)"

        case "$issue_type" in
            "vault_sealed")
                log "[FIX] Vault is sealed. Attempting to unseal..."
                local unseal_keys_file="/opt/my-secure-ha-stack/vault-unseal-keys.env"
                if [[ -f "$unseal_keys_file" ]]; then
                    source "$unseal_keys_file"
                    for key in "$VAULT_UNSEAL_KEY_1" "$VAULT_UNSEAL_KEY_2" "$VAULT_UNSEAL_KEY_3"; do
                        docker exec "$container" vault operator unseal "$key" && log "[FIX] Unseal key applied." || log "[WARN] Failed to apply unseal key."
                        sleep 2
                    done
                    if docker exec "$container" vault status 2>/dev/null | grep -q "Sealed.*false"; then
                        log "[SUCCESS] Vault unsealed successfully."
                    else
                        log "[ERROR] Failed to unseal Vault."
                    fi
                else
                    log "[ERROR] Unseal keys file not found: $unseal_keys_file"
                fi
                ;;
            "nginx_config_invalid")
                log "[CRITICAL] Nginx configuration is invalid. Cannot be fixed automatically."
                docker exec "$container" nginx -t 2>&1 | tee -a "$LOG_FILE"
                return 1
                ;;
            "keycloak_admin_exists")
                log "[FIX] Keycloak 'Admin user already exists' detected. This is informational. Restarting for stability."
                docker restart "$container"
                ;;
            *)
                log "[FIX] Performing generic restart for issue: $issue_type"
                docker restart "$container"
                ;;
        esac
        sleep 5
    done
    return 0
}

# Function to perform aggressive container fixing
fix_container_aggressively() {
    local container="$1"
    local service_dir="$2"
    local attempt=1

    log "🔧 INTELLIGENT FIX MODE for $container (from $service_dir) (up to $MAX_RETRIES attempts)"

    while [[ $attempt -le $MAX_RETRIES ]]; do
        log "[ATTEMPT $attempt/$MAX_RETRIES] Diagnosing and fixing $container..."

        local issues=($(diagnose_container_issues "$container" "$service_dir"))

        if [[ ${#issues[@]} -gt 0 ]]; then
            log "[DIAGNOSIS] Found ${#issues[@]} issues: ${issues[*]}"
            if ! apply_specific_fixes "$container" "$service_dir" "${issues[@]}"; then
                log "💥 CRITICAL: A non-recoverable error occurred during fixing. Halting fixes for $container."
                return 1
            fi
        else
            log "[DIAGNOSIS] No specific issues found. Performing a standard restart."
            docker restart "$container"
        fi

        log "[INFO] Waiting for container stabilization (20 seconds)..."
        sleep 20

        if check_container_health "$container" "$service_dir"; then
            log "✅ CONTAINER $container FULLY FIXED! (attempt $attempt)"
            return 0
        fi

        ((attempt++))
        if [[ $attempt -le $MAX_RETRIES ]]; then
            log "[INFO] Fix attempt failed, retrying in $RETRY_DELAY seconds..."
            sleep "$RETRY_DELAY"
        fi
    done

    log "💥 FAILED to fix $container after $MAX_RETRIES intelligent attempts."
    return 1
}

# Function to perform comprehensive container health check
check_container_health() {
    local container_name="$1"
    local service_dir="$2"

    log "======================================================"
    log "🔍 HEALTH CHECK FOR: $container_name (from $service_dir)"
    log "======================================================"

    if ! check_container_exists "$container_name"; then
        log "❌ CRITICAL: Container $container_name does not exist."
        return 1
    fi

    if ! check_container_running "$container_name"; then
        log "⚠️  Container $container_name is not running."
        return 1
    fi

    local health
    health=$(get_container_health "$container_name")
    if [[ "$health" == "unhealthy" ]]; then
        log "⚠️  Container $container_name is unhealthy."
        return 1
    elif [[ "$health" == "starting" ]]; then
        log "⏳ Container $container_name is still starting, waiting..."
        sleep 15
        health=$(get_container_health "$container_name")
        if [[ "$health" != "healthy" ]]; then
            log "⚠️  Container $container_name failed to become healthy."
            return 1
        fi
    fi

    if ! check_service_endpoint "$service_dir" "$container_name"; then
        log "⚠️  Service endpoint for $container_name not responding."
        return 1
    fi

    log "✅ Container $container_name is 100% operational!"
    return 0
}

# Function to apply specific fixes based on diagnosed issues
apply_specific_fixes() {
    local container="$1"
    shift
    local issues=("$@")

    log "[FIX] Applying targeted fixes for $container..."

    for issue in "${issues[@]}"; do
        local issue_type=${issue%%:*}
        local issue_detail=${issue#*:}

        log "[FIX] Addressing issue: $issue_type ($issue_detail)"

        case "$issue_type" in
            "vault_sealed")
                log "[FIX] Vault is sealed. Attempting to unseal..."
                local unseal_keys_file="/opt/my-secure-ha-stack/vault-unseal-keys.env"
                if [[ -f "$unseal_keys_file" ]]; then
                    source "$unseal_keys_file"
                    for key in "$VAULT_UNSEAL_KEY_1" "$VAULT_UNSEAL_KEY_2" "$VAULT_UNSEAL_KEY_3"; do
                        docker exec "$container" vault operator unseal "$key" && log "[FIX] Unseal key applied." || log "[WARN] Failed to apply unseal key."
                        sleep 2
                    done
                    if docker exec "$container" vault status 2>/dev/null | grep -q "Sealed.*false"; then
                        log "[SUCCESS] Vault unsealed successfully."
                    else
                        log "[ERROR] Failed to unseal Vault."
                    fi
                else
                    log "[ERROR] Unseal keys file not found: $unseal_keys_file"
                fi
                ;;
            "nginx_config_invalid")
                log "[CRITICAL] Nginx configuration is invalid. Cannot be fixed automatically."
                docker exec "$container" nginx -t 2>&1 | tee -a "$LOG_FILE"
                return 1
                ;;
            "keycloak_admin_exists")
                log "[FIX] Keycloak 'Admin user already exists' detected. This is informational. Restarting for stability."
                docker restart "$container"
                ;;
            *)
                log "[FIX] Performing generic restart for issue: $issue_type"
                docker restart "$container"
                ;;
        esac
        sleep 5
    done
    return 0
}

# Function to perform aggressive container fixing
fix_container_aggressively() {
    local container="$1"
    local attempt=1

    log "🔧 INTELLIGENT FIX MODE for $container (up to $MAX_RETRIES attempts)"

    while [[ $attempt -le $MAX_RETRIES ]]; do
        log "[ATTEMPT $attempt/$MAX_RETRIES] Diagnosing and fixing $container..."

        local issues=($(diagnose_container_issues "$container"))

        if [[ ${#issues[@]} -gt 0 ]]; then
            log "[DIAGNOSIS] Found ${#issues[@]} issues: ${issues[*]}"
            if ! apply_specific_fixes "$container" "${issues[@]}"; then
                log "💥 CRITICAL: A non-recoverable error occurred during fixing. Halting fixes for $container."
                return 1
            fi
        else
            log "[DIAGNOSIS] No specific issues found. Performing a standard restart."
            docker restart "$container"
        fi

        log "[INFO] Waiting for container stabilization (20 seconds)..."
        sleep 20

        if check_container_health "$container"; then
            log "✅ CONTAINER $container FULLY FIXED! (attempt $attempt)"
            return 0
        fi

        ((attempt++))
        if [[ $attempt -le $MAX_RETRIES ]]; then
            log "[INFO] Fix attempt failed, retrying in $RETRY_DELAY seconds..."
            sleep "$RETRY_DELAY"
        fi
    done

    log "💥 FAILED to fix $container after $MAX_RETRIES intelligent attempts."
    return 1
}

# Function to perform comprehensive container health check
check_container_health() {
    local service="$1"

    log "======================================================"
    log "🔍 HEALTH CHECK FOR: $service"
# ... existing code ...
    log "✅ Container $service is 100% operational!"
    return 0
}

# Function to extract container_name from a service's docker-compose file
get_container_name_from_compose() {
    local service_dir_name="$1"
    local service_base_dir="/opt/dev-purebliss/services"
    local compose_file=""
    # More specific search order first
    local potential_files=(
        "$service_base_dir/$service_dir_name/$service_dir_name.yml"
        "$service_base_dir/$service_dir_name/$service_dir_name.yaml"
        "$service_base_dir/$service_dir_name/docker-compose.yml"
        "$service_base_dir/$service_dir_name/docker-compose.yaml"
    )

    for file in "${potential_files[@]}"; do
        if [[ -f "$file" ]]; then
            compose_file="$file"
            break
        fi
    done

    if [[ -n "$compose_file" ]]; then
        # Attempt to parse container_name. Handles spaces and removes quotes.
        local name
        name=$(grep -m 1 "container_name:" "$compose_file" 2>/dev/null | sed -e 's/^[[:space:]]*container_name:[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/"//g' -e "s/'//g" || echo "")
        if [[ -n "$name" ]]; then
            echo "$name"
            return
        fi
    fi

    # Fallback to the directory name
    echo "$service_dir_name"
}

# Main execution
main() {
    log "INFO: Starting Docker Service Health Agent..."
    log "INFO: Processing services from '/opt/dev-purebliss/services' in a specific order."
    log "INFO: Each service will be restarted and validated to be 100% operational."

    if ! check_docker_daemon; then exit 1; fi

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

    local ordered_prefix=("vault" "vault-agent" "postgres")
    local processing_order=()
    local seen_services=()

    # Function to add a service to the processing order if not already seen
    add_service_to_order() {
        local service_to_add="$1"
        if [[ ! " ${seen_services[*]} " =~ " ${service_to_add} " ]]; then
            processing_order+=("$service_to_add")
            seen_services+=("$service_to_add")
        fi
    }

    # Add prefixed services first
    for service in "${ordered_prefix[@]}"; do
        if [[ " ${all_services[*]} " =~ " ${service} " ]]; then
            add_service_to_order "$service"
        fi
    done

    # Add the rest of the services
    for service in "${all_services[@]}"; do
        add_service_to_order "$service"
    done

    log "INFO: Service processing order: ${processing_order[*]}"

    local failed_containers=()

    for service_dir in "${processing_order[@]}"; do
        log "\n🎯 PROCESSING SERVICE DIRECTORY: $service_dir"

        local container_name
        container_name=$(get_container_name_from_compose "$service_dir")
        log "INFO: Determined container name for service '$service_dir' is '$container_name'."

        # First, check if the service is already healthy and running
        if check_container_health "$container_name" "$service_dir"; then
            log "✅ Service '$container_name' is already 100% operational. Skipping restart."
            continue
        fi

        log "⚠️  Service '$container_name' is not healthy. Proceeding with restart and validation."
        log "======================================================"

        local compose_file=""
        local potential_files=("$service_base_dir/$service_dir/$service_dir.yml" "$service_base_dir/$service_dir/$service_dir.yaml" "$service_base_dir/$service_dir/docker-compose.yml")
        for file in "${potential_files[@]}"; do
            if [ -f "$file" ]; then
                compose_file="$file"
                break
            fi
        done

        if [ -n "$compose_file" ]; then
            log "[ACTION] Restarting '$container_name' with docker-compose: $compose_file"
            docker-compose -f "$compose_file" down >/dev/null 2>&1 || log "[WARN] 'docker-compose down' for '$container_name' had issues."
            sleep 5
            docker-compose -f "$compose_file" up -d --force-recreate || log "[WARN] 'docker-compose up' for '$container_name' failed."
        else
            log "[ACTION] Restarting '$container_name' with 'docker restart'."
            docker restart "$container_name"
        fi
        log "[INFO] Waiting 15s for service to initialize after restart..."
        sleep 15

        # Dependency Check
        if [[ -n "${SERVICE_DEPENDENCIES[$service_dir]:-}" ]]; then
            for dep_dir in ${SERVICE_DEPENDENCIES[$service_dir]}; do
                local dep_container_name
                dep_container_name=$(get_container_name_from_compose "$dep_dir")
                log "[DEPENDENCY] Checking dependency: '$dep_container_name' (from '$dep_dir') for '$container_name'"
                if ! check_container_health "$dep_container_name" "$dep_dir"; then
                    log "[DEPENDENCY] Fixing dependency '$dep_container_name'..."
                    if ! fix_container_aggressively "$dep_container_name" "$dep_dir"; then
                        log "💥 CRITICAL: Failed to fix dependency '$dep_container_name' for '$container_name'. Aborting."
                        failed_containers+=("'$container_name' (dependency '$dep_container_name' failed)")
                        break 2
                    fi
                fi
            done
        fi

        # Health Validation and Fixing
        if ! check_container_health "$container_name" "$service_dir"; then
            log "⚠️  Service '$container_name' needs fixing after restart..."
            if ! fix_container_aggressively "$container_name" "$service_dir"; then
                log "💥 CRITICAL: Failed to fix '$container_name'. Aborting."
                failed_containers+=("'$container_name'")
                break
            fi
        fi
    done

    log "\n🏁 FINAL ENVIRONMENT STATUS:"
    log "============================"
    if [[ ${#failed_containers[@]} -gt 0 ]]; then
        log "❌ ENVIRONMENT NOT OPERATIONAL. Failed services: ${failed_containers[*]}"
        exit 1
    else
        log "🎉 SUCCESS! ALL PROCESSED SERVICES ARE 100% OPERATIONAL!"
        log "✅ Your Pure Bliss development environment is ready to use!"
        "$0" quick_health_summary
    fi
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
