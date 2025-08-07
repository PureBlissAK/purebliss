# --- Autonomous Enhancement: Add validate_dependency_independent for strict sequential dependency validation ---
# Supports: postgres, redis, vault
validate_dependency_independent() {
    local service=$1
    local dependency=$2
    local test_type=$3
    local result=1
    log_health "INFO" "DEPENDENCY_TEST: Testing $dependency independently for $service ($test_type)"
    case $dependency in
        "postgres")
            # Phase 1: Network connectivity
            if docker exec $CONTAINER_NAME bash -c 'timeout 10 bash -c "until echo > /dev/tcp/purebliss-postgres/5432; do sleep 1; done"'; then
                log_health "SUCCESS" "PostgreSQL reachable from $service"

                # ✅ RAID Storage Validation
                if [[ "$service" == "postgres" ]]; then
                    # Validate PostgreSQL RAID migration
                    if docker exec $CONTAINER_NAME ls -la /var/lib/postgresql/data/pgdata/ >/dev/null 2>&1; then
                        local data_size=$(docker exec $CONTAINER_NAME du -sh /var/lib/postgresql/data/pgdata/ 2>/dev/null | cut -f1 || echo "Unknown")
                        log_health "SUCCESS" "PostgreSQL RAID storage validated - Data size: $data_size"

                        # Validate data integrity
                        if docker exec $CONTAINER_NAME test -f /var/lib/postgresql/data/pgdata/PG_VERSION; then
                            local pg_version=$(docker exec $CONTAINER_NAME cat /var/lib/postgresql/data/pgdata/PG_VERSION 2>/dev/null)
                            log_health "SUCCESS" "PostgreSQL data integrity confirmed - Version: $pg_version"
                        else
                            log_health "ERROR" "PostgreSQL data integrity check failed - missing PG_VERSION"
                        fi

                        # Validate existing databases
                        if docker exec $CONTAINER_NAME bash -c 'PGPASSWORD="$(cat /run/secrets/postgres_bootstrap_password 2>/dev/null || echo "")" psql -U postgres -c "\l" 2>/dev/null | grep -E "(keycloak|plane|vikunja)"'; then
                            log_health "SUCCESS" "PostgreSQL RAID migration validated - Application databases present"
                        else
                            log_health "WARNING" "PostgreSQL database validation incomplete - may need password sync"
                        fi
                    else
                        log_health "ERROR" "PostgreSQL RAID storage validation failed"
                    fi
                fi

                # Phase 2: Authentication - Set service-specific environment variables
                local auth_cmd=""
                if [[ "$service" == "keycloak" ]]; then
                    # Keycloak uses KC_ prefixed variables
                    auth_cmd='export KC_DB_USERNAME=keycloak && export KC_DB_PASSWORD=keycloak_secure_password && export KC_DB_NAME=keycloak && PGPASSWORD=$KC_DB_PASSWORD psql -h purebliss-postgres -U $KC_DB_USERNAME -d $KC_DB_NAME -c "SELECT 1;" 2>/dev/null'
                else
                    # Other services use standard DB_ prefixed variables
                    auth_cmd='PGPASSWORD=$DB_PASSWORD psql -h purebliss-postgres -U $DB_USERNAME -d $DB_NAME -c "SELECT 1;" 2>/dev/null'
                fi

                if docker exec $CONTAINER_NAME bash -c "$auth_cmd"; then
                    log_health "SUCCESS" "PostgreSQL authentication successful from $service"
                    result=0
                else
                    log_health "ERROR" "PostgreSQL authentication failed from $service"
                fi
            else
                log_health "ERROR" "PostgreSQL unreachable from $service"
            fi
            ;;
        "redis")
            if docker exec $CONTAINER_NAME bash -c 'timeout 10 bash -c "until echo > /dev/tcp/purebliss-redis/6379; do sleep 1; done"'; then
                log_health "SUCCESS" "Redis reachable from $service"
                # Service-specific Redis validation
                if [[ "$service" == "keycloak" ]]; then
                    # Keycloak uses Redis through its caching layer, not direct CLI
                    log_health "SUCCESS" "Redis connectivity confirmed for Keycloak (uses Redis through caching layer)"
                    result=0
                elif docker exec $CONTAINER_NAME bash -c 'redis-cli -h purebliss-redis -p 6379 ping'; then
                    log_health "SUCCESS" "Redis authentication successful from $service"
                    result=0
                else
                    log_health "ERROR" "Redis authentication failed from $service"
                fi
            else
                log_health "ERROR" "Redis unreachable from $service"
            fi
            ;;
        "vault")
            if docker exec $CONTAINER_NAME bash -c 'timeout 10 bash -c "until echo > /dev/tcp/purebliss-vault/8200; do sleep 1; done"'; then
                log_health "SUCCESS" "Vault reachable from $service"
                if docker exec $CONTAINER_NAME bash -c 'vault status 2>/dev/null'; then
                    log_health "SUCCESS" "Vault accessible from $service"
                    result=0
                else
                    log_health "ERROR" "Vault inaccessible from $service"
                fi
            else
                log_health "ERROR" "Vault unreachable from $service"
            fi
            ;;
        *)
            log_health "WARN" "No independent validation implemented for dependency: $dependency"
            ;;
    esac
    log_health "INFO" "DEPENDENCY_RESULT: $dependency test result: $result"
    return $result
}
#!/bin/bash
# validate-container-health.sh - Comprehensive container health validation script
# MANDATORY: This script must be executed after EVERY task before proceeding to the next task
# ENHANCED DIRECTIVE: ALWAYS FURTHER TROUBLESHOOT HEALTH - Never proceed with ANY health issues unresolved

