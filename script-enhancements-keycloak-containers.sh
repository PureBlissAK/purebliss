#!/bin/bash

# Script Enhancement Recommendations for Keycloak and Other Containers
# Based on log analysis showing health check failures, dependency issues, and timeout problems
# Date: 2025-08-06
# Purpose: Implement specific improvements to prevent recurring issues identified in logs

set -euo pipefail

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_ENHANCEMENT [$1]: $2" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

log_action "INFO" "Starting script enhancement implementation based on log analysis"

# Enhancement 1: Keycloak Health Check Improvements
enhance_keycloak_health_checks() {
    log_action "INFO" "Enhancing Keycloak health check configuration"

    # Create enhanced Keycloak health check script
    cat > /opt/dev-purebliss/services/keycloak/enhanced-health-check.sh << 'EOF'
#!/bin/bash

# Enhanced Keycloak Health Check Script
# Addresses issues found in logs: health endpoint timeouts, dependency validation failures

set -euo pipefail

KEYCLOAK_HOST="${1:-localhost}"
KEYCLOAK_PORT="${2:-8080}"
MAX_RETRIES="${3:-30}"
RETRY_INTERVAL="${4:-10}"

# Function to check Keycloak readiness
check_keycloak_readiness() {
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt/$MAX_RETRIES: Checking Keycloak health..."

        # Check if Keycloak process is running
        if ! pgrep -f "keycloak" > /dev/null; then
            echo "Keycloak process not found, waiting..."
            sleep $RETRY_INTERVAL
            ((attempt++))
            continue
        fi

        # Check basic HTTP response
        if curl -f -s --connect-timeout 5 --max-time 10 "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}" > /dev/null 2>&1; then
            echo "Keycloak HTTP endpoint responding"

            # Check admin console availability
            if curl -f -s --connect-timeout 5 --max-time 10 "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/admin" > /dev/null 2>&1; then
                echo "Keycloak admin console accessible"

                # Check health endpoint
                if curl -f -s --connect-timeout 5 --max-time 10 "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/health" > /dev/null 2>&1; then
                    echo "Keycloak health endpoint responding"
                    return 0
                fi
            fi
        fi

        echo "Keycloak not ready, waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
        ((attempt++))
    done

    echo "Keycloak failed to become ready after $MAX_RETRIES attempts"
    return 1
}

# Function to validate dependencies before starting health checks
validate_dependencies() {
    echo "Validating Keycloak dependencies..."

    # Check PostgreSQL connectivity
    if ! nc -z purebliss-postgres 5432; then
        echo "ERROR: PostgreSQL not reachable on purebliss-postgres:5432"
        return 1
    fi

    # Check PostgreSQL readiness
    if ! docker exec purebliss-postgres pg_isready -U "${POSTGRES_USER:-keycloak}" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL not ready"
        return 1
    fi

    echo "Dependencies validated successfully"
    return 0
}

# Main execution
main() {
    echo "Starting enhanced Keycloak health check..."

    # First validate dependencies
    if ! validate_dependencies; then
        echo "Dependency validation failed"
        exit 1
    fi

    # Then check Keycloak readiness
    if check_keycloak_readiness; then
        echo "Keycloak is healthy and ready"
        exit 0
    else
        echo "Keycloak health check failed"
        exit 1
    fi
}

main "$@"
EOF

    chmod +x /opt/dev-purebliss/services/keycloak/enhanced-health-check.sh
    log_action "SUCCESS" "Enhanced Keycloak health check script created"
}

# Enhancement 2: Container Startup Sequencing Improvements
enhance_startup_sequencing() {
    log_action "INFO" "Creating enhanced startup sequencing script"

    cat > /opt/dev-purebliss/enhanced-startup-sequencer.sh << 'EOF'
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
EOF

    chmod +x /opt/dev-purebliss/enhanced-startup-sequencer.sh
    log_action "SUCCESS" "Enhanced startup sequencer created"
}

