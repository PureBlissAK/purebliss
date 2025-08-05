#!/bin/bash
set -euo pipefail

# Handle command line arguments for enhanced functionality
VAULT_ONLY_MODE=false
SECRETS_DETECTION_ONLY=false
FORCE_VAULT_INIT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --vault-only)
            VAULT_ONLY_MODE=true
            shift
            ;;
        --detect-secrets-only)
            SECRETS_DETECTION_ONLY=true
            shift
            ;;
        --force-vault-init)
            FORCE_VAULT_INIT=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --vault-only           Run only Vault-related operations"
            echo "  --detect-secrets-only  Run only secret detection via Vault agent"
            echo "  --force-vault-init     Force Vault initialization even if token exists"
            echo "  --help                 Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
POSTGRES_HOST="dev.purebliss.app"
POSTGRES_PORT="5432"

# Vault configuration
VAULT_ADDR="https://purebliss.app/vault:8200"
VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token 2>/dev/null || echo "")
VAULT_SANITY_AGENT="/opt/my-secure-ha-stack/orchestrator/agents/vault_sanity_agent.sh"

# Function to invoke Vault sanity agent for comprehensive secrets management
invoke_vault_sanity_agent() {
    local operation="$1"
    local service="${2:-}"

    log "INFO: Invoking Vault sanity agent for $operation"

    if [[ ! -f "$VAULT_SANITY_AGENT" ]]; then
        log "WARNING: Vault sanity agent not found at $VAULT_SANITY_AGENT. Skipping Vault integration."
        return 1
    fi

    case "$operation" in
        "initialize")
            log "INFO: Initializing and unsealing Vault via sanity agent..."
            bash "$VAULT_SANITY_AGENT" --initialize-only >> "$LOG_FILE" 2>&1
            if [[ $? -eq 0 ]]; then
                log "SUCCESS: Vault initialized and unsealed successfully"
                # Refresh token after initialization
                VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token 2>/dev/null || echo "")
                return 0
            else
                log "ERROR: Failed to initialize Vault via sanity agent"
                return 1
            fi
            ;;
        "detect_secrets")
            if [[ -n "$service" ]]; then
                log "INFO: Running Vault secret detection for service: $service"
                bash "$VAULT_SANITY_AGENT" --service "$service" --detect-only >> "$LOG_FILE" 2>&1
            else
                log "INFO: Running comprehensive Vault secret detection for all services"
                bash "$VAULT_SANITY_AGENT" --detect-all >> "$LOG_FILE" 2>&1
            fi
            ;;
        "store_postgres_secrets")
            log "INFO: Storing PostgreSQL secrets in Vault via sanity agent"
            # Create a temporary script to store PostgreSQL secrets
            local temp_script="/tmp/store_postgres_secrets.sh"
            cat > "$temp_script" << 'EOF'
#!/bin/bash
source /opt/my-secure-ha-stack/orchestrator/agents/vault_sanity_agent.sh
# Store PostgreSQL admin secrets
vault kv put secret/postgres/admin \
    username="postgres" \
    password="postgres" \
    database="postgres"
# Store service database secrets
vault kv put secret/database/plane username="plane" password="$(openssl rand -base64 32)" database="plane"
vault kv put secret/database/vikunja username="vikunja" password="$(openssl rand -base64 32)" database="vikunja"
vault kv put secret/database/keycloak username="keycloak" password="$(openssl rand -base64 32)" database="keycloak"
vault kv put secret/database/grafana username="grafana" password="$(openssl rand -base64 32)" database="grafana"
EOF
            chmod +x "$temp_script"
            bash "$temp_script" >> "$LOG_FILE" 2>&1
            rm -f "$temp_script"
            ;;
        *)
            log "ERROR: Unknown Vault sanity agent operation: $operation"
            return 1
            ;;
    esac
}

# Function to store secrets in Vault
store_vault_secret() {
    local secret_path="$1"
    local secret_data="$2"

    if [[ -z "$VAULT_TOKEN" ]]; then
        log "WARNING: Vault token not available. Cannot store secret at $secret_path."
        return 1
    fi

    local response=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$secret_data" \
        "$VAULT_ADDR/v1/$secret_path")

    if [[ $? -eq 0 ]]; then
        log "SUCCESS: Secret stored in Vault at $secret_path"
        return 0
    else
        log "ERROR: Failed to store secret in Vault at $secret_path"
        return 1
    fi
}