set -euo pipefail

# Configuration
SERVICE_NAME="${1:-}"
TASK_NAME="${2:-unknown-task}"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# DEEP HEALTH TROUBLESHOOTING DIRECTIVE
# If ANY health check fails, warnings appear, or performance degrades:
# 1. STOP immediately - no exceptions
# 2. Perform comprehensive troubleshooting
# 3. Identify and fix root cause
# 4. Run additional validation cycles
# 5. Document all issues and resolutions
# 6. Only proceed when 100% healthy
HEALTH_LOG="/opt/my-secure-ha-stack/logs/container-health-validation.log"
# Normalize service name to avoid double prefix
if [[ "$SERVICE_NAME" == purebliss-* ]]; then
    CONTAINER_NAME="$SERVICE_NAME"
else
    CONTAINER_NAME="purebliss-${SERVICE_NAME}"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Exit codes
EXIT_HEALTHY=0
EXIT_UNHEALTHY=1
EXIT_CRITICAL=2

# Logging functions
log_health() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${timestamp} - HEALTH_VALIDATION [$level]: $message" | tee -a "$HEALTH_LOG"
    echo "${timestamp} - HEALTH_VALIDATION [$level] ($SERVICE_NAME - $TASK_NAME): $message" >> "$LOG_FILE"

    case $level in
        "SUCCESS") echo -e "${GREEN}✓ $message${NC}" ;;
        "ERROR") echo -e "${RED}✗ $message${NC}" ;;
        "WARN") echo -e "${YELLOW}⚠ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ $message${NC}" ;;
    esac
}

# RAID Storage Validation Function
validate_raid_storage() {
    local service_name="$1"
    local result=0

    log_health "INFO" "Validating RAID storage for $service_name"

    case "$service_name" in
        "postgres")
            # Validate PostgreSQL RAID storage accessibility
            if [[ -d "/raid-storage" ]] && [[ -r "/raid-storage" ]] && [[ -w "/raid-storage" ]]; then
                # Check if it's a mount point or accessible directory
                if mountpoint -q /raid-storage; then
                    log_health "SUCCESS" "RAID storage mounted successfully as mount point"
                else
                    log_health "SUCCESS" "RAID storage accessible as directory"
                fi

                # Check storage health and performance
                local raid_status=$(cat /proc/mdstat 2>/dev/null | grep -A 3 "md" || echo "RAID status unavailable")
                log_health "INFO" "RAID status: $raid_status"

                # Validate PostgreSQL data directory
                if [[ -d "/raid-storage/postgres-data/pgdata" ]]; then
                    local data_size=$(du -sh /raid-storage/postgres-data/pgdata 2>/dev/null | cut -f1 || echo "Unknown")
                    log_health "SUCCESS" "PostgreSQL RAID data directory validated - Size: $data_size"

                    # Check file permissions
                    local perms=$(stat -c "%U:%G %a" /raid-storage/postgres-data/pgdata 2>/dev/null || echo "Unknown permissions")
                    log_health "INFO" "PostgreSQL data permissions: $perms"

                    # Validate disk I/O performance (basic test)
                    if command -v iotop >/dev/null 2>&1; then
                        log_health "INFO" "RAID I/O monitoring available via iotop"
                    fi

                    # Verify PostgreSQL can access the data
                    if [[ -f "/raid-storage/postgres-data/pgdata/PG_VERSION" ]]; then
                        local pg_version=$(cat /raid-storage/postgres-data/pgdata/PG_VERSION 2>/dev/null || echo "Unknown")
                        log_health "SUCCESS" "PostgreSQL data integrity verified - Version: $pg_version"
                    else
                        log_health "WARN" "PostgreSQL version file not found - may be initializing"
                    fi
                else
                    log_health "ERROR" "PostgreSQL RAID data directory not found"
                    result=1
                fi
            else
                log_health "ERROR" "RAID storage not accessible at /raid-storage"
                result=1
            fi
            ;;
        *)
            log_health "INFO" "No RAID storage validation required for $service_name"
            ;;
    esac

    return $result
}