# Enhancement 3: Docker Health Check Standardization
enhance_docker_health_checks() {
    log_action "INFO" "Creating standardized Docker health check configurations"

    # Create health check templates directory
    mkdir -p /opt/dev-purebliss/health-check-templates

    # Keycloak health check template
    cat > /opt/dev-purebliss/health-check-templates/keycloak-healthcheck.yml << 'EOF'
# Enhanced Keycloak Health Check Configuration
# Addresses "no-healthcheck" status found in logs

healthcheck:
  test: |
    bash -c '
      # Multi-stage health check for Keycloak

      # Stage 1: Process check
      if ! pgrep -f "keycloak" > /dev/null; then
        echo "Keycloak process not running"
        exit 1
      fi

      # Stage 2: Port check
      if ! nc -z localhost 8080; then
        echo "Keycloak port 8080 not accessible"
        exit 1
      fi

      # Stage 3: HTTP response check
      if ! curl -f -s --connect-timeout 3 --max-time 5 "http://localhost:8080" > /dev/null; then
        echo "Keycloak HTTP endpoint not responding"
        exit 1
      fi

      # Stage 4: Admin console check
      if ! curl -f -s --connect-timeout 3 --max-time 5 "http://localhost:8080/admin" > /dev/null; then
        echo "Keycloak admin console not accessible"
        exit 1
      fi

      echo "Keycloak is healthy"
      exit 0
    '
  interval: 15s
  timeout: 10s
  retries: 5
  start_period: 60s  # Allow more time for initial startup
EOF

    # PostgreSQL enhanced health check
    cat > /opt/dev-purebliss/health-check-templates/postgres-healthcheck.yml << 'EOF'
# Enhanced PostgreSQL Health Check Configuration

healthcheck:
  test: |
    bash -c '
      # Multi-stage health check for PostgreSQL

      # Stage 1: Process check
      if ! pgrep -f "postgres" > /dev/null; then
        echo "PostgreSQL process not running"
        exit 1
      fi

      # Stage 2: Ready check
      if ! pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres}; then
        echo "PostgreSQL not ready for connections"
        exit 1
      fi

      # Stage 3: Connection test
      if ! psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} -c "SELECT 1;" > /dev/null 2>&1; then
        echo "PostgreSQL connection test failed"
        exit 1
      fi

      echo "PostgreSQL is healthy"
      exit 0
    '
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
EOF

    # Redis enhanced health check
    cat > /opt/dev-purebliss/health-check-templates/redis-healthcheck.yml << 'EOF'
# Enhanced Redis Health Check Configuration

healthcheck:
  test: |
    bash -c '
      # Multi-stage health check for Redis

      # Stage 1: Process check
      if ! pgrep -f "redis-server" > /dev/null; then
        echo "Redis process not running"
        exit 1
      fi

      # Stage 2: Connection check
      if ! redis-cli ping > /dev/null 2>&1; then
        echo "Redis ping failed"
        exit 1
      fi

      # Stage 3: Write/read test
      if ! redis-cli set healthcheck "ok" > /dev/null 2>&1; then
        echo "Redis write test failed"
        exit 1
      fi

      if [ "$(redis-cli get healthcheck 2>/dev/null)" != "ok" ]; then
        echo "Redis read test failed"
        exit 1
      fi

      # Clean up test key
      redis-cli del healthcheck > /dev/null 2>&1

      echo "Redis is healthy"
      exit 0
    '
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 30s
EOF

    log_action "SUCCESS" "Docker health check templates created"
}

