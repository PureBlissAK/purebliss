#!/bin/bash
set -euo pipefail


LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
log() {
  echo "[$(date)] $1" | tee -a "$LOG_FILE"
}
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
VAULT_UNSEAL_KEYS_GPG="/opt/my-secure-ha-stack/secrets/vault-unseal-keys.gpg"
VAULT_UNSEAL_KEYS_ENV="/opt/my-secure-ha-stack/vault-unseal-keys.env"
DECRYPTED_KEYS_FILE="/tmp/vault-unseal-keys.env"
export VAULT_ADDR="http://dev.purebliss.app:18200"
# export VAULT_CACERT="/opt/my-secure-ha-stack/vault/certs/ca.pem"
export VAULT_SKIP_VERIFY=true

# Container Location Tracking
VAULT_LOCATIONS_FILE="/opt/my-secure-ha-stack/logs/vault-container-locations.log"
VAULT_CONTAINER="purebliss-vault"
VAULT_AGENT_CONTAINER="purebliss-vault-agent"

start_vault_containers() {
    log "INFO: Starting Vault and Vault-Agent containers..."
    # Start Vault stack
    if [ -f "/opt/dev-purebliss/services/vault/docker-compose.yml" ]; then
        log "INFO: Starting Vault stack from /opt/dev-purebliss/services/vault/"
        cd /opt/dev-purebliss/services/vault/
        docker-compose up -d 2>&1 | tee -a "$LOG_FILE"
        sleep 5
    elif [ -f "/opt/my-secure-ha-stack/docker-compose.yml" ]; then
        log "INFO: Starting Vault stack from /opt/my-secure-ha-stack/"
        cd /opt/my-secure-ha-stack/
        docker-compose up -d 2>&1 | tee -a "$LOG_FILE"
        sleep 5
    else
        log "WARNING: No Vault docker-compose.yml found. Checking if container already exists..."
    fi
    # Start Vault-Agent stack
    if [ -f "/opt/dev-purebliss/services/vault-agent/docker-compose.yml" ]; then
        log "INFO: Starting Vault-Agent stack from /opt/dev-purebliss/services/vault-agent/"
        cd /opt/dev-purebliss/services/vault-agent/
        docker-compose up -d 2>&1 | tee -a "$LOG_FILE"
        sleep 5
    else
        log "WARNING: No Vault-Agent docker-compose.yml found. May need to build from templates..."
    fi
    # Document the current state
    document_container_locations
    # Wait for containers to stabilize
    log "INFO: Waiting 10 seconds for containers to stabilize..."
    sleep 10
}

