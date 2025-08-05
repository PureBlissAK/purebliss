#!/bin/bash
# ============================================================================
# Pure Bliss Vault & Vault Agent Enhanced Stress Test - Full Stack Validation
#
# This comprehensive stress test validates Vault and Vault Agent usage across
# all Pure Bliss stack services with:
# - Performance metrics and timing
# - Load testing with concurrent operations
# - Vault token rotation and lease management
# - Service dependency validation
# - Error recovery testing
# - Resource utilization monitoring
#
# Logs all actions to /opt/my-secure-ha-stack/logs/dev-environment-setup.log
#
# Usage: ./stress-test-vault-stack.sh [iterations] [concurrent_ops] [stress_level] [single_service]
#   iterations: Number of test cycles (default: 10)
#   concurrent_ops: Parallel operations per service (default: 5)
#   stress_level: low|medium|high (default: medium)
#   single_service: Test only this service (optional, tests all if not specified)
#
# Examples:
#   ./stress-test-vault-stack.sh 5 3 low postgres    # Test only PostgreSQL
#   ./stress-test-vault-stack.sh 1 1 low vault       # Test only Vault core
#   DRY_RUN=1 ./stress-test-vault-stack.sh 1 1 low keycloak  # Dry run Keycloak only
# ============================================================================

set -euo pipefail

# Check for help first
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat << 'EOF'
Enhanced Vault & Vault Agent Stress Test

USAGE:
    ./stress-test-vault-stack.sh [ITERATIONS] [CONCURRENT_OPS] [STRESS_LEVEL] [SERVICE]

PARAMETERS:
    ITERATIONS      - Number of test iterations (default: 10)
    CONCURRENT_OPS  - Number of concurrent operations (default: 5)
    STRESS_LEVEL    - Test intensity: low, medium, high (default: medium)
    SERVICE         - Optional: Test specific service only (default: all services)

ENVIRONMENT VARIABLES:
    DRY_RUN=1      - Run tests without starting services (for development)
    DEBUG=1        - Enable verbose debugging output

EXAMPLES:
    # Full stack test with default settings
    ./stress-test-vault-stack.sh

    # High intensity test with 10 iterations and 8 concurrent operations
    ./stress-test-vault-stack.sh 10 8 high

    # Test only PostgreSQL service with low intensity
    ./stress-test-vault-stack.sh 3 2 low postgres

    # Dry run test for development
    DRY_RUN=1 ./stress-test-vault-stack.sh 1 1 low vault

AVAILABLE SERVICES:
    vault, postgres, vault-agent, redis, keycloak, letsencrypt, nginx,
    prometheus, loki, grafana, plane, codeserver

FEATURES:
    - Comprehensive Vault integration testing across all services
    - Dynamic secrets testing (PostgreSQL, Redis)
    - KV secrets engine testing
    - PKI certificate generation and validation
    - Service-specific policy and role testing
    - Performance metrics and recommendations
    - JSON report generation with detailed analytics
    - Health checks and service validation
    - Error handling with cleanup and recovery

OUTPUT:
    - Real-time progress with color-coded status
    - Detailed logs in /tmp/stress-test-TIMESTAMP.log
    - JSON report in /tmp/stress-test-report-TIMESTAMP.json
    - Performance metrics and optimization recommendations

EOF
    exit 0
fi

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
STRESS_LOG="/tmp/stress-test-$(date +%Y%m%d-%H%M%S).log"
ITERATIONS="${1:-10}"
CONCURRENT_OPS="${2:-5}"
STRESS_LEVEL="${3:-medium}"
SINGLE_SERVICE="${4:-}"
# Optional: DRY_RUN=1 disables all real Vault/Docker calls for offline testing
DRY_RUN="${DRY_RUN:-0}"

# Service definitions with dependencies and expected Vault paths
declare -A SERVICES=(
    ["vault"]="core,self"
    ["postgres"]="database,vault"
    ["vault-agent"]="core,vault"
    ["redis"]="cache,vault"
    ["keycloak"]="auth,vault,postgres"
    ["letsencrypt"]="certs,vault"
    ["nginx"]="proxy,vault,letsencrypt"
    ["prometheus"]="monitoring,vault"
    ["loki"]="logging,vault"
    ["grafana"]="visualization,vault"
    ["plane"]="issues,vault,postgres"
    ["codeserver"]="ide,vault"
)

# Performance metrics
declare -A METRICS=(
    ["total_tests"]=0
    ["successful_tests"]=0
    ["failed_tests"]=0
    ["vault_operations"]=0
    ["vault_failures"]=0
    ["avg_response_time"]=0
)

# Stress level configurations
case "$STRESS_LEVEL" in
    "low")
        VAULT_OPS_PER_ITERATION=3
        SLEEP_BETWEEN_OPS=1
        ;;
    "medium")
        VAULT_OPS_PER_ITERATION=10
        SLEEP_BETWEEN_OPS=0.5
        ;;
    "high")
        VAULT_OPS_PER_ITERATION=25
        SLEEP_BETWEEN_OPS=0.1
        ;;
    *)
        echo "Invalid stress level: $STRESS_LEVEL. Use low|medium|high"
        exit 1
        ;;