# Enhancement 4: Dependency Connection Validation
enhance_dependency_validation() {
    log_action "INFO" "Creating enhanced dependency validation script"

    cat > /opt/dev-purebliss/validate-service-dependencies.sh << 'EOF'
#!/bin/bash

# Enhanced Service Dependency Validation
# Addresses dependency connection failures found in logs

set -euo pipefail

# Service dependency validation functions
validate_postgres_connection() {
    local host=${1:-purebliss-postgres}
    local port=${2:-5432}
    local user=${3:-$POSTGRES_USER}
    local db=${4:-$POSTGRES_DB}

    echo "Validating PostgreSQL connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to PostgreSQL at $host:$port"
        return 1
    fi

    # PostgreSQL specific readiness check
    if ! docker exec purebliss-postgres pg_isready -U "$user" -d "$db" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL not ready for connections"
        return 1
    fi

    # Connection test
    if ! docker exec purebliss-postgres psql -U "$user" -d "$db" -c "SELECT 1;" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL connection test failed"
        return 1
    fi

    echo "PostgreSQL connection validated successfully"
    return 0
}

validate_redis_connection() {
    local host=${1:-purebliss-redis}
    local port=${2:-6379}

    echo "Validating Redis connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to Redis at $host:$port"
        return 1
    fi

    # Redis ping test
    if ! docker exec purebliss-redis redis-cli ping > /dev/null 2>&1; then
        echo "ERROR: Redis ping failed"
        return 1
    fi

    echo "Redis connection validated successfully"
    return 0
}

validate_vault_connection() {
    local host=${1:-purebliss-vault}
    local port=${2:-8200}

    echo "Validating Vault connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to Vault at $host:$port"
        return 1
    fi

    # Vault status check
    local vault_status=$(docker exec purebliss-vault vault status -format=json 2>/dev/null | jq -r '.initialized // false' 2>/dev/null || echo "false")

    if [ "$vault_status" != "true" ]; then
        echo "ERROR: Vault not initialized"
        return 1
    fi

    echo "Vault connection validated successfully"
    return 0
}

# Main validation function
validate_service_dependencies() {
    local service=$1

    echo "Validating dependencies for $service..."

    case $service in
        "keycloak")
            validate_postgres_connection && validate_redis_connection
            ;;
        "plane")
            validate_postgres_connection && validate_redis_connection
            ;;
        "nginx")
            validate_vault_connection
            ;;
        "vault-agent")
            validate_vault_connection
            ;;
        *)
            echo "No specific dependency validation for $service"
            return 0
            ;;
    esac
}

# Main execution
main() {
    local service=${1:-"all"}

    if [ "$service" = "all" ]; then
        echo "Validating all service dependencies..."
        for svc in keycloak plane nginx vault-agent; do
            echo "=== Validating $svc dependencies ==="
            validate_service_dependencies "$svc"
            echo
        done
    else
        validate_service_dependencies "$service"
    fi
}

main "$@"
EOF

    chmod +x /opt/dev-purebliss/validate-service-dependencies.sh
    log_action "SUCCESS" "Enhanced dependency validation script created"
}

# Enhancement 5: Timeout and Retry Logic Improvements
enhance_timeout_retry_logic() {
    log_action "INFO" "Creating enhanced timeout and retry logic"

    cat > /opt/dev-purebliss/retry-utils.sh << 'EOF'
#!/bin/bash

# Enhanced Retry and Timeout Utilities
# Addresses timeout issues found in logs (30 attempts for PostgreSQL health checks)

# Function to retry a command with exponential backoff
retry_with_backoff() {
    local max_attempts=${1:-5}
    local delay=${2:-1}
    local max_delay=${3:-60}
    local command="${@:4}"

    local attempt=1
    local current_delay=$delay

    echo "Executing with retry: $command"

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts..."

        if eval "$command"; then
            echo "Command succeeded on attempt $attempt"
            return 0
        fi

        if [ $attempt -eq $max_attempts ]; then
            echo "Command failed after $max_attempts attempts"
            return 1
        fi

        echo "Command failed, waiting ${current_delay}s before retry..."
        sleep $current_delay

        # Exponential backoff with jitter
        current_delay=$(( current_delay * 2 ))
        if [ $current_delay -gt $max_delay ]; then
            current_delay=$max_delay
        fi

        # Add jitter (±25%)
        local jitter=$(( current_delay / 4 ))
        local random_jitter=$(( (RANDOM % (jitter * 2)) - jitter ))
        current_delay=$(( current_delay + random_jitter ))

        ((attempt++))
    done
}

# Function to wait for port with timeout
wait_for_port() {
    local host=$1
    local port=$2
    local timeout=${3:-60}
    local check_interval=${4:-2}

    echo "Waiting for $host:$port to be available (timeout: ${timeout}s)..."

    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            echo "$host:$port is available"
            return 0
        fi

        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "Waiting for $host:$port... (${elapsed}s/${timeout}s)"
    done

    echo "Timeout waiting for $host:$port after ${timeout}s"
    return 1
}

# Function to wait for HTTP endpoint
wait_for_http_endpoint() {
    local url=$1
    local timeout=${2:-60}
    local check_interval=${3:-5}
    local expected_status=${4:-200}

    echo "Waiting for HTTP endpoint $url (timeout: ${timeout}s, expected: $expected_status)..."

    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time 5 "$url" 2>/dev/null || echo "000")

        if [ "$status" = "$expected_status" ]; then
            echo "HTTP endpoint $url is available (status: $status)"
            return 0
        fi

        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "Waiting for $url... (${elapsed}s/${timeout}s, status: $status)"
    done

    echo "Timeout waiting for HTTP endpoint $url after ${timeout}s"
    return 1
}