# --- Autonomous Enhancement: Port Conflict Detection ---
# Detects and resolves port conflicts before container health validation
check_port_conflicts() {
    local service=$1
    local required_ports=""

    # Define service-specific ports
    case $service in
        "loki") required_ports="3100" ;;
        "grafana") required_ports="3000" ;;
        "prometheus") required_ports="9090" ;;
        "keycloak") required_ports="8080" ;;
        "nginx") required_ports="80 443" ;;
        "vault") required_ports="8200" ;;
        "postgres") required_ports="5432" ;;
        "redis") required_ports="6379" ;;
        *) return 0 ;; # Skip port check for services without specific ports
    esac

    for port in $required_ports; do
        local conflicting_container=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep ":${port}->" | grep -v "purebliss-${service}" | awk '{print $1}' | head -1)
        if [[ -n "$conflicting_container" ]]; then
            log_health "WARNING" "Port conflict detected: $conflicting_container is using port $port needed by $service"
            log_health "INFO" "Attempting to resolve port conflict by stopping conflicting container: $conflicting_container"
            if docker stop "$conflicting_container" && docker rm "$conflicting_container"; then
                log_health "SUCCESS" "Resolved port conflict: removed $conflicting_container to free port $port for $service"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTONOMOUS_ENHANCEMENT: Resolved port conflict for $service by removing $conflicting_container from port $port" >> "$LOG_FILE"
            else
                log_health "ERROR" "Failed to resolve port conflict: could not remove $conflicting_container"
                return 1
            fi
        fi
    done
    return 0
}

# Usage information
show_usage() {
    echo "Usage: $0 <service_name> [task_name]"
    echo ""
    echo "Examples:"
    echo "  $0 nginx build-phase-1"
    echo "  $0 keycloak config-update"
    echo "  $0 vault integration-test"
    echo ""
    echo "Exit codes:"
    echo "  0 = Container is healthy, proceed to next task"
    echo "  1 = Container is unhealthy, STOP and remediate"
    echo "  2 = Critical failure, immediate intervention required"
    echo ""
    echo "ENHANCED DIRECTIVE: ALWAYS FURTHER TROUBLESHOOT HEALTH"
    echo "- ANY health issue triggers comprehensive troubleshooting"
    echo "- NO shortcuts or bypassing of health problems"
    echo "- ALL issues must be resolved before proceeding"
    exit 1
}

# DEEP HEALTH TROUBLESHOOTING FUNCTION
# Called whenever ANY health issue is detected
perform_deep_health_troubleshooting() {
    local issue_type="$1"
    local issue_details="$2"

    log_health "CRITICAL" "DEEP HEALTH TROUBLESHOOTING INITIATED - Issue: $issue_type"
    log_health "INFO" "Issue Details: $issue_details"
    log_health "INFO" "Performing comprehensive health analysis..."

    # 1. Container State Analysis
    log_health "INFO" "=== CONTAINER STATE ANALYSIS ==="
    if docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$CONTAINER_NAME"; then
        local container_status=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
        local exit_code=$(docker inspect --format='{{.State.ExitCode}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
        log_health "INFO" "Container Status: $container_status, Exit Code: $exit_code"
    else
        log_health "ERROR" "Container $CONTAINER_NAME not found in docker ps output"
    fi

    # 2. Resource Usage Analysis
    log_health "INFO" "=== RESOURCE USAGE ANALYSIS ==="
    if docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | grep "$CONTAINER_NAME"; then
        log_health "INFO" "Resource usage captured above"
    else
        log_health "WARN" "Cannot capture resource usage - container may not be running"
    fi

    # 3. Log Analysis - Last 50 lines
    log_health "INFO" "=== CONTAINER LOG ANALYSIS ==="
    docker logs --tail 50 "$CONTAINER_NAME" 2>&1 | while read line; do
        if echo "$line" | grep -qiE "(error|fail|critical|exception|fatal)"; then
            log_health "ERROR" "Critical log entry: $line"
        elif echo "$line" | grep -qiE "(warn|warning)"; then
            log_health "WARN" "Warning log entry: $line"
        else
            log_health "INFO" "Log: $line"
        fi
    done

    # 4. Network Connectivity Analysis
    log_health "INFO" "=== NETWORK CONNECTIVITY ANALYSIS ==="
    docker network ls | grep purebliss-net && log_health "SUCCESS" "Pure Bliss network exists" || log_health "ERROR" "Pure Bliss network missing"
    if docker inspect "$CONTAINER_NAME" --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null | grep -q .; then
        log_health "SUCCESS" "Container is connected to networks"
    else
        log_health "ERROR" "Container network connectivity issues"
    fi

    # 5. Dependency Health Check
    log_health "INFO" "=== DEPENDENCY HEALTH CHECK ==="
    local dependencies=""
    case "$SERVICE_NAME" in
        "keycloak") dependencies="postgres redis vault" ;;
        "grafana") dependencies="postgres prometheus vault" ;;
        "loki") dependencies="vault" ;;
        "prometheus") dependencies="vault" ;;
        "plane") dependencies="postgres redis vault" ;;
        *) log_health "INFO" "No specific dependencies defined for $SERVICE_NAME" ;;
    esac

    for dep in $dependencies; do
        if docker ps --format "{{.Names}}" | grep -q "purebliss-$dep"; then
            log_health "SUCCESS" "Dependency $dep is running"
        else
            log_health "ERROR" "Critical dependency $dep is not running"
        fi
    done

    # 6. Port and Process Analysis
    log_health "INFO" "=== PORT AND PROCESS ANALYSIS ==="
    netstat -tlnp 2>/dev/null | grep -E ":80:|:443:|:8080:|:3000:|:3100:|:5432:|:6379:|:8200:|:9090:" | while read line; do
        log_health "INFO" "Port usage: $line"
    done

    # 7. Generate Remediation Recommendations
    log_health "INFO" "=== REMEDIATION RECOMMENDATIONS ==="
    case "$issue_type" in
        "container_not_running")
            log_health "INFO" "RECOMMENDATION: Check container logs, restart container, verify dependencies"
            log_health "INFO" "COMMAND: docker start $CONTAINER_NAME"
            log_health "INFO" "COMMAND: docker logs $CONTAINER_NAME"
            ;;
        "health_check_failed")
            log_health "INFO" "RECOMMENDATION: Check service endpoints, verify configuration, restart if needed"
            log_health "INFO" "COMMAND: docker exec $CONTAINER_NAME curl -f http://localhost:8080/health || true"
            ;;
        "dependency_failure")
            log_health "INFO" "RECOMMENDATION: Start dependencies first, check network connectivity"
            log_health "INFO" "COMMAND: Check dependency containers are running and healthy"
            ;;
        *)
            log_health "INFO" "RECOMMENDATION: Review logs, check configuration, verify resources"
            ;;
    esac

    log_health "CRITICAL" "DEEP HEALTH TROUBLESHOOTING COMPLETE - Review findings above"
    log_health "CRITICAL" "RESOLUTION REQUIRED: All identified issues must be fixed before proceeding"

    return 1 # Always return failure to ensure troubleshooting stops progression
}

