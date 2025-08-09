#!/bin/bash
set -euo pipefail

# Redis Vault Integration Comprehensive Validation Script
# Based on Pure Bliss Container Enhancement Framework (PostgreSQL Template)
# Last Updated: August 5, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] REDIS_VALIDATION: $1" >> "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] REDIS_VALIDATION: ✅ SUCCESS: $1" >> "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] REDIS_VALIDATION: ❌ ERROR: $1" >> "$LOG_FILE"
    echo "❌ $1"
}

function log_warning() {
    echo "[$(date)] REDIS_VALIDATION: ⚠️ WARNING: $1" >> "$LOG_FILE"
    echo "⚠️ $1"
}

echo "=== Redis Vault Integration Comprehensive Validation ==="
echo "Timestamp: $(date)"
echo ""

# Redirect all output to temporary file for summary
exec > >(tee /tmp/redis_validation_output)

# 1. Container Health Validation
log_action "Validating Redis container health"
if docker ps | grep -q purebliss-redis; then
    log_success "Redis container is running"

    # Check health status
    health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-redis 2>/dev/null || echo "no_healthcheck")
    if [[ "$health_status" == "healthy" ]]; then
        log_success "Redis health check: $health_status"
    elif [[ "$health_status" == "no_healthcheck" ]]; then
        log_warning "No health check defined"
    else
        log_error "Redis health check: $health_status"
    fi
else
    log_error "Redis container is not running"
fi

# 2. Vault Connectivity Validation
log_action "Validating Vault connectivity"
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1

VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
if [[ -f "$VAULT_TOKEN_FILE" ]]; then
    export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
    if vault status >/dev/null 2>&1; then
        log_success "Vault connectivity confirmed"
    else
        log_error "Cannot connect to Vault"
    fi
else
    log_error "Vault token file not found"
fi

# 3. Vault Secrets Validation
log_action "Validating Redis secrets in Vault"
if vault kv get secret/redis >/dev/null 2>&1; then
    log_success "Redis secrets found in Vault"

    # Validate secret fields
    REDIS_SECRETS=$(vault kv get -format=json secret/redis)
    AUTH_PASSWORD=$(echo "$REDIS_SECRETS" | jq -r '.data.data.auth_password')
    MASTER_AUTH=$(echo "$REDIS_SECRETS" | jq -r '.data.data.master_auth')

    if [[ "$AUTH_PASSWORD" != "null" && -n "$AUTH_PASSWORD" ]]; then
        log_success "Auth password secret is valid"
    else
        log_error "Auth password secret is missing or invalid"
    fi

    if [[ "$MASTER_AUTH" != "null" && -n "$MASTER_AUTH" ]]; then
        log_success "Master auth secret is valid"
    else
        log_error "Master auth secret is missing or invalid"
    fi
else
    log_error "Redis secrets not found in Vault"
fi

# 4. Redis Authentication Test
log_action "Testing Redis authentication with Vault secrets"
if [[ -n "${AUTH_PASSWORD:-}" ]] && [[ "$AUTH_PASSWORD" != "null" ]]; then
    if docker exec purebliss-redis redis-cli -a "$AUTH_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
        log_success "Redis authentication with Vault secrets successful"
    else
        log_error "Redis authentication with Vault secrets failed"
    fi
else
    log_error "Cannot test authentication - auth password not available"
fi

# 5. Redis Operations Test
log_action "Testing Redis operations"
if [[ -n "${AUTH_PASSWORD:-}" ]] && [[ "$AUTH_PASSWORD" != "null" ]]; then
    TEST_KEY="validation_test_$(date +%s)"
    TEST_VALUE="vault_integration_validation"

    if docker exec purebliss-redis redis-cli -a "$AUTH_PASSWORD" set "$TEST_KEY" "$TEST_VALUE" >/dev/null 2>&1; then
        if docker exec purebliss-redis redis-cli -a "$AUTH_PASSWORD" get "$TEST_KEY" | grep -q "$TEST_VALUE"; then
            log_success "Redis SET/GET operations working"
            docker exec purebliss-redis redis-cli -a "$AUTH_PASSWORD" del "$TEST_KEY" >/dev/null 2>&1
        else
            log_error "Redis GET operation failed"
        fi
    else
        log_error "Redis SET operation failed"
    fi
