#!/bin/bash
set -euo pipefail
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
UNSEAL_FILE="/opt/my-secure-ha-stack/vault-unseal-keys.env"

# Source centralized environment variables
if [ -f /opt/my-secure-ha-stack/config.env ]; then
  set -a
  . /opt/my-secure-ha-stack/config.env
  set +a
fi

# Purge orphans and stale Docker resources for a clean environment
{
  echo "[$(date)] INFO: Purging orphaned and stale Docker containers, networks, volumes, and images..."
  docker-compose -f /opt/dev-purebliss/docker-compose.yml down --remove-orphans --volumes || true
  docker system prune -af --volumes || true
  docker network prune -f || true
  docker volume prune -f || true
  docker image prune -af || true
  echo "[$(date)] INFO: Docker environment purged."
} | tee -a "$LOG_FILE"

# Ensure purebliss-net Docker bridge network exists after prune
if ! docker network ls --format '{{.Name}}' | grep -q "^purebliss-net$"; then
  docker network create --driver bridge purebliss-net
  echo "[$(date)] INFO: Created Docker bridge network purebliss-net" | tee -a "$LOG_FILE"
else
  echo "[$(date)] INFO: Docker bridge network purebliss-net already exists" | tee -a "$LOG_FILE"
fi

# Create required persistent data and log directories for all services
REQUIRED_DIRS=(
  "$VAULT_DATA_PATH"
  "$VAULT_TLS_PATH"
  "${RAID0_MOUNT}/logs"
  "$POSTGRES_DATA_PATH"
  "$REDIS_DATA_PATH"
  "$PLANE_DATA_PATH"
  "$KEYCLOAK_DATA_PATH"
  "$NGINX_SSL_CERT_PATH"
  "${RAID0_MOUNT}/nginx/html"
  "$LOKI_DATA_PATH"
  "$PROMETHEUS_DATA_PATH"
  "$GRAFANA_DATA_PATH"
  "$CODESERVER_DATA_PATH"
  "$BACKUP_PATH"
)
for dir in "${REQUIRED_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    chmod 700 "$dir"
    echo "[$(date)] INFO: Created directory $dir" | tee -a "$LOG_FILE"
  fi
  # Loosen permissions for shared logs if needed
  if [[ "$dir" == *"/logs"* ]]; then
    chmod 750 "$dir"
  fi

done

mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date)] INFO: Starting all Pure Bliss core services" | tee -a "$LOG_FILE"

BASE="/opt/dev-purebliss/services"

# Generate minimal Dockerfiles for all core services if missing
for svc in nginx letsencrypt vault vault-agent redis postgres keycloak grafana loki prometheus plane codeserver; do
  # Convert hyphens to underscores for env var lookup
  DOCKERFILE_VAR="$(echo ${svc^^}_DOCKERFILE | tr '-' '_')"
  DOCKERFILE_NAME="${!DOCKERFILE_VAR:-$svc-dockerfile}"
  DOCKERFILE_PATH="$BASE/$svc/$DOCKERFILE_NAME"
  if [ ! -f "$DOCKERFILE_PATH" ]; then
    case $svc in
      nginx)
        echo -e "FROM nginx:latest\nCOPY . /usr/share/nginx/html" > "$DOCKERFILE_PATH" ;;
      letsencrypt)
        echo -e "FROM certbot/certbot:latest" > "$DOCKERFILE_PATH" ;;
      vault|vault-agent)
        echo -e "FROM hashicorp/vault:1.17.3" > "$DOCKERFILE_PATH" ;;
      redis)
        echo -e "FROM redis:7" > "$DOCKERFILE_PATH" ;;
      postgres)
        echo -e "FROM postgres:16" > "$DOCKERFILE_PATH" ;;
      keycloak)
        echo -e "FROM quay.io/keycloak/keycloak:24.0.5" > "$DOCKERFILE_PATH" ;;
      grafana)
        echo -e "FROM grafana/grafana:10.1.0" > "$DOCKERFILE_PATH" ;;
      loki)
        echo -e "FROM grafana/loki:2.9.0" > "$DOCKERFILE_PATH" ;;
      prometheus)
        echo -e "FROM prom/prometheus:2.47.0" > "$DOCKERFILE_PATH" ;;
      plane)
        echo -e "FROM makeplane/plane:app-latest" > "$DOCKERFILE_PATH" ;;
      codeserver)
        echo -e "FROM codercom/code-server:4.20.0" > "$DOCKERFILE_PATH" ;;
    esac
    echo "[$(date)] INFO: Generated $DOCKERFILE_PATH" | tee -a "$LOG_FILE"
  fi