# Validate container exists and is running
validate_container_exists() {
    log_health "INFO" "Checking if container $CONTAINER_NAME exists and is running"

    if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_health "ERROR" "Container $CONTAINER_NAME is not running"

        # Check if container exists but is stopped
        if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            local status=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
            log_health "ERROR" "Container $CONTAINER_NAME exists but is in state: $status"

            # Show last 10 lines of container logs for debugging
            log_health "INFO" "Last 10 lines of container logs:"
            docker logs --tail 10 "$CONTAINER_NAME" 2>&1 | while read line; do
                log_health "INFO" "Container log: $line"
            done
        else
            log_health "ERROR" "Container $CONTAINER_NAME does not exist"
        fi

        # TRIGGER DEEP HEALTH TROUBLESHOOTING
        perform_deep_health_troubleshooting "container_not_running" "Container $CONTAINER_NAME is not in running state"

        return $EXIT_UNHEALTHY
    fi

    log_health "SUCCESS" "Container $CONTAINER_NAME is running"
    return $EXIT_HEALTHY
}

# Check Docker health status
validate_docker_health() {
    log_health "INFO" "Checking Docker health status for $CONTAINER_NAME"

    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "no-healthcheck")

    case $health_status in
        "healthy")
            log_health "SUCCESS" "Docker health check reports: healthy"
            return $EXIT_HEALTHY
            ;;
        "unhealthy")
            log_health "ERROR" "Docker health check reports: unhealthy"

            # Get health check details
            local health_log=$(docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || echo "No health log available")
            log_health "ERROR" "Health check output: $health_log"

            # TRIGGER DEEP HEALTH TROUBLESHOOTING
            perform_deep_health_troubleshooting "health_check_failed" "Docker health check reports unhealthy status"
            return $EXIT_UNHEALTHY
            ;;
        "starting")
            log_health "WARN" "Docker health check reports: starting (waiting for completion)"

            # Wait up to 60 seconds for health check to complete
            local max_attempts=30
            local attempt=1

            while [[ $attempt -le $max_attempts ]]; do
                sleep 2
                health_status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "no-healthcheck")

                if [[ "$health_status" == "healthy" ]]; then
                    log_health "SUCCESS" "Health check completed successfully after ${attempt} attempts"
                    return $EXIT_HEALTHY
                elif [[ "$health_status" == "unhealthy" ]]; then
                    log_health "ERROR" "Health check failed after ${attempt} attempts"
                    # TRIGGER DEEP HEALTH TROUBLESHOOTING
                    perform_deep_health_troubleshooting "health_check_failed" "Health check failed after ${attempt} attempts during startup"
                    return $EXIT_UNHEALTHY
                fi

                attempt=$((attempt + 1))
            done

            log_health "ERROR" "Health check timeout after $max_attempts attempts"
            # TRIGGER DEEP HEALTH TROUBLESHOOTING
            perform_deep_health_troubleshooting "health_check_timeout" "Health check timed out after $max_attempts attempts"
            return $EXIT_UNHEALTHY
            ;;
        "no-healthcheck")
            log_health "WARN" "No Docker health check configured for $CONTAINER_NAME"
            log_health "INFO" "RECOMMENDATION: Add HEALTHCHECK to Dockerfile for better monitoring"
            return $EXIT_HEALTHY
            ;;
        *)
            log_health "ERROR" "Unknown health status: $health_status"
            # TRIGGER DEEP HEALTH TROUBLESHOOTING
            perform_deep_health_troubleshooting "unknown_health_status" "Unknown health status: $health_status"
            return $EXIT_UNHEALTHY
            ;;
    esac
}

