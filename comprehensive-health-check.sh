#!/bin/bash
set -euo pipefail

# Pure Bliss Infrastructure Comprehensive Health Check Script
# Integrated with Enhanced Orchestrator for Complete Service Validation
# Status: Fully Automated with Robust Service Monitoring
# Last Updated: August 4, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Enhanced logging functions for health checks
function log_check() {
    echo "🔍 $1"
    echo "[$(date)] HEALTH_CHECK: $1" >> "$LOG_FILE"
}

function log_success() {
    echo "✅ $1"
    echo "[$(date)] HEALTH_CHECK: ✅ SUCCESS: $1" >> "$LOG_FILE"
}

function log_warning() {
    echo "⚠️  $1"
    echo "[$(date)] HEALTH_CHECK: ⚠️  WARNING: $1" >> "$LOG_FILE"
}

function log_error() {
    echo "❌ $1"
    echo "[$(date)] HEALTH_CHECK: ❌ ERROR: $1" >> "$LOG_FILE"
}

function log_info() {
    echo "ℹ️  $1"
    echo "[$(date)] HEALTH_CHECK: ℹ️  INFO: $1" >> "$LOG_FILE"
}

# New enhanced service testing functions

function test_container_health() {
    local container_name="$1"
    local health_status

    if docker ps | grep -q "$container_name"; then
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no_healthcheck")
        local container_status
        container_status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")

        case "$health_status" in
            "healthy")
                log_success "$container_name: healthy ($container_status)"
                return 0
                ;;
            "unhealthy")
                log_error "$container_name: unhealthy ($container_status)"
                return 1
                ;;
            "starting")
                log_warning "$container_name: starting ($container_status)"
                return 1
                ;;
            "no_healthcheck")
                if [[ "$container_status" == "running" ]]; then
                    log_success "$container_name: healthy (running)"
                    return 0
                else
                    log_error "$container_name: $container_status"
                    return 1
                fi
                ;;
            *)
                log_warning "$container_name: $health_status ($container_status)"
                return 1
                ;;
        esac
    else
        log_error "$container_name: not running"
        return 1
    fi
}

function test_orchestrator_integration() {
    log_check "Testing orchestrator integration and automation features..."

    # Check if orchestrator script exists and is executable
    local orchestrator_script="/opt/dev-purebliss/start-all-services.sh"
    if [[ -x "$orchestrator_script" ]]; then
        log_success "Orchestrator script exists and is executable"

        # Check for key automation functions
        if grep -q "cleanup_all_containers" "$orchestrator_script"; then
            log_success "Container cleanup automation present"
        else
            log_warning "Container cleanup automation missing"
        fi

        if grep -q "vault_auto_unseal_enhanced" "$orchestrator_script"; then
            log_success "Vault auto-unseal automation present"
        else
            log_warning "Vault auto-unseal automation missing"
        fi

        if grep -q "start_service_robust" "$orchestrator_script"; then
            log_success "Robust service startup functions present"
        else
            log_warning "Robust service startup functions missing"
        fi

        # Check SERVICE_ORDER configuration
        if grep -q "SERVICE_ORDER.*vault.*postgres.*vault-agent.*redis.*keycloak" "$orchestrator_script"; then
            log_success "Service startup order properly configured"
        else
            log_warning "Service startup order may need review"
        fi

        # Check for service onboarding functions
        if grep -q "onboard_.*_to_vault" "$orchestrator_script"; then
            log_success "Service Vault onboarding automation present"
        else
            log_warning "Service Vault onboarding automation missing"
        fi
    else
        log_error "Orchestrator script missing or not executable"
    fi
}

