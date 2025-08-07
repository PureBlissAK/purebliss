function vault_letsencrypt_vault_integration_fix() {
    log_action "Fixing Letsencrypt Vault integration..."
    # Re-run onboarding
    if /opt/dev-purebliss/start-all-services.sh letsencrypt >> "$LOG_FILE" 2>&1; then
        log_success "Letsencrypt onboarding to Vault re-run successfully"
    else
        log_warning "Letsencrypt onboarding failed, check logs"
    fi
    # Validate Vault secrets
    vault kv get secret/letsencrypt >> "$LOG_FILE" 2>&1 || log_error "Vault secret/letsencrypt missing"
    # Validate container health
    docker inspect --format='{{.State.Health.Status}}' purebliss-letsencrypt >> "$LOG_FILE" 2>&1
    # Check certbot logs
    docker logs purebliss-letsencrypt --tail 40 >> "$LOG_FILE" 2>&1
    log_action "Letsencrypt Vault integration check complete"
}

function vault_prometheus_vault_integration_fix() {
    log_action "Fixing Prometheus Vault integration..."

    # Ensure Vault is accessible
    if ! vault status >/dev/null 2>&1; then
        log_error "Vault not accessible, cannot configure Prometheus"
        return 1
    fi

    # Verify Prometheus secrets in Vault
    if ! vault kv get prometheus-config/metrics >/dev/null 2>&1; then
        log_action "Creating Prometheus metrics configuration in Vault..."
        vault kv put prometheus-config/metrics \
          scrape_interval="15s" \
          evaluation_interval="15s" \
          retention_time="200h" \
          admin_password="$(openssl rand -base64 32)" >> "$LOG_FILE" 2>&1
    fi

    if ! vault kv get prometheus-config/targets >/dev/null 2>&1; then
        log_action "Creating Prometheus targets configuration in Vault..."
        vault kv put prometheus-config/targets \
          vault_endpoint="purebliss-vault:8200" \
          postgres_endpoint="purebliss-postgres:5432" \
          redis_endpoint="purebliss-redis:6379" \
          keycloak_endpoint="purebliss-keycloak:8080" \
          nginx_endpoint="purebliss-nginx:80" \
          grafana_endpoint="purebliss-grafana:3001" >> "$LOG_FILE" 2>&1
    fi

    # Fix data directory permissions
    if [[ -d "/tmp/purebliss-storage/prometheus" ]]; then
        sudo chown -R 65534:65534 /tmp/purebliss-storage/prometheus 2>/dev/null || true
        sudo chmod 755 /tmp/purebliss-storage/prometheus 2>/dev/null || true
    fi

    # Restart Prometheus if needed
    if docker ps -q -f name=purebliss-prometheus >/dev/null; then
        log_action "Restarting Prometheus container..."
        docker restart purebliss-prometheus >> "$LOG_FILE" 2>&1
    else
        log_action "Starting Prometheus container..."
        cd /opt/dev-purebliss/services/prometheus
        docker-compose -f prometheus-docker-compose.yml up -d >> "$LOG_FILE" 2>&1
    fi

    # Validate health
    sleep 10
    if curl -s http://localhost:9090/-/healthy | grep -q "Healthy"; then
        log_success "Prometheus health check passed"
    else
        log_warning "Prometheus health check failed"
    fi

    log_action "Prometheus Vault integration check complete"
}
function vault_nginx_pki_integration_fix() {
    log_action "Fixing Nginx Vault PKI integration..."
    # Re-run onboarding and cert renewal
    if /opt/dev-purebliss/start-all-services.sh nginx >> "$LOG_FILE" 2>&1; then
        log_success "Nginx onboarding to Vault PKI re-run successfully"
    else
        log_warning "Nginx onboarding failed, check logs"
    fi
    # Run cert renewal script
    if /opt/dev-purebliss/services/nginx/update_vault_certificates.sh >> "$LOG_FILE" 2>&1; then
        log_success "Nginx Vault certificate renewed"
    else
        log_warning "Nginx Vault certificate renewal failed"
    fi
    # Validate endpoint
    if curl -sk https://dev.purebliss.app -w '%{http_code}' | grep -q 200; then
        log_success "Nginx HTTPS endpoint is accessible"
    else
        log_error "Nginx HTTPS endpoint not accessible"
    fi
    # Check cert details
    docker exec purebliss-nginx openssl x509 -in /etc/nginx/certs/dev.purebliss.app/fullchain.pem -noout -issuer -subject -enddate >> "$LOG_FILE" 2>&1 || true
    log_action "Nginx PKI integration check complete"
}
#!/bin/bash
set -euo pipefail

