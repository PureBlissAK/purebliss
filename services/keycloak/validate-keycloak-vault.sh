#!/bin/bash
set -euo pipefail

# Keycloak Vault Integration Validation Script
# Comprehensive testing of Keycloak with Vault and PostgreSQL integration
# Author: PureBliss Development Team

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/opt/logs/dev-environment-setup.log"

# Test configuration
KEYCLOAK_URL="http://localhost:8080"
VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

log_test() {
    TEST_COUNT=$((TEST_COUNT + 1))
    echo "[$TEST_COUNT] $1"
    echo "[$(date)] TEST: Keycloak-Validation [$TEST_COUNT]: $1" >> "$LOG_FILE"
}

log_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "    ✅ PASS: $1"
    echo "[$(date)] PASS: Keycloak-Validation: $1" >> "$LOG_FILE"
}

log_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "    ❌ FAIL: $1"
    echo "[$(date)] FAIL: Keycloak-Validation: $1" >> "$LOG_FILE"
}

log_info() {
    echo "    ℹ️  INFO: $1"
    echo "[$(date)] INFO: Keycloak-Validation: $1" >> "$LOG_FILE"
}

log_warn() {
    echo "    ⚠️  WARN: $1"
    echo "[$(date)] WARN: Keycloak-Validation: $1" >> "$LOG_FILE"
}

# Test 1: Container Status
test_container_status() {
    log_test "Container Status Check"

    if docker ps | grep -q "purebliss-keycloak"; then
        local status=$(docker inspect purebliss-keycloak --format '{{.State.Status}}' 2>/dev/null || echo "unknown")
        if [ "$status" = "running" ]; then
            log_pass "Container is running"
        else
            log_fail "Container status: $status"
        fi
    else
        log_fail "Container not found or not running"
    fi
}

# Test 2: Health Endpoint
test_health_endpoint() {
    log_test "Health Endpoint Check"

    local health_url="$KEYCLOAK_URL/auth/health"
    local ready_url="$KEYCLOAK_URL/auth/health/ready"
    local live_url="$KEYCLOAK_URL/auth/health/live"

    # Test general health
    if curl -s -f "$health_url" > /dev/null; then
        log_pass "Health endpoint accessible"
    else
        log_fail "Health endpoint not accessible"
    fi

    # Test readiness
    if curl -s -f "$ready_url" > /dev/null; then
        log_pass "Ready endpoint reports ready"
    else
        log_fail "Ready endpoint not ready"
    fi

    # Test liveness
    if curl -s -f "$live_url" > /dev/null; then
        log_pass "Live endpoint reports alive"
    else
        log_fail "Live endpoint not alive"
    fi
}

# Test 3: Admin Console Access
test_admin_console() {
    log_test "Admin Console Access"

    local admin_url="$KEYCLOAK_URL/auth/admin"
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$admin_url" || echo "000")

    if [ "$response_code" = "200" ] || [ "$response_code" = "302" ]; then
        log_pass "Admin console accessible (HTTP $response_code)"
    else
        log_fail "Admin console not accessible (HTTP $response_code)"
    fi
}

