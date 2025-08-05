#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
CONFIG_ENV_PATH="/opt/my-secure-ha-stack/config.env"
export DOCKER_API_VERSION="1.41"

# Source centralized environment variables like the startup script
if [ -f "$CONFIG_ENV_PATH" ]; then
  set -a
  . "$CONFIG_ENV_PATH"
  set +a
fi

# --- UTILITY FUNCTIONS ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SanityCheck] $1" | tee -a "$LOG_FILE"
}

check_docker_daemon() {
    log "INFO: Checking Docker daemon status..."
    if ! docker info > /dev/null 2>&1; then
        log "CRITICAL: Docker daemon is not running. Cannot proceed."
        exit 1
    fi
    log "SUCCESS: Docker daemon is running."
}

# --- CONTAINER STATE CHECKS ---

check_container_exists() {
    local service="$1"
    local container_name="purebliss-$service"
    docker ps -a -q -f name="^${container_name}$" | grep -q .
}

check_container_running() {
    local service="$1"
    local container_name="purebliss-$service"
    docker ps -q -f name="^${container_name}$" | grep -q .
}

get_container_health() {
    local service="$1"
    local container_name="purebliss-$service"
    docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container_name" 2>/dev/null || echo "unknown"
}

check_service_endpoint() {
    local service="$1"
    local container_name="purebliss-$service"
    log "DEBUG: Checking endpoint for $service (container: $container_name)"
    case "$service" in
        "nginx") curl -s -f -k https://dev.purebliss.app/nginx_status > /dev/null 2>&1 || curl -s -f http://localhost:80 > /dev/null 2>&1 ;;
        "keycloak") curl -s -f http://dev.purebliss.app:8080/health > /dev/null 2>&1 ;;
        "vault") docker exec "$container_name" vault status > /dev/null 2>&1 && [[ "$(docker exec "$container_name" vault status -format=json 2>/dev/null | jq -r .sealed)" == "false" ]] ;;
        "postgres") docker exec "$container_name" pg_isready -U postgres > /dev/null 2>&1 ;;
        "redis") docker exec "$container_name" redis-cli ping | grep -q "PONG" ;;
        *) return 0 ;; # Default to true if no specific endpoint check
    esac
}

is_container_fully_healthy() {
    local service="$1"
    log "INFO: Performing full health check for $service..."

    if ! check_container_running "$service"; then
        log "WARN: $service is not running."
        return 1
    fi

    local health_status
    health_status=$(get_container_health "$service")
    if [[ "$health_status" == "unhealthy" ]]; then
        log "WARN: $service health check is 'unhealthy'."
        return 1
    fi

    if [[ "$health_status" == "starting" ]]; then
        log "INFO: $service is still starting. Waiting up to 30 seconds..."
        sleep 30
        health_status=$(get_container_health "$service")
        if [[ "$health_status" != "healthy" ]]; then
            log "WARN: $service failed to become healthy after waiting."
            return 1
        fi
    fi

    if ! check_service_endpoint "$service"; then
        log "WARN: $service endpoint is not responding correctly."
        return 1
    fi

    log "SUCCESS: $service is fully healthy and operational."
    return 0
}

# --- FIXING AND DIAGNOSTICS ---

declare -A SERVICE_DEPENDENCIES=(
    ["letsencrypt"]="nginx"
    ["vault"]="nginx letsencrypt"
    ["vault-agent"]="vault"
    ["postgres"]="vault vault-agent"
    ["keycloak"]="postgres vault"
    ["plane"]="postgres vault"
    ["vikunja"]="postgres vault"
    ["grafana"]="prometheus loki vault"
    ["prometheus"]="vault"
    ["loki"]="vault"
    ["codeserver"]="vault"
    ["redis"]="vault"
)

diagnose_issues() {
    local service="$1"
    local container_name="purebliss-$service"
    local issues=()
    log "INFO: Diagnosing potential issues for $service (container: $container_name)..."

    # Check for sealed Vault
    if [[ "$service" == "vault" ]] && docker exec "$container_name" vault status 2>/dev/null | grep -q "Sealed.*true"; then
        issues+=("vault_sealed")
    fi

    # Check for common log errors
    local log_errors
    log_errors=$(docker logs "$container_name" --tail 30 2>&1 | grep -iE "error|fail|denied|timeout|refused" || true)
    if [[ -n "$log_errors" ]]; then
        if echo "$log_errors" | grep -qi "permission denied"; then issues+=("permission_error"); fi
        if echo "$log_errors" | grep -qi "connection refused"; then issues+=("connection_error"); fi
    fi

    echo "${issues[@]}"
}