# Function to wait for container health
wait_for_container_health() {
    local container_name=$1
    local timeout=${2:-120}
    local check_interval=${3:-5}

    echo "Waiting for container $container_name to be healthy (timeout: ${timeout}s)..."

    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-container")

        case $health_status in
            "healthy")
                echo "Container $container_name is healthy"
                return 0
                ;;
            "no-container")
                echo "Container $container_name not found"
                return 1
                ;;
            "no-healthcheck")
                # For containers without health checks, check if running
                local running=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null || echo "false")
                if [ "$running" = "true" ]; then
                    echo "Container $container_name is running (no health check)"
                    return 0
                fi
                ;;
        esac

        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "Waiting for $container_name health... (${elapsed}s/${timeout}s, status: $health_status)"
    done

    echo "Timeout waiting for container $container_name health after ${timeout}s"
    return 1
}

# Export functions for use in other scripts
export -f retry_with_backoff
export -f wait_for_port
export -f wait_for_http_endpoint
export -f wait_for_container_health
EOF

    chmod +x /opt/dev-purebliss/retry-utils.sh
    log_action "SUCCESS" "Enhanced retry and timeout utilities created"
}

# Enhancement 6: Service-Specific Entrypoint Improvements
enhance_service_entrypoints() {
    log_action "INFO" "Creating enhanced service entrypoints"

    # Enhanced Keycloak entrypoint
    mkdir -p /opt/dev-purebliss/services/keycloak/entrypoints

    cat > /opt/dev-purebliss/services/keycloak/entrypoints/enhanced-entrypoint.sh << 'EOF'
#!/bin/bash

# Enhanced Keycloak Entrypoint
# Addresses startup issues and dependency validation failures found in logs

set -euo pipefail

# Source retry utilities
source /opt/dev-purebliss/retry-utils.sh

# Logging function
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] KEYCLOAK_ENTRYPOINT INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] KEYCLOAK_ENTRYPOINT ERROR: $1" >&2
}

