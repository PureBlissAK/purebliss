#!/bin/bash
#
# Pure Bliss Infrastructure Agent - Elite Infrastructure Deployment
# Top 0.01% Infrastructure Expert Implementation
#
# Service Order: Vault → PostgreSQL → Redis → Nginx → LetsEncrypt → Keycloak
#                → Grafana → Prometheus → Loki → Plane → Code-Server
#

set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/infrastructure-agent.log"
AGENT_DEFINITION="/opt/my-secure-ha-stack/orchestrator/agents/infrastructure-agent.md"
SERVICES_BASE="/opt/dev-purebliss/services"

# --- Elite Helper Functions ---

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFRA-AGENT] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

check_docker_network() {
    log "Ensuring Docker network: purebliss-net..."
    if ! docker network inspect purebliss-net >/dev/null 2>&1; then
        log "Creating purebliss-net bridge network..."
        docker network create --driver bridge purebliss-net || error_exit "Failed to create Docker network"
    else
        log "Network purebliss-net verified"
    fi
}

wait_for_service_healthy() {
    local service_name="$1"
    local max_wait="${2:-120}"
    local container_name="purebliss-$service_name"
    
    log "Waiting for $service_name to become healthy (max ${max_wait}s)..."
    
    for i in $(seq 1 $max_wait); do
        if docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
            local status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-health")
            if [[ "$status" == "healthy" ]]; then
                log "$service_name is healthy ✓"
                return 0
            elif [[ "$status" == "no-health" ]]; then
                # No health check defined, check if running
                local state=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
                if [[ "$state" == "running" ]]; then
                    log "$service_name is running (no health check) ✓"
                    return 0
                fi
            fi
        fi
        sleep 1
    done
    
    error_exit "$service_name failed to become healthy within ${max_wait}s"
}

start_service_with_compose() {
    local service_name="$1"
    local service_dir="$SERVICES_BASE/$service_name"
    local container_name="purebliss-$service_name"
    
    # Check if service is already healthy
    if docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")
        if [[ "$health" == "healthy" ]]; then
            log "$service_name is already healthy, skipping..."
            return 0
        fi
    fi
    
    log "Starting $service_name..."
    
    if [[ ! -d "$service_dir" ]]; then
        error_exit "Service directory not found: $service_dir"
    fi
    
    cd "$service_dir"
    
    # Try service-specific compose file first, then fall back to generic
    local compose_file=""
    if [[ -f "${service_name}-docker-compose.yml" ]]; then
        compose_file="${service_name}-docker-compose.yml"
    elif [[ -f "docker-compose.yml" ]]; then
        compose_file="docker-compose.yml"
    else
        error_exit "No docker-compose file found for $service_name in $service_dir"
    fi
    
    log "Using compose file: $compose_file"
    docker-compose -f "$compose_file" down --remove-orphans 2>/dev/null || true
    docker-compose -f "$compose_file" up -d || error_exit "Failed to start $service_name"
}

initialize_vault() {
    log "Initializing and unsealing Vault..."
    local unseal_file="/opt/my-secure-ha-stack/vault-unseal-keys.env"
    
    # Check if Vault is initialized
    if ! docker exec purebliss-vault vault status | grep -q 'Initialized.*true' 2>/dev/null; then
        log "Initializing Vault..."
        local init_output=$(docker exec purebliss-vault vault operator init -key-shares=3 -key-threshold=2 -format=json)
        
        # Extract keys and token
        local key1=$(echo "$init_output" | jq -r '.unseal_keys_b64[0]')
        local key2=$(echo "$init_output" | jq -r '.unseal_keys_b64[1]')
        local key3=$(echo "$init_output" | jq -r '.unseal_keys_b64[2]')
        local root_token=$(echo "$init_output" | jq -r '.root_token')
        
        # Save to file
        cat > "$unseal_file" << EOF
VAULT_DEV_UNSEAL_KEY_1="$key1"
VAULT_DEV_UNSEAL_KEY_2="$key2"
VAULT_DEV_UNSEAL_KEY_3="$key3"
VAULT_DEV_ROOT_TOKEN="$root_token"
EOF
        chmod 600 "$unseal_file"
        log "Vault initialized successfully"
    else
        log "Vault already initialized"
    fi
    
    # Load unseal keys
    if [[ -f "$unseal_file" ]]; then
        source "$unseal_file"
    else
        error_exit "Vault unseal keys not found"
    fi
    
    # Unseal if needed
    if docker exec purebliss-vault vault status | grep -q 'Sealed.*true' 2>/dev/null; then
        log "Unsealing Vault..."
        docker exec purebliss-vault vault operator unseal "$VAULT_DEV_UNSEAL_KEY_1" >/dev/null
        docker exec purebliss-vault vault operator unseal "$VAULT_DEV_UNSEAL_KEY_2" >/dev/null
        log "Vault unsealed successfully"
    else
        log "Vault already unsealed"
    fi
}