# Function to ensure PostgreSQL admin credentials are in Vault
ensure_postgres_admin_secrets() {
    log "INFO: Ensuring PostgreSQL admin credentials are stored in Vault..."

    # Check if admin secrets exist in Vault
    local existing_user=$(get_vault_secret "secret/postgres/admin" "username")

    if [[ -z "$existing_user" || "$existing_user" == "null" ]]; then
        log "INFO: PostgreSQL admin secrets not found in Vault. Creating them..."

        # Store default admin credentials in Vault
        local admin_data='{
            "data": {
                "username": "postgres",
                "password": "postgres",
                "database": "postgres"
            }
        }'

        if store_vault_secret "secret/postgres/admin" "$admin_data"; then
            log "SUCCESS: PostgreSQL admin credentials stored in Vault"
            # Refresh variables from Vault
            POSTGRES_ADMIN_USER=$(get_vault_secret "secret/postgres/admin" "username")
            POSTGRES_ADMIN_PASSWORD=$(get_vault_secret "secret/postgres/admin" "password")
            POSTGRES_ADMIN_DB=$(get_vault_secret "secret/postgres/admin" "database")
        else
            log "WARNING: Failed to store admin credentials in Vault, using fallback values"
        fi
    else
        log "SUCCESS: PostgreSQL admin credentials found in Vault"
    fi
}
# Enhanced function to get secrets from Vault with better error handling
get_vault_secret() {
    local secret_path="$1"
    local secret_key="$2"

    if [[ -z "$VAULT_TOKEN" ]]; then
        # Use echo to stderr to avoid polluting stdout (which is captured for variables)
        echo "WARNING: Vault token not found. Cannot retrieve secrets. Using fallback." >&2
        return 1
    fi

    # Use the vault sanity agent if available for better secret retrieval
    if [[ -f "$VAULT_SANITY_AGENT" ]]; then
        echo "DEBUG: Using Vault sanity agent for secret retrieval" >&2
        # Source the vault sanity agent functions if possible
        local vault_result=$(bash -c "
            export VAULT_ADDR='$VAULT_ADDR'
            export VAULT_TOKEN='$VAULT_TOKEN'
            vault kv get -field='$secret_key' '$secret_path' 2>/dev/null || echo 'VAULT_ERROR'
        ")

        if [[ "$vault_result" != "VAULT_ERROR" && -n "$vault_result" ]]; then
            echo "$vault_result"
            return 0
        fi
    fi

    # Fallback to direct API call
    local secret_value=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
        "$VAULT_ADDR/v1/$secret_path" | \
        jq -r ".data.data.${secret_key}" 2>/dev/null)

    if [[ "$secret_value" == "null" || -z "$secret_value" ]]; then
        echo "WARNING: Could not retrieve $secret_key from $secret_path. Using fallback." >&2
        return 1
    fi

    echo "$secret_value"
    return 0
}

# Get PostgreSQL admin credentials from Vault (moved after log function definition)
# POSTGRES_ADMIN_USER, POSTGRES_ADMIN_PASSWORD, POSTGRES_ADMIN_DB will be set later

log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# Now get PostgreSQL admin credentials from Vault
POSTGRES_ADMIN_USER=$(get_vault_secret "secret/postgres/admin" "username" || echo "postgres")
POSTGRES_ADMIN_PASSWORD=$(get_vault_secret "secret/postgres/admin" "password" || echo "postgres_admin_password")
POSTGRES_ADMIN_DB=$(get_vault_secret "secret/postgres/admin" "database" || echo "postgres")


# List of services that require database backends
DB_CONSUMER_SERVICES=("plane" "vikunja" "keycloak" "grafana")

# List of services that require Redis caching
REDIS_CONSUMER_SERVICES=("plane" "vikunja" "keycloak" "grafana")

# Redis configuration
REDIS_HOST="dev.purebliss.app"
REDIS_PORT="6379"
REDIS_CONTAINER="purebliss-redis"
# Helper function to check if a service is a DB consumer
is_redis_consumer() {
    local service="$1"
    for consumer in "${REDIS_CONSUMER_SERVICES[@]}"; do
        if [[ "$consumer" == "$service" ]]; then
            return 0
        fi
    done
    # Optionally, add dynamic detection here (env/volumes)
    return 1
}

# Function to test Redis connection from within the redis container
test_redis_connection() {
    local host="$1"
    local port="$2"
    log "INFO: Testing Redis connection to $host:$port"
    if docker exec "$REDIS_CONTAINER" redis-cli -h "$host" -p "$port" PING | grep -q PONG; then
        log "SUCCESS: Redis connection to $host:$port successful"
        return 0
    else
        log "ERROR: Redis connection to $host:$port failed"
        return 1
    fi
}

# Function to check and remediate service Redis configuration
check_service_redis_config() {
    local service="$1"
    local container="purebliss-${service}"
    if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
        container="$service"
        if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
            log "WARNING: Container $container not found for Redis check"
            return 1
        fi
    fi
    log "INFO: Checking Redis configuration for $service"
    local env_vars=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}}' 2>/dev/null || true)
    local has_correct_host=$(echo "$env_vars" | grep -E "(REDIS_HOST|CACHE_HOST|SESSION_HOST).*$REDIS_HOST" || true)
    if [[ -z "$has_correct_host" ]]; then
        log "WARNING: $service may not be configured with correct Redis host ($REDIS_HOST)"
        # Remediation: Suggest docker update or env file edit
        log "ACTION: Please update $service container to set REDIS_HOST=$REDIS_HOST"
    else
        log "INFO: $service has correct Redis host configuration"
    fi
    local has_correct_port=$(echo "$env_vars" | grep -E "(REDIS_PORT|CACHE_PORT|SESSION_PORT).*$REDIS_PORT" || true)
    if [[ -z "$has_correct_port" ]]; then
        log "WARNING: $service may not be configured with correct Redis port ($REDIS_PORT)"
        log "ACTION: Please update $service container to set REDIS_PORT=$REDIS_PORT"
    else
        log "INFO: $service has correct Redis port configuration"
    fi
    return 0
}

# Database configuration for each service - will be populated after functions are defined
declare -A DB_CONFIGS