# Vault Automated Break/Fix Script for Pure Bliss Infrastructure
# Fully Integrated with Enhanced Orchestrator start-all-services.sh
# Provides complete automation with intelligent problem resolution

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_SERVICE_DIR="/opt/dev-purebliss/services/vault"
BREAK_FIX_REPORT="$VAULT_SERVICE_DIR/vault-break-fix-report.md"

# Enhanced logging functions with timestamp and context
function log_action() {
    echo "[$(date)] VAULT_BREAKFIX: $1" >> "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] VAULT_BREAKFIX: ✅ SUCCESS: $1" >> "$LOG_FILE"
    echo "✅ $1"
}

function log_warning() {
    echo "[$(date)] VAULT_BREAKFIX: ⚠️  WARNING: $1" >> "$LOG_FILE"
    echo "⚠️  $1"
}

function log_error() {
    echo "[$(date)] VAULT_BREAKFIX: ❌ ERROR: $1" >> "$LOG_FILE"
    echo "❌ $1"
}

function verify_vault_ready() {
    local max_attempts=30
    local attempt=1

    log_action "Verifying Vault is ready for operations..."

    while [[ $attempt -le $max_attempts ]]; do
        if curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
            if curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
                log_success "Vault is unsealed and ready"
                return 0
            else
                log_action "Vault is sealed (attempt $attempt/$max_attempts)"
            fi
        else
            log_action "Vault endpoint not accessible (attempt $attempt/$max_attempts)"
        fi

        sleep 2
        ((attempt++))
    done

    log_error "Vault not ready after $max_attempts attempts"
    return 1
}

function get_service_status() {
    local service_name="$1"

    if docker ps | grep -q "$service_name"; then
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "no_healthcheck")
        local container_status
        container_status=$(docker inspect --format='{{.State.Status}}' "$service_name" 2>/dev/null || echo "unknown")

        case "$health_status" in
            "healthy")
                echo "✅ $service_name: healthy ($container_status)"
                ;;
            "unhealthy")
                echo "❌ $service_name: unhealthy ($container_status)"
                ;;
            "starting")
                echo "🔄 $service_name: starting ($container_status)"
                ;;
            "no_healthcheck")
                if [[ "$container_status" == "running" ]]; then
                    echo "✅ $service_name: running (no health check)"
                else
                    echo "❌ $service_name: $container_status"
                fi
                ;;
            *)
                echo "⚠️  $service_name: $health_status ($container_status)"
                ;;
        esac
    else
        echo "❌ $service_name: not running"
    fi
}

function show_service_overview() {
    log_action "Service Status Overview:"
    echo "=== Pure Bliss Service Status ==="
    get_service_status "purebliss-vault"
    get_service_status "purebliss-vault-agent"
    get_service_status "purebliss-postgres"
    get_service_status "purebliss-redis"
    get_service_status "purebliss-keycloak"
    echo ""
}

function vault_container_startup_fix() {
    log_action "Diagnosing container startup issues..."

    # Check if containers exist
    if ! docker ps -a | grep -q purebliss-vault; then
        log_action "Vault container not found. Running docker-compose up..."
        cd "$VAULT_SERVICE_DIR"
        docker-compose -f vault-docker-compose.yml up -d
        return 0
    fi

    # Check container status
    local vault_status agent_status
    vault_status=$(docker inspect --format='{{.State.Status}}' purebliss-vault 2>/dev/null || echo "missing")
    agent_status=$(docker inspect --format='{{.State.Status}}' purebliss-vault-agent 2>/dev/null || echo "missing")

    log_action "Vault Status: $vault_status, Agent Status: $agent_status"

    # Restart if not running
    if [[ "$vault_status" != "running" ]]; then
        log_action "Restarting Vault server..."
        docker restart purebliss-vault
        sleep 5
    fi

    if [[ "$agent_status" != "running" ]]; then
        log_action "Restarting Vault agent..."
        docker restart purebliss-vault-agent
        sleep 5
    fi

    log_action "Container startup fix completed"
}