esac

# Enhanced logging with performance metrics
log() {
  local level="${2:-INFO}"
  local message="[$level] [$(date '+%Y-%m-%d %H:%M:%S.%3N')] $1"
  echo "$message" >> "$STRESS_LOG"
  echo "$message"
}

# Performance timing helper
time_operation() {
  local start_time=$(date +%s.%N)
  "$@"
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
  echo "$duration"
}

# Enhanced service status check with performance metrics
is_running() {
  local service="$1"
  local start_time=$(date +%s.%N)
  local result
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[DRY RUN] Simulating is_running for $service: returning false" "INFO"
    result=1
  elif docker ps -q -f name=purebliss-$service | grep -q .; then
    result=0
  else
    result=1
  fi
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
  log "Service check for $service took ${duration}s" "PERF"
  return $result
}

# Enhanced health check with timeout and retry
is_healthy() {
  local service="$1"
  local max_retries=3
  local retry=0
  
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[DRY RUN] Simulating is_healthy for $service: returning false" "INFO"
    return 1
  fi
  while [[ $retry -lt $max_retries ]]; do
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-$service 2>/dev/null || echo "no_healthcheck")
    local container_status=$(docker inspect --format='{{.State.Status}}' purebliss-$service 2>/dev/null || echo "not_found")
    if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "no_healthcheck" && "$container_status" == "running" ]]; then
      log "Service $service is healthy (attempt $((retry+1)))" "SUCCESS"
      return 0
    fi
    log "Service $service health check failed: health=$health_status, status=$container_status (attempt $((retry+1)))" "WARNING"
    ((retry++))
    sleep 1
  done
  log "Service $service failed health check after $max_retries attempts" "ERROR"
  return 1
}

# Vault connectivity test with auto-detection
vault_connectivity_test() {
  local VAULT_ADDR_HTTP="http://127.0.0.1:8200"
  local VAULT_ADDR_HTTPS="https://127.0.0.1:8200"
  
  # Auto-detect Vault mode
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[DRY RUN] Simulating Vault connectivity test: returning success" "INFO"
    return 0
  fi
  if curl -s "$VAULT_ADDR_HTTP/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="$VAULT_ADDR_HTTP"
    log "Detected Vault in development mode (HTTP)" "INFO"
  elif curl -sk "$VAULT_ADDR_HTTPS/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="$VAULT_ADDR_HTTPS"
    export VAULT_SKIP_VERIFY=1
    log "Detected Vault in production mode (HTTPS)" "INFO"
  else
    log "Cannot connect to Vault on HTTP or HTTPS" "ERROR"
    return 1
  fi
  # Set token if available
  if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
  elif [[ "$VAULT_ADDR" == "$VAULT_ADDR_HTTP" ]]; then
    export VAULT_TOKEN="dev-root-token-purebliss"
  else
    log "No Vault token found for production mode" "ERROR"
    return 1
  fi
  # Test Vault status
  if vault status >/dev/null 2>&1; then
    log "Vault connectivity test passed" "SUCCESS"
    return 0
  else
    log "Vault connectivity test failed" "ERROR"
    return 1
  fi
}