# Initialize database configurations - called after functions are defined
init_db_configs() {
    DB_CONFIGS=(
        ["plane"]="plane:$(get_vault_secret "secret/database/plane" "password" || echo "plane_password"):plane"
        ["vikunja"]="vikunja:$(get_vault_secret "secret/database/vikunja" "password" || echo "vikunjapassword"):vikunja"
        ["keycloak"]="keycloak:$(get_vault_secret "secret/database/keycloak" "password" || echo "keycloak_password"):keycloak"
        ["grafana"]="grafana:$(get_vault_secret "secret/database/grafana" "password" || echo "grafana_password"):grafana"
        ["letsencrypt"]="letsencrypt:$(get_vault_secret "secret/database/letsencrypt" "password" || echo "letsencrypt_password"):letsencrypt"
        ["vault"]="vault:$(get_vault_secret "secret/database/vault" "password" || echo "vault_password"):vault"
    )
}

# Helper function to check if a service is a DB consumer
is_db_consumer() {
    local service="$1"

    # Exclude services that definitely don't use databases
    case "$service" in
        "nginx"|"redis"|"loki"|"prometheus")
            return 1
            ;;
    esac

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

# Function to detect database connection issues
detect_db_connection_issues() {
    local service="$1"
    local container="purebliss-${service}"
    local issues_found=()

    if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
        container="$service"
        if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
            return 1
        fi
    fi

    log "INFO: Scanning $service for database connection issues..."

    # Check environment variables for database configuration
    local env_vars=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}}' 2>/dev/null || true)

    # Database connection patterns
    local db_patterns=(

# --- ENFORCE POSTGRESQL BACKEND FOR ALL DB CONSUMERS (EXCEPT VAULT) ---
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

    # Skip PostgreSQL/Redis integration checks for the postgres service itself and for vault
    if [[ "$SERVICE" == "postgres" || "$CONTAINER" == "purebliss-postgres" || "$SERVICE" == "vault" || "$CONTAINER" == "purebliss-vault" ]]; then
        log "INFO: Skipping PostgreSQL/Redis integration checks for $SERVICE."
        continue
    fi

    # --- ENFORCE POSTGRESQL BACKEND ---
    if is_db_consumer "$SERVICE"; then
        # Check for non-Postgres backend (e.g., SQLite, MySQL) in env/config
        backend_detected="postgresql"
        env_vars=$(docker inspect "$CONTAINER" --format '{{range .Config.Env}}{{.}} {{end}}' 2>/dev/null || true)
        has_sqlite=$(echo "$env_vars" | grep -i "sqlite" || true)
        has_mysql=$(echo "$env_vars" | grep -i "mysql" || true)
        has_postgres=$(echo "$env_vars" | grep -i "postgres" || true)
        if [[ -n "$has_sqlite" ]]; then
            backend_detected="sqlite"
        elif [[ -n "$has_mysql" ]]; then
            backend_detected="mysql"
        elif [[ -z "$has_postgres" ]]; then
            backend_detected="unknown"
        fi

        if [[ "$backend_detected" != "postgresql" ]]; then
            log "WARNING: $SERVICE is NOT using PostgreSQL as backend (detected: $backend_detected). Attempting remediation."
            # Attempt remediation for Grafana (force config to use Postgres)
            if [[ "$SERVICE" == "grafana" ]]; then
                log "ACTION: Forcing Grafana to use PostgreSQL backend."
                GRAFANA_DB_PASSWORD=$(get_vault_secret "secret/database/grafana" "password" || echo "grafana_password")
                docker exec -e GRAFANA_DB_PASSWORD="$GRAFANA_DB_PASSWORD" "$CONTAINER" bash -c '
                  sed -i "/^;*type[ ]*=.*/c\\type = postgres" /etc/grafana/grafana.ini
                  sed -i "/^;*host[ ]*=.*/c\\host = dev.purebliss.app:5432" /etc/grafana/grafana.ini
                  sed -i "/^;*name[ ]*=.*/c\\name = grafana" /etc/grafana/grafana.ini
                  sed -i "/^;*user[ ]*=.*/c\\user = grafana" /etc/grafana/grafana.ini
                  sed -i "/^;*password[ ]*=.*/c\\password = $GRAFANA_DB_PASSWORD" /etc/grafana/grafana.ini
                  sed -i "/^;*ssl_mode[ ]*=.*/c\\ssl_mode = disable" /etc/grafana/grafana.ini
                '
                docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
                sleep 10
            else
                log "ERROR: $SERVICE is not using PostgreSQL and cannot be auto-remediated. Manual intervention required."
            fi
        else
            log "INFO: $SERVICE is using PostgreSQL as backend."
        fi
    fi

    # --- SMART REMEDIATION LOGIC FOR DB/REDIS CONSUMERS ---
    if is_db_consumer "$SERVICE"; then
        warning_found=0
        if detect_db_connection_issues "$SERVICE"; then
            log "ACTION: Attempting remediation for $SERVICE database connection issues."
            # Remediation: force database/user recreation and config check
            create_database_and_user "$SERVICE"
            check_service_db_config "$SERVICE"
            # Re-check for warnings
            if detect_db_connection_issues "$SERVICE"; then
                log "WARNING: $SERVICE still has DB connection issues after remediation. Debugging..."
                docker logs "$CONTAINER" --tail 50 | grep -iE "error|fail|critical" | tee -a "$LOG_FILE"
            else
                log "SUCCESS: $SERVICE DB issues remediated."
            fi
        fi
    fi

    # If service is a Redis consumer, ensure all Redis warnings are remediated
    if is_redis_consumer "$SERVICE"; then
        if check_service_redis_config "$SERVICE"; then
            if ! test_redis_connection "$REDIS_HOST" "$REDIS_PORT"; then
                log "ACTION: Attempting remediation for $SERVICE Redis connection."
                # Remediation: restart service and re-check
                docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
                sleep 5
                if ! test_redis_connection "$REDIS_HOST" "$REDIS_PORT"; then
                    log "WARNING: $SERVICE still has Redis connection issues after remediation. Debugging..."
                    docker logs "$CONTAINER" --tail 50 | grep -iE "error|fail|critical" | tee -a "$LOG_FILE"
                else
                    log "SUCCESS: $SERVICE Redis issues remediated."
                fi
            fi
        fi
    fi

    # If not a DB or Redis consumer, skip further checks
    if ! is_db_consumer "$SERVICE" && ! is_redis_consumer "$SERVICE"; then
        log "INFO: $SERVICE does not require PostgreSQL or Redis. Skipping integration checks."
        continue
    fi

    # --- AUTO-FIX LOOP ---
    log "INFO: Applying auto-fix for $SERVICE..."
    for attempt in {1..3}; do
        log "INFO: Auto-fix attempt $attempt for $SERVICE"

        # 0. Run Vault secret detection for this specific service
        if [[ -n "$VAULT_TOKEN" ]]; then
            log "INFO: Running Vault secret detection for $SERVICE"
            invoke_vault_sanity_agent "detect_secrets" "$SERVICE"
        fi

        # 1. Fix container health issues
        if ! docker ps -q -f name="$CONTAINER" > /dev/null 2>&1; then
            log "FIX: Starting stopped container $CONTAINER"
            docker start "$CONTAINER" >> "$LOG_FILE" 2>&1
            sleep 5
        fi

        # 2. Check and fix unhealthy containers
        health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$CONTAINER" 2>/dev/null || echo "unknown")
        if [[ "$health" == "unhealthy" ]]; then
            log "FIX: Restarting unhealthy container $CONTAINER"
            docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
            sleep 10
        fi

        # 3. Fix database setup for DB consumers
        if is_db_consumer "$SERVICE"; then
            log "FIX: Ensuring database setup for $SERVICE"
            create_database_and_user "$SERVICE"
        fi

        # 4. For specific service fixes
        case "$SERVICE" in
            "prometheus")
                if ! docker exec "$CONTAINER" promtool check config /etc/prometheus/prometheus.yml >> "$LOG_FILE" 2>&1; then
                    log "FIX: Prometheus config invalid, attempting restart with default config"
                    docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
                    sleep 10
                fi
                ;;
            "grafana")
                docker exec "$CONTAINER" chown -R grafana:grafana /var/lib/grafana >> "$LOG_FILE" 2>&1
                ;;
            "keycloak")
                log "INFO: Giving Keycloak additional startup time"
                sleep 15
                ;;
            "vault")
                if [[ -f "$VAULT_SANITY_AGENT" ]]; then
                    log "FIX: Running Vault sanity agent for vault service health"
                    invoke_vault_sanity_agent "initialize"
                fi
                ;;
        esac

        # Give service time to stabilize
        sleep 10

        # Check if service is now compliant
        compliant=1
        if ! docker ps -q -f name="$CONTAINER" > /dev/null 2>&1; then
            log "FAIL: Container $CONTAINER is not running"
            compliant=0
        fi
        health_check=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$CONTAINER" 2>/dev/null || echo "unknown")
        if [[ "$health_check" == "unhealthy" ]]; then
            log "FAIL: Container $CONTAINER is unhealthy"
            compliant=0
        elif [[ "$health_check" == "starting" ]]; then
            log "INFO: Container $CONTAINER is still starting"
            compliant=0
        fi
        if is_db_consumer "$SERVICE"; then
            if ! create_database_and_user "$SERVICE" > /dev/null 2>&1; then
                log "FAIL: Database setup issue for $SERVICE"
                compliant=0
            fi
        fi

        if [[ $compliant -eq 1 ]]; then
            log "SUCCESS: $SERVICE is now 100% compliant"
            break
        else
            log "WARNING: $SERVICE still not compliant after attempt $attempt"
            if [ $attempt -eq 3 ]; then
                log "ERROR: Failed to fix $SERVICE after 3 attempts. Running deep diagnostics."
                # --- ENHANCED DIAGNOSTICS FOR KEYCLOAK AND PROMETHEUS ---
                if [[ "$SERVICE" == "keycloak" ]]; then
                    log "DIAG: Collecting Keycloak DB env/config and logs for analysis."
                    docker exec "$CONTAINER" printenv | grep -i 'DB\|POSTGRES\|DATABASE' >> "$LOG_FILE" 2>&1 || true
                    docker exec "$CONTAINER" cat /opt/keycloak/conf/keycloak.conf >> "$LOG_FILE" 2>&1 || true
                    docker logs "$CONTAINER" --tail 100 >> "$LOG_FILE" 2>&1 || true
                    log "DIAG: Attempting forced DB/user recreation for Keycloak."
                    create_database_and_user "$SERVICE"
                    check_service_db_config "$SERVICE"
                fi
                if [[ "$SERVICE" == "prometheus" ]]; then
                    log "DIAG: Collecting Prometheus config and logs for analysis."
                    docker exec "$CONTAINER" cat /etc/prometheus/prometheus.yml >> "$LOG_FILE" 2>&1 || true
                    docker logs "$CONTAINER" --tail 100 >> "$LOG_FILE" 2>&1 || true
                    log "DIAG: Attempting config validation and forced restart for Prometheus."
                    docker exec "$CONTAINER" promtool check config /etc/prometheus/prometheus.yml >> "$LOG_FILE" 2>&1 || true
                    docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1 || true
                fi
                # For all, collect last 100 lines of logs for post-mortem
                docker logs "$CONTAINER" --tail 100 >> "$LOG_FILE" 2>&1 || true
            else
                log "INFO: Retrying auto-fix for $SERVICE in 5 seconds..."
                sleep 5
            fi
        fi
    done