# Test 4: Database Connectivity
test_database_connectivity() {
    log_test "Database Connectivity"

    # Load environment
    if [ -f "$SCRIPT_DIR/.env" ]; then
        source "$SCRIPT_DIR/.env"
    fi

    local db_host="${POSTGRES_HOST:-purebliss-postgres}"
    local db_port="${POSTGRES_PORT:-5432}"
    local db_name="${KEYCLOAK_DB_NAME:-keycloak}"
    local db_user="${KEYCLOAK_DB_USER:-keycloak}"
    local db_password="${KEYCLOAK_DB_PASSWORD:-keycloak_secure_password}"

    # Test database connection
    if PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT 1;" > /dev/null 2>&1; then
        log_pass "Database connection successful"

        # Test Keycloak tables exist
        local table_count
        table_count=$(PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE '%keycloak%' OR table_name LIKE '%realm%' OR table_name LIKE '%user_%';" 2>/dev/null | tr -d ' ' || echo "0")

        if [ "$table_count" -gt "0" ]; then
            log_pass "Keycloak database tables exist ($table_count found)"
        else
            log_info "No Keycloak tables found (may be first run)"
        fi
    else
        log_fail "Database connection failed"
    fi
}

# Test 5: Redis Connectivity
test_redis_connectivity() {
    log_test "Redis Connectivity"

    # Load environment
    if [ -f "$SCRIPT_DIR/.env" ]; then
        source "$SCRIPT_DIR/.env"
    fi

    local redis_host="${REDIS_HOST:-purebliss-redis}"
    local redis_port="${REDIS_PORT:-6379}"
    local redis_database="${REDIS_DATABASE:-1}"
    local redis_password="${REDIS_PASSWORD}"

    # Test Redis connection using redis-cli if available
    if command -v redis-cli >/dev/null 2>&1; then
        if redis-cli -h "$redis_host" -p "$redis_port" ${redis_password:+-a "$redis_password"} ping > /dev/null 2>&1; then
            log_pass "Redis connection successful"

            # Test Redis database selection
            if redis-cli -h "$redis_host" -p "$redis_port" ${redis_password:+-a "$redis_password"} -n "$redis_database" ping > /dev/null 2>&1; then
                log_pass "Redis database $redis_database accessible"

                # Test basic Redis operations
                local test_key="keycloak:test:$(date +%s)"
                if redis-cli -h "$redis_host" -p "$redis_port" ${redis_password:+-a "$redis_password"} -n "$redis_database" SET "$test_key" "test_value" EX 60 > /dev/null 2>&1; then
                    log_pass "Redis write operation successful"

                    if redis-cli -h "$redis_host" -p "$redis_port" ${redis_password:+-a "$redis_password"} -n "$redis_database" GET "$test_key" | grep -q "test_value" 2>/dev/null; then
                        log_pass "Redis read operation successful"
                        # Clean up test key
                        redis-cli -h "$redis_host" -p "$redis_port" ${redis_password:+-a "$redis_password"} -n "$redis_database" DEL "$test_key" > /dev/null 2>&1
                    else
                        log_fail "Redis read operation failed"
                    fi
                else
                    log_fail "Redis write operation failed"
                fi
            else
                log_fail "Redis database $redis_database not accessible"
            fi
        else
            log_fail "Redis connection failed"
        fi
    else
        # Test using Docker if redis-cli not available
        if docker exec purebliss-redis redis-cli -h localhost -p "$redis_port" ${redis_password:+-a "$redis_password"} ping > /dev/null 2>&1; then
            log_pass "Redis connection successful (via Docker)"
        else
            log_fail "Redis connection failed and redis-cli not available"
        fi
    fi
}

# Test 6: Vault Connectivity
test_vault_connectivity() {
    log_test "Vault Connectivity"

    # Test Vault health
    local vault_health=$(curl -s "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo '{"sealed":true}')
    local vault_sealed=$(echo "$vault_health" | jq -r '.sealed // true' 2>/dev/null || echo "true")

    if echo "$vault_health" | jq -e '.' > /dev/null 2>&1; then
        log_pass "Vault is accessible"

        if [ "$vault_sealed" = "false" ]; then
            log_pass "Vault is unsealed"
        else
            log_warn "Vault is sealed"
        fi
    else
        log_fail "Vault is not accessible"
    fi
}

# Test 7: Vault Secrets Access
test_vault_secrets() {
    log_test "Vault Secrets Access"

    # Get token
    local vault_token=""
    if [ -n "${VAULT_TOKEN:-}" ]; then
        vault_token="$VAULT_TOKEN"
    elif [ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]; then
        vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    fi

    if [ -z "$vault_token" ]; then
        log_fail "No Vault token available"
        return
    fi

    # Test Keycloak secrets
    local db_secret=$(curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/secret/data/keycloak/database" 2>/dev/null || echo '{}')
    if echo "$db_secret" | jq -e '.data.data.username' > /dev/null 2>&1; then
        log_pass "Keycloak database secrets accessible in Vault"
    else
        log_fail "Keycloak database secrets not found in Vault"
    fi

    local admin_secret=$(curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/secret/data/keycloak/admin" 2>/dev/null || echo '{}')
    if echo "$admin_secret" | jq -e '.data.data.username' > /dev/null 2>&1; then
        log_pass "Keycloak admin secrets accessible in Vault"
    else
        log_fail "Keycloak admin secrets not found in Vault"
    fi
}

# Test 7: Container Logs Check
test_container_logs() {
    log_test "Container Logs Analysis"

    if ! docker ps | grep -q "purebliss-keycloak"; then
        log_fail "Container not running, cannot check logs"
        return
    fi

    local logs=$(docker logs purebliss-keycloak --tail 50 2>&1 || echo "")

    # Check for startup success
    if echo "$logs" | grep -q "Keycloak.*started"; then
        log_pass "Keycloak startup successful"
    elif echo "$logs" | grep -q "KC.*started in"; then
        log_pass "Keycloak started successfully"
    else
        log_warn "Keycloak startup status unclear from logs"
    fi

    # Check for database connection
    if echo "$logs" | grep -q -i "database.*connected\|connection.*successful"; then
        log_pass "Database connection logged"
    elif echo "$logs" | grep -q -i "database.*error\|connection.*failed"; then
        log_fail "Database connection errors in logs"
    else
        log_info "No explicit database connection status in logs"
    fi

    # Check for Vault integration
    if echo "$logs" | grep -q -i "vault.*success\|vault.*configured"; then
        log_pass "Vault integration logged"
    elif echo "$logs" | grep -q -i "vault.*error\|vault.*failed"; then
        log_fail "Vault integration errors in logs"
    else
        log_info "No explicit Vault integration status in logs"
    fi

    # Check for errors
    local error_count=$(echo "$logs" | grep -c -i "error\|exception\|failed" || echo "0")
    if [ "$error_count" -eq "0" ]; then
        log_pass "No errors in recent logs"
    else
        log_warn "$error_count errors found in recent logs"
    fi
}

# Test 8: Admin Authentication
test_admin_authentication() {
    log_test "Admin Authentication"

    # Get admin credentials from Vault
    local vault_token=""
    if [ -n "${VAULT_TOKEN:-}" ]; then
        vault_token="$VAULT_TOKEN"
    elif [ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]; then
        vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    fi

    if [ -z "$vault_token" ]; then
        log_warn "No Vault token, skipping admin authentication test"
        return
    fi

    local admin_secret=$(curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/secret/data/keycloak/admin" 2>/dev/null || echo '{}')
    local admin_user=$(echo "$admin_secret" | jq -r '.data.data.username // "admin"' 2>/dev/null || echo "admin")
    local admin_password=$(echo "$admin_secret" | jq -r '.data.data.password // "admin123"' 2>/dev/null || echo "admin123")

    # Test admin login
    local auth_url="$KEYCLOAK_URL/auth/realms/master/protocol/openid-connect/token"
    local auth_response=$(curl -s -X POST "$auth_url" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$admin_user" \
        -d "password=$admin_password" \
        -d "grant_type=password" \
        -d "client_id=admin-cli" 2>/dev/null || echo '{}')

    if echo "$auth_response" | jq -e '.access_token' > /dev/null 2>&1; then
        log_pass "Admin authentication successful"
    else
        log_fail "Admin authentication failed"
        log_info "Auth response: $(echo "$auth_response" | jq -r '.error_description // .error // "Unknown error"' 2>/dev/null || echo "No response")"
    fi
}

# Test 9: Performance Metrics
test_performance() {
    log_test "Performance Metrics"

    if ! docker ps | grep -q "purebliss-keycloak"; then
        log_fail "Container not running, cannot check performance"
        return
    fi

    # Memory usage
    local memory_usage
    memory_usage=$(docker stats purebliss-keycloak --no-stream --format "table {{.MemUsage}}" | tail -n 1 | awk '{print $1}' | sed 's/MiB//' || echo "0")
    if [ "${memory_usage%.*}" -lt "1000" ]; then
        log_pass "Memory usage acceptable: ${memory_usage}MiB"
    else
        log_warn "High memory usage: ${memory_usage}MiB"
    fi

    # CPU usage
    local cpu_usage
    cpu_usage=$(docker stats purebliss-keycloak --no-stream --format "table {{.CPUPerc}}" | tail -n 1 | sed 's/%//' || echo "0")
    if [ "${cpu_usage%.*}" -lt "50" ]; then
        log_pass "CPU usage acceptable: ${cpu_usage}%"
    else
        log_warn "High CPU usage: ${cpu_usage}%"
    fi

    # Response time
    local start_time=$(date +%s%3N)
    curl -s "$KEYCLOAK_URL/auth" > /dev/null 2>&1 || true
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))

    if [ "$response_time" -lt "2000" ]; then
        log_pass "Response time acceptable: ${response_time}ms"
    else
        log_warn "Slow response time: ${response_time}ms"
    fi
}

# Test 10: Configuration Validation
test_configuration() {
    log_test "Configuration Validation"

    # Check environment file
    if [ -f "$SCRIPT_DIR/.env" ]; then
        log_pass "Environment file exists"

        # Validate required variables
        source "$SCRIPT_DIR/.env"
        local required_vars=("VAULT_ADDR" "POSTGRES_HOST" "KEYCLOAK_DB_NAME" "KC_HOSTNAME")
        local missing_vars=0

        for var in "${required_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                log_fail "Missing required variable: $var"
                missing_vars=$((missing_vars + 1))
            fi
        done

        if [ "$missing_vars" -eq "0" ]; then
            log_pass "All required environment variables present"
        fi
    else
        log_fail "Environment file missing"
    fi

    # Check Docker Compose file
    if [ -f "$SCRIPT_DIR/keycloak-vault-docker-compose.yml" ]; then
        log_pass "Docker Compose file exists"
    else
        log_fail "Docker Compose file missing"
    fi

    # Check entrypoint script
    if [ -f "$SCRIPT_DIR/keycloak-vault-entrypoint.sh" ] && [ -x "$SCRIPT_DIR/keycloak-vault-entrypoint.sh" ]; then
        log_pass "Entrypoint script exists and is executable"
    else
        log_fail "Entrypoint script missing or not executable"
    fi
}

# Generate summary report
generate_summary() {
    echo ""
    echo "====================================="
    echo "KEYCLOAK VAULT INTEGRATION TEST SUMMARY"
    echo "====================================="
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"
    echo "Success Rate: $(( (PASS_COUNT * 100) / TEST_COUNT ))%"
    echo ""

    if [ "$FAIL_COUNT" -eq "0" ]; then
        echo "🎉 ALL TESTS PASSED!"
        echo "Keycloak Vault integration is working correctly."
    elif [ "$FAIL_COUNT" -lt "3" ]; then
        echo "⚠️  MINOR ISSUES DETECTED"
        echo "Keycloak is mostly functional but has minor issues."
    else
        echo "❌ CRITICAL ISSUES DETECTED"
        echo "Keycloak has significant problems that need attention."
    fi

    echo ""
    echo "📋 Detailed results logged to: $LOG_FILE"
    echo ""

    # Log summary
    echo "[$(date)] SUMMARY: Keycloak-Validation - Tests: $TEST_COUNT, Passed: $PASS_COUNT, Failed: $FAIL_COUNT" >> "$LOG_FILE"
}

# Main validation function
main() {
    echo "Starting Keycloak Vault Integration Validation"
    echo "=============================================="
    echo ""

    # Run all tests
    test_container_status
    test_health_endpoint
    test_admin_console
    test_database_connectivity
    test_redis_connectivity
    test_vault_connectivity
    test_vault_secrets
    test_container_logs
    test_admin_authentication
    test_performance
    test_configuration

    # Generate summary
    generate_summary

    # Return appropriate exit code
    if [ "$FAIL_COUNT" -eq "0" ]; then
        exit 0
    else
        exit 1
    fi
}

# Execute main function
main "$@"