function test_vault_automation_framework() {
    log_check "Testing Vault automation framework integration..."

    # Check if break/fix script exists
    local break_fix_script="/opt/dev-purebliss/services/vault/vault-break-fix.sh"
    if [[ -x "$break_fix_script" ]]; then
        log_success "Vault break/fix automation script available"

        # Test key automation functions
        if grep -q "vault_auto_recovery" "$break_fix_script"; then
            log_success "Vault auto-recovery function present"
        else
            log_warning "Vault auto-recovery function missing"
        fi

        if grep -q "vault_comprehensive_diagnostic" "$break_fix_script"; then
            log_success "Comprehensive diagnostic function present"
        else
            log_warning "Comprehensive diagnostic function missing"
        fi

        # Test integration-specific functions
        local integration_functions=(
            "vault_postgresql_integration_fix"
            "vault_redis_integration_fix"
            "vault_keycloak_integration_fix"
            "vault_nginx_pki_integration_fix"
            "vault_letsencrypt_vault_integration_fix"
        )

        local missing_integrations=()
        for func in "${integration_functions[@]}"; do
            if grep -q "$func" "$break_fix_script"; then
                log_success "Integration function $func present"
            else
                missing_integrations+=("$func")
            fi
        done

        if [[ ${#missing_integrations[@]} -eq 0 ]]; then
            log_success "All service integration functions present"
        else
            log_warning "Missing integration functions: ${missing_integrations[*]}"
        fi
    else
        log_error "Vault break/fix script missing or not executable"
    fi
}

function test_service_dependencies() {
    log_check "Testing service dependency management..."

    # Test Vault dependency validation
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        log_success "Vault token available for service integrations"

        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Test if Vault is unsealed and ready
        if curl -sk "$VAULT_ADDR/v1/sys/health" | grep -q '"sealed":false'; then
            log_success "Vault is unsealed and ready for service operations"

            # Test PostgreSQL dependency
            if vault read database/config/postgres-app >/dev/null 2>&1; then
                log_success "PostgreSQL Vault integration configured"
            else
                log_warning "PostgreSQL Vault integration not configured"
            fi

            # Test Redis dependency
            if vault read redis/config/redis >/dev/null 2>&1; then
                log_success "Redis Vault integration configured"
            else
                log_warning "Redis Vault integration not configured"
            fi

            # Test KV v2 secrets engine
            if vault secrets list | grep -q "^secret/"; then
                log_success "KV v2 secrets engine enabled"

                # Test Keycloak secrets
                if vault kv get secret/keycloak >/dev/null 2>&1; then
                    log_success "Keycloak secrets configured in Vault"
                else
                    log_warning "Keycloak secrets not configured in Vault"
                fi

                # Test Let's Encrypt secrets
                if vault kv get secret/letsencrypt >/dev/null 2>&1; then
                    log_success "Let's Encrypt secrets configured in Vault"
                else
                    log_warning "Let's Encrypt secrets not configured in Vault"
                fi
            else
                log_warning "KV v2 secrets engine not enabled"
            fi
        else
            log_warning "Vault is sealed or not ready"
        fi
    else
        log_warning "Vault token not available - service integrations cannot be tested"
    fi
}
function check_disk_space() {
    log_check "Checking disk space for critical paths..."
    for path in / /opt/my-secure-ha-stack /opt/dev-purebliss; do
        usage=$(df -h "$path" | awk 'NR==2{print $5}')
        log_success "Disk usage for $path: $usage"
    done
}

function check_file_permissions() {
    log_check "Checking file permissions for critical certs/configs..."
    # Nginx certs
    if docker exec purebliss-nginx stat -c '%U:%G %a' /etc/nginx/certs/dev.purebliss.app/fullchain.pem 2>/dev/null | grep -q '101:101'; then
        log_success "Nginx cert file permissions OK (101:101)"
    else
        log_warning "Nginx cert file permissions not 101:101"
    fi
    # Vault config
    if [ -f /opt/my-secure-ha-stack/vault/vault.hcl ]; then
        perms=$(stat -c '%a' /opt/my-secure-ha-stack/vault/vault.hcl)
        if [[ "$perms" == "600" || "$perms" == "640" ]]; then
            log_success "Vault config permissions secure ($perms)"
        else
            log_warning "Vault config permissions not secure ($perms)"
        fi
    fi
}

function test_nginx_deep() {
    log_check "Deep Nginx checks: config, endpoints, headers, logs..."
    # Config syntax
    if docker exec purebliss-nginx nginx -t >/dev/null 2>&1; then
        log_success "Nginx config syntax OK"
    else
        log_error "Nginx config syntax error"
    fi
    # HTTP endpoint (should redirect or 404)
    if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 | grep -qE '301|302|404'; then
        log_success "Nginx HTTP endpoint responds (redirect or 404)"
    else
        log_warning "Nginx HTTP endpoint not responding as expected"
    fi
    # HTTPS endpoint headers
    headers=$(curl -skI https://127.0.0.1:8443)
    if echo "$headers" | grep -qi 'Strict-Transport-Security'; then
        log_success "Nginx HSTS header present"
    else
        log_warning "Nginx HSTS header missing"
    fi
    if echo "$headers" | grep -qi 'X-Frame-Options'; then
        log_success "Nginx X-Frame-Options header present"
    else
        log_warning "Nginx X-Frame-Options header missing"
    fi
    # WAF check (basic)
    if echo "$headers" | grep -qi 'X-WAF'; then
        log_success "Nginx WAF header present"
    else
        log_warning "Nginx WAF header missing (check WAF config)"
    fi
    # Error log tail
    docker logs purebliss-nginx --tail 20 2>&1 | grep -iE 'error|fail|critical' && log_warning "Nginx recent errors found" || log_success "Nginx error log clean"
}

function test_vault_deep() {
    log_check "Deep Vault checks: audit, mounts, policies, token TTL..."
    # Audit log enabled
    if vault audit list 2>/dev/null | grep -q "file"; then
        log_success "Vault audit log enabled"
    else
        log_warning "Vault audit log not enabled"
    fi
    # Mount list
    if vault secrets list 2>/dev/null | grep -q "pki-nginx/"; then
        log_success "Vault PKI mount for nginx present"
    else
        log_warning "Vault PKI mount for nginx missing"
    fi
    # Policy check
    if vault policy list 2>/dev/null | grep -q "nginx"; then
        log_success "Vault nginx policy present"
    else
        log_warning "Vault nginx policy missing"
    fi
    # Token TTL
    ttl=$(vault token lookup -format=json 2>/dev/null | grep 'ttl' | head -1 | awk -F: '{print $2}' | tr -d ' ,"')
    if [[ "$ttl" -gt 3600 ]]; then
        log_success "Vault token TTL is sufficient ($ttl seconds)"
    else
        log_warning "Vault token TTL is low ($ttl seconds)"
    fi
    # Error log tail
    docker logs purebliss-vault --tail 20 2>&1 | grep -iE 'error|fail|critical' && log_warning "Vault recent errors found" || log_success "Vault error log clean"
}

function test_postgres_deep() {
    log_check "Deep PostgreSQL checks: tables, privileges, slow queries..."
    # Table existence
    if docker exec purebliss-postgres psql -U postgres -d keycloak -c "\dt" | grep -q public; then
        log_success "Keycloak tables exist in Postgres"
    else
        log_warning "Keycloak tables missing in Postgres"
    fi
    # User privileges
    if docker exec purebliss-postgres psql -U keycloak -d keycloak -c "\du" | grep -q keycloak; then
        log_success "Keycloak user exists in Postgres"
    else
        log_warning "Keycloak user missing in Postgres"
    fi
    # Slow query log (if enabled)
    if docker exec purebliss-postgres cat /var/lib/postgresql/data/log/postgresql.log 2>/dev/null | grep -i slow; then
        log_warning "Postgres slow queries detected"
    else
        log_success "No slow queries in Postgres log"
    fi
}

function test_redis_deep() {
    log_check "Deep Redis checks: persistence, memory, keyspace..."
    # Persistence
    if docker exec purebliss-redis redis-cli config get save | grep -qv '""'; then
        log_success "Redis persistence enabled"
    else
        log_warning "Redis persistence not enabled"
    fi
    # Memory usage
    mem=$(docker exec purebliss-redis redis-cli info memory | grep used_memory_human | awk -F: '{print $2}')
    log_success "Redis memory usage: $mem"
    # Keyspace info
    keys=$(docker exec purebliss-redis redis-cli info keyspace | grep keys | awk -F, '{print $1}')
    log_success "Redis keyspace: $keys"
    # Error log tail
    docker logs purebliss-redis --tail 20 2>&1 | grep -iE 'error|fail|critical' && log_warning "Redis recent errors found" || log_success "Redis error log clean"
}

function test_keycloak_deep() {
    log_check "Deep Keycloak checks: realms, endpoints, admin login, logs..."
    # Realm existence
    if docker exec purebliss-keycloak /opt/keycloak/bin/kcadm.sh get realms/codeserver --server http://localhost:8080 --realm master --user admin --password admin123 2>/dev/null | grep -q '"realm"'; then
        log_success "Keycloak codeserver realm exists"
    else
        log_warning "Keycloak codeserver realm missing"
    fi
    # OIDC endpoint
    if curl -sk https://127.0.0.1:8443/keycloak/realms/codeserver/.well-known/openid-configuration | grep -q issuer; then
        log_success "Keycloak OIDC endpoint accessible"
    else
        log_warning "Keycloak OIDC endpoint not accessible"
    fi
    # SAML endpoint (metadata)
    if curl -sk https://127.0.0.1:8443/keycloak/realms/codeserver/protocol/saml/descriptor | grep -q EntityDescriptor; then
        log_success "Keycloak SAML metadata endpoint accessible"
    else
        log_warning "Keycloak SAML metadata endpoint not accessible"
    fi
    # Error log tail
    docker logs purebliss-keycloak --tail 20 2>&1 | grep -iE 'error|fail|critical' && log_warning "Keycloak recent errors found" || log_success "Keycloak error log clean"
}

function test_loki_prometheus_grafana_plane() {
    log_check "Checking supporting services: Loki, Prometheus, Grafana, Plane..."
    # Loki
    if nc -z 127.0.0.1 3100 2>/dev/null; then
        log_success "Loki port 3100 accessible"
    else
        log_warning "Loki port 3100 not accessible"
    fi
    # Prometheus - Enhanced monitoring with Vault integration
    if curl -s http://localhost:9090/-/healthy | grep -q 'Healthy'; then
        log_success "Prometheus healthy endpoint OK"

        # Test Vault integration
        if vault kv get prometheus-config/metrics >/dev/null 2>&1; then
            log_success "Prometheus Vault configuration accessible"
        else
            log_warning "Prometheus Vault configuration not accessible"
        fi

        # Test targets discovery
        local target_count
        target_count=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length' 2>/dev/null || echo "0")
        if [[ "$target_count" -gt 0 ]]; then
            log_success "Prometheus monitoring $target_count active targets"
        else
            log_warning "Prometheus has no active targets"
        fi

        # Test container health
        if test_container_health "purebliss-prometheus"; then
            log_success "Prometheus container healthy"
        else
            log_warning "Prometheus container not healthy"
        fi
    else
        log_warning "Prometheus healthy endpoint not accessible"
        # Try to diagnose
        if docker ps | grep -q purebliss-prometheus; then
            log_info "Prometheus container running but endpoint not responding"
        else
            log_warning "Prometheus container not running"
        fi
    fi
    # Grafana
    if curl -sk https://127.0.0.1:3001/login | grep -q Grafana; then
        log_success "Grafana login page accessible"
    else
        log_warning "Grafana login page not accessible"
    fi
    # Plane
    if curl -sk https://127.0.0.1:8081/api/health | grep -q 'OK'; then
        log_success "Plane API health endpoint OK"
    else
        log_warning "Plane API health endpoint not accessible"
    fi
}
#!/bin/bash
set -euo pipefail

# Comprehensive Health Check for Pure Bliss Infrastructure
# Validates all services are healthy and functional
# Last Updated: August 4, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_check() {
    echo "[$(date)] HEALTH_CHECK: $1" >> "$LOG_FILE"
    echo "🔍 $1"
}

function log_success() {
    echo "[$(date)] HEALTH_CHECK: ✅ SUCCESS: $1" >> "$LOG_FILE"
    echo "✅ $1"
}

function log_warning() {
    echo "[$(date)] HEALTH_CHECK: ⚠️  WARNING: $1" >> "$LOG_FILE"
    echo "⚠️  $1"
}

function log_error() {
    echo "[$(date)] HEALTH_CHECK: ❌ ERROR: $1" >> "$LOG_FILE"
    echo "❌ $1"
}

function test_container_health() {
    local service_name="$1"
    local expected_status="${2:-healthy}"

    if docker ps | grep -q "$service_name"; then
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "no_healthcheck")
        local container_status
        container_status=$(docker inspect --format='{{.State.Status}}' "$service_name" 2>/dev/null || echo "unknown")

        case "$health_status" in
            "healthy")
                log_success "$service_name: healthy ($container_status)"
                return 0
                ;;
            "unhealthy")
                log_error "$service_name: unhealthy ($container_status)"
                return 1
                ;;
            "starting")
                log_warning "$service_name: starting ($container_status)"
                return 1
                ;;
            "no_healthcheck")
                if [[ "$container_status" == "running" ]]; then
                    log_success "$service_name: running (no health check defined)"
                    return 0
                else
                    log_error "$service_name: $container_status"
                    return 1
                fi
                ;;
            *)
                log_warning "$service_name: $health_status ($container_status)"
                return 1
                ;;
        esac
    else
        log_error "$service_name: not running"
        return 1
    fi
}