apply_fixes() {
    local service="$1"
    local container_name="purebliss-$service"
    local issues_string="$2"
    read -ra issues <<< "$issues_string"

    if [[ ${#issues[@]} -eq 0 ]]; then
        log "INFO: No specific issues diagnosed for $service."
        return
    fi

    log "INFO: Applying fixes for diagnosed issues: ${issues[*]}..."
    for issue in "${issues[@]}"; do
        case "$issue" in
            "vault_sealed")
                log "FIX: Vault is sealed. Attempting to unseal..."
                local unseal_keys_file="/opt/my-secure-ha-stack/vault-unseal-keys.env"
                if [[ -f "$unseal_keys_file" ]]; then
                    source "$unseal_keys_file"
                    for key in "${VAULT_DEV_UNSEAL_KEY_1:-}" "${VAULT_DEV_UNSEAL_KEY_2:-}" "${VAULT_DEV_UNSEAL_KEY_3:-}"; do
                        if [[ -n "$key" ]]; then
                            docker exec "$container_name" vault operator unseal "$key" >/dev/null 2>&1
                            sleep 1
                        fi
                    done
                    if ! docker exec "$container_name" vault status 2>/dev/null | grep -q "Sealed.*false"; then
                        log "ERROR: Failed to unseal Vault."
                    else
                        log "SUCCESS: Vault unsealed."
                    fi
                else
                    log "ERROR: Cannot unseal Vault, keys not found at $unseal_keys_file."
                fi
                ;;
            "permission_error")
                log "FIX: Detected permission error. This often requires manual intervention to fix volume permissions on the host."
                ;;
            "connection_error")
                log "FIX: Detected connection error. This may be due to a dependency not being ready. Dependency checks should handle this."
                ;;
            *)
                log "WARN: No specific fix available for issue '$issue'."
                ;;
        esac
    done
}

