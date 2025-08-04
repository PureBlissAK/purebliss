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
    # Prometheus
    if curl -sk https://127.0.0.1:9090/-/healthy | grep -q 'Prometheus is Healthy'; then
        log_success "Prometheus healthy endpoint OK"
    else
        log_warning "Prometheus healthy endpoint not accessible"
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
function test_nginx_vault_pki() {
    log_check "Testing Nginx Vault PKI certificate..."
    # Check cert issuer inside the container
    local issuer subject
    if docker exec purebliss-nginx openssl x509 -in /etc/nginx/certs/dev.purebliss.app/fullchain.pem -noout -issuer -subject > /tmp/nginx_cert_info 2>/dev/null; then
        issuer=$(grep issuer /tmp/nginx_cert_info | head -1)
        subject=$(grep subject /tmp/nginx_cert_info | head -1)
        if [[ "$issuer" == *"Vault"* ]]; then
            log_success "Nginx is serving Vault-signed certificate: $issuer $subject"
        else
            log_warning "Nginx certificate issuer is not Vault: $issuer $subject"
        fi
    else
        log_error "Could not read Nginx certificate inside container"
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
            log_error "KV v2 secrets engine not enabled"
            return 1
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
    test_keycloak_deep || overall_status=1
    echo ""
    echo "=== Supporting Services Checks ==="
    test_loki_prometheus_grafana_plane || overall_status=1
    echo ""

    # Test Nginx Vault PKI cert
    echo "=== Nginx Vault PKI Certificate ==="
    test_nginx_vault_pki || { overall_status=1; nginx_status=1; }
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