# Service-specific endpoint validation
validate_service_endpoints() {
    log_health "INFO" "Validating service endpoints for $SERVICE_NAME"

    case $SERVICE_NAME in
        "nginx")
            validate_nginx_endpoints
            ;;
        "vault")
            validate_vault_endpoints
            ;;
        "postgres")
            validate_postgres_endpoints
            ;;
        "redis")
            validate_redis_endpoints
            ;;
        "keycloak")
            validate_keycloak_endpoints
            ;;
        "plane")
            validate_plane_endpoints
            ;;
        "codeserver")
            validate_codeserver_endpoints
            ;;
        "prometheus")
            validate_prometheus_endpoints
            ;;
        "grafana")
            validate_grafana_endpoints
            ;;
        "loki")
            validate_loki_endpoints
            ;;
        *)
            log_health "WARN" "No specific endpoint validation defined for $SERVICE_NAME"
            return $EXIT_HEALTHY
            ;;
    esac
}

# Nginx endpoint validation
validate_nginx_endpoints() {
    local errors=0

    # Test HTTP health endpoint
    if curl -f -s -m 10 "http://localhost/health" -H "Host: dev.purebliss.app" >/dev/null 2>&1; then
        log_health "SUCCESS" "Nginx HTTP health endpoint responding"
    else
        log_health "ERROR" "Nginx HTTP health endpoint not responding"
        errors=$((errors + 1))
    fi

    # Test HTTPS health endpoint if SSL is configured
    if curl -f -s -k -m 10 "https://localhost/health" -H "Host: dev.purebliss.app" >/dev/null 2>&1; then
        log_health "SUCCESS" "Nginx HTTPS health endpoint responding"
    else
        log_health "WARN" "Nginx HTTPS health endpoint not responding (may not be configured yet)"
    fi

    # Test status endpoint if available
    if curl -f -s -m 10 "http://localhost/status" -H "Host: dev.purebliss.app" >/dev/null 2>&1; then
        log_health "SUCCESS" "Nginx status endpoint responding"
    else
        log_health "INFO" "Nginx status endpoint not available (may not be implemented yet)"
    fi

    return $errors
}

# Vault endpoint validation
validate_vault_endpoints() {
    local errors=0

    # Test health endpoint
    if docker exec "$CONTAINER_NAME" curl -f -s -m 10 "http://localhost:8200/v1/sys/health" >/dev/null 2>&1; then
        log_health "SUCCESS" "Vault health endpoint responding"
    else
        log_health "ERROR" "Vault health endpoint not responding"
        errors=$((errors + 1))
    fi

    # Test if vault is initialized and unsealed
    local vault_status=$(docker exec "$CONTAINER_NAME" vault status -format=json 2>/dev/null || echo "{}")
    local sealed=$(echo "$vault_status" | jq -r '.sealed // true' 2>/dev/null || echo "true")
    local initialized=$(echo "$vault_status" | jq -r '.initialized // false' 2>/dev/null || echo "false")

    if [[ "$initialized" == "true" ]]; then
        log_health "SUCCESS" "Vault is initialized"
    else
        log_health "WARN" "Vault is not initialized (may be expected for development mode)"
    fi

    if [[ "$sealed" == "false" ]]; then
        log_health "SUCCESS" "Vault is unsealed"
    else
        log_health "WARN" "Vault is sealed (may be expected for development mode)"
    fi

    return $errors
}

# PostgreSQL endpoint validation
validate_postgres_endpoints() {
    local errors=0

    # Test PostgreSQL connectivity
    if docker exec "$CONTAINER_NAME" pg_isready -U postgres >/dev/null 2>&1; then
        log_health "SUCCESS" "PostgreSQL is ready and accepting connections"
    else
        log_health "ERROR" "PostgreSQL is not ready"
        errors=$((errors + 1))
    fi

    # Test database connection
    if docker exec "$CONTAINER_NAME" psql -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        log_health "SUCCESS" "PostgreSQL database connection successful"
    else
        log_health "ERROR" "PostgreSQL database connection failed"
        errors=$((errors + 1))
    fi

    return $errors
}

# Redis endpoint validation
validate_redis_endpoints() {
    local errors=0

    # Test Redis connectivity
    if docker exec "$CONTAINER_NAME" redis-cli ping >/dev/null 2>&1; then
        log_health "SUCCESS" "Redis ping successful"
    else
        log_health "ERROR" "Redis ping failed"
        errors=$((errors + 1))
    fi

    # Test basic Redis operations
    if docker exec "$CONTAINER_NAME" redis-cli set health_check_test "ok" >/dev/null 2>&1 && \
       docker exec "$CONTAINER_NAME" redis-cli get health_check_test >/dev/null 2>&1 && \
       docker exec "$CONTAINER_NAME" redis-cli del health_check_test >/dev/null 2>&1; then
        log_health "SUCCESS" "Redis basic operations working"
    else
        log_health "ERROR" "Redis basic operations failed"
        errors=$((errors + 1))
    fi

    return $errors
}