# Enhanced Vault secret validation with load testing
vault_secret_check() {
  local service="$1"
  if [[ -z "${service+x}" || -z "$service" ]]; then
    log "[FATAL] Service variable is unset or empty in vault_secret_check" "ERROR"
    METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
    return 1
  fi
  local concurrent_ops="${2:-1}"
  local operation_count=0
  local success_count=0

  METRICS["vault_operations"]=$((METRICS["vault_operations"] + 1))

  if [[ -z "$service" ]]; then
    log "[FATAL] Service variable is unset in vault_secret_check" "ERROR"
    METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
    return 1
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    log "[DRY RUN] Simulating vault_secret_check for $service: marking as failed (service down)" "INFO"
    METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
    return 0
  fi

  case "$service" in
    vault)
      # Test multiple Vault operations concurrently
      log "Testing Vault core operations for $service with $concurrent_ops concurrent ops" "INFO"
      
      for ((op=1; op<=concurrent_ops; op++)); do
        (
          local op_start=$(date +%s.%N)
          
          # Test 1: Status check
          if vault status >/dev/null 2>&1; then
            ((success_count++))
          fi
          
          # Test 2: Auth methods list
          if vault auth list >/dev/null 2>&1; then
            ((success_count++))
          fi
          
          # Test 3: Secrets engines list
          if vault secrets list >/dev/null 2>&1; then
            ((success_count++))
          fi
          
          local op_end=$(date +%s.%N)
          local op_duration=$(echo "$op_end - $op_start" | bc -l 2>/dev/null || echo "0")
          log "Vault operation $op completed in ${op_duration}s" "PERF"
          
        ) &
        ((operation_count++))
      done
      wait
      
      if [[ $success_count -ge $((concurrent_ops * 2)) ]]; then
        log "Vault core operations: SUCCESS ($success_count/$((concurrent_ops * 3)) operations)" "SUCCESS"
        METRICS["successful_tests"]=$((METRICS["successful_tests"] + 1))
      else
        log "Vault core operations: FAILED ($success_count/$((concurrent_ops * 3)) operations)" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        METRICS["vault_failures"]=$((METRICS["vault_failures"] + 1))
      fi
      ;;
      
    postgres)
      log "Testing PostgreSQL dynamic credentials with $concurrent_ops concurrent ops" "INFO"
      local cred_success=0
      
      for ((op=1; op<=concurrent_ops; op++)); do
        (
          local op_start=$(date +%s.%N)
          
          # Test dynamic credential generation
          if creds=$(vault read -format=json database/creds/postgres-role 2>/dev/null); then
            local username=$(echo "$creds" | jq -r '.data.username' 2>/dev/null)
            local password=$(echo "$creds" | jq -r '.data.password' 2>/dev/null)
            
            if [[ -n "$username" && -n "$password" && "$username" != "null" && "$password" != "null" ]]; then
              # Test actual database connection with generated credentials
              if docker exec purebliss-postgres psql -U "$username" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
                ((cred_success++))
                log "Dynamic credential test $op: SUCCESS (user: $username)" "SUCCESS"
              else
                log "Dynamic credential test $op: DB connection failed (user: $username)" "ERROR"
              fi
            else
              log "Dynamic credential test $op: Invalid credentials format" "ERROR"
            fi
          else
            log "Dynamic credential test $op: Vault read failed" "ERROR"
          fi
          
          local op_end=$(date +%s.%N)
          local op_duration=$(echo "$op_end - $op_start" | bc -l 2>/dev/null || echo "0")
          log "PostgreSQL credential operation $op took ${op_duration}s" "PERF"
          
        ) &
      done
      wait
      
      if [[ $cred_success -ge $((concurrent_ops / 2)) ]]; then
        log "PostgreSQL dynamic credentials: SUCCESS ($cred_success/$concurrent_ops tests passed)" "SUCCESS"
        METRICS["successful_tests"]=$((METRICS["successful_tests"] + 1))
      else
        log "PostgreSQL dynamic credentials: FAILED ($cred_success/$concurrent_ops tests passed)" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        METRICS["vault_failures"]=$((METRICS["vault_failures"] + 1))
      fi
      ;;
      
    redis)
      log "Testing Redis Vault configuration with $concurrent_ops concurrent ops" "INFO"
      local redis_success=0
      
      for ((op=1; op<=concurrent_ops; op++)); do
        (
          local op_start=$(date +%s.%N)
          
          # Test Redis configuration in Vault
          if vault read redis/config/redis >/dev/null 2>&1; then
            ((redis_success++))
            log "Redis config test $op: SUCCESS" "SUCCESS"
          else
            log "Redis config test $op: FAILED" "ERROR"
          fi
          
          # Test Redis connection directly
          if docker exec purebliss-redis redis-cli ping | grep -q PONG; then
            log "Redis direct connection test $op: SUCCESS" "SUCCESS"
          else
            log "Redis direct connection test $op: FAILED" "ERROR"
          fi
          
          local op_end=$(date +%s.%N)
          local op_duration=$(echo "$op_end - $op_start" | bc -l 2>/dev/null || echo "0")
          log "Redis operation $op took ${op_duration}s" "PERF"
          
        ) &
      done
      wait
      
      if [[ $redis_success -ge $((concurrent_ops / 2)) ]]; then
        log "Redis Vault integration: SUCCESS ($redis_success/$concurrent_ops tests passed)" "SUCCESS"
        METRICS["successful_tests"]=$((METRICS["successful_tests"] + 1))
      else
        log "Redis Vault integration: FAILED ($redis_success/$concurrent_ops tests passed)" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        METRICS["vault_failures"]=$((METRICS["vault_failures"] + 1))
      fi
      ;;
      
    keycloak)
      log "Testing Keycloak Vault secrets with $concurrent_ops concurrent ops" "INFO"
      local kc_success=0
      
      for ((op=1; op<=concurrent_ops; op++)); do
        (
          local op_start=$(date +%s.%N)
          
          # Test Keycloak secrets retrieval
          if secrets=$(vault kv get -format=json secret/keycloak 2>/dev/null); then
            local admin_pass=$(echo "$secrets" | jq -r '.data.data.admin_password' 2>/dev/null)
            local db_pass=$(echo "$secrets" | jq -r '.data.data.postgres_password' 2>/dev/null)
            
            if [[ -n "$admin_pass" && -n "$db_pass" && "$admin_pass" != "null" && "$db_pass" != "null" ]]; then
              ((kc_success++))
              log "Keycloak secrets test $op: SUCCESS" "SUCCESS"
              
              # Test Keycloak endpoint
              if curl -sk "http://localhost:8080/" >/dev/null 2>&1; then
                log "Keycloak endpoint test $op: SUCCESS" "SUCCESS"
              else
                log "Keycloak endpoint test $op: FAILED" "ERROR"
              fi
            else
              log "Keycloak secrets test $op: Invalid secret format" "ERROR"
            fi
          else
            log "Keycloak secrets test $op: Vault read failed" "ERROR"
          fi
          
          local op_end=$(date +%s.%N)
          local op_duration=$(echo "$op_end - $op_start" | bc -l 2>/dev/null || echo "0")
          log "Keycloak operation $op took ${op_duration}s" "PERF"
          
        ) &
      done
      wait
      
      if [[ $kc_success -ge $((concurrent_ops / 2)) ]]; then
        log "Keycloak Vault integration: SUCCESS ($kc_success/$concurrent_ops tests passed)" "SUCCESS"
        METRICS["successful_tests"]=$((METRICS["successful_tests"] + 1))
      else
        log "Keycloak Vault integration: FAILED ($kc_success/$concurrent_ops tests passed)" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        METRICS["vault_failures"]=$((METRICS["vault_failures"] + 1))
      fi
      ;;
      
    nginx)
      log "Testing Nginx PKI certificates with $concurrent_ops concurrent ops" "INFO"
      local nginx_success=0
      
      for ((op=1; op<=concurrent_ops; op++)); do
        (
          local op_start=$(date +%s.%N)
          
          # Test PKI CA certificate
          if vault read pki-nginx/cert/ca >/dev/null 2>&1; then
            ((nginx_success++))
            log "Nginx PKI test $op: SUCCESS" "SUCCESS"
          else
            log "Nginx PKI test $op: CA read failed" "ERROR"
          fi
          
          # Test certificate generation
          if cert_data=$(vault write -format=json pki-nginx/issue/nginx-role common_name="dev.purebliss.app" ttl="24h" 2>/dev/null); then
            local certificate=$(echo "$cert_data" | jq -r '.data.certificate' 2>/dev/null)
            if [[ -n "$certificate" && "$certificate" != "null" ]]; then
              log "Nginx certificate generation test $op: SUCCESS" "SUCCESS"
            else
              log "Nginx certificate generation test $op: Invalid certificate" "ERROR"
            fi
          else
            log "Nginx certificate generation test $op: FAILED" "ERROR"
          fi
          
          local op_end=$(date +%s.%N)
          local op_duration=$(echo "$op_end - $op_start" | bc -l 2>/dev/null || echo "0")
          log "Nginx PKI operation $op took ${op_duration}s" "PERF"
          
        ) &
      done
      wait
      
      if [[ $nginx_success -ge $((concurrent_ops / 2)) ]]; then
        log "Nginx PKI integration: SUCCESS ($nginx_success/$concurrent_ops tests passed)" "SUCCESS"
        METRICS["successful_tests"]=$((METRICS["successful_tests"] + 1))
      else
        log "Nginx PKI integration: FAILED ($nginx_success/$concurrent_ops tests passed)" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        METRICS["vault_failures"]=$((METRICS["vault_failures"] + 1))
      fi
      ;;
      
    vault-agent)
      log "Testing Vault Agent functionality with $concurrent_ops checks" "INFO"
      local agent_success=0
      
      for ((op=1; op<=concurrent_ops; op++)); do
        (
          local op_start=$(date +%s.%N)
          
          # Check Vault Agent logs for token renewal
          if docker logs purebliss-vault-agent --tail 50 | grep -q "renewed auth token\|auth token"; then
            ((agent_success++))
            log "Vault Agent token renewal test $op: SUCCESS" "SUCCESS"
          else
            log "Vault Agent token renewal test $op: No renewal logs found" "WARNING"
          fi
          
          # Test Vault Agent API proxy
          if curl -sk "http://localhost:8100/v1/sys/health" >/dev/null 2>&1; then
            log "Vault Agent API proxy test $op: SUCCESS" "SUCCESS"
          else
            log "Vault Agent API proxy test $op: FAILED" "ERROR"
          fi
          
          local op_end=$(date +%s.%N)
          local op_duration=$(echo "$op_end - $op_start" | bc -l 2>/dev/null || echo "0")
          log "Vault Agent operation $op took ${op_duration}s" "PERF"
          
        ) &
      done
      wait
      
      if [[ $agent_success -ge $((concurrent_ops / 2)) ]]; then
        log "Vault Agent functionality: SUCCESS ($agent_success/$concurrent_ops tests passed)" "SUCCESS"
        METRICS["successful_tests"]=$((METRICS["successful_tests"] + 1))
      else
        log "Vault Agent functionality: FAILED ($agent_success/$concurrent_ops tests passed)" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        METRICS["vault_failures"]=$((METRICS["vault_failures"] + 1))
      fi
      ;;
      
    prometheus|loki|letsencrypt|grafana|plane|codeserver)
      log "Testing $service Vault configuration with $concurrent_ops concurrent ops" "INFO"
      local config_success=0
      
      for ((op=1; op<=concurrent_ops; op++)); do
        (
          local op_start=$(date +%s.%N)
          
          case "$service" in
            prometheus)
              # Check Prometheus config secret
              if vault kv get prometheus-config/metrics >/dev/null 2>&1; then
                ((config_success++))
                log "Prometheus config secret test $op: SUCCESS" "SUCCESS"
              else
                log "Prometheus config secret test $op: FAILED" "ERROR"
              fi
              # Check Prometheus policy exists
              if vault policy read prometheus-policy >/dev/null 2>&1; then
                log "Prometheus policy test $op: SUCCESS" "SUCCESS"
              else
                log "Prometheus policy test $op: FAILED" "ERROR"
              fi
              ;;
            loki)
              # Check Loki config secret
              if vault kv get loki-config/settings >/dev/null 2>&1; then
                ((config_success++))
                log "Loki config secret test $op: SUCCESS" "SUCCESS"
              else
                log "Loki config secret test $op: FAILED" "ERROR"
              fi
              # Check Loki policy
              if vault policy read loki-policy >/dev/null 2>&1; then
                log "Loki policy test $op: SUCCESS" "SUCCESS"
              else
                log "Loki policy test $op: FAILED" "ERROR"
              fi
              ;;
            letsencrypt)
              # Check Let's Encrypt config secret
              if vault kv get secret/letsencrypt >/dev/null 2>&1; then
                ((config_success++))
                log "Let's Encrypt config secret test $op: SUCCESS" "SUCCESS"
              else
                log "Let's Encrypt config secret test $op: FAILED" "ERROR"
              fi
              # Check Let's Encrypt policy
              if vault policy read letsencrypt-policy >/dev/null 2>&1; then
                log "Let's Encrypt policy test $op: SUCCESS" "SUCCESS"
              else
                log "Let's Encrypt policy test $op: FAILED" "ERROR"
              fi
              ;;
            grafana)
              # Admin credentials
              if vault kv get secret/grafana/admin >/dev/null 2>&1; then
                ((config_success++))
                log "Grafana admin secret test $op: SUCCESS" "SUCCESS"
              else
                log "Grafana admin secret test $op: FAILED" "ERROR"
              fi
              # Data source URLs
              if vault kv get secret/grafana/datasources >/dev/null 2>&1; then
                log "Grafana datasource secret test $op: SUCCESS" "SUCCESS"
              else
                log "Grafana datasource secret test $op: FAILED" "ERROR"
              fi
              # Policy
              if vault policy read grafana-policy >/dev/null 2>&1; then
                log "Grafana policy test $op: SUCCESS" "SUCCESS"
              else
                log "Grafana policy test $op: FAILED" "ERROR"
              fi
              ;;
            plane)
              # Secret keys
              if vault kv get secret/plane/keys >/dev/null 2>&1; then
                ((config_success++))
                log "Plane secret keys test $op: SUCCESS" "SUCCESS"
              else
                log "Plane secret keys test $op: FAILED" "ERROR"
              fi
              # Database URL
              if vault kv get secret/plane/database >/dev/null 2>&1; then
                log "Plane database secret test $op: SUCCESS" "SUCCESS"
              else
                log "Plane database secret test $op: FAILED" "ERROR"
              fi
              # Policy
              if vault policy read plane-policy >/dev/null 2>&1; then
                log "Plane policy test $op: SUCCESS" "SUCCESS"
              else
                log "Plane policy test $op: FAILED" "ERROR"
              fi
              ;;
            codeserver)
              # Password generation
              if vault kv get secret/codeserver/password >/dev/null 2>&1; then
                ((config_success++))
                log "CodeServer password secret test $op: SUCCESS" "SUCCESS"
              else
                log "CodeServer password secret test $op: FAILED" "ERROR"
              fi
              # Proxy config
              if vault kv get secret/codeserver/proxy >/dev/null 2>&1; then
                log "CodeServer proxy secret test $op: SUCCESS" "SUCCESS"
              else
                log "CodeServer proxy secret test $op: FAILED" "ERROR"
              fi
              # Policy
              if vault policy read codeserver-policy >/dev/null 2>&1; then
                log "CodeServer policy test $op: SUCCESS" "SUCCESS"
              else
                log "CodeServer policy test $op: FAILED" "ERROR"
              fi
              ;;
          esac
          
          local op_end=$(date +%s.%N)
          local op_duration=$(echo "$op_end - $op_start" | bc -l 2>/dev/null || echo "0")
          log "$service config operation $op took ${op_duration}s" "PERF"
          
        ) &
      done
      wait
      
      if [[ $config_success -ge $((concurrent_ops / 2)) ]]; then
        log "$service Vault integration: SUCCESS ($config_success/$concurrent_ops tests passed)" "SUCCESS"
        METRICS["successful_tests"]=$((METRICS["successful_tests"] + 1))
      else
        log "$service Vault integration: FAILED ($config_success/$concurrent_ops tests passed)" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        METRICS["vault_failures"]=$((METRICS["vault_failures"] + 1))
      fi
      ;;
      
    "")
      log "[FATAL] Service variable is empty in case statement" "ERROR"
      METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
      ;;
    *)
      log "No specific Vault test implemented for $service" "WARNING"
      ;;
  esac
  
  METRICS["total_tests"]=$((METRICS["total_tests"] + 1))
}