done

# Start Nginx and Let's Encrypt first (build then up)
for svc in nginx letsencrypt; do
  if [ -d "$BASE/$svc" ]; then
    COMPOSE_VAR="$(echo ${svc^^}_DOCKER_COMPOSE_FILE | tr '-' '_')"
    COMPOSE_FILE="${!COMPOSE_VAR:-docker-compose.yml}"
    echo "[$(date)] INFO: Building $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose -f "$COMPOSE_FILE" build) || {
      echo "[$(date)] ERROR: Failed to build $svc" | tee -a "$LOG_FILE"; exit 1;
    }
    echo "[$(date)] INFO: Starting $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose -f "$COMPOSE_FILE" up -d) || {
      echo "[$(date)] ERROR: Failed to start $svc" | tee -a "$LOG_FILE"; exit 1;
    }
  else
    echo "[$(date)] WARNING: $BASE/$svc directory not found, skipping." | tee -a "$LOG_FILE"
  fi
done

# Wait for Nginx and Let's Encrypt to be healthy before starting Vault
for svc in nginx letsencrypt; do
  for i in {1..30}; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' purebliss-$svc 2>/dev/null || echo "notfound")
    if [[ "$STATUS" == "healthy" ]]; then
      echo "[$(date)] INFO: $svc is healthy." | tee -a "$LOG_FILE"
      break
    fi
    echo "[$(date)] INFO: Waiting for $svc to become healthy... ($i/30)" | tee -a "$LOG_FILE"
    sleep 4
  done
  if [[ "$STATUS" != "healthy" ]]; then
    echo "[$(date)] ERROR: $svc did not become healthy in time." | tee -a "$LOG_FILE"
    exit 1
  fi
done

# Start Vault and Vault Agent next (build then up)
for svc in vault vault-agent; do
  if [ -d "$BASE/$svc" ]; then
    COMPOSE_VAR="$(echo ${svc^^}_DOCKER_COMPOSE_FILE | tr '-' '_')"
    COMPOSE_FILE="${!COMPOSE_VAR:-docker-compose.yml}"
    echo "[$(date)] INFO: Building $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose -f "$COMPOSE_FILE" build) || {
      echo "[$(date)] ERROR: Failed to build $svc" | tee -a "$LOG_FILE"; exit 1;
    }
    echo "[$(date)] INFO: Starting $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose -f "$COMPOSE_FILE" up -d) || {
      echo "[$(date)] ERROR: Failed to start $svc" | tee -a "$LOG_FILE"; exit 1;
    }
  else
    echo "[$(date)] WARNING: $BASE/$svc directory not found, skipping." | tee -a "$LOG_FILE"
  fi
done

# Wait for Vault to be healthy
for i in {1..30}; do
  VAULT_STATUS=$(docker inspect --format='{{.State.Health.Status}}' purebliss-vault 2>/dev/null || echo "notfound")
  if [[ "$VAULT_STATUS" == "healthy" ]]; then
    echo "[$(date)] INFO: Vault is healthy." | tee -a "$LOG_FILE"
    break
  fi
  echo "[$(date)] INFO: Waiting for Vault to become healthy... ($i/30)" | tee -a "$LOG_FILE"
  sleep 4
done
if [[ "$VAULT_STATUS" != "healthy" ]]; then
  echo "[$(date)] ERROR: Vault did not become healthy in time." | tee -a "$LOG_FILE"
  exit 1
fi

# Initialize Vault if needed and write unseal keys/root token
if ! docker exec purebliss-vault vault status | grep -q 'Initialized.*true'; then
  echo "[$(date)] INFO: Initializing Vault..." | tee -a "$LOG_FILE"
  INIT_OUTPUT=$(docker exec purebliss-vault vault operator init -key-shares=3 -key-threshold=2 -format=json)
  VAULT_DEV_UNSEAL_KEY_1=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
  VAULT_DEV_UNSEAL_KEY_2=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[1]')
  VAULT_DEV_UNSEAL_KEY_3=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[2]')
  VAULT_DEV_ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
else
  echo "[$(date)] INFO: Vault already initialized. Loading unseal keys/root token from $UNSEAL_FILE if present, else querying Vault..." | tee -a "$LOG_FILE"
  if [ -f "$UNSEAL_FILE" ]; then
    set -a
    . "$UNSEAL_FILE"
    set +a
  fi
  # Query the current unseal keys and root token if possible (dev mode or automation)
  VAULT_DEV_UNSEAL_KEY_1=${VAULT_DEV_UNSEAL_KEY_1:-}
  VAULT_DEV_UNSEAL_KEY_2=${VAULT_DEV_UNSEAL_KEY_2:-}
  VAULT_DEV_UNSEAL_KEY_3=${VAULT_DEV_UNSEAL_KEY_3:-}
  VAULT_DEV_ROOT_TOKEN=${VAULT_DEV_ROOT_TOKEN:-}
