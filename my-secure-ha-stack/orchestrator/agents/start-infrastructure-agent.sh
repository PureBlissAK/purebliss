#!/bin/bash
#
# Pure Bliss Infrastructure Agent - Startup Script
#
# This script initializes and runs the infrastructure agent, which is responsible for
# maintaining the health and status of the Pure Bliss Elite Social Media Technology Stack.
#

LOG_FILE="/opt/my-secure-ha-stack/logs/infrastructure-agent.log"
AGENT_DEFINITION="/opt/my-secure-ha-stack/orchestrator/agents/infrastructure-agent.md"

# --- Helper Functions ---

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $1" | tee -a "$LOG_FILE"
}

check_docker_network() {
    log "Checking for Docker network: purebliss-net..."
    if ! docker network inspect purebliss-net >/dev/null 2>&1; then
        log "Network 'purebliss-net' not found. Creating it..."
        docker network create purebliss-net
    else
        log "Network 'purebliss-net' already exists."
    fi
}

start_service() {
    local service_name="$1"
    local compose_file="$2"
    log "Starting service: $service_name..."
    if [ -f "$compose_file" ]; then
        docker-compose -f "$compose_file" up -d
        log "$service_name started."
    else
        log "ERROR: Compose file not found for $service_name at $compose_file"
    fi
}

# --- Main Agent Logic ---

log "--- Pure Bliss Infrastructure Agent Initializing ---"
log "Agent Definition: $AGENT_DEFINITION"

# 1. Ensure Docker network is available
check_docker_network

# 2. Start core infrastructure services in order
start_service "Vault" "/opt/pure-bliss-dev/infrastructure/docker-compose/01-vault-core.yml"
# Add other core services here as they are created

# 3. Unseal Vault (simplified for this script)
log "Checking Vault status..."
# In a real scenario, this would involve fetching keys and unsealing
# For now, we just check the status
docker exec purebliss-vault vault status

# 4. Start application-level infrastructure
start_service "Nginx & Certbot" "/opt/pure-bliss-dev/infrastructure/docker-compose/05-nginx.yml"
start_service "Keycloak" "/opt/pure-bliss-dev/infrastructure/docker-compose/07-keycloak.yml"

# 5. Final Health Check
log "--- Performing Final System-Wide Health Check ---"
docker ps -a --filter "network=purebliss-net" --format "table {{.Names}}\t{{.Status}}\t{{.State}}"

log "--- Pure Bliss Infrastructure Agent Initialization Complete ---"