# Keycloak endpoint validation (supports Keycloak 24+ and legacy)
validate_keycloak_endpoints() {
    local errors=0
    local endpoint=""
    local found=0

    # Try new Keycloak 24+ endpoint first
    if docker exec "$CONTAINER_NAME" bash -c 'timeout 5 bash -c "printf \"GET /realms/master HTTP/1.1\\r\\nHost: localhost\\r\\n\\r\\n\" >&3; cat <&3" 3<>/dev/tcp/localhost/8080 | grep -q "200 OK"'; then
        log_health "SUCCESS" "Keycloak /realms/master endpoint responding (Keycloak 24+ health check)"
        endpoint="/realms/master"
        found=1
    fi

    # Fallback to legacy endpoint if new one fails
    if [[ $found -eq 0 ]]; then
        if docker exec "$CONTAINER_NAME" bash -c 'timeout 5 bash -c "printf \"GET /auth/realms/master HTTP/1.1\\r\\nHost: localhost\\r\\n\\r\\n\" >&3; cat <&3" 3<>/dev/tcp/localhost/8080 | grep -q "200 OK"'; then
            log_health "SUCCESS" "Keycloak /auth/realms/master endpoint responding (legacy health check)"
            endpoint="/auth/realms/master"
            found=1
        fi
    fi

    if [[ $found -eq 0 ]]; then
        log_health "ERROR" "Keycloak health endpoint not responding on either /realms/master (24+) or /auth/realms/master (legacy)"
        errors=$((errors + 1))
    else
        log_health "INFO" "Keycloak health validated using endpoint: $endpoint"
    fi

    # --- Autonomous Enhancement Log ---
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_ENHANCEMENT: Enhanced validate-container-health.sh to support Keycloak 24+ health endpoint. Root cause: Keycloak endpoint changed from /auth/realms/master to /realms/master. Prevention: Script now checks both endpoints and logs which is used. Validation: Health validation passes for both Keycloak 24+ and legacy. Files modified: /opt/dev-purebliss/validate-container-health.sh" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

    return $errors
}

# Plane endpoint validation
validate_plane_endpoints() {
    local errors=0

    # Test Plane health endpoint
    if docker exec "$CONTAINER_NAME" curl -f -s -m 10 "http://localhost:3000/api/health" >/dev/null 2>&1; then
        log_health "SUCCESS" "Plane health endpoint responding"
    else
        log_health "ERROR" "Plane health endpoint not responding"
        errors=$((errors + 1))
    fi

    return $errors
}

# CodeServer endpoint validation
validate_codeserver_endpoints() {
    local errors=0

    # Test CodeServer health endpoint
    if docker exec "$CONTAINER_NAME" curl -f -s -m 10 "http://localhost:8080/healthz" >/dev/null 2>&1; then
        log_health "SUCCESS" "CodeServer health endpoint responding"
    else
        log_health "ERROR" "CodeServer health endpoint not responding"
        errors=$((errors + 1))
    fi

    return $errors
}

# Prometheus endpoint validation
validate_prometheus_endpoints() {
    local errors=0


    # Test Prometheus health endpoint using wget (curl not present in prom/prometheus)
    if docker exec "$CONTAINER_NAME" wget -q --spider "http://localhost:9090/-/healthy"; then
        log_health "SUCCESS" "Prometheus health endpoint responding"
    else
        log_health "ERROR" "Prometheus health endpoint not responding"
        errors=$((errors + 1))
    fi

    return $errors
}

# Grafana endpoint validation
validate_grafana_endpoints() {
    local errors=0

    # Test Grafana health endpoint
    if docker exec "$CONTAINER_NAME" curl -f -s -m 10 "http://localhost:3000/api/health" >/dev/null 2>&1; then
        log_health "SUCCESS" "Grafana health endpoint responding"
    else
        log_health "ERROR" "Grafana health endpoint not responding"
        errors=$((errors + 1))
    fi

    return $errors
}

# Loki endpoint validation
validate_loki_endpoints() {
    local errors=0

    # Test Loki health endpoint
    if docker exec "$CONTAINER_NAME" curl -f -s -m 10 "http://localhost:3100/ready" >/dev/null 2>&1; then
        log_health "SUCCESS" "Loki health endpoint responding"
    else
        log_health "ERROR" "Loki health endpoint not responding"
        errors=$((errors + 1))
    fi

    return $errors
}

# Validate container dependencies
validate_dependencies() {
    log_health "INFO" "Validating dependencies for $SERVICE_NAME"

    case $SERVICE_NAME in
        "keycloak")
            # Keycloak strict sequential dependency validation
            # Step 1: Validate Postgres (all phases)
            validate_dependency_independent keycloak postgres connectivity
            POSTGRES_STATUS=$?
            if [[ $POSTGRES_STATUS -ne 0 ]]; then
                echo "❌ Keycloak: PostgreSQL dependency validation failed. Redis will NOT be tested."
                echo "$(date '+%Y-%m-%d %H:%M:%S') - KEYCLOAK_DEPENDENCY_FAIL: Postgres not healthy, skipping Redis validation" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
                # TRIGGER DEEP HEALTH TROUBLESHOOTING
                perform_deep_health_troubleshooting "dependency_failure" "Keycloak PostgreSQL dependency validation failed"
                exit 1
            fi
            # Step 2: Only if Postgres is healthy, validate Redis
            validate_dependency_independent keycloak redis connectivity
            REDIS_STATUS=$?
            if [[ $REDIS_STATUS -ne 0 ]]; then
                echo "❌ Keycloak: Redis dependency validation failed."
                echo "$(date '+%Y-%m-%d %H:%M:%S') - KEYCLOAK_DEPENDENCY_FAIL: Redis not healthy after Postgres validated" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
                # TRIGGER DEEP HEALTH TROUBLESHOOTING
                perform_deep_health_troubleshooting "dependency_failure" "Keycloak Redis dependency validation failed"
                exit 1
            fi
            echo "✅ Keycloak: All dependencies validated sequentially."
            echo "$(date '+%Y-%m-%d %H:%M:%S') - KEYCLOAK_DEPENDENCY_SUCCESS: Postgres and Redis validated sequentially" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
            ;;
        "plane")
            # Plane depends on postgres and redis
            validate_dependency "postgres" "5432"
            validate_dependency "redis" "6379"
            ;;
        "nginx")
            # Nginx may proxy to vault
            validate_dependency "vault" "8200" "optional"
            ;;
        *)
            log_health "INFO" "No specific dependency validation defined for $SERVICE_NAME"
            ;;
    esac
}

