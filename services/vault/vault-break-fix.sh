#!/bin/bash
set -euo pipefail

# Vault Automated Break/Fix Script
# Pure Bliss Development Environment
# Integrates with start-all-services.sh for automated problem resolution

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_SERVICE_DIR="/opt/dev-purebliss/services/vault"
BREAK_FIX_REPORT="$VAULT_SERVICE_DIR/vault-break-fix-report.md"

function log_action() {
    echo "[$(date)] VAULT_BREAKFIX: $1" >> "$LOG_FILE"
    echo "🔧 $1"
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

function vault_comprehensive_diagnostic() {
    log_action "Running comprehensive Vault diagnostic..."
    
    # Container status
    echo "=== Container Status ==="
    docker ps | grep vault || echo "No Vault containers running"
    
    # Health status
    echo "=== Health Status ==="
    local vault_health agent_status
    vault_health=$(docker inspect --format='{{.State.Health.Status}}' purebliss-vault 2>/dev/null || echo "unknown")
    agent_status=$(docker inspect --format='{{.State.Status}}' purebliss-vault-agent 2>/dev/null || echo "unknown")
    echo "Vault Health: $vault_health"
    echo "Agent Status: $agent_status"
    
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
    
    # File system checks
    echo "=== File System Checks ==="
    if [[ -f "$VAULT_SERVICE_DIR/vault.hcl" ]]; then
        echo "✅ Vault config file exists"
    else
        echo "❌ Vault config file missing"
    fi
    
    if [[ -f "$VAULT_SERVICE_DIR/certs/selfsigned/privkey.pem" ]]; then
        echo "✅ TLS certificates exist"
    else
        echo "❌ TLS certificates missing"
    fi
    
    # Recent logs
    echo "=== Recent Logs ==="
    echo "Vault Server:"
    docker logs purebliss-vault --tail 5 2>/dev/null || echo "No logs available"
    echo "Vault Agent:"
    docker logs purebliss-vault-agent --tail 5 2>/dev/null || echo "No logs available"
    
    log_action "Comprehensive diagnostic completed"
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
    
    log_action "Emergency rebuild completed"
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
        "diagnostic"|"diag")
            vault_comprehensive_diagnostic
            ;;
        "emergency"|"rebuild")
            vault_emergency_rebuild
            ;;
        "all"|"comprehensive")
            vault_network_fix
            vault_permissions_fix
            vault_tls_config_fix
            vault_agent_config_fix
            vault_container_startup_fix
            vault_postgresql_integration_fix
            vault_redis_integration_fix
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
            echo "  diagnostic          - Run comprehensive diagnostic"
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