# Resource monitoring
monitor_resources() {
  local iteration="$1"
  log "=== Resource Monitoring - Iteration $iteration ===" "PERF"
  
  # Docker container resource usage
  for service in "${!SERVICES[@]}"; do
    if is_running "$service"; then
      local stats=$(docker stats purebliss-$service --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || echo "N/A")
      log "Resource usage for $service: $stats" "PERF"
    fi
  done
  
  # System resource usage
  local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
  local memory_usage=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
  local disk_usage=$(df -h /opt | awk 'NR==2{print $5}')
  
  log "System resources: CPU=$cpu_usage%, Memory=$memory_usage, Disk=$disk_usage" "PERF"
}

# Service dependency validation
validate_dependencies() {
  local service="$1"
  local dependencies="${SERVICES[$service]}"
  local dep_check=true
  
  log "Validating dependencies for $service: $dependencies" "INFO"
  
  case "$service" in
    keycloak)
      if ! is_running "postgres" || ! is_running "vault"; then
        log "Keycloak dependency check failed: requires postgres and vault" "ERROR"
        dep_check=false
      fi
      ;;
    nginx)
      if ! is_running "vault"; then
        log "Nginx dependency check failed: requires vault for PKI" "ERROR"
        dep_check=false
      fi
      ;;
    vault-agent|prometheus|loki|grafana|plane|codeserver)
      if ! is_running "vault"; then
        log "$service dependency check failed: requires vault" "ERROR"
        dep_check=false
      fi
      ;;
    plane)
      if ! is_running "postgres" || ! is_running "vault"; then
        log "Plane dependency check failed: requires postgres and vault" "ERROR"
        dep_check=false
      fi
      ;;
  esac
  
  if [[ "$dep_check" == "true" ]]; then
    log "Dependency validation passed for $service" "SUCCESS"
    return 0
  else
    log "Dependency validation failed for $service" "ERROR"
    return 1
  fi
}