function vault_permissions_fix() {
    log_action "Fixing permission issues..."

    # Check if we can use sudo without password prompt
    local can_sudo=false
    if sudo -n true 2>/dev/null; then
        can_sudo=true
        log_action "Sudo privileges available without password prompt"
    else
        log_action "Sudo requires password prompt - using alternative methods"
    fi

    # Fix cert permissions
    if [[ "$can_sudo" == "true" ]]; then
        sudo chown -R 1000:1000 "$VAULT_SERVICE_DIR/certs/" 2>/dev/null || true
    else
        # Try without sudo first, fall back to Docker exec
        chown -R 1000:1000 "$VAULT_SERVICE_DIR/certs/" 2>/dev/null || {
            log_action "Cannot fix cert permissions - may need manual intervention"
            echo "⚠️  Manual fix needed: sudo chown -R 1000:1000 $VAULT_SERVICE_DIR/certs/"
        }
    fi
    chmod 644 "$VAULT_SERVICE_DIR/certs/selfsigned/"*.pem 2>/dev/null || true

    # Fix data directory permissions inside container (always works)
    if docker ps | grep -q purebliss-vault; then
        log_action "Fixing Vault data directory permissions inside container..."
        docker exec purebliss-vault chown vault:vault /vault/data 2>/dev/null || true
    fi

    # Fix host vault directory permissions
    if [[ "$can_sudo" == "true" ]]; then
        sudo chown -R 1000:1000 /opt/my-secure-ha-stack/vault/ 2>/dev/null || true
    else
        log_action "Cannot fix host vault directory permissions - may need manual intervention"
        echo "⚠️  Manual fix needed: sudo chown -R 1000:1000 /opt/my-secure-ha-stack/vault/"
    fi

    # Fix secrets directory
    if [[ "$can_sudo" == "true" ]]; then
        sudo mkdir -p /opt/my-secure-ha-stack/secrets/vault 2>/dev/null
        sudo chown -R "$USER:$USER" /opt/my-secure-ha-stack/secrets/vault 2>/dev/null
    else
        # Try without sudo
        mkdir -p /opt/my-secure-ha-stack/secrets/vault 2>/dev/null || {
            echo "⚠️  Manual fix needed: sudo mkdir -p /opt/my-secure-ha-stack/secrets/vault"
            echo "⚠️  Manual fix needed: sudo chown -R $USER:$USER /opt/my-secure-ha-stack/secrets/vault"
        }
    fi
    chmod 700 /opt/my-secure-ha-stack/secrets/vault 2>/dev/null || true

    log_action "Permissions fixed successfully (automated where possible)"
}