ensure_service_healthy() {
    local service="$1"
    local service_base_dir="/opt/dev-purebliss/services"
    local max_attempts=3
    local attempt=1

    log "------------------------------------------------------"
    log "Ensuring service '$service' is 100% operational."

    while (( attempt <= max_attempts )); do
        if is_container_fully_healthy "$service"; then
            log "SUCCESS: Validation passed for $service."
            return 0
        fi

        log "WARN: Service '$service' is not healthy. Attempt $attempt/$max_attempts to fix."

        # 1. Fix dependencies first
        local dependencies="${SERVICE_DEPENDENCIES[$service]:-}"
        if [[ -n "$dependencies" ]]; then
            log "INFO: Checking dependencies for $service: $dependencies"
            for dep in $dependencies; do
                if ! is_container_fully_healthy "$dep"; then
                    log "WARN: Dependency '$dep' for '$service' is not healthy. Attempting to fix it first."
                    # Recursive call to fix dependency
                    if ! ensure_service_healthy "$dep"; then
                        log "CRITICAL: Failed to fix dependency '$dep' for '$service'. Cannot proceed with '$service'."
                        return 1
                    fi
                fi
            done
        fi

        # 2. Restart the service
        log "INFO: Restarting service '$service'..."
        local compose_file=$(get_docker_compose_file "$service" "$service_base_dir")

        if [[ -n "$compose_file" ]]; then
            log "DEBUG: Using compose file: $compose_file"
            (cd "$service_base_dir/$service" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$(basename "$compose_file")" down --remove-orphans >/dev/null 2>&1)
            (cd "$service_base_dir/$service" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$(basename "$compose_file")" up -d >/dev/null 2>&1)
        else
            log "DEBUG: No compose file found, using docker restart for $service"
            docker restart "purebliss-$service" >/dev/null 2>&1
        fi
        log "INFO: Waiting 20 seconds for service to initialize..."
        sleep 20

        # 3. Diagnose and apply specific fixes
        local issues
        issues=$(diagnose_issues "$service")
        if [[ -n "$issues" ]]; then
            apply_fixes "$service" "$issues"
            log "INFO: Re-waiting 10 seconds after applying fixes..."
            sleep 10
        fi

        ((attempt++))
    done

    log "CRITICAL: Failed to make service '$service' healthy after $max_attempts attempts."
    docker logs "purebliss-$service" --tail 50 | tee -a "$LOG_FILE"
    return 1
}

# --- SERVICE DISCOVERY ---

get_docker_compose_file() {
    local service="$1"
    local service_base_dir="$2"

    # Use the same logic as the startup script
    COMPOSE_VAR="$(echo ${service^^}_DOCKER_COMPOSE_FILE | tr '-' '_')"
    COMPOSE_FILE="${!COMPOSE_VAR:-docker-compose.yml}"

    local compose_path="$service_base_dir/$service/$COMPOSE_FILE"
    if [[ -f "$compose_path" ]]; then
        echo "$compose_path"
    else
        echo ""
    fi
}

get_all_services() {
    # Use the exact same service list and order as the startup script
    # This ensures we check the same services that the startup script manages
    echo "nginx letsencrypt vault vault-agent redis postgres keycloak grafana loki prometheus plane codeserver vikunja"
}

discover_all_services() {
    local service_base_dir="$1"
    local discovered_services=()

    # Get the services from the startup script's service list
    local all_services=($(get_all_services))

    for service_name in "${all_services[@]}"; do
        if [[ -d "$service_base_dir/$service_name" ]]; then
            local compose_file=$(get_docker_compose_file "$service_name" "$service_base_dir")
            if [[ -n "$compose_file" ]]; then
                discovered_services+=("$service_name")
            fi
        fi
    done

    echo "${discovered_services[@]}"
}


# --- MAIN EXECUTION ---

main() {
    log "--- Starting Container Sanity Check ---"
    check_docker_daemon

    # --- PRE-CHECK: Run test_discovery.sh for service and vault sanity ---
    if [[ -f "/opt/test_discovery.sh" ]]; then
        log "INFO: Running pre-check: /opt/test_discovery.sh"
        bash /opt/test_discovery.sh
        precheck_status=$?
        if [[ $precheck_status -ne 0 ]]; then
            log "WARNING: Pre-check script /opt/test_discovery.sh reported issues. See above for details."
        else
            log "INFO: Pre-check script /opt/test_discovery.sh completed successfully."
        fi
    else
        log "INFO: Pre-check script /opt/test_discovery.sh not found. Skipping."
    fi

    local service_base_dir="/opt/dev-purebliss/services"
    if [[ ! -d "$service_base_dir" ]]; then
        log "CRITICAL: Service directory not found at '$service_base_dir'. Exiting."
        exit 1
    fi

    # Use the same processing order as the startup script
    # First: nginx, letsencrypt
    # Second: vault, vault-agent
    # Third: remaining services (redis postgres keycloak grafana loki prometheus plane codeserver vikunja)
    local startup_order_phase1=("nginx" "letsencrypt")
    local startup_order_phase2=("vault" "vault-agent")
    local startup_order_phase3=("redis" "postgres" "keycloak" "grafana" "loki" "prometheus" "plane" "codeserver" "vikunja")

    local all_services=()
    local processing_order=()
    declare -A seen_services

    # Discover all services with compose files
    log "INFO: Discovering all services in $service_base_dir..."
    read -ra all_services <<< "$(discover_all_services "$service_base_dir")"

    if [[ ${#all_services[@]} -eq 0 ]]; then
        log "CRITICAL: No services with docker-compose files found in '$service_base_dir'. Exiting."
        exit 1
    fi

    log "INFO: Discovered ${#all_services[@]} services: ${all_services[*]}"

    # Function to add a service to the processing order if not already seen and if it exists
    add_service_to_order() {
        local service_to_add="$1"
        if [[ -z "${seen_services[$service_to_add]:-}" ]]; then
            # Check if the service exists in the discovered services
            for s in "${all_services[@]}"; do
                if [[ "$s" == "$service_to_add" ]]; then
                    processing_order+=("$service_to_add")
                    seen_services["$service_to_add"]=1
                    break
                fi
            done
        fi
    }

    # Add services in the same order as the startup script
    for service in "${startup_order_phase1[@]}"; do
        add_service_to_order "$service"
    done

    for service in "${startup_order_phase2[@]}"; do
        add_service_to_order "$service"
    done

    for service in "${startup_order_phase3[@]}"; do
        add_service_to_order "$service"
    done

    log "INFO: Determined processing order: ${processing_order[*]}"

    local failed_services=()
    for service in "${processing_order[@]}"; do
        if is_container_fully_healthy "$service"; then
            log "INFO: Service '$service' is already healthy. Skipping."
            continue
        fi

        if ! ensure_service_healthy "$service"; then
            failed_services+=("$service")
            log "CRITICAL: Halting script because essential service '$service' failed to start."
            break # Stop processing further services
        fi
    done

    log "--- Sanity Check Complete ---"
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log "RESULT: FAILURE. The following services failed: ${failed_services[*]}"
        exit 1
    else
        log "RESULT: SUCCESS. All services are healthy and operational."
        # Show a quick summary at the end
        echo -e "\n==== DOCKER QUICK HEALTH SUMMARY ====\n"
        printf "%-30s | %-10s | %-15s\n" "CONTAINER" "STATE" "HEALTH"
        printf '%s\n' "$(printf '=%.0s' {1..60})"
        docker ps --format '{{.Names}}' | grep "^purebliss-" | while read -r name; do
            service_name=$(echo "$name" | sed 's/^purebliss-//')
            state=$(docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null || echo "unknown")
            health=$(get_container_health "$service_name")
            printf "%-30s | %-10s | %-15s\n" "$name" "$state" "$health"
        done
        echo -e "====================================\n"
    fi
}

main "$@"