# Token rotation stress test
test_token_rotation() {
  log "=== Testing Vault Token Rotation ===" "INFO"
  
  if ! vault_connectivity_test; then
    log "Skipping token rotation test - Vault not accessible" "WARNING"
    return 1
  fi
  
  # Create a test token
  local test_token=$(vault token create -policy=default -ttl=30s -format=json 2>/dev/null | jq -r '.auth.client_token')
  
  if [[ -n "$test_token" && "$test_token" != "null" ]]; then
    log "Created test token for rotation: ${test_token:0:8}..." "SUCCESS"
    
    # Test token usage
    VAULT_TOKEN="$test_token" vault token lookup >/dev/null 2>&1
    local lookup_result=$?
    
    if [[ $lookup_result -eq 0 ]]; then
      log "Test token lookup successful" "SUCCESS"
    else
      log "Test token lookup failed" "ERROR"
    fi
    
    # Wait for token to expire and test
    log "Waiting for token expiration..." "INFO"
    sleep 35
    
    VAULT_TOKEN="$test_token" vault token lookup >/dev/null 2>&1
    local expired_result=$?
    
    if [[ $expired_result -ne 0 ]]; then
      log "Token correctly expired after TTL" "SUCCESS"
    else
      log "Token did not expire as expected" "ERROR"
    fi
  else
    log "Failed to create test token for rotation test" "ERROR"
    return 1
  fi
}