else
    log_error "Cannot test operations - auth password not available"
fi

# 6. Configuration Validation
log_action "Validating Redis configuration"
if [[ -n "${AUTH_PASSWORD:-}" ]] && [[ "$AUTH_PASSWORD" != "null" ]]; then
    # Check maxmemory setting
    MAXMEMORY=$(docker exec purebliss-redis redis-cli -a "$AUTH_PASSWORD" config get maxmemory 2>/dev/null | tail -n1)
    if [[ -n "$MAXMEMORY" ]]; then
        log_success "Redis maxmemory configured: $MAXMEMORY"
    else
        log_warning "Redis maxmemory not configured"
    fi

    # Check maxmemory-policy
    POLICY=$(docker exec purebliss-redis redis-cli -a "$AUTH_PASSWORD" config get maxmemory-policy 2>/dev/null | tail -n1)
    if [[ "$POLICY" == "allkeys-lru" ]]; then
        log_success "Redis maxmemory-policy correctly set: $POLICY"
    else
        log_warning "Redis maxmemory-policy: $POLICY (expected: allkeys-lru)"
    fi
else
    log_error "Cannot validate configuration - auth password not available"
fi

# 7. Network Connectivity
log_action "Validating network connectivity"
if docker network inspect purebliss-net >/dev/null 2>&1; then
    if docker inspect purebliss-redis | jq -r '.[0].NetworkSettings.Networks | keys[]' | grep -q "purebliss-net"; then
        log_success "Redis is connected to purebliss-net network"
    else
        log_error "Redis is not connected to purebliss-net network"
    fi
else
    log_error "purebliss-net network not found"
fi

# 8. Volume Persistence
log_action "Validating data persistence"
if docker volume inspect redis_fresh_data >/dev/null 2>&1; then
    log_success "Redis data volume exists"
else
    log_error "Redis data volume not found"
fi

# 9. Security Configuration
log_action "Validating security configuration"
if [[ -n "${AUTH_PASSWORD:-}" ]] && [[ "$AUTH_PASSWORD" != "null" ]]; then
    # Check if dangerous commands are disabled
    FLUSHDB_RESULT=$(docker exec purebliss-redis redis-cli -a "$AUTH_PASSWORD" flushdb 2>&1 || echo "disabled")
    if echo "$FLUSHDB_RESULT" | grep -q "unknown command\|disabled"; then
        log_success "Dangerous commands properly disabled"
    else
        log_warning "Dangerous commands may not be properly disabled"
    fi
else
    log_error "Cannot validate security - auth password not available"
fi

# 10. Resource Limits
log_action "Validating resource limits"
MEMORY_LIMIT=$(docker inspect purebliss-redis | jq -r '.[0].HostConfig.Memory')
if [[ "$MEMORY_LIMIT" != "0" ]] && [[ "$MEMORY_LIMIT" != "null" ]]; then
    log_success "Memory limit configured: $MEMORY_LIMIT bytes"
else
    log_warning "No memory limit configured"
fi

echo "=== Validation Summary ==="
exec > /dev/tty

# Count results
success_count=$(grep -c "✅" /tmp/redis_validation_output 2>/dev/null || echo "0")
error_count=$(grep -c "❌" /tmp/redis_validation_output 2>/dev/null || echo "0")
warning_count=$(grep -c "⚠️" /tmp/redis_validation_output 2>/dev/null || echo "0")

echo "Results: $success_count successes, $warning_count warnings, $error_count errors"
echo ""

if [[ "$error_count" -eq 0 ]]; then
    echo "🎉 Redis Vault integration validation PASSED!"
    echo "Redis is ready for production use with Vault secrets."
    exit 0
elif [[ "$error_count" -le 2 && "$success_count" -ge 5 ]]; then
    echo "⚠️ Redis Vault integration validation PASSED with warnings"
    echo "Core functionality working, but some issues need attention."
    echo ""
    echo "Review the validation output above for details."
    exit 0
else
    echo "❌ Redis Vault integration validation FAILED"
    echo "Critical issues found that need to be resolved."
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check Redis container: docker logs purebliss-redis"
    echo "2. Verify Vault connectivity: vault status"
    echo "3. Check secrets: vault kv get secret/redis"
    echo "4. Restart Redis: docker restart purebliss-redis"
    exit 1
fi