done
    if [[ -z "$has_correct_port" ]]; then
        log "WARNING: $service may not be configured with correct database port ($POSTGRES_PORT)"
    else
        log "INFO: $service has correct database port configuration"
    fi

    # Check for database name configuration
    local has_db_name=$(echo "$env_vars" | grep -E "(DB_NAME|DATABASE_NAME).*$db_name" || true)
    if [[ -z "$has_db_name" ]]; then
        log "WARNING: $service may not be configured with correct database name ($db_name)"
    else
        log "INFO: $service has correct database name configuration"
        config_ok=1
    fi

    return $config_ok
}

log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# Function to discover all running containers and extract service names
discover_services() {
    local services=()

    # Get all running containers with purebliss- prefix
    local containers=$(docker ps --format "{{.Names}}" | grep "^purebliss-" | sort)

    for container in $containers; do
        # Extract service name by removing purebliss- prefix
        local service_name="${container#purebliss-}"
        # Only add if service_name is a valid identifier (alphanumeric, dash, underscore, no spaces or brackets)
        if [[ "$service_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            services+=("$service_name")
        fi
    done

    # Also check for containers without purebliss- prefix that might be part of our stack
    local other_containers=$(docker ps --format "{{.Names}}" | grep -v "^purebliss-" | sort)

    for container in $other_containers; do
        # Check if container has environment variables or volumes that suggest it's part of our stack
        local has_postgres_config=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}} {{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep -i postgres || true)
        local has_purebliss_config=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}} {{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep -i purebliss || true)

        # Only add if container name is valid and matches our pattern
        if [[ ( -n "$has_postgres_config" || -n "$has_purebliss_config" ) && "$container" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            services+=("$container")
        fi
    done

    if [ ${#services[@]} -eq 0 ]; then
        services=(postgres keycloak nginx plane redis grafana loki prometheus vault vikunja)
    fi

    echo "${services[@]}"
}

# Dynamically discover services
SERVICES=($(discover_services))

initialize_postgres() {
    log "INFO: Checking PostgreSQL container ($POSTGRES_CONTAINER) health and status."

    # Check if PostgreSQL container is running
    if ! docker ps -q -f name="$POSTGRES_CONTAINER" > /dev/null 2>&1; then
        log "ERROR: PostgreSQL container $POSTGRES_CONTAINER is not running."
        return 1
    fi

    # Check PostgreSQL health
    if check_postgres_health; then
        log "INFO: PostgreSQL container is healthy."
    else
        log "WARNING: PostgreSQL container is not healthy. Checking if it's still starting..."

        # Wait a bit and check again
        sleep 10
        if check_postgres_health; then
            log "INFO: PostgreSQL container is now healthy."
        else
            log "ERROR: PostgreSQL container is still not healthy. Manual intervention may be required."
            docker logs "$POSTGRES_CONTAINER" --tail 20 >> "$LOG_FILE" 2>&1
            return 1
        fi
    fi

    # Test admin connection
    if test_postgres_connection "localhost" "5432" "$POSTGRES_ADMIN_USER" "$POSTGRES_ADMIN_PASSWORD" "$POSTGRES_ADMIN_DB"; then
        log "SUCCESS: PostgreSQL admin connection successful."
        return 0
    else
        log "ERROR: PostgreSQL admin connection failed."
        return 1
    fi
}


# --- PRE-FLIGHT CHECKS ---
log "INFO: Starting pre-flight checks for Vault, PostgreSQL and Redis..."

# Initialize database configurations now that functions are defined
init_db_configs

# 0. Ensure Vault is accessible and unsealed using Vault sanity agent
log "INFO: Checking Vault accessibility via Vault sanity agent..."
if [[ -z "$VAULT_TOKEN" || "$FORCE_VAULT_INIT" == true ]]; then
    if [[ "$FORCE_VAULT_INIT" == true ]]; then
        log "INFO: Force Vault initialization requested..."
    else
        log "WARNING: Vault token not found. Attempting to initialize Vault via sanity agent..."
    fi

    if invoke_vault_sanity_agent "initialize"; then
        log "SUCCESS: Vault initialized successfully via sanity agent"
        VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token 2>/dev/null || echo "")
    else
        log "WARNING: Failed to initialize Vault. Will use fallback credentials."
    fi
fi

if [[ -n "$VAULT_TOKEN" ]]; then
    vault_status=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" | jq -r '.sealed' 2>/dev/null || echo "unknown")
    if [[ "$vault_status" == "false" ]]; then
        log "SUCCESS: Vault is accessible and unsealed."

        # Ensure PostgreSQL secrets are properly managed by Vault
        ensure_postgres_admin_secrets

        # Run comprehensive secret detection for all services
        log "INFO: Running Vault secret detection for all services..."
        invoke_vault_sanity_agent "detect_secrets"

        # Store PostgreSQL-specific secrets if not already present
        invoke_vault_sanity_agent "store_postgres_secrets"

    else
        log "WARNING: Vault is not accessible or sealed. Will use fallback credentials."
        VAULT_TOKEN=""  # Clear token to force fallback
    fi
else
    log "WARNING: Unable to obtain Vault token. Using fallback credentials."
fi

POSTGRES_CONTAINER="purebliss-postgres"

# 1. Ensure PostgreSQL is healthy
if ! initialize_postgres; then
    log "CRITICAL: PostgreSQL is not healthy. Exiting script."
    exit 1
fi

# 2. Ensure Redis is healthy
if ! docker ps -q -f name="$REDIS_CONTAINER" > /dev/null 2>&1; then
    log "CRITICAL: Redis container $REDIS_CONTAINER is not running. Exiting script."
    exit 1
fi
if test_redis_connection "$REDIS_HOST" "$REDIS_PORT"; then
    log "SUCCESS: Redis is healthy."
else
    log "CRITICAL: Redis is not healthy. Exiting script."
    exit 1
fi

log "SUCCESS: Pre-flight checks passed. PostgreSQL and Redis are healthy."
# --- END PRE-FLIGHT CHECKS ---

log "INFO: Starting PostgreSQL sanity check for all services."
log "INFO: Mode: $([ "$VAULT_ONLY_MODE" = true ] && echo "VAULT_ONLY" || [ "$SECRETS_DETECTION_ONLY" = true ] && echo "SECRETS_DETECTION_ONLY" || echo "FULL_INTEGRATION")"

# Handle special modes
if [[ "$SECRETS_DETECTION_ONLY" == true ]]; then
    log "INFO: Running secrets detection mode only..."
    invoke_vault_sanity_agent "detect_secrets"
    log "INFO: Secrets detection completed. Exiting."
    exit 0
fi

if [[ "$VAULT_ONLY_MODE" == true ]]; then
    log "INFO: Running Vault-only mode..."
    invoke_vault_sanity_agent "initialize"
    invoke_vault_sanity_agent "store_postgres_secrets"
    invoke_vault_sanity_agent "detect_secrets"
    log "INFO: Vault operations completed. Exiting."
    exit 0
fi

# Add a maximum retry limit for health checks
MAX_RETRIES=3

# Store all services for summary report
ALL_SERVICES=("${SERVICES[@]}")



# Sequentially process each service, pausing for manual confirmation if not 100% compliant
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

    # Skip PostgreSQL/Redis integration checks for the postgres service itself and for vault
    if [[ "$SERVICE" == "postgres" || "$CONTAINER" == "purebliss-postgres" || "$SERVICE" == "vault" || "$CONTAINER" == "purebliss-vault" ]]; then
        log "INFO: Skipping PostgreSQL/Redis integration checks for $SERVICE."
        continue
    fi

    # --- SMART REMEDIATION LOGIC FOR DB/REDIS CONSUMERS ---
    # If service is a DB consumer, ensure all DB warnings are remediated
    if is_db_consumer "$SERVICE"; then
        warning_found=0
        if detect_db_connection_issues "$SERVICE"; then
            log "ACTION: Attempting remediation for $SERVICE database connection issues."
            # Remediation: force database/user recreation and config check
            create_database_and_user "$SERVICE"
            check_service_db_config "$SERVICE"
            # Re-check for warnings
            if detect_db_connection_issues "$SERVICE"; then
                log "WARNING: $SERVICE still has DB connection issues after remediation. Debugging..."
                docker logs "$CONTAINER" --tail 50 | grep -iE "error|fail|critical" | tee -a "$LOG_FILE"
            else
                log "SUCCESS: $SERVICE DB issues remediated."
            fi
        fi
    fi

    # If service is a Redis consumer, ensure all Redis warnings are remediated
    if is_redis_consumer "$SERVICE"; then
        if check_service_redis_config "$SERVICE"; then
            if ! test_redis_connection "$REDIS_HOST" "$REDIS_PORT"; then
                log "ACTION: Attempting remediation for $SERVICE Redis connection."
                # Remediation: restart service and re-check
                docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
                sleep 5
                if ! test_redis_connection "$REDIS_HOST" "$REDIS_PORT"; then
                    log "WARNING: $SERVICE still has Redis connection issues after remediation. Debugging..."
                    docker logs "$CONTAINER" --tail 50 | grep -iE "error|fail|critical" | tee -a "$LOG_FILE"
                else
                    log "SUCCESS: $SERVICE Redis issues remediated."
                fi
            fi
        fi
    fi

    # If not a DB or Redis consumer, skip further checks
    if ! is_db_consumer "$SERVICE" && ! is_redis_consumer "$SERVICE"; then
        log "INFO: $SERVICE does not require PostgreSQL or Redis. Skipping integration checks."
        continue
    fi

    # --- AUTO-FIX LOOP ---
    log "INFO: Applying auto-fix for $SERVICE..."
    for attempt in {1..3}; do
        log "INFO: Auto-fix attempt $attempt for $SERVICE"

        # 0. Run Vault secret detection for this specific service
        if [[ -n "$VAULT_TOKEN" ]]; then
            log "INFO: Running Vault secret detection for $SERVICE"
            invoke_vault_sanity_agent "detect_secrets" "$SERVICE"
        fi

        # 1. Fix container health issues
        if ! docker ps -q -f name="$CONTAINER" > /dev/null 2>&1; then
            log "FIX: Starting stopped container $CONTAINER"
            docker start "$CONTAINER" >> "$LOG_FILE" 2>&1
            sleep 5
        fi

        # 2. Check and fix unhealthy containers
        health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$CONTAINER" 2>/dev/null || echo "unknown")
        if [[ "$health" == "unhealthy" ]]; then
            log "FIX: Restarting unhealthy container $CONTAINER"
            docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
            sleep 10
        fi

        # 3. Fix database setup for DB consumers
        if is_db_consumer "$SERVICE"; then
            log "FIX: Ensuring database setup for $SERVICE"
            create_database_and_user "$SERVICE"
        fi

        # 4. For specific service fixes
        case "$SERVICE" in
            "prometheus")
                if ! docker exec "$CONTAINER" promtool check config /etc/prometheus/prometheus.yml >> "$LOG_FILE" 2>&1; then
                    log "FIX: Prometheus config invalid, attempting restart with default config"
                    docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
                    sleep 10
                fi
                ;;
            "grafana")
                docker exec "$CONTAINER" chown -R grafana:grafana /var/lib/grafana >> "$LOG_FILE" 2>&1
                ;;
            "keycloak")
                log "INFO: Giving Keycloak additional startup time"
                sleep 15
                ;;
            "vault")
                if [[ -f "$VAULT_SANITY_AGENT" ]]; then
                    log "FIX: Running Vault sanity agent for vault service health"
                    invoke_vault_sanity_agent "initialize"
                fi
                ;;
        esac

        # Give service time to stabilize
        sleep 10

        # Check if service is now compliant
        compliant=1
        if ! docker ps -q -f name="$CONTAINER" > /dev/null 2>&1; then
            log "FAIL: Container $CONTAINER is not running"
            compliant=0
        fi
        health_check=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$CONTAINER" 2>/dev/null || echo "unknown")
        if [[ "$health_check" == "unhealthy" ]]; then
            log "FAIL: Container $CONTAINER is unhealthy"
            compliant=0
        elif [[ "$health_check" == "starting" ]]; then
            log "INFO: Container $CONTAINER is still starting"
            compliant=0
        fi
        if is_db_consumer "$SERVICE"; then
            if ! create_database_and_user "$SERVICE" > /dev/null 2>&1; then
                log "FAIL: Database setup issue for $SERVICE"
                compliant=0
            fi
        fi

        if [[ $compliant -eq 1 ]]; then
            log "SUCCESS: $SERVICE is now 100% compliant"
            break
        else
            log "WARNING: $SERVICE still not compliant after attempt $attempt"
            if [ $attempt -eq 3 ]; then
                log "ERROR: Failed to fix $SERVICE after 3 attempts. Running deep diagnostics."
                # --- ENHANCED DIAGNOSTICS FOR KEYCLOAK AND PROMETHEUS ---
                if [[ "$SERVICE" == "keycloak" ]]; then
                    log "DIAG: Collecting Keycloak DB env/config and logs for analysis."
                    docker exec "$CONTAINER" printenv | grep -i 'DB\|POSTGRES\|DATABASE' >> "$LOG_FILE" 2>&1 || true
                    docker exec "$CONTAINER" cat /opt/keycloak/conf/keycloak.conf >> "$LOG_FILE" 2>&1 || true
                    docker logs "$CONTAINER" --tail 100 >> "$LOG_FILE" 2>&1 || true
                    log "DIAG: Attempting forced DB/user recreation for Keycloak."
                    create_database_and_user "$SERVICE"
                    check_service_db_config "$SERVICE"
                fi
                if [[ "$SERVICE" == "prometheus" ]]; then
                    log "DIAG: Collecting Prometheus config and logs for analysis."
                    docker exec "$CONTAINER" cat /etc/prometheus/prometheus.yml >> "$LOG_FILE" 2>&1 || true
                    docker logs "$CONTAINER" --tail 100 >> "$LOG_FILE" 2>&1 || true
                    log "DIAG: Attempting config validation and forced restart for Prometheus."
                    docker exec "$CONTAINER" promtool check config /etc/prometheus/prometheus.yml >> "$LOG_FILE" 2>&1 || true
                    docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1 || true
                fi
                # For all, collect last 100 lines of logs for post-mortem
                docker logs "$CONTAINER" --tail 100 >> "$LOG_FILE" 2>&1 || true
            else
                log "INFO: Retrying auto-fix for $SERVICE in 5 seconds..."
                sleep 5
            fi
        fi
    done