# Generate comprehensive report
generate_report() {
  local test_duration="$1"
  local report_file="/tmp/stress-test-report-$(date +%Y%m%d-%H%M%S).json"

  log "=== Generating Comprehensive Stress Test Report ===" "INFO"

  # Check for jq
  if ! command -v jq >/dev/null 2>&1; then
    log "jq is not installed. Cannot generate JSON report." "ERROR"
    echo "jq is not installed. Cannot generate JSON report." >&2
    return 1
  fi

  # Check write permissions
  if ! touch "$report_file" 2>/dev/null; then
    log "Cannot write to $report_file. Check permissions." "ERROR"
    echo "Cannot write to $report_file. Check permissions." >&2
    return 1
  fi
  rm -f "$report_file"

  # Calculate success rate
  local total_tests=${METRICS["total_tests"]}
  local successful_tests=${METRICS["successful_tests"]}
  local success_rate=0
  if [[ $total_tests -gt 0 ]]; then
    success_rate=$(echo "scale=2; $successful_tests * 100 / $total_tests" | bc -l 2>/dev/null || echo "0")
  fi

  # Calculate Vault operation success rate
  local vault_ops=${METRICS["vault_operations"]}
  local vault_failures=${METRICS["vault_failures"]}
  local vault_success_rate=0
  if [[ $vault_ops -gt 0 ]]; then
    vault_success_rate=$(echo "scale=2; ($vault_ops - $vault_failures) * 100 / $vault_ops" | bc -l 2>/dev/null || echo "0")
  fi

  # Generate JSON report
  {
    echo "{"
    echo "  \"stress_test_report\": {"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," 
    echo "    \"test_duration_seconds\": $test_duration,"
    echo "    \"configuration\": {"
    echo "      \"iterations\": $ITERATIONS,"
    echo "      \"concurrent_operations\": $CONCURRENT_OPS,"
    echo "      \"stress_level\": \"$STRESS_LEVEL\"," 
    echo "      \"vault_ops_per_iteration\": $VAULT_OPS_PER_ITERATION,"
    if [[ -n "$SINGLE_SERVICE" ]]; then
      echo "      \"single_service_mode\": true,"
      echo "      \"target_service\": \"$SINGLE_SERVICE\","
      echo "      \"service_dependencies\": \"${SERVICES[$SINGLE_SERVICE]}\""
    else
      echo "      \"single_service_mode\": false"
    fi
    echo "    },"
    echo "    \"metrics\": {"
    echo "      \"total_tests\": $total_tests,"
    echo "      \"successful_tests\": $successful_tests,"
    echo "      \"failed_tests\": ${METRICS["failed_tests"]},"
    echo "      \"success_rate_percent\": $success_rate,"
    echo "      \"vault_operations\": $vault_ops,"
    echo "      \"vault_failures\": $vault_failures,"
    echo "      \"vault_success_rate_percent\": $vault_success_rate"
    echo "    },"
    echo "    \"services_tested\": ["
    local first=true
    if [[ -n "$SINGLE_SERVICE" ]]; then
      echo "      \"$SINGLE_SERVICE\""
    else
      for service in "${!SERVICES[@]}"; do
        if [[ "$first" == "false" ]]; then
          echo ","
        fi
        echo -n "      \"$service\""
        first=false
      done
    fi
    echo ""
    echo "    ],"
    echo "    \"recommendations\": []"
    echo "  }"
    echo "}"
  } > "$report_file" || { log "Failed to write JSON report to $report_file" "ERROR"; echo "Failed to write JSON report to $report_file" >&2; return 1; }


  # Add recommendations based on results
  if [[ $(echo "$success_rate < 90" | bc -l 2>/dev/null || echo "1") -eq 1 ]]; then
    if ! jq '.stress_test_report.recommendations += ["Overall success rate below 90% - investigate failing services"]' "$report_file" > "${report_file}.tmp" && mv "${report_file}.tmp" "$report_file"; then
      log "Failed to update recommendations in report (success rate)" "ERROR"
    fi
  fi

  if [[ $(echo "$vault_success_rate < 95" | bc -l 2>/dev/null || echo "1") -eq 1 ]]; then
    if ! jq '.stress_test_report.recommendations += ["Vault operation success rate below 95% - check Vault performance"]' "$report_file" > "${report_file}.tmp" && mv "${report_file}.tmp" "$report_file"; then
      log "Failed to update recommendations in report (vault success rate)" "ERROR"
    fi
  fi

  # Add remediation for Postgres dynamic credentials failures
  if grep -q "PostgreSQL dynamic credentials: FAILED" "$LOG_FILE"; then
    if ! jq '.stress_test_report.recommendations += [
      "Remediation for Postgres dynamic credentials failure:",
      "1. Ensure Vault database secrets engine is enabled at path database/.",
      "2. Verify the postgres-role exists and is configured with correct creation statements.",
      "3. Check Vault policy allows access to database/creds/postgres-role.",
      "4. Confirm Postgres is running and accessible from the Vault container.",
      "5. Validate that the generated credentials can connect to Postgres (check pg_hba.conf and user privileges).",
      "6. Review Vault and Postgres logs for errors during credential creation or login.",
      "7. Test manually: vault read database/creds/postgres-role and try to connect with returned credentials."
    ]' "$report_file" > "${report_file}.tmp" && mv "${report_file}.tmp" "$report_file"; then
      log "Failed to update Postgres remediation in report" "ERROR"
    fi
  fi

  # Add generic remediation for any service failures
  if grep -q "FAILED" "$LOG_FILE"; then
    if ! jq '.stress_test_report.recommendations += [
      "General remediation steps for Vault/service integration failures:",
      "- Check Vault secrets engine and role configuration for the service.",
      "- Ensure Vault token/policy grants required permissions.",
      "- Validate service container is running and healthy.",
      "- Review service and Vault logs for error details.",
      "- Test secrets retrieval and usage manually for the failing service."
    ]' "$report_file" > "${report_file}.tmp" && mv "${report_file}.tmp" "$report_file"; then
      log "Failed to update general remediation in report" "ERROR"
    fi
  fi

  log "Stress test report generated: $report_file" "SUCCESS"
  log "Overall Success Rate: ${success_rate}%" "INFO"
  log "Vault Success Rate: ${vault_success_rate}%" "INFO"

  # Display summary
  echo "=================================================="
  if [[ -n "$SINGLE_SERVICE" ]]; then
    echo "SINGLE SERVICE STRESS TEST SUMMARY ($SINGLE_SERVICE)"
  else
    echo "STRESS TEST SUMMARY"
  fi
  echo "=================================================="
  echo "Duration: ${test_duration}s"
  echo "Total Tests: $total_tests"
  echo "Successful: $successful_tests"
  echo "Failed: ${METRICS["failed_tests"]}"
  echo "Success Rate: ${success_rate}%"
  echo "Vault Operations: $vault_ops"
  echo "Vault Failures: $vault_failures"
  echo "Vault Success Rate: ${vault_success_rate}%"
  if [[ -n "$SINGLE_SERVICE" ]]; then
    echo "Target Service: $SINGLE_SERVICE"
    echo "Dependencies: ${SERVICES[$SINGLE_SERVICE]}"
  fi
  echo "Report: $report_file"
  echo "Detailed Logs: $STRESS_LOG"
  echo "=================================================="
}