# Pre-startup validation
validate_environment() {
    log_info "Validating environment variables..."

    local required_vars=(
        "KEYCLOAK_ADMIN"
        "KEYCLOAK_ADMIN_PASSWORD"
        "KC_DB_URL_HOST"
        "KC_DB_USERNAME"
        "KC_DB_PASSWORD"
        "KC_DB_URL_DATABASE"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done

    log_info "Environment variables validated"
}

# Database dependency validation
validate_database_dependency() {
    log_info "Validating database dependency..."

    local db_host="${KC_DB_URL_HOST:-purebliss-postgres}"
    local db_port="${KC_DB_URL_PORT:-5432}"

    # Wait for PostgreSQL port
    if ! wait_for_port "$db_host" "$db_port" 120; then
        log_error "PostgreSQL not available at $db_host:$db_port"
        exit 1
    fi

    # Wait for PostgreSQL readiness
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_info "Testing PostgreSQL readiness (attempt $attempt/$max_attempts)..."

        if docker exec purebliss-postgres pg_isready -U "${KC_DB_USERNAME}" -d "${KC_DB_URL_DATABASE}" > /dev/null 2>&1; then
            log_info "PostgreSQL is ready"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            log_error "PostgreSQL not ready after $max_attempts attempts"
            exit 1
        fi

        sleep 5
        ((attempt++))
    done

    log_info "Database dependency validated"
}

# Keycloak configuration preparation
prepare_keycloak_config() {
    log_info "Preparing Keycloak configuration..."

    # Create necessary directories
    mkdir -p /opt/keycloak/data/import

    # Set proper permissions
    chown -R keycloak:keycloak /opt/keycloak/data

    log_info "Keycloak configuration prepared"
}

# Keycloak startup with enhanced monitoring
start_keycloak() {
    log_info "Starting Keycloak with enhanced monitoring..."

    # Start Keycloak in background
    /opt/keycloak/bin/kc.sh start-dev \
        --db=postgres \
        --db-url="jdbc:postgresql://${KC_DB_URL_HOST}:${KC_DB_URL_PORT:-5432}/${KC_DB_URL_DATABASE}" \
        --db-username="${KC_DB_USERNAME}" \
        --db-password="${KC_DB_PASSWORD}" \
        --hostname="${KC_HOSTNAME:-localhost}" \
        --proxy=edge \
        --http-enabled=true \
        --hostname-strict=false &

    local keycloak_pid=$!

    # Monitor startup
    log_info "Monitoring Keycloak startup (PID: $keycloak_pid)..."

    # Wait for HTTP endpoint to be available
    if wait_for_http_endpoint "http://localhost:8080" 300; then
        log_info "Keycloak HTTP endpoint is available"
    else
        log_error "Keycloak HTTP endpoint failed to start"
        kill $keycloak_pid 2>/dev/null || true
        exit 1
    fi

    # Wait for admin console
    if wait_for_http_endpoint "http://localhost:8080/admin" 60; then
        log_info "Keycloak admin console is available"
    else
        log_error "Keycloak admin console not available"
        kill $keycloak_pid 2>/dev/null || true
        exit 1
    fi

    log_info "Keycloak started successfully"

    # Keep the process running
    wait $keycloak_pid
}

# Signal handlers for graceful shutdown
cleanup() {
    log_info "Received shutdown signal, stopping Keycloak..."
    pkill -f "kc.sh" || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main execution
main() {
    log_info "Enhanced Keycloak entrypoint starting..."

    validate_environment
    validate_database_dependency
    prepare_keycloak_config
    start_keycloak
}

main "$@"
EOF

    chmod +x /opt/dev-purebliss/services/keycloak/entrypoints/enhanced-entrypoint.sh
    log_action "SUCCESS" "Enhanced Keycloak entrypoint created"
}

# Main execution function
main() {
    log_action "INFO" "Beginning script enhancement implementation"

    # Run all enhancements
    enhance_keycloak_health_checks
    enhance_startup_sequencing
    enhance_docker_health_checks
    enhance_dependency_validation
    enhance_timeout_retry_logic
    enhance_service_entrypoints

    # Update log with completion summary
    log_action "SUCCESS" "Script enhancement implementation completed"
    log_action "INFO" "Enhanced components:"
    log_action "INFO" "- Keycloak health check script with dependency validation"
    log_action "INFO" "- Startup sequencing with proper dependency ordering"
    log_action "INFO" "- Standardized Docker health check templates"
    log_action "INFO" "- Enhanced dependency validation utility"
    log_action "INFO" "- Retry and timeout utilities with exponential backoff"
    log_action "INFO" "- Enhanced service entrypoints with monitoring"

    # Execute mandatory health validation
    log_action "INFO" "Executing mandatory health validation after script enhancement"
    if /opt/dev-purebliss/validate-container-health.sh keycloak script-enhancement-implementation; then
        log_action "SUCCESS" "Health validation passed - enhancements ready for deployment"
    else
        log_action "ERROR" "Health validation failed - review enhancement implementation"
        exit 1
    fi
}

# Execute main function
main "$@"