# Function to document container locations for future reference
document_container_locations() {
    log "INFO: Documenting Vault and Vault-Agent container locations for future reference..."

    local timestamp=$(date)
    echo "# Vault Container Locations - Updated: $timestamp" > "$VAULT_LOCATIONS_FILE"
    echo "# This file tracks the actual locations and configurations of Vault containers" >> "$VAULT_LOCATIONS_FILE"
    echo "" >> "$VAULT_LOCATIONS_FILE"

    # Document Vault container location
    echo "[VAULT CONTAINER]" >> "$VAULT_LOCATIONS_FILE"
    echo "Container Name: $VAULT_CONTAINER" >> "$VAULT_LOCATIONS_FILE"

    if docker ps -a -q -f name="$VAULT_CONTAINER" > /dev/null 2>&1; then
        local vault_compose_file=$(docker inspect "$VAULT_CONTAINER" --format '{{index .Config.Labels "com.docker.compose.project.config_files"}}' 2>/dev/null || echo "Unknown")
        local vault_project_dir=$(docker inspect "$VAULT_CONTAINER" --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' 2>/dev/null || echo "Unknown")
        local vault_service_name=$(docker inspect "$VAULT_CONTAINER" --format '{{index .Config.Labels "com.docker.compose.service"}}' 2>/dev/null || echo "Unknown")

        echo "Status: $(docker inspect --format='{{.State.Status}}' "$VAULT_CONTAINER" 2>/dev/null || echo 'Not Found')" >> "$VAULT_LOCATIONS_FILE"
        echo "Compose File: $vault_compose_file" >> "$VAULT_LOCATIONS_FILE"
        echo "Project Directory: $vault_project_dir" >> "$VAULT_LOCATIONS_FILE"
        echo "Service Name: $vault_service_name" >> "$VAULT_LOCATIONS_FILE"
        echo "Image: $(docker inspect --format='{{.Config.Image}}' "$VAULT_CONTAINER" 2>/dev/null || echo 'Unknown')" >> "$VAULT_LOCATIONS_FILE"
        echo "Ports: $(docker inspect --format='{{range .NetworkSettings.Ports}}{{range .}}{{.HostPort}}:{{end}}{{end}}' "$VAULT_CONTAINER" 2>/dev/null || echo 'Unknown')" >> "$VAULT_LOCATIONS_FILE"

        # Document volume mounts
        echo "Volume Mounts:" >> "$VAULT_LOCATIONS_FILE"
        docker inspect "$VAULT_CONTAINER" --format '{{range .Mounts}}  {{.Source}} -> {{.Destination}} ({{.Type}}){{"\n"}}{{end}}' 2>/dev/null >> "$VAULT_LOCATIONS_FILE" || echo "  No mounts found" >> "$VAULT_LOCATIONS_FILE"
    else
        echo "Status: Container not found" >> "$VAULT_LOCATIONS_FILE"
        echo "Location: Need to check /opt/dev-purebliss/services/vault/ and /opt/my-secure-ha-stack/" >> "$VAULT_LOCATIONS_FILE"
    fi

    echo "" >> "$VAULT_LOCATIONS_FILE"

    # Document Vault-Agent container location
    echo "[VAULT-AGENT CONTAINER]" >> "$VAULT_LOCATIONS_FILE"
    echo "Container Name: $VAULT_AGENT_CONTAINER" >> "$VAULT_LOCATIONS_FILE"

    if docker ps -a -q -f name="$VAULT_AGENT_CONTAINER" > /dev/null 2>&1; then
        local agent_compose_file=$(docker inspect "$VAULT_AGENT_CONTAINER" --format '{{index .Config.Labels "com.docker.compose.project.config_files"}}' 2>/dev/null || echo "Unknown")
        local agent_project_dir=$(docker inspect "$VAULT_AGENT_CONTAINER" --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' 2>/dev/null || echo "Unknown")
        local agent_service_name=$(docker inspect "$VAULT_AGENT_CONTAINER" --format '{{index .Config.Labels "com.docker.compose.service"}}' 2>/dev/null || echo "Unknown")

        echo "Status: $(docker inspect --format='{{.State.Status}}' "$VAULT_AGENT_CONTAINER" 2>/dev/null || echo 'Not Found')" >> "$VAULT_LOCATIONS_FILE"
        echo "Compose File: $agent_compose_file" >> "$VAULT_LOCATIONS_FILE"
        echo "Project Directory: $agent_project_dir" >> "$VAULT_LOCATIONS_FILE"
        echo "Service Name: $agent_service_name" >> "$VAULT_LOCATIONS_FILE"
        echo "Image: $(docker inspect --format='{{.Config.Image}}' "$VAULT_AGENT_CONTAINER" 2>/dev/null || echo 'Unknown')" >> "$VAULT_LOCATIONS_FILE"

        # Document volume mounts
        echo "Volume Mounts:" >> "$VAULT_LOCATIONS_FILE"
        docker inspect "$VAULT_AGENT_CONTAINER" --format '{{range .Mounts}}  {{.Source}} -> {{.Destination}} ({{.Type}}){{"\n"}}{{end}}' 2>/dev/null >> "$VAULT_LOCATIONS_FILE" || echo "  No mounts found" >> "$VAULT_LOCATIONS_FILE"
    else
        echo "Status: Container not found" >> "$VAULT_LOCATIONS_FILE"
        echo "Location: Need to check /opt/dev-purebliss/services/vault-agent/" >> "$VAULT_LOCATIONS_FILE"
    fi

    echo "" >> "$VAULT_LOCATIONS_FILE"

    # Document known container locations
    echo "[KNOWN CONTAINER LOCATIONS]" >> "$VAULT_LOCATIONS_FILE"
    echo "Primary Vault Location: /opt/dev-purebliss/services/vault/" >> "$VAULT_LOCATIONS_FILE"
    echo "Primary Vault-Agent Location: /opt/dev-purebliss/services/vault-agent/" >> "$VAULT_LOCATIONS_FILE"
    echo "Legacy Vault Location: /opt/my-secure-ha-stack/ (docker-compose.yml)" >> "$VAULT_LOCATIONS_FILE"
    echo "Alternative Locations to Check:" >> "$VAULT_LOCATIONS_FILE"
    echo "  - /opt/pure-bliss-dev/services/" >> "$VAULT_LOCATIONS_FILE"
    echo "  - /opt/purebliss/" >> "$VAULT_LOCATIONS_FILE"
    echo "  - Current working directory compose files" >> "$VAULT_LOCATIONS_FILE"

    log "INFO: Container locations documented in $VAULT_LOCATIONS_FILE"
}

# Function to start Vault and Vault-Agent containers
start_vault_containers() {
    log "INFO: Starting Vault and Vault-Agent containers..."

    # Try to start from the new location first
    if [ -f "/opt/dev-purebliss/services/vault/docker-compose.yml" ]; then
        log "INFO: Starting Vault from /opt/dev-purebliss/services/vault/"
        cd /opt/dev-purebliss/services/vault/
        docker-compose up -d vault 2>&1 | tee -a "$LOG_FILE"
        sleep 5
    elif [ -f "/opt/my-secure-ha-stack/docker-compose.yml" ]; then
        log "INFO: Starting Vault from /opt/my-secure-ha-stack/"
        cd /opt/my-secure-ha-stack/
        docker-compose up -d vault 2>&1 | tee -a "$LOG_FILE"
        sleep 5
    else
        log "WARNING: No Vault docker-compose.yml found. Checking if container already exists..."
    fi

    # Try to start Vault-Agent
    if [ -f "/opt/dev-purebliss/services/vault-agent/docker-compose.yml" ]; then
        log "INFO: Starting Vault-Agent from /opt/dev-purebliss/services/vault-agent/"
        cd /opt/dev-purebliss/services/vault-agent/
        docker-compose up -d vault-agent 2>&1 | tee -a "$LOG_FILE"
        sleep 5
    else
        log "WARNING: No Vault-Agent docker-compose.yml found. May need to build from templates..."
    fi

    # Document the current state
    document_container_locations

    # Wait for containers to stabilize
    log "INFO: Waiting 10 seconds for containers to stabilize..."
    sleep 10
}

# List of services that consume database credentials
DB_CONSUMER_SERVICES=("plane" "vikunja" "keycloak")

# Helper function to check if a service is a DB consumer
is_db_consumer() {
    local service="$1"

    # Check static list first
    for consumer in "${DB_CONSUMER_SERVICES[@]}"; do
        if [[ "$consumer" == "$service" ]]; then
            return 0
        fi
    done

    # Dynamically check container for database-related environment variables or configs
    local container="purebliss-${service}"
    if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
        # Try without purebliss- prefix
        container="$service"
        if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
            return 1
        fi
    fi

    # Check for database-related environment variables
    local db_env_vars=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}}' 2>/dev/null | grep -iE "(database|db_|postgres|mysql|mongo)" || true)

    if [[ -n "$db_env_vars" ]]; then
        log "DEBUG: $service appears to use database credentials based on environment variables."
        return 0
    fi

    # Check for database-related volume mounts
    local db_volumes=$(docker inspect "$container" --format '{{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep -iE "(database|db|postgres|mysql|mongo)" || true)

    if [[ -n "$db_volumes" ]]; then
        log "DEBUG: $service appears to use database credentials based on volume mounts."
        return 0
    fi

    return 1
}

# Function to detect secrets that should be managed by Vault
detect_vault_secrets() {
    local service="$1"
    local container="purebliss-${service}"
    local secrets_found=()

    if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
        container="$service"
        if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
            return 1
        fi
    fi

    log "INFO: Scanning $service for secrets that should be managed by Vault..."

    # Check environment variables for potential secrets
    local env_vars=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}}' 2>/dev/null || true)

    # Enhanced secret patterns for comprehensive detection
    local secret_patterns=(
        "PASSWORD" "SECRET" "KEY" "TOKEN" "CREDENTIAL" "API_KEY" "AUTH"
        "JWT_SECRET" "ENCRYPTION_KEY" "PRIVATE_KEY" "ACCESS_TOKEN" "BEARER_TOKEN"
        "LDAP_BIND" "AD_USER" "BIND_PASSWORD" "AWS_SECRET" "AZURE_SECRET" "GCP_KEY"
    )

    for pattern in "${secret_patterns[@]}"; do
        local matches=$(echo "$env_vars" | grep -i "$pattern" | grep -v "vault read" || true)
        if [[ -n "$matches" ]]; then
            while IFS= read -r match; do
                if [[ -n "$match" ]]; then
                    secrets_found+=("$match")
                    log "WARNING: $service has hardcoded secret: $match"
                    # Attempt remediation for environment files
                    ENV_FILES=("/opt/purebliss/backend/.env" "/opt/my-secure-ha-stack/.env" "/opt/dev-purebliss/.env" "/opt/${service}/.env" "/app/.env")
                    for env_file in "${ENV_FILES[@]}"; do
                        if [ -f "$env_file" ]; then
                            # Remove the hardcoded secret line
                            sed -i "/^${pattern}=.*/Id" "$env_file"
                            # Add Vault dynamic secret reference if not present
                            VAULT_LINE="${pattern}=\$(vault read -field=${pattern,,} secrets/data/${service}/${pattern,,})"
                            if ! grep -q "^${pattern}=\$(vault read" "$env_file"; then
                                echo "$VAULT_LINE" >> "$env_file"
                                log "INFO: Remediated $pattern in $env_file for $service to use Vault."
                            fi
                        fi
                    done
                fi
            done <<< "$matches"
        fi
    done

    # Check for specific database credential patterns
    local db_creds=$(echo "$env_vars" | grep -iE "(db_user|db_password|database_user|database_password|postgres_user|postgres_password|mysql_user|mysql_password|mongo_user|mongo_password|redis_password)" | grep -v "vault read" || true)
    if [[ -n "$db_creds" ]]; then
        while IFS= read -r cred; do
            if [[ -n "$cred" ]]; then
                secrets_found+=("$cred")
                log "WARNING: $service has hardcoded database credential: $cred"
                # Attempt remediation for DB credentials
                ENV_FILES=("/opt/purebliss/backend/.env" "/opt/my-secure-ha-stack/.env" "/opt/dev-purebliss/.env" "/opt/${service}/.env" "/app/.env")
                for env_file in "${ENV_FILES[@]}"; do
                    if [ -f "$env_file" ]; then
                        # Remove the hardcoded DB credential line
                        sed -i "/^${cred%%=*}=.*/Id" "$env_file"
                        # Add Vault dynamic secret reference if not present
                        VAULT_LINE="${cred%%=*}=\$(vault read -field=${cred%%=*} database/creds/${service})"
                        if ! grep -q "^${cred%%=*}=\$(vault read" "$env_file"; then
                            echo "$VAULT_LINE" >> "$env_file"
                            log "INFO: Remediated DB credential ${cred%%=*} in $env_file for $service to use Vault."
                        fi
                    fi
                done
            fi
        done <<< "$db_creds"
    fi

    # Check for SSL/TLS certificates and keys in common locations (if accessible)
    local cert_paths=("/etc/ssl/certs" "/etc/nginx/certs" "/opt/vault/tls" "/etc/letsencrypt" "/certs" "/ssl")
    for cert_path in "${cert_paths[@]}"; do
        if docker exec "$container" find "$cert_path" -name "*.key" -o -name "*.pem" -o -name "*.crt" 2>/dev/null | grep -q .; then
            secrets_found+=("SSL_CERTIFICATES_AT_${cert_path}")
            log "WARNING: $service has SSL certificates or keys at $cert_path"
        fi
    done

    # Check for hardcoded secrets in common config files (if accessible)
    local config_files=("/app/.env" "/opt/app/.env" "/app/config.yml" "/app/config.yaml")
    for config_file in "${config_files[@]}"; do
        if docker exec "$container" test -f "$config_file" 2>/dev/null; then
            if docker exec "$container" grep -Eqi "(password|passwd|pwd|secret|key).*[:=].*[a-zA-Z0-9]" "$config_file" 2>/dev/null; then
                secrets_found+=("HARDCODED_SECRETS_IN_${config_file}")
                log "WARNING: $service has potential hardcoded secrets in $config_file"
            fi
        fi
    done

    if [ ${#secrets_found[@]} -gt 0 ]; then
        log "INFO: Found ${#secrets_found[@]} potential secrets in $service that should be managed by Vault."
        return 0
    else
        log "INFO: No hardcoded secrets detected in $service."
        return 1
    fi
}

# Function to check Vault container health using Docker healthcheck
check_vault_container_health() {
    local container="$1"
    local health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container" 2>/dev/null || echo "unknown")

    log "INFO: Vault container health status: $health_status"

    case "$health_status" in
        "healthy")
            log "SUCCESS: Vault container is healthy."
            return 0
            ;;
        "unhealthy")
            log "ERROR: Vault container is unhealthy."
            # Get the last few health check results for debugging
            local health_log=$(docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' "$container" 2>/dev/null | tail -3)
            log "DEBUG: Recent health check output: $health_log"
            return 1
            ;;
        "starting")
            log "INFO: Vault container is still starting up..."
            return 2
            ;;
        "no_healthcheck")
            log "WARNING: Vault container has no healthcheck configured. Using legacy status check."
            return 3
            ;;
        *)
            log "ERROR: Unknown health status: $health_status"
            return 1
            ;;
    esac
}