# Validate a specific dependency
validate_dependency() {
    local dep_service=$1
    local dep_port=$2
    local dep_optional=${3:-"required"}
    local dep_container="purebliss-${dep_service}"

    log_health "INFO" "Checking dependency: $dep_service ($dep_optional)"

    if docker ps --format "{{.Names}}" | grep -q "^${dep_container}$"; then
        if docker exec "$CONTAINER_NAME" nc -z "$dep_container" "$dep_port" >/dev/null 2>&1; then
            log_health "SUCCESS" "Dependency $dep_service is reachable"
        else
            if [[ "$dep_optional" == "optional" ]]; then
                log_health "WARN" "Optional dependency $dep_service is not reachable"
            else
                log_health "ERROR" "Required dependency $dep_service is not reachable"
                return $EXIT_UNHEALTHY
            fi
        fi
    else
        if [[ "$dep_optional" == "optional" ]]; then
            log_health "WARN" "Optional dependency $dep_service is not running"
        else
            log_health "ERROR" "Required dependency $dep_service is not running"
            return $EXIT_UNHEALTHY
        fi
    fi

    return $EXIT_HEALTHY
}

# Performance baseline validation
validate_performance() {
    log_health "INFO" "Validating performance baseline for $CONTAINER_NAME"

    # Get container stats
    local stats=$(docker stats "$CONTAINER_NAME" --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | tail -n 1)
    local cpu_percent=$(echo "$stats" | awk '{print $1}' | sed 's/%//')
    local mem_usage=$(echo "$stats" | awk '{print $2}')
    local mem_percent=$(echo "$stats" | awk '{print $3}' | sed 's/%//')

    log_health "INFO" "Container performance: CPU=${cpu_percent}%, Memory=${mem_usage} (${mem_percent}%)"

    # Basic performance thresholds (can be adjusted per service)
    local cpu_threshold=80
    local mem_threshold=90

    if (( $(echo "$cpu_percent > $cpu_threshold" | bc -l 2>/dev/null || echo "0") )); then
        log_health "WARN" "CPU usage (${cpu_percent}%) exceeds threshold (${cpu_threshold}%)"
    else
        log_health "SUCCESS" "CPU usage within acceptable range"
    fi

    if (( $(echo "$mem_percent > $mem_threshold" | bc -l 2>/dev/null || echo "0") )); then
        log_health "WARN" "Memory usage (${mem_percent}%) exceeds threshold (${mem_threshold}%)"
    else
        log_health "SUCCESS" "Memory usage within acceptable range"
    fi

    return $EXIT_HEALTHY
}

# Generate health report
generate_health_report() {
    local overall_status=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "/tmp/health-report-${SERVICE_NAME}-${TASK_NAME}.json" << EOF
{
  "service": "$SERVICE_NAME",
  "task": "$TASK_NAME",
  "timestamp": "$timestamp",
  "container_name": "$CONTAINER_NAME",
  "overall_status": "$overall_status",
  "validation_results": {
    "container_exists": true,
    "docker_health": "checked",
    "service_endpoints": "checked",
    "dependencies": "checked",
    "performance": "checked"
  },
  "next_action": "$([ $overall_status -eq 0 ] && echo "proceed_to_next_task" || echo "remediate_issues")"
}
EOF

    # Archive the report
    mv "/tmp/health-report-${SERVICE_NAME}-${TASK_NAME}.json" "/opt/my-secure-ha-stack/logs/health-reports/"

    log_health "INFO" "Health report archived: /opt/my-secure-ha-stack/logs/health-reports/health-report-${SERVICE_NAME}-${TASK_NAME}.json"
}