done

# Generate comprehensive summary report
generate_summary_report() {
    log "======================================="
    log "POSTGRES SANITY AGENT - COMPREHENSIVE SUMMARY"
    log "======================================="

    local total_containers=$(echo "${ALL_SERVICES[@]}" | wc -w)
    local healthy_containers=0
    local db_integrated=0
    local connection_issues=0
    local action_required=0


    log "INFO: Total containers discovered: $total_containers"
    log ""
    log "CONTAINER STATUS SUMMARY:"
    log "-------------------------"
    log "(Includes Redis and PostgreSQL integration checks)"


    for service in "${ALL_SERVICES[@]}"; do
        container_name=""
        if docker ps -q -f name="purebliss-${service}" > /dev/null 2>&1; then
            container_name="purebliss-${service}"
        else
            container_name="$service"
        fi

        # Check container health
        is_healthy=0
        if docker ps -q -f name="$container_name" > /dev/null 2>&1; then
            health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}' "$container_name" 2>/dev/null || echo "unknown")
            if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "running" ]]; then
                is_healthy=1
                healthy_containers=$((healthy_containers + 1))
            fi
        fi

        # Check database integration
        db_status="NOT_REQUIRED"
        if is_db_consumer "$service"; then
            db_status="DB_CONSUMER"
            db_integrated=$((db_integrated + 1))
        fi

        # Check Redis integration
        redis_status="NOT_REQUIRED"
        if is_redis_consumer "$service"; then
            redis_status="REDIS_CONSUMER"
        fi

        # Check for connection issues
        has_issues="NO"
        if detect_db_connection_issues "$service" > /dev/null 2>&1; then
            has_issues="YES"
            connection_issues=$((connection_issues + 1))
        fi

        # Determine if action is required
        needs_action="NO"
        if [[ "$is_healthy" -eq 0 ]] || [[ "$has_issues" == "YES" ]]; then
            needs_action="YES"
            action_required=$((action_required + 1))
        fi

        printf "%-20s | Health: %-7s | DB Status: %-12s | Redis: %-14s | Issues: %-3s | Action: %-3s\n" \
            "$service" \
            "$([[ $is_healthy -eq 1 ]] && echo "OK" || echo "FAILED")" \
            "$db_status" \
            "$redis_status" \
            "$has_issues" \
            "$needs_action"
    done

    log ""
    log "SUMMARY STATISTICS:"
    log "-------------------"
    log "Total Containers:        $total_containers"
    log "Healthy Containers:      $healthy_containers"
    log "DB Consumers:            $db_integrated"
    log "Connection Issues:       $connection_issues"
    log "Action Required:         $action_required"

    local health_percentage=$((total_containers > 0 ? healthy_containers * 100 / total_containers : 0))
    local integration_percentage=$((total_containers > 0 ? db_integrated * 100 / total_containers : 0))

    log ""
    log "HEALTH METRICS:"
    log "---------------"
    log "Container Health:        ${health_percentage}%"
    log "DB Integration Coverage: ${integration_percentage}%"

    # PostgreSQL specific metrics
    log ""
    log "POSTGRESQL METRICS:"
    log "-------------------"
    if check_postgres_health; then
        log "PostgreSQL Status:       HEALTHY"

        # Get database list
        local db_count=$(docker exec "$POSTGRES_CONTAINER" psql -h localhost -p 5432 -U "$POSTGRES_ADMIN_USER" -d "$POSTGRES_ADMIN_DB" -tAc "SELECT COUNT(*) FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres');" 2>/dev/null || echo "0")
        log "Service Databases:       $db_count"

        # Get user count (excluding system users)
        local user_count=$(docker exec "$POSTGRES_CONTAINER" psql -h localhost -p 5432 -U "$POSTGRES_ADMIN_USER" -d "$POSTGRES_ADMIN_DB" -tAc "SELECT COUNT(*) FROM pg_user WHERE usename NOT IN ('postgres');" 2>/dev/null || echo "0")
        log "Service Users:           $user_count"
    else
        log "PostgreSQL Status:       UNHEALTHY"
    fi

    # Vault integration metrics
    log ""
    log "VAULT INTEGRATION METRICS:"
    log "--------------------------"
    if [[ -n "$VAULT_TOKEN" ]]; then
        vault_health=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" | jq -r '.sealed' 2>/dev/null || echo "unknown")
        if [[ "$vault_health" == "false" ]]; then
            log "Vault Status:            HEALTHY & UNSEALED"
            log "Vault Integration:       ENABLED"
            log "Secret Management:       ACTIVE"

            # Check if PostgreSQL secrets exist in Vault
            local postgres_secret_check=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/postgres/admin" | jq -r '.data' 2>/dev/null || echo "null")
            log "PostgreSQL Secrets:      $([[ "$postgres_secret_check" != "null" ]] && echo "STORED_IN_VAULT" || echo "FALLBACK_VALUES")"

            # Count how many service secrets are in Vault
            local vault_secrets_count=0
            for service in "${ALL_SERVICES[@]}"; do
                local service_secret_check=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/database/$service" | jq -r '.data' 2>/dev/null || echo "null")
                [[ "$service_secret_check" != "null" ]] && vault_secrets_count=$((vault_secrets_count + 1))
            done
            log "Services with Vault Secrets: $vault_secrets_count/${#ALL_SERVICES[@]}"
        else
            log "Vault Status:            SEALED/UNHEALTHY"
            log "Vault Integration:       DISABLED"
            log "Secret Management:       FALLBACK_MODE"
        fi
    else
        log "Vault Status:            TOKEN_UNAVAILABLE"
        log "Vault Integration:       DISABLED"
        log "Secret Management:       FALLBACK_MODE"
    fi

    if [[ $action_required -gt 0 ]]; then
        log ""
        log "WARNING: $action_required containers require attention!"
        log "Please review the above status and take appropriate action."
    else
        log ""
        log "SUCCESS: All containers are healthy and properly configured with PostgreSQL!"
    fi

    log "======================================="
    log "END OF SUMMARY REPORT"
    log "======================================="
}

# Call the summary report function
generate_summary_report

log "INFO: PostgreSQL sanity check completed for all services."