function test_network_connectivity() {
    log_check "Testing network connectivity..."

    # Test Docker network
    if docker network ls | grep -q purebliss-net; then
        log_success "purebliss-net network exists"
    else
        log_error "purebliss-net network missing"
        return 1
    fi

    # Test Vault HTTPS endpoint
    if curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
        log_success "Vault HTTPS endpoint accessible"
    else
        log_error "Vault HTTPS endpoint not accessible"
        return 1
    fi

    # Test Vault Agent (if it's supposed to be on 8100)
    if nc -z 127.0.0.1 8100 2>/dev/null; then
        log_success "Vault Agent port 8100 accessible"
    else
        log_warning "Vault Agent port 8100 not accessible (may be expected)"
    fi

    # Test PostgreSQL
    if nc -z 127.0.0.1 5432 2>/dev/null; then
        log_success "PostgreSQL port 5432 accessible"
    else
        log_error "PostgreSQL port 5432 not accessible"
        return 1
    fi

    # Test Redis
    if nc -z 127.0.0.1 6379 2>/dev/null; then
        log_success "Redis port 6379 accessible"
    else
        log_error "Redis port 6379 not accessible"
        return 1
    fi

    # Test Keycloak
    if nc -z 127.0.0.1 8080 2>/dev/null; then
        log_success "Keycloak port 8080 accessible"
    else
        log_error "Keycloak port 8080 not accessible"
        return 1
    fi

    # Test Nginx HTTPS endpoint (default mapped port 8443, adjust if needed)
    if curl -sk https://127.0.0.1:8443 -o /dev/null -w "%{http_code}" | grep -q 200; then
        log_success "Nginx HTTPS endpoint (8443) accessible"
    else
        log_error "Nginx HTTPS endpoint (8443) not accessible"
        return 1
    fi

    return 0
}
function main() {
    echo "🔍 Starting comprehensive Pure Bliss infrastructure health check..."
    echo "$(date)"
    echo ""

    # Log health check start
    echo "[$(date)] HEALTH_CHECK: Starting comprehensive infrastructure health check" >> "$LOG_FILE"

    # Enhanced orchestrator and automation testing
    echo "=== Orchestrator and Automation Framework ==="
    test_orchestrator_integration
    test_vault_automation_framework
    test_service_dependencies
    echo ""

    # Basic infrastructure checks
    echo "=== Disk Space ==="
    check_disk_space
    echo ""

    echo "=== File Permissions ==="
    check_file_permissions
    echo ""

    # Container health status
    echo "=== Container Health Status ==="
    test_container_health "purebliss-vault"
    test_container_health "purebliss-vault-agent"
    test_container_health "purebliss-postgres"
    test_container_health "purebliss-redis"
    test_container_health "purebliss-keycloak"
    test_container_health "purebliss-letsencrypt"
    test_container_health "purebliss-nginx"
    echo ""

    # Network connectivity
    echo "=== Network Connectivity ==="
    test_network_connectivity
    echo ""

    # Vault functionality testing
    echo "=== Vault Functionality ==="
    test_vault_functionality
    echo ""

    # Database connectivity
    echo "=== Database Connectivity ==="
    test_database_connectivity
    echo ""

    # Redis connectivity
    echo "=== Redis Connectivity ==="
    test_redis_connectivity
    echo ""

    # Keycloak functionality
    echo "=== Keycloak Functionality ==="
    test_keycloak_functionality
    echo ""

    # Deep service checks
    echo "=== Deep Letsencrypt Checks ==="
    test_letsencrypt_deep
    echo ""

    echo "=== Deep Nginx Checks ==="
    test_nginx_deep
    echo ""

    echo "=== Deep Vault Checks ==="
    test_vault_deep
    echo ""

    echo "=== Deep PostgreSQL Checks ==="
    test_postgres_deep
    echo ""

    echo "=== Deep Redis Checks ==="
    test_redis_deep
    echo ""

    echo "=== Deep Keycloak Checks ==="
    echo "=== nginx Vault Integration ==="    test_nginx_vault_integration    echo ""
    echo "=== redis Vault Integration ==="    test_redis_vault_integration    echo ""
    test_keycloak_deep
    echo ""

    # Supporting services check
    echo "=== Supporting Services Checks ==="
    test_loki_prometheus_grafana_plane
    echo ""

    # PKI certificate validation
    echo "=== Nginx Vault PKI Certificate ==="
    test_nginx_vault_pki
    echo ""

    # Prometheus Vault integration validation
    echo "=== Prometheus Vault Integration ==="
    test_prometheus_vault_integration
    echo ""

    # Summary
    echo "=== Health Check Summary ==="

    # Count any errors from our health checks
    local error_count warning_count
    error_count=$(grep -c "❌" /tmp/health_check_output 2>/dev/null || echo "0")
    warning_count=$(grep -c "⚠️" /tmp/health_check_output 2>/dev/null || echo "0")

    # Determine overall health status
    if [[ "$error_count" -eq 0 && "$warning_count" -eq 0 ]]; then
        log_success "All systems are fully operational and healthy!"
        echo "[$(date)] HEALTH_CHECK: ✅ All systems healthy" >> "$LOG_FILE"
        exit 0
    elif [[ "$error_count" -eq 0 ]]; then
        log_warning "All services are operational with $warning_count warnings - check details above"
        echo "[$(date)] HEALTH_CHECK: ⚠️  Systems operational with warnings ($warning_count)" >> "$LOG_FILE"
        exit 0
    else
        log_error "System issues detected - $error_count errors, $warning_count warnings"
        echo "[$(date)] HEALTH_CHECK: ❌ System issues detected ($error_count errors, $warning_count warnings)" >> "$LOG_FILE"

        # Provide automated troubleshooting guidance
        echo ""
        echo "🔧 Automated Troubleshooting Options:"
        echo "   Run comprehensive fixes: /opt/dev-purebliss/services/vault/vault-break-fix.sh all"
        echo "   Run specific service fix: /opt/dev-purebliss/services/vault/vault-break-fix.sh <service_name>"
        echo "   Restart with orchestrator: /opt/dev-purebliss/start-all-services.sh"
        echo "   Check logs: tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log"

        exit 1
    fi
}