# Main stress test execution

# Trap errors and always generate a report
trap 'last_status=$?; log "[FATAL] Script exited unexpectedly with code $last_status" "ERROR"; generate_report "$(( $(date +%s) - ${start_time:-$(date +%s)} ) )"; exit $last_status' ERR

main() {
  start_time=$(date +%s)
  log "=== Starting Enhanced Vault & Vault Agent Stress Test ===" "INFO"
  log "Configuration: Iterations=$ITERATIONS, Concurrent Ops=$CONCURRENT_OPS, Stress Level=$STRESS_LEVEL" "INFO"
  
  # Single service mode
  if [[ -n "$SINGLE_SERVICE" ]]; then
    if [[ -n "${SERVICES[$SINGLE_SERVICE]:-}" ]]; then
      log "Single service mode: Testing only $SINGLE_SERVICE" "INFO"
      log "Service dependencies: ${SERVICES[$SINGLE_SERVICE]}" "INFO"
    else
      log "Error: Service '$SINGLE_SERVICE' not found in SERVICES array" "ERROR"
      log "Available services: ${!SERVICES[*]}" "INFO"
      exit 1
    fi
  else
    log "Full stack mode: Testing all ${#SERVICES[@]} services" "INFO"
  fi
  
  log "Detailed logs: $STRESS_LOG" "INFO"

  # Initial Vault connectivity test
  if ! vault_connectivity_test; then
    log "Initial Vault connectivity test failed - aborting stress test" "ERROR"
    generate_report "$(( $(date +%s) - $start_time ))"
    exit 1
  fi

  # Token rotation test (run once at the beginning, skip for single service mode unless it's vault)
  if [[ -z "$SINGLE_SERVICE" || "$SINGLE_SERVICE" == "vault" ]]; then
    test_token_rotation || log "Token rotation test failed, continuing with main tests" "WARNING"
    log "Token rotation test complete. Proceeding to main service tests." "INFO"
  else
    log "Skipping token rotation test in single service mode (not testing vault)" "INFO"
  fi

  # Main stress test iterations
  for ((i=1; i<=ITERATIONS; i++)); do
    log "=== Stress Test Iteration $i/$ITERATIONS ===" "INFO"

    # Monitor resources every 5 iterations (only in full stack mode)
    if [[ $((i % 5)) -eq 0 && -z "$SINGLE_SERVICE" ]]; then
      monitor_resources "$i"
    fi

    # Determine which services to test
    local services_to_test=()
    if [[ -n "$SINGLE_SERVICE" ]]; then
      services_to_test=("$SINGLE_SERVICE")
      log "Testing single service: $SINGLE_SERVICE" "INFO"
    else
      # Test all services
      for service in "${!SERVICES[@]}"; do
        services_to_test+=("$service")
      done
    fi

    for service in "${services_to_test[@]}"; do
      if [[ -z "${service+x}" || -z "$service" ]]; then
        log "Skipping unset or empty service name in main loop" "WARNING"
        continue
      fi
      log "Testing service: $service" "INFO"

      if [[ "$DRY_RUN" == "1" ]]; then
        log "[DRY RUN] Simulating service $service as down" "INFO"
        vault_secret_check "$service" "$CONCURRENT_OPS"
        continue
      fi

      if is_running "$service"; then
        if is_healthy "$service"; then
          # Validate dependencies (skip dependency checks for single service mode)
          if [[ -n "$SINGLE_SERVICE" ]] || validate_dependencies "$service"; then
            if [[ -n "$SINGLE_SERVICE" ]]; then
              log "Skipping dependency validation in single service mode" "INFO"
            fi
            # Run Vault integration tests
            vault_secret_check "$service" "$CONCURRENT_OPS"
          else
            log "Skipping Vault tests for $service due to dependency failure" "WARNING"
            METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
          fi
        else
          log "Service $service is not healthy - skipping tests" "ERROR"
          METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
        fi
      else
        log "Service $service is not running - skipping tests" "ERROR"
        METRICS["failed_tests"]=$((METRICS["failed_tests"] + 1))
      fi

      # Small delay between service tests
      sleep "$SLEEP_BETWEEN_OPS"
    done

    log "=== End of Iteration $i/$ITERATIONS ===" "INFO"

    # Longer delay between iterations for system recovery
    if [[ $i -lt $ITERATIONS ]]; then
      sleep 2
    fi
  done

  local end_time=$(date +%s)
  local test_duration=$((end_time - start_time))

  if [[ -n "$SINGLE_SERVICE" ]]; then
    log "=== Enhanced Vault & Vault Agent Stress Test Complete for $SINGLE_SERVICE ===" "SUCCESS"
  else
    log "=== Enhanced Vault & Vault Agent Stress Test Complete ===" "SUCCESS"
  fi

  # Generate comprehensive report
  generate_report "$test_duration"
}

# Execute main function
main "$@"