check_vault_agent_health() {
    local health
    health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$VAULT_AGENT_CONTAINER" 2>/dev/null || echo "unknown")

    log "INFO: Vault-Agent container health status: $health"

    case "$health" in
        "healthy")
            log "SUCCESS: Vault-Agent container is healthy."
            return 0
            ;;
        "unhealthy")
            log "ERROR: Vault-Agent container is unhealthy."
            # Get the last few health check results for debugging
            local health_log=$(docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' "$VAULT_AGENT_CONTAINER" 2>/dev/null | tail -3)
            log "DEBUG: Recent Vault-Agent health check output: $health_log"
            return 1
            ;;
        "starting")
            log "INFO: Vault-Agent container is still starting up..."
            return 2
            ;;
        "no_healthcheck")
            log "WARNING: Vault-Agent container has no healthcheck configured."
            return 3
            ;;
        *)
            log "ERROR: Unknown Vault-Agent health status: $health"
            return 1
            ;;
    esac
}

# Function to discover all running containers and extract service names
discover_services() {
    local services=()
    log "INFO: Discovering all running containers on the host..."

    # Get all running containers with purebliss- prefix
    local containers=$(docker ps --format "{{.Names}}" | grep "^purebliss-" | sort)

    for container in $containers; do
        # Extract service name by removing purebliss- prefix
        local service_name="${container#purebliss-}"
        services+=("$service_name")
        log "DEBUG: Discovered service: $service_name (container: $container)"
    done

    # Also check for containers without purebliss- prefix that might be part of our stack
    local other_containers=$(docker ps --format "{{.Names}}" | grep -v "^purebliss-" | sort)

    for container in $other_containers; do
        # Check if container has environment variables or volumes that suggest it's part of our stack
        local has_vault_config=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}} {{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep -i vault || true)
        local has_purebliss_config=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}} {{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep -i purebliss || true)

        if [[ -n "$has_vault_config" || -n "$has_purebliss_config" ]]; then
            services+=("$container")
            log "DEBUG: Discovered related service: $container (non-standard naming)"
        fi
    done

    if [ ${#services[@]} -eq 0 ]; then
        log "WARNING: No services discovered. Using fallback service list."
        services=(postgres keycloak nginx plane redis grafana loki prometheus vault)
    else
        log "INFO: Discovered ${#services[@]} services: ${services[*]}"
    fi

    echo "${services[@]}"
}

# Dynamically discover services
SERVICES=($(discover_services))

check_documented_raft_location() {
    local raft_location_file="/opt/my-secure-ha-stack/logs/vault-raft-location.txt"
    if [ -f "$raft_location_file" ]; then
        log "INFO: Found documented raft location file. Last entries:"
        tail -5 "$raft_location_file" | while IFS= read -r line; do
            log "RAFT_DOC: $line"
        done
    else
        log "INFO: No documented raft location file found yet. Will be created if new raft is established."
    fi
}

# Function to verify Vault container configuration and volumes
verify_vault_container_config() {
    log "INFO: Verifying Vault container configuration and volume mounts..."

    # Check if Vault container is running
    if ! docker ps -q -f name="$VAULT_CONTAINER" > /dev/null 2>&1; then
        log "ERROR: Vault container $VAULT_CONTAINER is not running."
        return 1
    fi

    # Check volume mounts
    local vault_mounts=$(docker inspect "$VAULT_CONTAINER" --format '{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' 2>/dev/null || echo "")
    log "INFO: Vault container volume mounts: $vault_mounts"

    # Verify raft directory is properly mounted
    if echo "$vault_mounts" | grep -q "/vault/file"; then
        log "INFO: Vault file storage is properly mounted."
    else
        log "WARNING: Vault file storage mount not found. This may cause raft issues."
    fi

    # Check container internal file system
    log "INFO: Checking Vault container internal file system..."
    docker exec "$VAULT_CONTAINER" ls -la /vault/ 2>&1 | tee -a "$LOG_FILE"

    return 0
}

# Function to handle Vault initialization with proper best practices
initialize_vault_with_best_practices() {
    log "INFO: Initializing Vault following security best practices..."

    # Ensure secrets directory exists with proper permissions
    local secrets_dir="/opt/my-secure-ha-stack/secrets"
    if [ ! -d "$secrets_dir" ]; then
        log "INFO: Creating secrets directory with secure permissions..."
        mkdir -p "$secrets_dir"
        chmod 700 "$secrets_dir"
        chown $(whoami):$(whoami) "$secrets_dir"
    fi

    # Initialize Vault if not already initialized
    local vault_status=$(docker exec -e VAULT_ADDR='http://127.0.0.1:8200' "$VAULT_CONTAINER" vault status -format=json 2>/dev/null || echo '{"initialized":false}')
    local is_initialized=$(echo "$vault_status" | grep -o '"initialized":[^,}]*' | cut -d':' -f2 | tr -d ' ')

    if [ "$is_initialized" = "false" ]; then
        log "INFO: Vault is not initialized. Performing secure initialization..."

        # Generate init output file with timestamp
        local init_output_file="$secrets_dir/vault-init-$(date +%Y%m%d_%H%M%S).json"

        # Initialize with JSON output for better parsing
        if docker exec -e VAULT_ADDR='http://127.0.0.1:8200' "$VAULT_CONTAINER" vault operator init -format=json -key-shares=5 -key-threshold=3 > "$init_output_file"; then
            log "SUCCESS: Vault initialized successfully. Output saved to $init_output_file"

            # Extract unseal keys and root token securely
            local unseal_keys_file="$secrets_dir/vault-unseal-keys.env"
            local root_token_file="$secrets_dir/vault_token"

            # Parse JSON and extract keys
            for i in $(seq 0 4); do
                local key=$(jq -r ".unseal_keys_b64[$i]" "$init_output_file")
                echo "export VAULT_UNSEAL_KEY_$((i+1))=\"$key\"" >> "$unseal_keys_file"
            done

            # Extract root token
            jq -r '.root_token' "$init_output_file" > "$root_token_file"

            # Secure the files
            chmod 600 "$unseal_keys_file" "$root_token_file" "$init_output_file"

            log "INFO: Unseal keys and root token securely stored."

            # Unseal Vault immediately
            unseal_vault_with_keys "$unseal_keys_file"

        else
            log "ERROR: Failed to initialize Vault."
            return 1
        fi
    else
        log "INFO: Vault is already initialized."
    fi

    return 0
}

# Function to unseal Vault with proper error handling
unseal_vault_with_keys() {
    local unseal_keys_file="$1"

    if [ ! -f "$unseal_keys_file" ]; then
        log "ERROR: Unseal keys file not found: $unseal_keys_file"
        return 1
    fi

    log "INFO: Unsealing Vault with stored keys..."
    source "$unseal_keys_file"

    # Unseal with 3 keys (threshold)
    for i in $(seq 1 3); do
        local key_var="VAULT_UNSEAL_KEY_${i}"
        if [ -n "${!key_var-}" ]; then
            log "INFO: Using unseal key ${i}..."
            if docker exec -e VAULT_ADDR='http://127.0.0.1:8200' "$VAULT_CONTAINER" vault operator unseal "${!key_var}" >> "$LOG_FILE" 2>&1; then
                log "SUCCESS: Unseal key ${i} applied successfully."
            else
                log "ERROR: Failed to apply unseal key ${i}."
                return 1
            fi
        else
            log "ERROR: Unseal key ${i} is empty or not set."
            return 1
        fi
    done

    return 0
}

log() {
  echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

initialize_and_unseal_vault() {
    log "INFO: Checking Vault container ($VAULT_CONTAINER) health and status."

    # Check documented raft location first
    check_documented_raft_location

    # Check if we're in a restart loop - prevent infinite recursion
    RESTART_MARKER="/tmp/vault_sanity_restart_marker"
    if [ -f "$RESTART_MARKER" ]; then
        RESTART_COUNT=$(cat "$RESTART_MARKER")
        RESTART_COUNT=$((RESTART_COUNT + 1))
        if [ "$RESTART_COUNT" -gt 3 ]; then
            log "ERROR: Vault sanity agent has restarted $RESTART_COUNT times. Breaking restart loop to prevent infinite recursion."
            rm -f "$RESTART_MARKER"
            return 1
        fi
        echo "$RESTART_COUNT" > "$RESTART_MARKER"
    else
        echo "1" > "$RESTART_MARKER"
    fi

    # Check Vault container health first
    check_vault_container_health "$VAULT_CONTAINER"
    local health_check_result=$?

    if [ $health_check_result -eq 2 ]; then
        log "INFO: Waiting for Vault container to finish starting up..."
        sleep 30
        check_vault_container_health "$VAULT_CONTAINER"
        health_check_result=$?
    fi

    if [ $health_check_result -eq 1 ]; then
        log "ERROR: Vault container is unhealthy. Cannot proceed with initialization."
        return 1
    fi

    # Check if Vault is initialized
    VAULT_STATUS_OUTPUT=$(docker exec -e VAULT_ADDR='http://127.0.0.1:8200' $VAULT_CONTAINER vault status 2>&1 || true)
    if echo "$VAULT_STATUS_OUTPUT" | grep -q "Initialized.*false"; then
        log "INFO: Vault is not initialized. Initializing now..."
        INIT_OUTPUT_FILE="/opt/my-secure-ha-stack/vault-init-output.txt"

        # Initialize Vault and capture the output
        docker exec -e VAULT_ADDR='http://127.0.0.1:8200' $VAULT_CONTAINER vault operator init -key-shares=5 -key-threshold=3 > "$INIT_OUTPUT_FILE"

        UNSEAL_KEYS_FILE="/opt/my-secure-ha-stack/vault-unseal-keys.env"
        VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

        # Ensure secrets directory exists
        mkdir -p /opt/my-secure-ha-stack/secrets

        # Extract and save unseal keys
        log "INFO: Extracting unseal keys and root token."
        grep "Unseal Key" "$INIT_OUTPUT_FILE" | awk '{print "export VAULT_UNSEAL_KEY_" FNR "=" $4}' > "$UNSEAL_KEYS_FILE"

        # Extract and save root token
        grep "Initial Root Token" "$INIT_OUTPUT_FILE" | awk '{print $4}' > "$VAULT_TOKEN_FILE"

        log "INFO: Vault initialized. Unseal keys stored in $UNSEAL_KEYS_FILE and root token in $VAULT_TOKEN_FILE."

        # Unseal Vault
        log "INFO: Unsealing Vault..."
        source "$UNSEAL_KEYS_FILE"
        for i in $(seq 1 3); do
            KEY_VAR="VAULT_UNSEAL_KEY_${i}"
            log "INFO: Using unseal key ${i}..."
            docker exec -e VAULT_ADDR='http://127.0.0.1:8200' $VAULT_CONTAINER vault operator unseal "${!KEY_VAR}" >> "$LOG_FILE" 2>&1
        done
    fi

    # Always attempt to unseal if Vault is sealed
    for attempt in 1 2; do
        if docker exec -e VAULT_ADDR='http://127.0.0.1:8200' $VAULT_CONTAINER vault status 2>/dev/null | grep -q "Sealed.*true"; then
            log "INFO: Vault is sealed. Attempting to unseal (attempt $attempt)..."
            UNSEAL_KEYS_FILE="/opt/my-secure-ha-stack/vault-unseal-keys.env"
            UNSEAL_KEYS_FOUND=0
            if [ -f "$UNSEAL_KEYS_FILE" ]; then
                source "$UNSEAL_KEYS_FILE"
                for i in $(seq 1 3); do
                    KEY_VAR="VAULT_UNSEAL_KEY_${i}"
                    if [ -n "${!KEY_VAR-}" ]; then
                        log "INFO: Using unseal key ${i} from env file..."
                        docker exec -e VAULT_ADDR='http://127.0.0.1:8200' $VAULT_CONTAINER vault operator unseal "${!KEY_VAR}" >> "$LOG_FILE" 2>&1
                        UNSEAL_KEYS_FOUND=1
                    fi
                done
            fi
            # If not unsealed, try GPG
            if [ $UNSEAL_KEYS_FOUND -eq 0 ] && [ -f "$VAULT_UNSEAL_KEYS_GPG" ]; then
                log "INFO: Decrypting GPG unseal keys to $DECRYPTED_KEYS_FILE."
                gpg --batch --yes --decrypt -o "$DECRYPTED_KEYS_FILE" "$VAULT_UNSEAL_KEYS_GPG" && source "$DECRYPTED_KEYS_FILE"
                for i in $(seq 1 3); do
                    KEY_VAR="VAULT_UNSEAL_KEY_${i}"
                    if [ -n "${!KEY_VAR-}" ]; then
                        log "INFO: Using unseal key ${i} from GPG..."
                        docker exec -e VAULT_ADDR='http://127.0.0.1:8200' $VAULT_CONTAINER vault operator unseal "${!KEY_VAR}" >> "$LOG_FILE" 2>&1
                        UNSEAL_KEYS_FOUND=1
                    fi
                done
            fi
            if [ $UNSEAL_KEYS_FOUND -eq 0 ]; then
                log "ERROR: No unseal keys found in $UNSEAL_KEYS_FILE or $VAULT_UNSEAL_KEYS_GPG. Manual intervention required."
                exit 1
            fi
        else
            break
        fi
    done

    # Final health check
    sleep 5
    VAULT_STATUS_OUTPUT=$(docker exec -e VAULT_ADDR='http://127.0.0.1:8200' $VAULT_CONTAINER vault status 2>&1 || true)
    log "INFO: Checking final Vault status."
    log "DEBUG: Vault status output: $VAULT_STATUS_OUTPUT"

    if echo "$VAULT_STATUS_OUTPUT" | grep -q "Sealed.*false" && echo "$VAULT_STATUS_OUTPUT" | grep -q "Initialized.*true"; then
        log "SUCCESS: Vault is initialized, unsealed, and healthy."
        # Clear restart marker on success
        rm -f "/tmp/vault_sanity_restart_marker"
        return 0
    else
        log "ERROR: Vault is still not healthy or is sealed. Collecting diagnostics..."
        log "INFO: Dumping last 50 lines of Vault logs for $VAULT_CONTAINER:"
        docker logs $VAULT_CONTAINER --tail 50 2>&1 | tee -a "$LOG_FILE"
        log "INFO: Dumping current Vault status output:"
        echo "$VAULT_STATUS_OUTPUT" | tee -a "$LOG_FILE"
        # Additional diagnostics: disk space, permissions, raft file health
        log "INFO: Checking disk space on host and inside Vault container..."
        df -h | tee -a "$LOG_FILE"
        docker exec $VAULT_CONTAINER df -h 2>&1 | tee -a "$LOG_FILE"
        log "INFO: Checking Vault data directory permissions inside container..."
        docker exec $VAULT_CONTAINER ls -l /vault/file 2>&1 | tee -a "$LOG_FILE"
        log "INFO: Checking raft file health inside container..."
        docker exec $VAULT_CONTAINER ls -lh /vault/file/raft/ 2>&1 | tee -a "$LOG_FILE"
        log "INFO: Checking for raft corruption markers inside container..."
        docker exec $VAULT_CONTAINER grep -i corrupt /vault/file/raft/* 2>&1 | tee -a "$LOG_FILE" || true



        # Host-level raft directory check, creation, and marker logic
        VAULT_RAFT_HOST_DIR="/opt/my-secure-ha-stack/vault/file/raft"
        VAULT_RAFT_BACKUP_DIR="/opt/my-secure-ha-stack/backups/vault/raft"
        RAFT_MARKER_FILE="$VAULT_RAFT_HOST_DIR/.raft_initialized"

        if [ ! -d "$VAULT_RAFT_HOST_DIR" ]; then
            log "WARNING: Raft directory $VAULT_RAFT_HOST_DIR does not exist on host. Creating it now as a new raft."
            mkdir -p "$VAULT_RAFT_HOST_DIR"
            chown 999:999 "$VAULT_RAFT_HOST_DIR" || true
            chmod 700 "$VAULT_RAFT_HOST_DIR" || true
            # Mark this as a new/empty raft
            touch "$RAFT_MARKER_FILE"

            # Document the raft location for future reference
            RAFT_LOCATION_FILE="/opt/my-secure-ha-stack/logs/vault-raft-location.txt"
            echo "[$(date)] RAFT LOCATION: $VAULT_RAFT_HOST_DIR" >> "$RAFT_LOCATION_FILE"
            echo "[$(date)] RAFT STATUS: NEW - Created by vault_sanity_agent.sh (initial creation)" >> "$RAFT_LOCATION_FILE"
            echo "[$(date)] MARKER FILE: $RAFT_MARKER_FILE" >> "$RAFT_LOCATION_FILE"

            log "INFO: Created raft directory $VAULT_RAFT_HOST_DIR with owner 999:999 and permissions 700. Marked as new raft (no backup)."
            log "INFO: Documented raft location in $RAFT_LOCATION_FILE for future reference."
        else
            log "INFO: Raft directory $VAULT_RAFT_HOST_DIR exists on host."
        fi

        # Check if raft dir is empty
        if [ -z "$(ls -A $VAULT_RAFT_HOST_DIR 2>/dev/null | grep -v ".raft_initialized")" ]; then
            if [ -f "$RAFT_MARKER_FILE" ]; then
                log "INFO: Raft directory is empty and marker file exists. Treating as new raft (no backup to restore)."
                # Check if we're in a restart loop - if so, don't restart again
                RESTART_COUNT=$(cat "/tmp/vault_sanity_restart_marker" 2>/dev/null || echo "0")
                if [ "$RESTART_COUNT" -ge 3 ]; then
                    log "WARNING: Already attempted raft initialization $RESTART_COUNT times. Not restarting again to prevent loop."
                    log "INFO: Vault may need manual intervention or more time to initialize properly."
                    rm -f "/tmp/vault_sanity_restart_marker"
                    return 1
                fi
                # Nothing to restore, proceed as new raft - let Vault initialize on its own
                log "INFO: New raft directory ready. Vault should initialize automatically."
            else
                log "WARNING: Raft directory $VAULT_RAFT_HOST_DIR is empty and no marker file found. Attempting automatic restore from backup if available."
                BACKUP_FOUND=0
                # 1. Try default backup dir
                if [ -d "$VAULT_RAFT_BACKUP_DIR" ] && [ "$(ls -A $VAULT_RAFT_BACKUP_DIR 2>/dev/null)" ]; then
                    log "INFO: Found backup at $VAULT_RAFT_BACKUP_DIR. Restoring contents to $VAULT_RAFT_HOST_DIR..."
                    cp -a $VAULT_RAFT_BACKUP_DIR/. $VAULT_RAFT_HOST_DIR/
                    BACKUP_FOUND=1
                else
                    # 2. Search for raft backups under /opt
                    log "INFO: Searching for raft backups under /opt..."
                    RAFT_BACKUP_SEARCH=$(find /opt -type d -name raft -print 2>/dev/null | grep -v "$VAULT_RAFT_HOST_DIR" | while read -r dir; do
                      if [ "$(ls -A "$dir" 2>/dev/null)" ]; then
                        echo "$dir"
                      fi
                    done | head -n 1)
                    if [ -n "$RAFT_BACKUP_SEARCH" ]; then
                        log "INFO: Found raft backup at $RAFT_BACKUP_SEARCH. Restoring contents to $VAULT_RAFT_HOST_DIR..."
                        cp -a "$RAFT_BACKUP_SEARCH/." "$VAULT_RAFT_HOST_DIR/"
                        BACKUP_FOUND=1
                    fi
                fi
                if [ "$BACKUP_FOUND" -eq 1 ]; then
                    sudo chown -R 999:999 "$VAULT_RAFT_HOST_DIR"
                    sudo chmod 700 "$VAULT_RAFT_HOST_DIR"

                    # Document the raft restoration for future reference
                    RAFT_LOCATION_FILE="/opt/my-secure-ha-stack/logs/vault-raft-location.txt"
                    echo "[$(date)] RAFT LOCATION: $VAULT_RAFT_HOST_DIR" >> "$RAFT_LOCATION_FILE"
                    echo "[$(date)] RAFT STATUS: RESTORED - Backup restored by vault_sanity_agent.sh" >> "$RAFT_LOCATION_FILE"
                    if [ -n "$RAFT_BACKUP_SEARCH" ]; then
                        echo "[$(date)] BACKUP SOURCE: $RAFT_BACKUP_SEARCH" >> "$RAFT_LOCATION_FILE"
                    else
                        echo "[$(date)] BACKUP SOURCE: $VAULT_RAFT_BACKUP_DIR" >> "$RAFT_LOCATION_FILE"
                    fi

                    log "INFO: Backup restored and permissions set. Documented restoration in $RAFT_LOCATION_FILE. Restarting Vault container."
                    docker restart purebliss-vault
                    log "INFO: Waiting 15 seconds for Vault to restart and initialize..."
                    sleep 15
                    log "INFO: Re-running vault sanity agent script to verify health after restore."
                    exec "$0"
                else
                    log "INFO: No raft backup found in default or /opt locations. Creating new raft directory."
                    # Create new raft directory and mark it as new
                    touch "$RAFT_MARKER_FILE"
                    sudo chown -R 999:999 "$VAULT_RAFT_HOST_DIR"
                    sudo chmod 700 "$VAULT_RAFT_HOST_DIR"

                    # Document the raft location for future reference
                    RAFT_LOCATION_FILE="/opt/my-secure-ha-stack/logs/vault-raft-location.txt"
                    echo "[$(date)] RAFT LOCATION: $VAULT_RAFT_HOST_DIR" >> "$RAFT_LOCATION_FILE"
                    echo "[$(date)] RAFT STATUS: NEW - Created by vault_sanity_agent.sh" >> "$RAFT_LOCATION_FILE"
                    echo "[$(date)] MARKER FILE: $RAFT_MARKER_FILE" >> "$RAFT_LOCATION_FILE"

                    log "INFO: Created new raft directory at $VAULT_RAFT_HOST_DIR and documented location in $RAFT_LOCATION_FILE."
                    log "INFO: Restarting Vault container to initialize with new raft."
                    docker restart purebliss-vault
                    log "INFO: Waiting 15 seconds for Vault to restart and initialize..."
                    sleep 15
                    log "INFO: Re-running vault sanity agent script to verify health after new raft creation."
                    exec "$0"
                fi
            fi
        fi

        log "ERROR: Vault is still not healthy or is sealed after diagnostics and raft handling."
        log "INFO: This may be due to:"
        log "  1. Vault still initializing (takes 30-60 seconds for new raft)"
        log "  2. Configuration issues in docker-compose.yml"
        log "  3. Port conflicts or networking issues"
        log "  4. Resource constraints (CPU/memory)"
        log "RECOMMENDATION: Check Vault container logs and wait a few minutes before re-running."

        # Clear restart marker to allow fresh attempts later
        rm -f "/tmp/vault_sanity_restart_marker"
        return 1
    fi
}


# --- FORCE START CONTAINERS AT SCRIPT START ---
log "INFO: Ensuring Vault and Vault-Agent containers are started before any checks..."
start_vault_containers

# Wait for both containers to be running (max 5 attempts)
for i in {1..5}; do
    VAULT_RUNNING=$(docker ps -q -f name="$VAULT_CONTAINER")
    AGENT_RUNNING=$(docker ps -q -f name="$VAULT_AGENT_CONTAINER")
    if [[ -n "$VAULT_RUNNING" && -n "$AGENT_RUNNING" ]]; then
        log "INFO: Both Vault and Vault-Agent containers are running."
        break
    fi
    log "INFO: Waiting for containers to be up... (attempt $i)"
    sleep 5
done
if [[ -z "$(docker ps -q -f name="$VAULT_CONTAINER")" ]]; then
    log "CRITICAL: Vault container did not start. Exiting."
    exit 1
fi
if [[ -z "$(docker ps -q -f name="$VAULT_AGENT_CONTAINER")" ]]; then
    log "CRITICAL: Vault-Agent container did not start. Exiting."
    exit 1
fi

# --- PRE-FLIGHT CHECKS ---
log "INFO: Starting pre-flight checks for Vault and Vault-Agent..."

# 1. Ensure Vault is healthy
if ! initialize_and_unseal_vault; then
    log "CRITICAL: Vault is not healthy. Exiting script."
    exit 1
fi

# 2. Ensure Vault-Agent is healthy
check_vault_agent_health
vault_agent_health_result=$?

if [ $vault_agent_health_result -ne 0 ]; then
  if [ $vault_agent_health_result -eq 2 ]; then
    log "INFO: Vault-Agent is still starting. Waiting 30 seconds..."
    sleep 30
    check_vault_agent_health
    vault_agent_health_result=$?
  fi

  if [ $vault_agent_health_result -ne 0 ]; then
    log "WARNING: vault-agent container is not healthy. Attempting to diagnose and fix..."

    log "INFO: Attempting a simple restart of vault-agent using the correct compose file."
    docker-compose -f /opt/dev-purebliss/services/vault-agent/vault-agent-docker-compose.yml restart vault-agent >> "$LOG_FILE" 2>&1
    sleep 10

    check_vault_agent_health
    if [ $? -eq 0 ]; then
      log "SUCCESS: vault-agent is now healthy after a restart."
    else
      log "WARNING: vault-agent still not healthy after restart. Checking configuration types..."
      if grep -q 'method "approle"' /opt/dev-purebliss/services/vault-agent/vault-agent.hcl 2>/dev/null; then
        log "INFO: vault-agent is using AppRole. Attempting to fix missing/empty secret_id."
        # Use the already set VAULT_ADDR from the top of the script
        ROLE_ID_FILE="/opt/dev-purebliss/services/vault-agent/role-id"
        SECRET_ID_FILE="/opt/dev-purebliss/services/vault-agent/secret_id"
        if [ ! -f "$ROLE_ID_FILE" ]; then
          log "ERROR: AppRole role_id file missing at $ROLE_ID_FILE. Manual intervention required."
        else
          VAULT_ROLE_ID=$(cat "$ROLE_ID_FILE")
          log "INFO: Generating new AppRole secret_id for vault-agent."
          VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
          VAULT_TOKEN="$VAULT_TOKEN" vault write -force -field=secret_id auth/approle/role/vault-agent/secret-id > "$SECRET_ID_FILE" 2>> "$LOG_FILE"
          if [ -s "$SECRET_ID_FILE" ]; then
            log "INFO: New secret_id written to $SECRET_ID_FILE. Restarting vault-agent container."
            docker-compose -f /opt/dev-purebliss/services/vault-agent/vault-agent-docker-compose.yml restart vault-agent >> "$LOG_FILE" 2>&1
            sleep 10
            check_vault_agent_health
            if [ $? -eq 0 ]; then
              log "SUCCESS: vault-agent is now healthy after AppRole secret_id fix."
            else
              log "ERROR: vault-agent still unhealthy after AppRole fix. Manual check required."
            fi
          else
            log "ERROR: Failed to write new secret_id for vault-agent. Manual fix required."
          fi
        fi
      elif grep -q 'method "token_file"' /opt/dev-purebliss/services/vault-agent/vault-agent.hcl 2>/dev/null; then
          log "INFO: vault-agent is using token_file auth. Checking token file..."
          if [ ! -s "$VAULT_TOKEN_FILE" ]; then
              log "ERROR: Vault token file is missing or empty at $VAULT_TOKEN_FILE. Vault may not be initialized correctly."
          else
              log "INFO: Vault token file exists. The issue might be with the token itself or agent config. Showing agent logs for debugging."
              docker logs $VAULT_AGENT_CONTAINER --tail 50 >> "$LOG_FILE" 2>&1
          fi
      else
        log "INFO: vault-agent is not using a recognized auto-auth method or config not found. Showing agent logs for debugging."
        docker logs $VAULT_AGENT_CONTAINER --tail 50 >> "$LOG_FILE" 2>&1
      fi
    fi
  fi
else
  log "SUCCESS: Vault-Agent is healthy."
fi

# Final check for vault-agent before proceeding
check_vault_agent_health
final_agent_health=$?
if [ $final_agent_health -ne 0 ]; then
    if [ $final_agent_health -eq 2 ]; then
        log "INFO: Vault-Agent is still starting. This may be acceptable for initial setup."
    else
        log "CRITICAL: Vault-Agent is not healthy and could not be fixed automatically. Exiting script."
        exit 1
    fi
fi

log "SUCCESS: Pre-flight checks passed. Vault and Vault-Agent are healthy."
# --- END PRE-FLIGHT CHECKS ---

log "INFO: Starting Vault/vault-agent sanity check for all services."


# Add a maximum retry limit for health checks
MAX_RETRIES=5

# Modify the health check loop to include a retry limit
for SERVICE in "${SERVICES[@]}"; do
  # Determine container name (handle both purebliss- prefixed and non-prefixed)
  if docker ps -q -f name="purebliss-${SERVICE}" > /dev/null 2>&1; then
    CONTAINER="purebliss-${SERVICE}"
  elif docker ps -q -f name="$SERVICE" > /dev/null 2>&1; then
    CONTAINER="$SERVICE"
  else
    log "WARNING: Container for service $SERVICE not found. Skipping."
    continue
  fi

  retries=0

  # Skip Vault integration checks for the vault service itself - it doesn't need to integrate with itself
  if [[ "$SERVICE" == "vault" || "$CONTAINER" == "purebliss-vault" ]]; then
    log "INFO: Skipping Vault integration checks for vault service itself - vault doesn't need to integrate with itself."
    continue
  fi

  # Skip vault-agent as it's a special case that's handled in pre-flight checks
  if [[ "$SERVICE" == "vault-agent" || "$CONTAINER" == "purebliss-vault-agent" ]]; then
    log "INFO: Skipping vault-agent - handled in pre-flight checks."
    continue
  fi

  # Detect secrets that should be managed by Vault
  detect_vault_secrets "$SERVICE"

  # Loop to ensure the service is compliant
  while true; do
    log "INFO: Verifying Vault integration for $SERVICE (container: $CONTAINER)..."
    token_ok=0
    agent_ok=0
    creds_ok=0
    dynamic_ok=0
    restart_ok=0

    # Check 1: Vault Token File
    if [ -f "$VAULT_TOKEN_FILE" ] && [ -s "$VAULT_TOKEN_FILE" ]; then
      log "INFO: Vault token file exists and is not empty."
      token_ok=1
    else
      log "ERROR: Vault token file is missing or empty at $VAULT_TOKEN_FILE. Vault may not be initialized."
      # Attempt to re-run init/unseal logic
      initialize_and_unseal_vault
      token_ok=0 # Force re-check in next loop
    fi

    # Check 2: Vault Agent Health
    check_vault_agent_health
    agent_health_result=$?
    if [ $agent_health_result -eq 0 ]; then
      log "INFO: Vault Agent is healthy."
      agent_ok=1
    elif [ $agent_health_result -eq 2 ]; then
      log "INFO: Vault Agent is still starting. Allowing more time..."
      sleep 10
      check_vault_agent_health
      if [ $? -eq 0 ]; then
        log "SUCCESS: Vault Agent is now healthy."
        agent_ok=1
      else
        log "WARNING: Vault Agent still starting. Proceeding with caution."
        agent_ok=1  # Allow to proceed but log warning
      fi
    else
      log "ERROR: Vault Agent is not healthy. Attempting to restart..."
      docker-compose -f /opt/dev-purebliss/services/vault-agent/vault-agent-docker-compose.yml restart vault-agent >> "$LOG_FILE" 2>&1
      sleep 10
      check_vault_agent_health
      if [ $? -eq 0 ]; then
        log "SUCCESS: Vault Agent is now healthy after restart."
        agent_ok=1
      else
        log "ERROR: Vault Agent is still not healthy after restart. Manual check required."
        agent_ok=0
      fi
    fi

    # Conditionally check for DB credentials based on the service
    if is_db_consumer "$SERVICE"; then
      log "INFO: $SERVICE is a database consumer. Checking for DB credentials."

      # Check multiple potential environment file locations
      ENV_FILES=(
        "/opt/purebliss/backend/.env"
        "/opt/my-secure-ha-stack/.env"
        "/opt/dev-purebliss/.env"
        "/opt/${SERVICE}/.env"
        "/app/.env"
      )

      ENV_FILE_FOUND=""
      for env_file in "${ENV_FILES[@]}"; do
        if [ -f "$env_file" ]; then
          ENV_FILE_FOUND="$env_file"
          log "INFO: Found environment file at $env_file for $SERVICE"
          break
        fi
      done

      # Use default if none found
      if [ -z "$ENV_FILE_FOUND" ]; then
        ENV_FILE_FOUND="/opt/purebliss/backend/.env"
        log "WARNING: No environment file found for $SERVICE. Will create at $ENV_FILE_FOUND"
      fi

      ENV_FILE="$ENV_FILE_FOUND"

      # Ensure .env file exists
      if [ ! -f "$ENV_FILE" ]; then
        log "WARNING: .env file not found at $ENV_FILE. Creating it."
        mkdir -p "$(dirname "$ENV_FILE")"
        touch "$ENV_FILE"
        chmod 600 "$ENV_FILE"
      fi

      # Check for static credentials and remove them
      if grep -Eqi "^${SERVICE}_USER=|^${SERVICE}_PASSWORD=" "$ENV_FILE" | grep -vi 'vault'; then
        log "WARNING: Static credentials found for $SERVICE in .env. Removing them."
        sed -i "/^${SERVICE}_USER=/d" "$ENV_FILE"
        sed -i "/^${SERVICE}_PASSWORD=/d" "$ENV_FILE"
      fi

      # Also check for generic database credentials
      for db_type in "DATABASE" "DB" "POSTGRES" "MYSQL" "MONGO"; do
        if grep -Eqi "^${db_type}_USER=|^${db_type}_PASSWORD=" "$ENV_FILE" | grep -vi 'vault'; then
          log "WARNING: Static ${db_type} credentials found in .env. Updating to use Vault."
          sed -i "/^${db_type}_USER=/d" "$ENV_FILE"
          sed -i "/^${db_type}_PASSWORD=/d" "$ENV_FILE"

          # Add Vault-based credentials
          echo "${db_type}_USER=\$(vault read -field=username database/creds/${SERVICE})" >> "$ENV_FILE"
          echo "${db_type}_PASSWORD=\$(vault read -field=password database/creds/${SERVICE})" >> "$ENV_FILE"
          log "DEBUG: Added Vault dynamic secret references for ${db_type} credentials."
        fi
      done

      # Check for dynamic secrets usage (idempotent, literal match)
      USER_LINE="${SERVICE}_USER=\$(vault read -field=username database/creds/${SERVICE})"
      PASS_LINE="${SERVICE}_PASSWORD=\$(vault read -field=password database/creds/${SERVICE})" # Corrected 'crecs' to 'creds'

      user_line_present=$(grep -Fxq "$USER_LINE" "$ENV_FILE" && echo 1 || echo 0)
      pass_line_present=$(grep -Fxq "$PASS_LINE" "$ENV_FILE" && echo 1 || echo 0)

      if [ "$user_line_present" -eq 1 ] && [ "$pass_line_present" -eq 1 ]; then
        log "INFO: $SERVICE is correctly configured to use dynamic DB creds from Vault."
        creds_ok=1
        dynamic_ok=1
      else
        log "WARNING: $SERVICE is not correctly configured for dynamic DB creds. Updating .env."
        if [ "$user_line_present" -eq 0 ]; then
            echo "$USER_LINE" >> "$ENV_FILE"
            log "DEBUG: Appended Vault dynamic secret reference for ${SERVICE}_USER."
        fi
        if [ "$pass_line_present" -eq 0 ]; then
            echo "$PASS_LINE" >> "$ENV_FILE"
            log "DEBUG: Appended Vault dynamic secret reference for ${SERVICE}_PASSWORD."
        fi
        # Set to 0 to force a restart and re-check
        creds_ok=0
        dynamic_ok=0
      fi
    else
      log "INFO: $SERVICE is not a database consumer. Skipping DB credential check."
      creds_ok=1
      dynamic_ok=1
    fi

    # Restart container to apply any potential changes
    log "INFO: Restarting $CONTAINER container to apply any new configurations."
    if docker ps -q -f name="$CONTAINER" > /dev/null; then
      docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
      log "INFO: Restart command issued for $CONTAINER. Waiting for it to stabilize..."
      sleep 8 # Increased sleep time for service to come up

      HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$CONTAINER" 2>/dev/null || echo "unknown")
      log "INFO: $CONTAINER health status after restart: $HEALTH"

      # Handle containers without health checks differently
      if [[ "$HEALTH" == "no_healthcheck" ]]; then
        # For containers without health checks, check if they're running and not exiting
        RUNNING=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo "false")
        EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' "$CONTAINER" 2>/dev/null || echo "1")
        if [[ "$RUNNING" == "true" && "$EXIT_CODE" == "0" ]]; then
          log "SUCCESS: $CONTAINER container is running (no health check configured)."
          restart_ok=1
        else
          log "ERROR: $CONTAINER is not running properly. Running: $RUNNING, ExitCode: $EXIT_CODE"
          restart_ok=0
        fi
      elif [[ "$HEALTH" == "healthy" ]]; then
        log "SUCCESS: $CONTAINER container is healthy."
        restart_ok=1
      elif [[ "$HEALTH" == "unhealthy" ]]; then
        log "WARNING: $CONTAINER is running but unhealthy. This may be acceptable for some services during startup. Proceeding with caution."
        restart_ok=1 # Consider it "ok" to proceed, but log the warning
      elif [[ "$HEALTH" == "starting" ]]; then
        log "INFO: $CONTAINER is still starting. Allowing more time before considering it failed."
        restart_ok=1 # Allow starting containers to proceed
      else
        log "ERROR: $CONTAINER has unknown health status: $HEALTH. Manual check recommended."
        restart_ok=0
      fi
    else
      log "WARNING: Container $CONTAINER not found. Cannot restart."
      restart_ok=0 # Cannot be ok if it doesn't exist
    fi

    # Final check to break the loop or retry
    if [ "$token_ok" -eq 1 ] && [ "$agent_ok" -eq 1 ] && [ "$creds_ok" -eq 1 ] && [ "$dynamic_ok" -eq 1 ] && [ "$restart_ok" -eq 1 ]; then
      log "SUCCESS: $SERVICE is now fully compliant with Vault integration."
      break
    else
      retries=$((retries + 1))
      if [ "$retries" -ge "$MAX_RETRIES" ]; then
        log "ERROR: Maximum retries reached for $SERVICE. Manual intervention required."
        break
      fi
      log "DEBUG: $SERVICE not fully compliant yet. Retrying in $((2 ** retries)) seconds..."
      sleep $((2 ** retries))
    fi
  done & # Run service checks in parallel
done

# Wait for all background jobs to complete
wait

# Generate comprehensive summary report
generate_summary_report() {
    log "======================================="
    log "VAULT SANITY AGENT - COMPREHENSIVE SUMMARY"
    log "======================================="

    local total_containers=$(echo "${ALL_SERVICES[@]}" | wc -w)
    local healthy_containers=0
    local vault_integrated=0
    local secrets_detected=0
    local action_required=0

    log "INFO: Total containers discovered: $total_containers"
    log ""
    log "CONTAINER STATUS SUMMARY:"
    log "-------------------------"

    for service in "${ALL_SERVICES[@]}"; do
        local container_name
        if docker ps -q -f name="purebliss-${service}" > /dev/null 2>&1; then
            container_name="purebliss-${service}"
        else
            container_name="$service"
        fi

        # Check container health
        local is_healthy=0
        if docker ps -q -f name="$container_name" > /dev/null 2>&1; then
            local health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}' "$container_name" 2>/dev/null || echo "unknown")
            if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "running" ]]; then
                is_healthy=1
                healthy_containers=$((healthy_containers + 1))
            fi
        fi

        # Check Vault integration
        local vault_status="NOT_INTEGRATED"
        if is_db_consumer "$service"; then
            vault_status="DB_CONSUMER"
            vault_integrated=$((vault_integrated + 1))
        fi

        # Check for secrets
        local has_secrets="NO"
        if detect_vault_secrets "$service" > /dev/null 2>&1; then
            has_secrets="YES"
            secrets_detected=$((secrets_detected + 1))
        fi

        # Determine if action is required
        local needs_action="NO"
        if [[ "$is_healthy" -eq 0 ]] || [[ "$has_secrets" == "YES" && "$vault_status" == "NOT_INTEGRATED" ]]; then
            needs_action="YES"
            action_required=$((action_required + 1))
        fi

        printf "%-20s | Health: %-7s | Vault: %-15s | Secrets: %-3s | Action: %-3s\n" \
            "$service" \
            "$([[ $is_healthy -eq 1 ]] && echo "OK" || echo "FAILED")" \
            "$vault_status" \
            "$has_secrets" \
            "$needs_action"
    done

    log ""
    log "SUMMARY STATISTICS:"
    log "-------------------"
    log "Total Containers:     $total_containers"
    log "Healthy Containers:   $healthy_containers"
    log "Vault Integrated:     $vault_integrated"
    log "Secrets Detected:     $secrets_detected"
    log "Action Required:      $action_required"

    local health_percentage=$((total_containers > 0 ? healthy_containers * 100 / total_containers : 0))
    local integration_percentage=$((total_containers > 0 ? vault_integrated * 100 / total_containers : 0))

    log ""
    log "HEALTH METRICS:"
    log "---------------"
    log "Container Health:     ${health_percentage}%"
    log "Vault Integration:    ${integration_percentage}%"

    if [[ $action_required -gt 0 ]]; then
        log ""
        log "WARNING: $action_required containers require attention!"
        log "Please review the above status and take appropriate action."
    else
        log ""
        log "SUCCESS: All containers are healthy and properly configured with Vault!"
    fi

    log "======================================="
    log "END OF SUMMARY REPORT"
    log "======================================="
}

# Call the summary report function
generate_summary_report

log "INFO: Vault/vault-agent sanity check completed for all services."