fi
# Always update the unseal file with the latest values
cat <<EOF > "$UNSEAL_FILE"
# Auto-generated by Pure Bliss environment setup
# Vault unseal key and root token for automation (development only)
VAULT_DEV_UNSEAL_KEY_1="$VAULT_DEV_UNSEAL_KEY_1"
VAULT_DEV_UNSEAL_KEY_2="$VAULT_DEV_UNSEAL_KEY_2"
VAULT_DEV_UNSEAL_KEY_3="$VAULT_DEV_UNSEAL_KEY_3"
VAULT_DEV_ROOT_TOKEN="$VAULT_DEV_ROOT_TOKEN"
EOF
chmod 600 "$UNSEAL_FILE"
echo "[$(date)] INFO: Vault unseal keys/root token written to $UNSEAL_FILE" | tee -a "$LOG_FILE"

# Unseal Vault if needed
if docker exec purebliss-vault vault status | grep -q 'Sealed.*true'; then
  echo "[$(date)] INFO: Unsealing Vault..." | tee -a "$LOG_FILE"
  docker exec purebliss-vault vault operator unseal "$VAULT_DEV_UNSEAL_KEY_1"
  docker exec purebliss-vault vault operator unseal "$VAULT_DEV_UNSEAL_KEY_2"
fi

# Wait for Vault Agent to be running
for i in {1..30}; do
  AGENT_STATUS=$(docker inspect --format='{{.State.Status}}' purebliss-vault-agent 2>/dev/null || echo "notfound")
  if [[ "$AGENT_STATUS" == "running" ]]; then
    echo "[$(date)] INFO: Vault Agent is running." | tee -a "$LOG_FILE"
    break
  fi
  echo "[$(date)] INFO: Waiting for Vault Agent to be running... ($i/30)" | tee -a "$LOG_FILE"
  sleep 4
done
if [[ "$AGENT_STATUS" != "running" ]]; then
  echo "[$(date)] ERROR: Vault Agent did not start in time." | tee -a "$LOG_FILE"
  exit 1
fi

# Store Nginx and Let's Encrypt secrets in Vault
for svc in nginx letsencrypt; do
  if [ -x /opt/dev-purebliss/dev_scripts/vault-secrets.sh ]; then
    echo "[$(date)] INFO: Uploading $svc certs/keys to Vault..." | tee -a "$LOG_FILE"
    /opt/dev-purebliss/dev_scripts/vault-secrets.sh "$svc" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: vault-secrets.sh not found or not executable, skipping $svc secret upload." | tee -a "$LOG_FILE"
  fi
done
# Restart Vault Agent to render new templates
if docker ps -q -f name=purebliss-vault-agent; then
  echo "[$(date)] INFO: Restarting Vault Agent to render latest secrets/templates..." | tee -a "$LOG_FILE"
  docker restart purebliss-vault-agent | tee -a "$LOG_FILE"
fi

# Start remaining services (build then up)
for svc in redis postgres keycloak grafana loki prometheus plane codeserver; do
  if [ -d "$BASE/$svc" ]; then
    COMPOSE_VAR="$(echo ${svc^^}_DOCKER_COMPOSE_FILE | tr '-' '_')"
    COMPOSE_FILE="${!COMPOSE_VAR:-docker-compose.yml}"
    echo "[$(date)] INFO: Building $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose -f "$COMPOSE_FILE" build) || {
      echo "[$(date)] ERROR: Failed to build $svc" | tee -a "$LOG_FILE"; exit 1;
    }
    echo "[$(date)] INFO: Starting $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose -f "$COMPOSE_FILE" up -d) || {
      echo "[$(date)] ERROR: Failed to start $svc" | tee -a "$LOG_FILE"; exit 1;
    }
  else
    echo "[$(date)] WARNING: $BASE/$svc directory not found, skipping." | tee -a "$LOG_FILE"
  fi
done

echo "[$(date)] INFO: All core services started. Checking status..." | tee -a "$LOG_FILE"
docker ps --format 'table {{.Names}}\t{{.Status}}' | tee -a "$LOG_FILE"
echo "[$(date)] INFO: Pure Bliss stack startup complete." | tee -a "$LOG_FILE"