setup_ssl_certificates() {
    log "Setting up SSL certificates..."
    local cert_dir="/opt/dev-purebliss/services/nginx/certs"
    
    mkdir -p "$cert_dir"
    
    # Generate self-signed certificate
    if [[ ! -f "$cert_dir/dev.purebliss.app.crt" ]]; then
        log "Generating self-signed SSL certificate..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$cert_dir/dev.purebliss.app.key" \
            -out "$cert_dir/dev.purebliss.app.crt" \
            -subj "/C=US/ST=FL/L=Tampa/O=PureBliss/CN=dev.purebliss.app" \
            -addext "subjectAltName = DNS:dev.purebliss.app,DNS:*.dev.purebliss.app" || error_exit "Failed to generate SSL certificate"
        
        chmod 644 "$cert_dir/dev.purebliss.app.crt"
        chmod 600 "$cert_dir/dev.purebliss.app.key"
        log "Self-signed SSL certificate generated"
    else
        log "SSL certificate already exists"
    fi
}

# --- Main Agent Logic ---

log "=== Pure Bliss Infrastructure Agent - Elite Deployment Starting ==="
log "Agent Definition: $AGENT_DEFINITION"
log "Services Base: $SERVICES_BASE"

# 0. Clean slate - stop unhealthy containers only
log "Preparing deployment environment..."

# Only stop unhealthy containers, keep healthy ones
for container in $(docker ps -a --filter "name=purebliss" --format "{{.Names}}" 2>/dev/null || true); do
    if [[ -n "$container" ]]; then
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")
        if [[ "$health" != "healthy" ]]; then
            log "Stopping unhealthy container: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        else
            log "Keeping healthy container: $container"
        fi
    fi
done

# 1. Ensure Docker network
check_docker_network

# 2. Setup SSL certificates first
setup_ssl_certificates

# 3. Phase 1: Core Infrastructure (Vault → PostgreSQL → Redis)
log "=== Phase 1: Core Infrastructure ==="

log "Starting Vault (Secrets Management)..."
start_service_with_compose "vault"
wait_for_service_healthy "vault" 60
initialize_vault

log "Starting PostgreSQL (Database)..."
start_service_with_compose "postgres"
wait_for_service_healthy "postgres" 60

log "Starting Redis (Cache)..."
start_service_with_compose "redis"
wait_for_service_healthy "redis" 60

# 4. Phase 2: Web Infrastructure (Nginx → LetsEncrypt → Keycloak)
log "=== Phase 2: Web Infrastructure ==="

log "Starting Nginx (Reverse Proxy)..."
start_service_with_compose "nginx"
wait_for_service_healthy "nginx" 60

log "Starting LetsEncrypt (SSL Management)..."
start_service_with_compose "letsencrypt"
sleep 10  # Give it time to start

log "Starting Keycloak (Authentication)..."
start_service_with_compose "keycloak"
wait_for_service_healthy "keycloak" 120

# 5. Phase 3: Monitoring Stack (Grafana → Prometheus → Loki)
log "=== Phase 3: Monitoring Stack ==="

log "Starting Grafana (Dashboards)..."
start_service_with_compose "grafana"
wait_for_service_healthy "grafana" 60

log "Starting Prometheus (Metrics)..."
start_service_with_compose "prometheus"
wait_for_service_healthy "prometheus" 60

log "Starting Loki (Logs)..."
start_service_with_compose "loki"
wait_for_service_healthy "loki" 60

# 6. Phase 4: Application Services (Plane → Code-Server)
log "=== Phase 4: Application Services ==="

log "Starting Plane (Project Management)..."
start_service_with_compose "plane"
wait_for_service_healthy "plane" 120

log "Starting Code-Server (IDE)..."
start_service_with_compose "codeserver"
wait_for_service_healthy "codeserver" 60

# 7. Final verification and status report
log "=== Final Infrastructure Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=purebliss"

log "=== Service Health Summary ==="
for service in vault postgres redis nginx keycloak grafana prometheus loki plane codeserver; do
    container="purebliss-$service"
    if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
        status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "running")
        log "$service: $status ✓"
    else
        log "$service: NOT RUNNING ✗"
    fi
done

log "=== Pure Bliss Infrastructure Agent - Deployment Complete ==="
log "Access Points:"
log "  - Main App: https://dev.purebliss.app"
log "  - Code-Server: https://dev.purebliss.app/codeserver"
log "  - Keycloak: https://dev.purebliss.app/auth"
log "  - Grafana: https://dev.purebliss.app/grafana"
log "  - Vault: https://dev.purebliss.app/vault"