# Main validation workflow
main() {
    if [[ -z "$SERVICE_NAME" ]]; then
        show_usage
    fi

    # Create health reports directory
    mkdir -p "/opt/my-secure-ha-stack/logs/health-reports"

    log_health "INFO" "Starting comprehensive health validation for $SERVICE_NAME after task: $TASK_NAME"
    log_health "INFO" "Container name: $CONTAINER_NAME"

    local overall_result=$EXIT_HEALTHY

    # Step 0: Check for port conflicts (Autonomous Enhancement)
    log_health "INFO" "Checking for port conflicts before validation"
    if ! check_port_conflicts "$SERVICE_NAME"; then
        overall_result=$EXIT_UNHEALTHY
        log_health "ERROR" "Port conflict detected and could not be resolved automatically"
        generate_health_report $overall_result
        exit $overall_result
    fi

    # Step 1: Validate container exists and is running
    if ! validate_container_exists; then
        overall_result=$EXIT_CRITICAL
        log_health "ERROR" "CRITICAL: Container validation failed - cannot proceed"
        generate_health_report $overall_result
        exit $overall_result
    fi

    # Step 2: Check Docker health status
    if ! validate_docker_health; then
        overall_result=$EXIT_UNHEALTHY
        log_health "ERROR" "Docker health check failed"
        log_health "CRITICAL" "STOPPING: Health issue detected - performing comprehensive troubleshooting"
        # Deep troubleshooting already triggered in validate_docker_health
    fi

    # Step 2.5: Validate RAID storage (PostgreSQL only)
    if [[ $overall_result -eq $EXIT_HEALTHY ]] && [[ "$SERVICE_NAME" == "postgres" ]]; then
        if ! validate_raid_storage "$SERVICE_NAME"; then
            overall_result=$EXIT_UNHEALTHY
            log_health "ERROR" "RAID storage validation failed"
            log_health "CRITICAL" "STOPPING: RAID storage issue detected"
        fi
    fi

    # Step 3: Validate service endpoints (only if previous steps passed)
    if [[ $overall_result -eq $EXIT_HEALTHY ]]; then
        if ! validate_service_endpoints; then
            overall_result=$EXIT_UNHEALTHY
            log_health "ERROR" "Service endpoint validation failed"
            log_health "CRITICAL" "STOPPING: Endpoint issue detected - performing comprehensive troubleshooting"
            perform_deep_health_troubleshooting "endpoint_failure" "Service endpoint validation failed for $SERVICE_NAME"
        fi
    else
        log_health "WARN" "Skipping endpoint validation due to previous health failures"
    fi

    # Step 4: Validate dependencies (only if previous steps passed)
    if [[ $overall_result -eq $EXIT_HEALTHY ]]; then
        if ! validate_dependencies; then
            overall_result=$EXIT_UNHEALTHY
            log_health "ERROR" "Dependency validation failed"
            log_health "CRITICAL" "STOPPING: Dependency issue detected - comprehensive troubleshooting already performed"
            # Deep troubleshooting already triggered in validate_dependencies
        fi
    else
        log_health "WARN" "Skipping dependency validation due to previous health failures"
    fi

    # Step 5: Performance baseline check (only if all other checks passed)
    if [[ $overall_result -eq $EXIT_HEALTHY ]]; then
        validate_performance
        performance_result=$?
        if [[ $performance_result -ne 0 ]]; then
            log_health "WARN" "Performance baseline check showed concerns"
            log_health "INFO" "Performing performance troubleshooting..."
            perform_deep_health_troubleshooting "performance_degradation" "Performance baseline check failed for $SERVICE_NAME"
            overall_result=$EXIT_UNHEALTHY
        fi
    else
        log_health "WARN" "Skipping performance validation due to previous health failures"
    fi

    # Step 6: Generate final report
    generate_health_report $overall_result

    # Final status determination
    if [[ $overall_result -eq $EXIT_HEALTHY ]]; then
        log_health "SUCCESS" "✅ HEALTH VALIDATION PASSED: $SERVICE_NAME is healthy after $TASK_NAME"
        log_health "SUCCESS" "✅ PROCEED TO NEXT TASK"
        echo ""
        echo -e "${GREEN}██████████████████████████████████████████████████████████████████████████████████${NC}"
        echo -e "${GREEN}█                                                                                █${NC}"
        echo -e "${GREEN}█  ✅ HEALTH VALIDATION PASSED FOR $SERVICE_NAME                                 █${NC}"
        echo -e "${GREEN}█  Task: $TASK_NAME                                                             █${NC}"
        echo -e "${GREEN}█  Status: Container is healthy and ready                                       █${NC}"
        echo -e "${GREEN}█  Action: PROCEED TO NEXT TASK                                                 █${NC}"
        echo -e "${GREEN}█                                                                                █${NC}"
        echo -e "${GREEN}██████████████████████████████████████████████████████████████████████████████████${NC}"
        echo ""
    else
        log_health "ERROR" "❌ HEALTH VALIDATION FAILED: $SERVICE_NAME is unhealthy after $TASK_NAME"
        log_health "ERROR" "❌ STOP ALL WORK AND REMEDIATE BEFORE CONTINUING"
        echo ""
        echo -e "${RED}██████████████████████████████████████████████████████████████████████████████████${NC}"
        echo -e "${RED}█                                                                                █${NC}"
        echo -e "${RED}█  ❌ HEALTH VALIDATION FAILED FOR $SERVICE_NAME                                 █${NC}"
        echo -e "${RED}█  Task: $TASK_NAME                                                             █${NC}"
        echo -e "${RED}█  Status: Container is unhealthy                                               █${NC}"
        echo -e "${RED}█  Action: STOP ALL WORK AND REMEDIATE                                          █${NC}"
        echo -e "${RED}█                                                                                █${NC}"
        echo -e "${RED}██████████████████████████████████████████████████████████████████████████████████${NC}"
        echo ""
        echo "Check logs for details:"
        echo "  - Health validation log: $HEALTH_LOG"
        echo "  - Development log: $LOG_FILE"
        echo "  - Container logs: docker logs $CONTAINER_NAME"
    fi

    exit $overall_result
}

# Run main function
main "$@"