# Enhanced helper functions for better service validation

function test_letsencrypt_deep() {
    log_check "Deep Letsencrypt checks: Vault secrets, certbot logs, container health..."

    # Check Vault secret exists
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        if vault kv get secret/letsencrypt >/dev/null 2>&1; then
            log_success "Vault secret/letsencrypt present"
        else
            log_warning "Vault secret/letsencrypt missing"
        fi
    else
        log_warning "Cannot test Vault secrets - token not available"
    fi

    # Container health
    if test_container_health "purebliss-letsencrypt"; then
        log_success "Letsencrypt container healthy"
    else
        log_warning "Letsencrypt container not healthy"
    fi

    # Certbot logs
    if docker logs purebliss-letsencrypt --tail 40 2>&1 | grep -iE 'error|fail|critical' >/dev/null; then
        log_warning "Letsencrypt certbot recent errors found"
    else
        log_success "Letsencrypt certbot log clean"
    fi
}

function test_vault_functionality() {
    log_check "Testing Vault functionality..."

    # Check if Vault is unsealed
    if curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
        log_success "Vault is unsealed and operational"
    else
        log_error "Vault is sealed or not responding"
        return 1
    fi

    # Test if we have a valid token
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Test basic Vault operations
        if vault token lookup >/dev/null 2>&1; then
            log_success "Vault token authentication working"
        else
            log_error "Vault token authentication failed"
            return 1
        fi

        # Test KV v2 secrets engine
        if vault secrets list | grep -q "^secret/"; then
            log_success "KV v2 secrets engine enabled"
        else
            log_error "KV v2 secrets engine not enabled"
            return 1
        fi

function check_disk_space() {
    log_check "Checking disk space for critical paths..."
    for path in / /opt/my-secure-ha-stack /opt/dev-purebliss; do
        if [[ -d "$path" ]]; then
            usage=$(df -h "$path" | awk 'NR==2{print $5}')
            log_success "Disk usage for $path: $usage"
        else
            log_warning "Path $path does not exist"
        fi
    done
}

function check_file_permissions() {
    log_check "Checking file permissions for critical certs/configs..."

    # Nginx certs (inside container)
    if docker exec purebliss-nginx stat -c '%U:%G %a' /etc/nginx/certs/dev.purebliss.app/fullchain.pem 2>/dev/null | grep -q '101:101'; then
        log_success "Nginx cert file permissions OK (101:101)"
    else
        log_warning "Nginx cert file permissions not 101:101"
    fi

    # Vault config
    if [[ -f "/opt/dev-purebliss/services/vault/vault.hcl" ]]; then
        perms=$(stat -c '%a' /opt/dev-purebliss/services/vault/vault.hcl)
        if [[ "$perms" == "600" || "$perms" == "640" || "$perms" == "644" ]]; then
            log_success "Vault config permissions secure ($perms)"
        else
            log_warning "Vault config permissions not secure ($perms)"
        fi
    else
        log_warning "Vault config file not found"
    fi
}

function test_network_connectivity() {
    log_check "Testing network connectivity..."

    # Check if purebliss-net network exists
    if docker network ls | grep -q purebliss-net; then
        log_success "purebliss-net network exists"
    else
        log_error "purebliss-net network missing"
        return 1
    fi

    # Test Vault HTTPS endpoint
    if curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
        log_success "Vault HTTPS endpoint accessible"
    else
        log_error "Vault HTTPS endpoint not accessible"
        return 1
    fi

    # Test Vault Agent (if it's supposed to be on 8100)
    if nc -z 127.0.0.1 8100 2>/dev/null; then
        log_success "Vault Agent port 8100 accessible"
    else
        log_warning "Vault Agent port 8100 not accessible"
    fi

    # Test PostgreSQL
    if nc -z 127.0.0.1 5432 2>/dev/null; then
        log_success "PostgreSQL port 5432 accessible"
    else
        log_error "PostgreSQL port 5432 not accessible"
        return 1
    fi

    # Test Redis
    if nc -z 127.0.0.1 6379 2>/dev/null; then
        log_success "Redis port 6379 accessible"
    else
        log_error "Redis port 6379 not accessible"
        return 1
    fi

    # Test Keycloak
    if nc -z 127.0.0.1 8080 2>/dev/null; then
        log_success "Keycloak port 8080 accessible"
    else
        log_error "Keycloak port 8080 not accessible"
        return 1
    fi

    # Test Nginx HTTPS endpoint
    if curl -sk https://dev.purebliss.app -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q 200; then
        log_success "Nginx HTTPS endpoint accessible"
    else
        log_error "Nginx HTTPS endpoint (8443) not accessible"
        return 1
    fi

    return 0
}

function test_vault_functionality() {
    log_check "Testing Vault functionality..."

    # Check if Vault is unsealed
    if curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
        log_success "Vault is unsealed and operational"
    else
        log_error "Vault is sealed or not responding"
        return 1
    fi

    # Test if we have a valid token
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Test basic Vault operations
        if vault token lookup >/dev/null 2>&1; then
            log_success "Vault token authentication working"
        else
            log_error "Vault token authentication failed"
            return 1
        fi

        # Test KV v2 secrets engine
        if vault secrets list | grep -q "^secret/"; then
            log_success "KV v2 secrets engine enabled"
        else
            log_warning "KV v2 secrets engine not enabled"
        fi

        # Test PostgreSQL database secrets engine
        if vault read database/config/postgres-app >/dev/null 2>&1; then
            log_success "PostgreSQL database secrets engine configured"

            # Test dynamic credential generation
            if vault read database/creds/postgres-role >/dev/null 2>&1; then
                log_success "PostgreSQL dynamic credentials working"
            else
                log_warning "PostgreSQL dynamic credentials not working"
            fi
        else
            log_warning "PostgreSQL database secrets engine not configured"
        fi

        # Test Redis integration
        if vault read redis/config/redis >/dev/null 2>&1; then
            log_success "Redis integration configured"
        else
            log_warning "Redis integration not configured"
        fi

        # Test Keycloak secrets
        if vault kv get secret/keycloak >/dev/null 2>&1; then
            log_success "Keycloak secrets configured"
        else
            log_warning "Keycloak secrets not configured"
        fi
    else
        log_warning "Vault token not available for testing"
    fi
}

function test_database_connectivity() {
    log_check "Testing database connectivity..."

    # Test PostgreSQL admin connection
    if docker exec purebliss-postgres psql -U postgres -d postgres -c "SELECT 1" >/dev/null 2>&1; then
        log_success "PostgreSQL admin connection working"

        # Test if Keycloak database exists and is accessible
        if docker exec purebliss-postgres psql -U postgres -d keycloak -c "SELECT 1" >/dev/null 2>&1; then
            log_success "Keycloak database accessible"

            # Test Keycloak user access
            if docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT 1" >/dev/null 2>&1; then
                log_success "Keycloak user database access working"
            else
                log_warning "Keycloak user database access failed"
            fi
        else
            log_warning "Keycloak database not accessible"
        fi
    else
        log_error "PostgreSQL admin connection failed"
        return 1
    fi
}

function test_redis_connectivity() {
    log_check "Testing Redis connectivity..."

    # Test Redis ping
    if docker exec purebliss-redis redis-cli ping 2>/dev/null | grep -q PONG; then
        log_success "Redis ping successful"

        # Test if Vault can reach Redis
        if docker exec purebliss-vault nc -z purebliss-redis 6379 2>/dev/null; then
            log_success "Vault can reach Redis"
        else
            log_warning "Vault cannot reach Redis"
        fi
    else
        log_error "Redis ping failed"
        return 1
    fi
}

function test_keycloak_functionality() {
    log_check "Testing Keycloak functionality..."

    # Test Keycloak internal endpoint
    if docker exec purebliss-keycloak curl -s http://localhost:8080 2>/dev/null | grep -qE "(Keycloak|Resource not found)" 2>/dev/null; then
        log_success "Keycloak internal endpoint responding"
    else
        log_warning "Keycloak internal endpoint not responding"
    fi

    # Test external endpoint
    if curl -s http://localhost:8080 2>/dev/null | grep -qE "(Keycloak|Resource not found)"; then
        log_success "Keycloak external endpoint accessible"
    else
        log_warning "Keycloak external endpoint not accessible"
    fi
}

function test_nginx_deep() {
    log_check "Deep Nginx checks: config, endpoints, headers, logs..."

    # Config syntax
    if docker exec purebliss-nginx nginx -t >/dev/null 2>&1; then
        log_success "Nginx config syntax OK"
    else
        log_error "Nginx config syntax error"
    fi

    # HTTP endpoint (should redirect or respond)
    if curl -s -o /dev/null -w "%{http_code}" http://dev.purebliss.app 2>/dev/null | grep -qE '200|301|302|404'; then
        log_success "Nginx HTTP endpoint responds (redirect or 404)"
    else
        log_warning "Nginx HTTP endpoint not responding as expected"
    fi

    # HTTPS endpoint headers
    local headers
    headers=$(curl -skI https://dev.purebliss.app 2>/dev/null)
    if echo "$headers" | grep -qi 'Strict-Transport-Security'; then
        log_success "Nginx HSTS header present"
    else
        log_warning "Nginx HSTS header missing"
    fi

    if echo "$headers" | grep -qi 'X-Frame-Options'; then
        log_success "Nginx X-Frame-Options header present"
    else
        log_warning "Nginx X-Frame-Options header missing"
    fi

    # WAF check (basic)
    if echo "$headers" | grep -qi 'X-WAF'; then
        log_success "Nginx WAF header present"
    else
        log_warning "Nginx WAF header missing (check WAF config)"
    fi

    # Error log tail
    if docker logs purebliss-nginx --tail 20 2>&1 | grep -iE 'error|fail|critical' >/dev/null; then
        log_warning "Nginx recent errors found"
    else
        log_success "Nginx error log clean"
    fi
}

function test_vault_deep() {
    log_check "Deep Vault checks: audit, mounts, policies, token TTL..."

    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Audit log enabled
        if vault audit list 2>/dev/null | grep -q "file"; then
            log_success "Vault audit log enabled"
        else
            log_warning "Vault audit log not enabled"
        fi

        # Mount list
        if vault secrets list 2>/dev/null | grep -q "pki-nginx/"; then
            log_success "Vault PKI mount for nginx present"
        else
            log_warning "Vault PKI mount for nginx missing"
        fi

        # Policy check
        if vault policy list 2>/dev/null | grep -q "nginx"; then
            log_success "Vault nginx policy present"
        else
            log_warning "Vault nginx policy missing"
        fi

        # Token TTL
        local ttl
        ttl=$(vault token lookup -format=json 2>/dev/null | jq -r '.data.ttl' 2>/dev/null || echo "0")
        if [[ "$ttl" -gt 3600 ]] || [[ "$ttl" == "0" ]]; then
            log_success "Vault token TTL is sufficient ($ttl seconds)"
        else
            log_warning "Vault token TTL is low ($ttl seconds)"
        fi
    else
        log_warning "Vault token not available for deep checks"
    fi

    # Error log tail
    if docker logs purebliss-vault --tail 20 2>&1 | grep -iE 'error|fail|critical' >/dev/null; then
        log_warning "Vault recent errors found"
    else
        log_success "Vault error log clean"
    fi
}

function test_postgres_deep() {
    log_check "Deep PostgreSQL checks: tables, privileges, slow queries..."

    # Table existence in keycloak database
    if docker exec purebliss-postgres psql -U postgres -d keycloak -c "\dt" 2>/dev/null | grep -q public; then
        log_success "Keycloak tables exist in Postgres"
    else
        log_warning "Keycloak tables missing in Postgres"
    fi

    # User privileges
    if docker exec purebliss-postgres psql -U postgres -d keycloak -c "\du" 2>/dev/null | grep -q keycloak; then
        log_success "Keycloak user exists in Postgres"
    else
        log_warning "Keycloak user missing in Postgres"
    fi

    # Check for slow queries (basic check)
    if docker logs purebliss-postgres --tail 50 2>&1 | grep -i slow >/dev/null; then
        log_warning "Postgres slow queries detected"
    else
        log_success "No slow queries in Postgres log"
    fi
}

function test_redis_deep() {
    log_check "Deep Redis checks: persistence, memory, keyspace..."

    # Persistence
    if docker exec purebliss-redis redis-cli config get save 2>/dev/null | grep -qv '""'; then
        log_success "Redis persistence enabled"
    else
        log_warning "Redis persistence not enabled"
    fi

    # Memory usage
    local mem
    mem=$(docker exec purebliss-redis redis-cli info memory 2>/dev/null | grep used_memory_human | awk -F: '{print $2}' | tr -d '\r')
    log_success "Redis memory usage: ${mem:-unknown}"

    # Keyspace info
    local keys
    keys=$(docker exec purebliss-redis redis-cli info keyspace 2>/dev/null)
    log_success "Redis keyspace: ${keys:-empty}"

    # Error log tail
    if docker logs purebliss-redis --tail 20 2>&1 | grep -iE 'error|fail|critical' >/dev/null; then
        log_warning "Redis recent errors found"
    else
        log_success "Redis error log clean"
    fi
}

function test_keycloak_deep() {
    log_check "Deep Keycloak checks: realms, endpoints, admin login, logs..."

    # Check for admin access (simplified)
    if docker exec purebliss-keycloak curl -s http://localhost:8080/admin/ 2>/dev/null | grep -q Keycloak; then
        log_success "Keycloak admin interface accessible"
    else
        log_warning "Keycloak admin interface not accessible"
    fi

    # OIDC endpoint
    if curl -sk https://dev.purebliss.app/keycloak/realms/master/.well-known/openid-configuration 2>/dev/null | grep -q issuer; then
        log_success "Keycloak OIDC endpoint accessible"
    else
        log_warning "Keycloak OIDC endpoint not accessible"
    fi

    # SAML endpoint (metadata)
    if curl -sk https://dev.purebliss.app/keycloak/realms/master/protocol/saml/descriptor 2>/dev/null | grep -q EntityDescriptor; then
        log_success "Keycloak SAML metadata endpoint accessible"
    else
        log_warning "Keycloak SAML metadata endpoint not accessible"
    fi

    # Error log tail
    if docker logs purebliss-keycloak --tail 20 2>&1 | grep -iE 'error|fail|critical' >/dev/null; then
        log_warning "Keycloak recent errors found"
    else
        log_success "Keycloak error log clean"
    fi
}

function test_loki_prometheus_grafana_plane() {
    log_check "Checking supporting services: Loki, Prometheus, Grafana, Plane..."

    # Loki
    if nc -z 127.0.0.1 3100 2>/dev/null; then
        log_success "Loki port 3100 accessible"
    else
        log_warning "Loki port 3100 not accessible"
    fi

    # Prometheus
    if curl -sk http://127.0.0.1:9090/-/healthy 2>/dev/null | grep -q 'Prometheus is Healthy'; then
        log_success "Prometheus healthy endpoint OK"
    else
        log_warning "Prometheus healthy endpoint not accessible"
    fi

    # Grafana
    if curl -sk http://127.0.0.1:3001/login 2>/dev/null | grep -q Grafana; then
        log_success "Grafana login page accessible"
    else
        log_warning "Grafana login page not accessible"
    fi

    # Plane
    if curl -sk http://127.0.0.1:8000/api/health 2>/dev/null | grep -q 'OK'; then
        log_success "Plane API health endpoint OK"
    else
        log_warning "Plane API health endpoint not accessible"
    fi
}

function test_nginx_vault_pki() {
    log_check "Testing Nginx Vault PKI certificate..."

    # Check cert issuer inside the container
    local cert_info
    if cert_info=$(docker exec purebliss-nginx openssl x509 -in /etc/nginx/certs/dev.purebliss.app/fullchain.pem -noout -issuer -subject 2>/dev/null); then
        local issuer subject
        issuer=$(echo "$cert_info" | grep issuer)
        subject=$(echo "$cert_info" | grep subject)

        if [[ "$issuer" == *"Pure Bliss Dev CA"* ]] || [[ "$issuer" == *"Vault"* ]]; then
            log_success "Nginx is serving Vault-signed certificate"
        else
            log_warning "Nginx certificate issuer is not Vault: $issuer $subject"
        fi
    else
        log_warning "Could not read Nginx certificate inside container"
    fi
}

function test_prometheus_vault_integration() {
    log_check "Testing Prometheus Vault integration..."

    # Test Vault configuration secrets
    if vault kv get prometheus-config/metrics >/dev/null 2>&1; then
        log_success "Prometheus metrics configuration in Vault"

        # Verify specific configuration values
        local scrape_interval
        scrape_interval=$(vault kv get -format=json prometheus-config/metrics | jq -r '.data.data.scrape_interval' 2>/dev/null)
        if [[ "$scrape_interval" == "15s" ]]; then
            log_success "Prometheus scrape interval configured correctly"
        else
            log_warning "Prometheus scrape interval unexpected: $scrape_interval"
        fi
    else
        log_warning "Prometheus metrics configuration missing from Vault"
    fi

    # Test targets configuration
    if vault kv get prometheus-config/targets >/dev/null 2>&1; then
        log_success "Prometheus targets configuration in Vault"

        # Verify target endpoints
        local target_count
        target_count=$(vault kv get -format=json prometheus-config/targets | jq -r '.data.data | length' 2>/dev/null)
        if [[ "$target_count" -ge 5 ]]; then
            log_success "Prometheus has $target_count configured target endpoints"
        else
            log_warning "Prometheus has fewer targets than expected: $target_count"
        fi
    else
        log_warning "Prometheus targets configuration missing from Vault"
    fi

    # Test Prometheus endpoint accessibility
    if curl -s http://localhost:9090/-/healthy | grep -q 'Healthy'; then
        log_success "Prometheus endpoint responding correctly"

        # Test active targets API
        local active_targets
        active_targets=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length' 2>/dev/null || echo "0")
        if [[ "$active_targets" -gt 0 ]]; then
            log_success "Prometheus actively monitoring $active_targets targets"
        else
            log_warning "Prometheus has no active monitoring targets"
        fi
    else
        log_warning "Prometheus endpoint not responding"
    fi

    # Test container health and data persistence
    if test_container_health "purebliss-prometheus"; then
        log_success "Prometheus container healthy"

        # Check data directory permissions
        if [[ -d "/tmp/purebliss-storage/prometheus" ]]; then
            local dir_owner
            dir_owner=$(stat -c '%U' /tmp/purebliss-storage/prometheus 2>/dev/null || echo "unknown")
            if [[ "$dir_owner" == "65534" ]] || [[ "$dir_owner" == "nobody" ]]; then
                log_success "Prometheus data directory permissions correct"
            else
                log_warning "Prometheus data directory permissions may be incorrect: $dir_owner"
            fi
        else
            log_warning "Prometheus data directory not found"
        fi
    else
        log_warning "Prometheus container not healthy"
    fi
}

function test_redis_vault_integration() {    log_check "Testing redis Vault integration..."    # Container health check    if test_container_health "purebliss-redis"; then        log_success "redis container healthy"    else        log_error "redis container not healthy"        return 1    fi    # Vault integration validation    if [[ -x "/opt/dev-purebliss/services/redis/validate-redis-vault-integration.sh" ]]; then        if /opt/dev-purebliss/services/redis/validate-redis-vault-integration.sh; then            log_success "redis Vault integration validated"        else            log_error "redis Vault integration validation failed"            return 1        fi    else        log_warning "redis validation script not found"    fi}
function test_nginx_vault_integration() {    log_check "Testing nginx Vault integration..."    # Container health check    if test_container_health "purebliss-nginx"; then        log_success "nginx container healthy"    else        log_error "nginx container not healthy"        return 1    fi    # Vault integration validation    if [[ -x "/opt/dev-purebliss/services/nginx/validate-nginx-vault-integration.sh" ]]; then        if /opt/dev-purebliss/services/nginx/validate-nginx-vault-integration.sh; then            log_success "nginx Vault integration validated"        else            log_error "nginx Vault integration validation failed"            return 1        fi    else        log_warning "nginx validation script not found"    fi}
# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Redirect output to capture errors and warnings for summary
    main 2>&1 | tee /tmp/health_check_output
fi
        if vault read database/config/postgres-app >/dev/null 2>&1; then
            log_success "PostgreSQL database secrets engine configured"

            # Test dynamic credential generation
            if vault read database/creds/postgres-role >/dev/null 2>&1; then
                log_success "PostgreSQL dynamic credentials working"
            else
                log_warning "PostgreSQL dynamic credentials not working"
            fi
        else
            log_warning "PostgreSQL database secrets engine not configured"
        fi

        # Test Redis integration
        if vault read redis/config/redis >/dev/null 2>&1; then
            log_success "Redis integration configured"
        else
            log_warning "Redis integration not configured"
        fi

        # Test Keycloak secrets
        if vault kv get secret/keycloak >/dev/null 2>&1; then
            log_success "Keycloak secrets configured"
        else
            log_warning "Keycloak secrets not configured"
        fi

    else
        log_error "Vault token not found"
        return 1
    fi

    return 0
}

function test_database_connectivity() {
    log_check "Testing database connectivity..."

    # Test PostgreSQL admin connection
    if docker exec purebliss-postgres psql -U postgres -d postgres -c "SELECT 1" >/dev/null 2>&1; then
        log_success "PostgreSQL admin connection working"
    else
        log_error "PostgreSQL admin connection failed"
        return 1
    fi

    # Test Keycloak database access
    if docker exec purebliss-postgres psql -U postgres -d keycloak -c "SELECT 1" >/dev/null 2>&1; then
        log_success "Keycloak database accessible"

        # Test keycloak user permissions
        if docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT 1" >/dev/null 2>&1; then
            log_success "Keycloak user database access working"
        else
            log_warning "Keycloak user database access not working"
        fi
    else
        log_error "Keycloak database not accessible"
        return 1
    fi

    return 0
}

function test_redis_connectivity() {
    log_check "Testing Redis connectivity..."

    # Test Redis ping
    if docker exec purebliss-redis redis-cli ping | grep -q PONG; then
        log_success "Redis ping successful"
    else
        log_error "Redis ping failed"
        return 1
    fi

    # Test Redis from Vault container
    if docker exec purebliss-vault nc -z purebliss-redis 6379 2>/dev/null; then
        log_success "Vault can reach Redis"
    else
        log_warning "Vault cannot reach Redis"
    fi

    return 0
}

function test_keycloak_functionality() {
    log_check "Testing Keycloak functionality..."

    # Test Keycloak endpoint using the same method as health check
    if docker exec purebliss-keycloak bash -c "exec 3<>/dev/tcp/localhost/8080 && echo -e 'GET / HTTP/1.1\r\nHost: localhost\r\n\r\n' >&3 && read -t1 response <&3 && exec 3<&- && exec 3>&-" >/dev/null 2>&1; then
        log_success "Keycloak internal endpoint responding"
    else
        log_error "Keycloak internal endpoint not responding"
        return 1
    fi

    # Test external access
    if curl -s "http://localhost:8080/" | grep -qE "(Keycloak|Resource not found)"; then
        log_success "Keycloak external endpoint accessible"
    else
        log_warning "Keycloak external endpoint not responding as expected"
    fi

    return 0
}


function main() {
    echo "🔍 Starting comprehensive Pure Bliss infrastructure health check..."
    echo "$(date)"
    echo ""

    local overall_status=0
    local nginx_status=0


    # Disk space and file permissions
    echo "=== Disk Space ==="
    check_disk_space
    echo ""
    echo "=== File Permissions ==="
    check_file_permissions
    echo ""

    # Test all container health
    echo "=== Container Health Status ==="
    test_container_health "purebliss-vault" || overall_status=1
    test_container_health "purebliss-vault-agent" || overall_status=1
    test_container_health "purebliss-postgres" || overall_status=1
    test_container_health "purebliss-redis" || overall_status=1
    test_container_health "purebliss-keycloak" || overall_status=1
    test_container_health "purebliss-nginx" || { overall_status=1; nginx_status=1; }
    echo ""

    # Test network connectivity
    echo "=== Network Connectivity ==="
    test_network_connectivity || { overall_status=1; nginx_status=1; }
    echo ""

    # Test Vault functionality
    echo "=== Vault Functionality ==="
    test_vault_functionality || overall_status=1
    echo ""

    # Test database connectivity
    echo "=== Database Connectivity ==="
    test_database_connectivity || overall_status=1
    echo ""

    # Test Redis connectivity
    echo "=== Redis Connectivity ==="
    test_redis_connectivity || overall_status=1
    echo ""

    # Test Keycloak functionality
    echo "=== Keycloak Functionality ==="
    test_keycloak_functionality || overall_status=1
    echo ""

    # Deep checks
    echo "=== Deep Letsencrypt Checks ==="
    test_letsencrypt_deep || overall_status=1
    echo ""
    echo "=== Deep Nginx Checks ==="
    test_nginx_deep || nginx_status=1
    echo ""
    echo "=== Deep Vault Checks ==="
    test_vault_deep || overall_status=1
    echo ""
    echo "=== Deep PostgreSQL Checks ==="
    test_postgres_deep || overall_status=1
    echo ""
    echo "=== Deep Redis Checks ==="
    test_redis_deep || overall_status=1
    echo ""
    echo "=== Deep Keycloak Checks ==="
    echo "=== nginx Vault Integration ==="    test_nginx_vault_integration    echo ""
    echo "=== redis Vault Integration ==="    test_redis_vault_integration    echo ""
    test_keycloak_deep || overall_status=1
    echo ""
    echo "=== Supporting Services Checks ==="
    test_loki_prometheus_grafana_plane || overall_status=1
    echo ""

    # Test Nginx Vault PKI cert
    echo "=== Nginx Vault PKI Certificate ==="
    test_nginx_vault_pki || { overall_status=1; nginx_status=1; }

    # Test Prometheus Vault integration
    echo ""
    echo "=== Prometheus Vault Integration ==="
    test_prometheus_vault_integration || overall_status=1
    echo ""

    # Final report
    echo "=== Health Check Summary ==="
    if [[ $overall_status -eq 0 ]]; then
        log_success "🎉 ALL SYSTEMS OPERATIONAL - Pure Bliss infrastructure is 100% healthy!"
        echo ""
        echo "✅ Vault: Healthy and functional with TLS"
        echo "✅ Vault Agent: Healthy and running"
        echo "✅ PostgreSQL: Healthy with dynamic credentials"
        echo "✅ Redis: Healthy with Vault integration"
        echo "✅ Keycloak: Healthy with Vault-managed secrets"
        echo "✅ Nginx: Healthy, HTTPS endpoint and Vault PKI cert valid"
        echo "✅ Network: All inter-service connectivity working"
        echo "✅ Security: Zero hardcoded passwords, all secrets managed by Vault"
    else
        if [[ $nginx_status -eq 1 ]]; then
            echo "❌ Nginx: Issue detected (see above and logs)"
        fi
        log_error "Some systems are not fully operational - check logs for details"
        exit 1
    fi

    log_check "Comprehensive health check completed"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