function vault_tls_config_fix() {
    log_action "Fixing TLS configuration..."

    # Regenerate self-signed certs if missing or invalid
    local cert_dir="$VAULT_SERVICE_DIR/certs/selfsigned"
    if [[ ! -f "$cert_dir/privkey.pem" ]] || [[ ! -f "$cert_dir/fullchain.pem" ]]; then
        log_action "Regenerating self-signed certificates..."
        mkdir -p "$cert_dir"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$cert_dir/privkey.pem" \
            -out "$cert_dir/fullchain.pem" \
            -subj "/CN=dev.purebliss.app"

        chown 1000:1000 "$cert_dir"/*.pem
        chmod 644 "$cert_dir"/*.pem
        log_action "Certificates regenerated successfully"
    fi

    # Verify config file
    local config_file="$VAULT_SERVICE_DIR/vault.hcl"
    if [[ ! -f "$config_file" ]]; then
        log_action "Creating Vault configuration..."
        cat > "$config_file" << 'EOF'
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/selfsigned/fullchain.pem"
  tls_key_file  = "/vault/certs/selfsigned/privkey.pem"
  tls_disable   = 0
}

api_addr = "https://dev.purebliss.app:8200"
ui = true
EOF
        log_action "Configuration created successfully"
    fi

    log_action "TLS configuration fix completed"
}

function vault_network_fix() {
    log_action "Fixing network configuration..."

    # Check if network exists
    if ! docker network ls | grep -q purebliss-net; then
        log_action "Creating purebliss-net network..."
        docker network create purebliss-net
        log_action "Network created successfully"
    fi

    log_action "Network configuration fix completed"
}

function vault_agent_config_fix() {
    log_action "Fixing Vault Agent configuration..."

    # Ensure agent config directory exists
    local agent_config_dir="$VAULT_SERVICE_DIR/vault-agent-config"
    mkdir -p "$agent_config_dir"
    chown -R "$USER:$USER" "$agent_config_dir"

    # Create/verify agent config
    local agent_config="$agent_config_dir/config.hcl"
    if [[ ! -f "$agent_config" ]] || ! grep -q "listener" "$agent_config"; then
        log_action "Creating Vault Agent configuration..."
        cat > "$agent_config" << 'EOF'
# Simplified Vault Agent config for development
pid_file = "/tmp/agent.pid"

vault {
  address = "https://vault:8200"
  tls_skip_verify = true
}

cache {
  use_auto_auth_token = false
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}
EOF
        log_action "Agent configuration created successfully"
    fi

    log_action "Vault Agent configuration fix completed"
}

function vault_postgresql_integration_fix() {
    log_action "Fixing PostgreSQL integration..."

    # Check if PostgreSQL is running
    if ! docker ps | grep -q purebliss-postgres; then
        log_action "PostgreSQL not running. Starting PostgreSQL with Vault integration..."
        if [[ -x "/opt/dev-purebliss/services/postgres/start-fresh.sh" ]]; then
            /opt/dev-purebliss/services/postgres/start-fresh.sh
        else
            log_action "PostgreSQL start script not found"
            return 1
        fi
    fi

    # Verify Vault token exists
    if [[ ! -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        log_action "Vault token not found - cannot configure database integration"
        return 1
    fi

    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

    # Configure database secrets engine if not already configured
    if ! vault read database/config/postgres-app >/dev/null 2>&1; then
        log_action "Configuring Vault database secrets engine..."
        vault write database/config/postgres-app \
            plugin_name=postgresql-database-plugin \
            connection_url="postgresql://{{username}}:{{password}}@purebliss-postgres:5432/postgres?sslmode=disable" \
            allowed_roles="postgres-role" \
            username="vault_admin" \
            password="vault_admin_password_123" \
            disable_escaping=true || {
            log_action "Failed to configure database secrets engine"
            return 1
        }
        log_action "Database secrets engine configured successfully"
    fi

    # Test credential generation
    if vault read database/creds/postgres-role >/dev/null 2>&1; then
        log_action "PostgreSQL integration working - dynamic credentials can be generated"
    else
        log_action "PostgreSQL integration issue - cannot generate dynamic credentials"
        return 1
    fi

    log_action "PostgreSQL integration fix completed successfully"
}

function vault_redis_integration_fix() {
    log_action "Fixing Redis integration..."

    # Check if Redis container is running
    if ! docker ps | grep -q purebliss-redis; then
        log_action "Redis container not running - cannot validate integration"
        return 1
    fi

    # Ensure Vault is ready
    if ! curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
        log_action "Vault is sealed - cannot validate Redis integration"
        return 1
    fi

    # Test Redis connection from Vault
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Test Redis database plugin connection
        if vault read redis/config/redis >/dev/null 2>&1; then
            log_action "Redis connection configured in Vault"

            # Test network connectivity
            if docker exec purebliss-vault nc -z purebliss-redis 6379 2>/dev/null; then
                log_action "Network connectivity to Redis confirmed"
            else
                log_action "Cannot reach Redis from Vault container"
                return 1
            fi
        else
            log_action "Redis connection not configured - running onboarding..."
            # Trigger Redis onboarding
            /opt/dev-purebliss/start-all-services.sh redis
        fi
    else
        log_action "Vault token not found - cannot test Redis integration"
        return 1
    fi

    log_action "Redis integration validation completed"
}

function vault_keycloak_integration_fix() {
    log_action "Fixing Keycloak-Vault-PostgreSQL integration..."

    # Check if Keycloak container is running
    if ! docker ps | grep -q purebliss-keycloak; then
        log_error "Keycloak container not running - cannot validate integration"
        return 1
    fi

    # Check health status and fix if needed
    local keycloak_health
    keycloak_health=$(docker inspect --format='{{.State.Health.Status}}' purebliss-keycloak 2>/dev/null || echo "no_healthcheck")

    if [[ "$keycloak_health" == "unhealthy" ]]; then
        log_action "Keycloak health check failing - investigating..."

        # Check if health check is using unavailable tools
        local healthcheck_test
        healthcheck_test=$(docker inspect --format='{{json .Config.Healthcheck.Test}}' purebliss-keycloak 2>/dev/null)

        if echo "$healthcheck_test" | grep -q "curl"; then
            log_warning "Health check using curl (not available in container)"
            log_action "Recommend updating docker-compose.yml health check to TCP-based method"
            echo "   Suggested health check: exec 3<>/dev/tcp/localhost/8080 && echo -e 'GET / HTTP/1.1\\r\\nHost: localhost\\r\\n\\r\\n' >&3"
        fi

        if echo "$healthcheck_test" | grep -q "ss"; then
            log_warning "Health check using ss (not available in container)"
            log_action "Recommend updating docker-compose.yml health check to TCP-based method"
        fi

        # Try restarting the container
        log_action "Restarting Keycloak container..."
        docker restart purebliss-keycloak
        sleep 30

        # Check health again
        keycloak_health=$(docker inspect --format='{{.State.Health.Status}}' purebliss-keycloak 2>/dev/null || echo "no_healthcheck")
        if [[ "$keycloak_health" == "healthy" ]]; then
            log_success "Keycloak health check now passing after restart"
        fi
    fi

    # Ensure Vault is ready for secrets
    if ! curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
        log_error "Vault is sealed - cannot validate Keycloak integration"
        return 1
    fi

    # Ensure PostgreSQL is running
    if ! docker ps | grep -q purebliss-postgres; then
        log_error "PostgreSQL container not running - Keycloak requires database"
        return 1
    fi

    # Test Keycloak secrets in Vault
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Check if Keycloak secrets exist in Vault
        if vault kv get secret/keycloak >/dev/null 2>&1; then
            log_success "Keycloak secrets configured in Vault"

            # Validate PostgreSQL database permissions
            if docker exec purebliss-postgres psql -U postgres -d keycloak -c "SELECT 1" >/dev/null 2>&1; then
                log_success "Keycloak database accessible"

                # Check keycloak user permissions
                if docker exec purebliss-postgres psql -U postgres -d keycloak -c "\du keycloak" | grep -q keycloak; then
                    log_success "Keycloak database user configured"

                    # Test keycloak user can access public schema
                    if docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT 1" >/dev/null 2>&1; then
                        log_success "Keycloak user schema permissions working"
                    else
                        log_action "Fixing Keycloak user schema permissions..."
                        docker exec purebliss-postgres psql -U postgres -d keycloak -c "GRANT USAGE, CREATE ON SCHEMA public TO keycloak;"
                        docker exec purebliss-postgres psql -U postgres -d keycloak -c "ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO keycloak;"
                        log_success "Keycloak schema permissions fixed"
                    fi
                else
                    log_warning "Keycloak database user not found - may need setup"
                fi
            else
                log_error "Cannot access Keycloak database"
                return 1
            fi

            # Test Keycloak endpoint accessibility using the same method as health check
            if docker exec purebliss-keycloak bash -c "exec 3<>/dev/tcp/localhost/8080 && echo -e 'GET / HTTP/1.1\r\nHost: localhost\r\n\r\n' >&3 && read -t1 response <&3 && exec 3<&- && exec 3>&-" >/dev/null 2>&1; then
                log_success "Keycloak endpoint responding correctly"
            else
                log_warning "Keycloak endpoint not responding - checking container logs..."
                docker logs purebliss-keycloak --tail 5
            fi

        else
            log_action "Keycloak secrets not configured - creating default secrets..."
            # Enable KV v2 secrets engine if not already enabled
            vault secrets enable -version=2 kv 2>/dev/null || true

            # Create default Keycloak secrets if missing
            vault kv put secret/keycloak \
                admin_password="admin123" \
                db_password="keycloak_password" || {
                log_error "Failed to create Keycloak secrets"
                return 1
            }
            log_success "Default Keycloak secrets created successfully"
        fi
    else
        log_error "Vault token not found - cannot test Keycloak integration"
        return 1
    fi

    log_success "Keycloak integration validation completed"
}

function vault_kv_secrets_engine_fix() {
    log_action "Ensuring KV v2 secrets engine is enabled and functional..."

    # Ensure Vault is ready
    if ! curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
        log_action "Vault is sealed - cannot configure KV secrets engine"
        return 1
    fi

    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Check if KV v2 is enabled
        if ! vault secrets list | grep -q "^secret/"; then
            log_action "Enabling KV v2 secrets engine..."
            vault secrets enable -version=2 kv || {
                log_action "Failed to enable KV v2 secrets engine"
                return 1
            }
            log_action "KV v2 secrets engine enabled successfully"
        else
            log_action "KV v2 secrets engine already enabled"
        fi

        # Test KV functionality with a test secret
        if ! vault kv get secret/test >/dev/null 2>&1; then
            log_action "Testing KV v2 functionality..."
            vault kv put secret/test test_key="test_value" || {
                log_action "KV v2 test write failed"
                return 1
            }

            if vault kv get secret/test | grep -q "test_value"; then
                log_action "KV v2 functionality confirmed"
                vault kv delete secret/test 2>/dev/null || true
            else
                log_action "KV v2 test read failed"
                return 1
            fi
        fi

    else
        log_action "Vault token not found - cannot test KV secrets engine"
        return 1
    fi

    log_action "KV v2 secrets engine validation completed"
}

function vault_comprehensive_diagnostic() {
    log_action "Running comprehensive Vault diagnostic..."

    # Service status overview
    show_service_overview

    # Container status
    echo "=== Container Status ==="
    docker ps | grep -E "(purebliss-vault|purebliss-redis|purebliss-postgres|purebliss-keycloak)" || echo "No Pure Bliss containers running"
    echo ""

    # Network connectivity
    echo "=== Network Tests ==="
    if curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
        echo "✅ Vault HTTPS endpoint accessible"
    else
        echo "❌ Vault HTTPS endpoint not accessible"
    fi

    if nc -z 127.0.0.1 8100 2>/dev/null; then
        echo "✅ Vault Agent port 8100 accessible"
    else
        echo "❌ Vault Agent port 8100 not accessible"
    fi

    # Check if purebliss-net network exists
    if docker network ls | grep -q purebliss-net; then
        echo "✅ purebliss-net network exists"
    else
        echo "❌ purebliss-net network missing"
    fi
    echo ""

    # Vault status check
    echo "=== Vault Status ==="
    if curl -sk https://127.0.0.1:8200/v1/sys/health 2>/dev/null; then
        echo ""
    else
        echo "❌ Vault API not responding"
    fi
    echo ""

    # PostgreSQL Integration Check
    echo "=== PostgreSQL Integration ==="
    if docker ps | grep -q purebliss-postgres; then
        echo "✅ PostgreSQL container running"

        # Check Vault database secrets engine
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
            export VAULT_ADDR="https://127.0.0.1:8200"
            export VAULT_SKIP_VERIFY=1
            export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

            # Test database connection config
            if vault read database/config/postgres-app >/dev/null 2>&1; then
                echo "✅ Database secrets engine configured"

                # Test credential generation
                if vault read database/creds/postgres-role >/dev/null 2>&1; then
                    echo "✅ Dynamic credential generation working"
                else
                    echo "❌ Dynamic credential generation failed"
                fi
            else
                echo "❌ Database secrets engine not configured"
            fi
        else
            echo "⚠️  Vault token not available for database testing"
        fi
    else
        echo "⚠️  PostgreSQL container not running - integration not testable"
    fi

    # Redis Integration Check
    echo "=== Redis Integration ==="
    if docker ps | grep -q purebliss-redis; then
        echo "✅ Redis container running"

        # Check Vault Redis database plugin
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
            export VAULT_ADDR="https://127.0.0.1:8200"
            export VAULT_SKIP_VERIFY=1
            export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

            # Test Redis connection config
            if vault read redis/config/redis >/dev/null 2>&1; then
                echo "✅ Redis connection configured in Vault"

                # Test network connectivity
                if docker exec purebliss-vault nc -z purebliss-redis 6379 2>/dev/null; then
                    echo "✅ Network connectivity to Redis confirmed"
                else
                    echo "❌ Cannot reach Redis from Vault container"
                fi
            else
                echo "❌ Redis connection not configured in Vault"
            fi
        else
            echo "⚠️  Vault token not available for Redis testing"
        fi
    else
        echo "⚠️  Redis container not running - integration not testable"
    fi

    # Keycloak Integration Check
    echo "=== Keycloak Integration ==="
    if docker ps | grep -q purebliss-keycloak; then
        echo "✅ Keycloak container running"

        # Check Keycloak health
        local keycloak_health
        keycloak_health=$(docker inspect --format='{{.State.Health.Status}}' purebliss-keycloak 2>/dev/null || echo "no_healthcheck")
        echo "Keycloak Health: $keycloak_health"

        # Check Vault KV secrets for Keycloak
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
            export VAULT_ADDR="https://127.0.0.1:8200"
            export VAULT_SKIP_VERIFY=1
            export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

            # Test KV v2 secrets engine
            if vault secrets list | grep -q "^secret/"; then
                echo "✅ KV v2 secrets engine enabled"

                # Test Keycloak secrets
                if vault kv get secret/keycloak >/dev/null 2>&1; then
                    echo "✅ Keycloak secrets configured in Vault"

                    # Test Keycloak database access
                    if docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT 1" >/dev/null 2>&1; then
                        echo "✅ Keycloak database user access working"
                    else
                        echo "❌ Keycloak database user access failed"
                    fi

                    # Test Keycloak endpoint
                    if curl -s "http://localhost:8080/" | grep -qE "(Keycloak|Resource not found)"; then
                        echo "✅ Keycloak endpoint responding"
                    else
                        echo "❌ Keycloak endpoint not responding"
                    fi
                else
                    echo "❌ Keycloak secrets not configured in Vault"
                fi
            else
                echo "❌ KV v2 secrets engine not enabled"
            fi
        else
            echo "⚠️  Vault token not available for Keycloak testing"
        fi
    else
        echo "⚠️  Keycloak container not running - integration not testable"
    fi

    # KV Secrets Engine Check
    echo "=== KV v2 Secrets Engine ==="
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        if vault secrets list | grep -q "^secret/"; then
            echo "✅ KV v2 secrets engine enabled"

            # List configured secrets
            echo "Configured secrets:"
            vault kv list secret/ 2>/dev/null | grep -v "^Keys$" | grep -v "^----$" | sed 's/^/  - /' || echo "  (no secrets configured)"
        else
            echo "❌ KV v2 secrets engine not enabled"
        fi
    else
        echo "⚠️  Vault token not available for KV testing"
    fi

    # File system checks
    echo "=== File System Checks ==="
    if [[ -f "$VAULT_SERVICE_DIR/vault.hcl" ]]; then
        echo "✅ Vault config file exists"
    else
        echo "❌ Vault config file missing"
    fi

    if [[ -f "$VAULT_SERVICE_DIR/certs/selfsigned/privkey.pem" ]]; then
        echo "✅ TLS certificates exist"
        # Check certificate expiration
        local cert_expiry
        cert_expiry=$(openssl x509 -in "$VAULT_SERVICE_DIR/certs/selfsigned/fullchain.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
        echo "   Certificate expires: $cert_expiry"
    else
        echo "❌ TLS certificates missing"
    fi

    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        echo "✅ Vault token file exists"
    else
        echo "❌ Vault token file missing"
    fi
    echo ""

    # Recent logs
    echo "=== Recent Logs ==="
    echo "Vault Server (last 5 lines):"
    docker logs purebliss-vault --tail 5 2>/dev/null | sed 's/^/  /' || echo "  No logs available"
    echo ""
    echo "Vault Agent (last 5 lines):"
    docker logs purebliss-vault-agent --tail 5 2>/dev/null | sed 's/^/  /' || echo "  No logs available"
    echo ""

    # Integration summary
    echo "=== Integration Summary ==="
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        # Count enabled secrets engines
        local secrets_count
        secrets_count=$(vault secrets list 2>/dev/null | grep -c "/" || echo "0")
        echo "Enabled secrets engines: $secrets_count"

        # Count configured secrets
        local configured_secrets
        configured_secrets=$(vault kv list secret/ 2>/dev/null | grep -v "^Keys$" | grep -v "^----$" | wc -l || echo "0")
        echo "Configured KV secrets: $configured_secrets"

        # Service integration status
        local postgres_integrated redis_integrated keycloak_integrated
        postgres_integrated="❌"
        redis_integrated="❌"
        keycloak_integrated="❌"

        if vault read database/config/postgres-app >/dev/null 2>&1; then
            postgres_integrated="✅"
        fi

        if vault read redis/config/redis >/dev/null 2>&1; then
            redis_integrated="✅"
        fi

        if vault kv get secret/keycloak >/dev/null 2>&1; then
            keycloak_integrated="✅"
        fi

        echo "PostgreSQL Integration: $postgres_integrated"
        echo "Redis Integration: $redis_integrated"
        echo "Keycloak Integration: $keycloak_integrated"
    else
        echo "⚠️  Cannot check integrations - Vault token unavailable"
    fi
    echo ""

    log_success "Comprehensive diagnostic completed"
}

function vault_emergency_rebuild() {
    log_action "Emergency rebuild of Vault service..."

    # Stop and remove containers
    cd "$VAULT_SERVICE_DIR"
    docker-compose -f vault-docker-compose.yml down 2>/dev/null || true

    # Apply all fixes
    vault_network_fix
    vault_permissions_fix
    vault_tls_config_fix
    vault_agent_config_fix

    # Rebuild and start
    log_action "Rebuilding containers..."
    docker-compose -f vault-docker-compose.yml up -d --build

    # Wait for startup
    sleep 15

    # Verify
    vault_comprehensive_diagnostic

    log_success "Emergency rebuild completed"
}

function vault_auto_recovery() {
    log_action "Starting automatic service recovery..."

    # Service status check
    show_service_overview

    # Step 1: Check if any containers are missing
    local missing_services=()

    if ! docker ps -a | grep -q purebliss-vault; then
        missing_services+=("vault")
    fi

    if ! docker ps -a | grep -q purebliss-vault-agent; then
        missing_services+=("vault-agent")
    fi

    if [[ ${#missing_services[@]} -gt 0 ]]; then
        log_action "Missing containers detected: ${missing_services[*]}"
        vault_container_startup_fix
    fi

    # Step 2: Check for unhealthy containers
    local vault_health
    vault_health=$(docker inspect --format='{{.State.Health.Status}}' purebliss-vault 2>/dev/null || echo "unknown")

    if [[ "$vault_health" == "unhealthy" ]]; then
        log_action "Vault container unhealthy - attempting recovery..."
        vault_permissions_fix
        vault_tls_config_fix
        docker restart purebliss-vault
        sleep 10
    fi

    # Step 3: Verify Vault is accessible
    if ! verify_vault_ready; then
        log_warning "Vault not ready - applying comprehensive fixes..."
        vault_network_fix
        vault_permissions_fix
        vault_tls_config_fix
        vault_container_startup_fix

        # Give it another chance
        if ! verify_vault_ready; then
            log_error "Auto-recovery failed - manual intervention may be required"
            return 1
        fi
    fi

    # Step 4: Ensure KV secrets engine is working
    vault_kv_secrets_engine_fix

    # Step 5: Test integrations
    if docker ps | grep -q purebliss-postgres; then
        vault_postgresql_integration_fix || log_warning "PostgreSQL integration issues detected"
    fi

    if docker ps | grep -q purebliss-redis; then
        vault_redis_integration_fix || log_warning "Redis integration issues detected"
    fi

    if docker ps | grep -q purebliss-keycloak; then
        vault_keycloak_integration_fix || log_warning "Keycloak integration issues detected"
    fi

    log_success "Automatic service recovery completed"

    # Final status check
    show_service_overview
}

function main() {
    local fix_type="${1:-diagnostic}"

    log_action "Starting Vault break/fix procedure: $fix_type"

    case "$fix_type" in
        "container_startup"|"startup")
            vault_container_startup_fix
            ;;
        "permissions"|"perms")
            vault_permissions_fix
            ;;
        "tls_config"|"tls")
            vault_tls_config_fix
            ;;
        "network")
            vault_network_fix
            ;;
        "agent_config"|"agent")
            vault_agent_config_fix
            ;;
        "postgresql_integration"|"postgres"|"db")
            vault_postgresql_integration_fix
            ;;
        "redis_integration"|"redis")
            vault_redis_integration_fix
            ;;
        "keycloak_integration"|"keycloak")
            vault_keycloak_integration_fix
            ;;
        "nginx_integration"|"nginx")
            vault_nginx_integration_fix
            ;;
        "nginx_pki_integration"|"nginx_pki"|"nginx")
            vault_nginx_pki_integration_fix
            ;;
        "letsencrypt_vault_integration"|"letsencrypt_vault"|"letsencrypt")
            vault_letsencrypt_vault_integration_fix
            ;;
        "prometheus_vault_integration"|"prometheus_vault"|"prometheus")
            vault_prometheus_vault_integration_fix
            ;;
        "kv_secrets"|"kv"|"secrets")
            vault_kv_secrets_engine_fix
            ;;
        "diagnostic"|"diag")
            vault_comprehensive_diagnostic
            ;;
        "emergency"|"rebuild")
            vault_emergency_rebuild
            ;;
        "auto_recovery"|"auto"|"recovery")
            vault_auto_recovery
            ;;
        "status"|"overview")
            show_service_overview
            ;;
        "all"|"comprehensive")
            vault_network_fix
            vault_permissions_fix
            vault_tls_config_fix
            vault_agent_config_fix
            vault_kv_secrets_engine_fix
            vault_container_startup_fix
            vault_postgresql_integration_fix
            vault_redis_integration_fix
            vault_keycloak_integration_fix
            vault_nginx_pki_integration_fix
            sleep 10
            vault_comprehensive_diagnostic
            ;;
        *)
            echo "❌ Unknown fix type: $fix_type"
            echo ""
            echo "Available fix types:"
            echo "  container_startup    - Fix container startup issues"
            echo "  permissions         - Fix file/directory permissions"
            echo "  tls_config          - Fix TLS configuration and certificates"
            echo "  network             - Fix Docker network issues"
            echo "  agent_config        - Fix Vault Agent configuration"
            echo "  postgresql_integration - Fix PostgreSQL database integration"
            echo "  redis_integration   - Fix Redis integration and validation"
            echo "  keycloak_integration - Fix Keycloak-Vault-PostgreSQL integration"
            echo "  nginx_pki_integration - Fix Nginx Vault PKI onboarding and cert renewal"
            echo "  kv_secrets          - Fix KV v2 secrets engine configuration"
            echo "  diagnostic          - Run comprehensive diagnostic"
            echo "  auto_recovery       - Intelligent automatic service recovery"
            echo "  status              - Show service status overview"
            echo "  emergency           - Emergency rebuild (stops/rebuilds everything)"
            echo "  all                 - Apply all fixes"
            exit 1
            ;;
    esac

    log_action "Break/fix procedure completed: $fix_type"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

function vault_nginx_integration_fix() {
    log_action "Fixing nginx Vault integration..."

    # Check if nginx container is running
    if ! docker ps | grep -q purebliss-nginx; then
        log_error "nginx container not running - cannot validate integration"
        return 1
    fi

    # Ensure Vault is ready
    if ! curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
        log_error "Vault is sealed - cannot validate nginx integration"
        return 1
    fi

    # Restart nginx integration
    if [[ -x "/opt/dev-purebliss/services/nginx/start-nginx-with-vault.sh" ]]; then
        log_action "Restarting nginx with Vault integration..."
        /opt/dev-purebliss/services/nginx/start-nginx-with-vault.sh
    else
        log_warning "nginx Vault integration script not found"
    fi

    # Validate integration
    if [[ -x "/opt/dev-purebliss/services/nginx/validate-nginx-vault-integration.sh" ]]; then
        log_action "Validating nginx Vault integration..."
        /opt/dev-purebliss/services/nginx/validate-nginx-vault-integration.sh
    else
        log_warning "nginx validation script not found"
    fi

    log_success "nginx Vault integration validation completed"
}
