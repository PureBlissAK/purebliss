#!/bin/bash
set -euo pipefail

# Service-specific user IDs for permission management:
# - Grafana: 472:472
# - Prometheus: 0:0 (root)
# - Loki: 0:0 (root)

CONFIG_ENV_PATH="/opt/my-secure-ha-stack/config.env"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
UNSEAL_FILE="/opt/my-secure-ha-stack/vault-unseal-keys.env"

# Source centralized environment variables
if [ -f "$CONFIG_ENV_PATH" ]; then
  set -a
  . "$CONFIG_ENV_PATH"
  set +a
fi

# Purge orphans and stale Docker resources for a clean environment (preserving certificates)
{
  echo "[$(date)] INFO: Purging orphaned and stale Docker containers, networks, and images (preserving certificate volumes)..."
  docker-compose -f /opt/dev-purebliss/docker-compose.yml down --remove-orphans || true
  docker system prune -af || true
  docker network prune -f || true
  docker image prune -af || true
  echo "[$(date)] INFO: Docker environment purged (certificate volumes preserved)."
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
  "${RAID0_MOUNT}/letsencrypt/webroot"
  "${RAID0_MOUNT}/nginx/certs/archive"
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

  # Set specific permissions for Grafana log file
  if [[ "$dir" == *"/logs"* ]]; then
    # Create Grafana log file if it doesn't exist
    if [ ! -f "${RAID0_MOUNT}/logs/grafana.log" ]; then
      touch "${RAID0_MOUNT}/logs/grafana.log"
      chown 472:472 "${RAID0_MOUNT}/logs/grafana.log" 2>/dev/null || true
      chmod 644 "${RAID0_MOUNT}/logs/grafana.log"
    fi
  fi

  # Set specific permissions for Prometheus data directory
  if [[ "$dir" == *"/prometheus/data"* ]]; then
    chmod 755 "$dir"
    chown -R 0:0 "$dir" 2>/dev/null || true
  fi

  # Set specific permissions for Grafana data directory
  if [[ "$dir" == *"/grafana/data"* ]]; then
    chmod 755 "$dir"
    chown -R 472:472 "$dir" 2>/dev/null || true

    # Create required Grafana subdirectories
    mkdir -p "$dir/plugins"
    mkdir -p "$dir/dashboards"
    mkdir -p "$dir/datasources"
    mkdir -p "$dir/provisioning"
    chown -R 472:472 "$dir" 2>/dev/null || true
    chmod -R 755 "$dir"
  fi

  # Set specific permissions for Loki data directory
  if [[ "$dir" == *"/loki/data"* ]]; then
    chmod 755 "$dir"
    chown -R 0:0 "$dir" 2>/dev/null || true
  fi

  # Set specific permissions for Let's Encrypt webroot directory
  if [[ "$dir" == *"/letsencrypt/webroot"* ]]; then
    chmod 755 "$dir"
    chown -R root:root "$dir" 2>/dev/null || true

    # Create .well-known/acme-challenge directory structure
    mkdir -p "$dir/.well-known/acme-challenge"
    chmod 755 "$dir/.well-known"
    chmod 755 "$dir/.well-known/acme-challenge"
    chown -R root:root "$dir/.well-known" 2>/dev/null || true
  fi

  # Set specific permissions for Let's Encrypt archive directory
  if [[ "$dir" == *"/nginx/certs/archive"* ]]; then
    chmod 755 "$dir"
    chown -R root:root "$dir" 2>/dev/null || true
  fi
done

# Ensure services directory has proper ownership for editing
echo "[$(date)] INFO: Setting services directory ownership..." | tee -a "$LOG_FILE"
chown -R $USER:$USER /opt/dev-purebliss/services/ 2>/dev/null || true
chmod -R 755 /opt/dev-purebliss/services/ 2>/dev/null || true

# SSL Certificate Setup - Two-phase approach
echo "[$(date)] INFO: Setting up SSL certificates..." | tee -a "$LOG_FILE"

# Function to generate self-signed certificate
generate_self_signed_cert() {
  local cert_dir="${NGINX_SSL_CERT_PATH}/dev.purebliss.app"
  echo "[$(date)] INFO: Generating self-signed SSL certificate..." | tee -a "$LOG_FILE"
  mkdir -p "$cert_dir"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$cert_dir/privkey.pem" \
    -out "$cert_dir/fullchain.pem" \
    -subj "/C=US/ST=State/L=City/O=PureBliss/CN=dev.purebliss.app" \
    -addext "subjectAltName = DNS:dev.purebliss.app,DNS:*.dev.purebliss.app,IP:98.116.198.97,IP:192.168.168.30"
  chmod 644 "$cert_dir/fullchain.pem"
  chmod 600 "$cert_dir/privkey.pem"
  echo "[$(date)] INFO: Self-signed SSL certificate generated successfully." | tee -a "$LOG_FILE"
}

# Function to check if Let's Encrypt certificate exists
check_letsencrypt_cert() {
  local letsencrypt_cert_dir=""
  for cert_dir in "${NGINX_SSL_CERT_PATH}/live/dev.purebliss.app-0001" "${NGINX_SSL_CERT_PATH}/live/dev.purebliss.app"; do
    if [ -f "$cert_dir/fullchain.pem" ] && [ -f "$cert_dir/privkey.pem" ]; then
      letsencrypt_cert_dir="$cert_dir"
      break
    fi
  done
  echo "$letsencrypt_cert_dir"
}

# Function to setup Let's Encrypt certificate using two-phase approach
setup_letsencrypt_cert() {
  echo "[$(date)] INFO: Setting up Let's Encrypt certificate..." | tee -a "$LOG_FILE"

  # Check if Let's Encrypt certificate already exists
  local existing_cert=$(check_letsencrypt_cert)
  if [ -n "$existing_cert" ]; then
    echo "[$(date)] INFO: Let's Encrypt certificate already exists at $existing_cert." | tee -a "$LOG_FILE"
    return 0
  fi

  echo "[$(date)] INFO: No Let's Encrypt certificate found. Starting two-phase certificate acquisition..." | tee -a "$LOG_FILE"

  # Phase 1: Start simple Nginx for ACME challenges
  echo "[$(date)] INFO: Phase 1: Starting simple Nginx for ACME challenges..." | tee -a "$LOG_FILE"
  cd /opt/dev-purebliss/services/nginx

  # Stop any existing nginx containers
  docker-compose -f nginx-docker-compose.yml --env-file "$CONFIG_ENV_PATH" down 2>/dev/null || true
  docker stop purebliss-nginx-simple 2>/dev/null || true
  docker rm purebliss-nginx-simple 2>/dev/null || true

  # Build and start simple nginx
  docker build -f nginx-simple-dockerfile -t purebliss-nginx-simple . 2>/dev/null || true
  docker-compose -f nginx-simple-docker-compose.yml --env-file "$CONFIG_ENV_PATH" up -d 2>/dev/null || true

  # Wait for simple Nginx to be ready
  for i in {1..30}; do
    if curl -s http://localhost/ >/dev/null 2>&1; then
      echo "[$(date)] INFO: Simple Nginx is ready for ACME challenges." | tee -a "$LOG_FILE"
      break
    fi
    echo "[$(date)] INFO: Waiting for simple Nginx to be ready... ($i/30)" | tee -a "$LOG_FILE"
    sleep 2
  done

  # Start Let's Encrypt container
  echo "[$(date)] INFO: Starting Let's Encrypt container..." | tee -a "$LOG_FILE"
  cd /opt/dev-purebliss/services/letsencrypt
  docker-compose -f letsencrypt-docker-compose.yml --env-file "$CONFIG_ENV_PATH" up -d 2>/dev/null || true

  # Wait for Let's Encrypt container to be ready
  for i in {1..30}; do
    if docker ps --format '{{.Names}}' | grep -q "purebliss-letsencrypt"; then
      echo "[$(date)] INFO: Let's Encrypt container is ready." | tee -a "$LOG_FILE"
      break
    fi
    echo "[$(date)] INFO: Waiting for Let's Encrypt container... ($i/30)" | tee -a "$LOG_FILE"
    sleep 2
  done

  # Generate Let's Encrypt certificate
  echo "[$(date)] INFO: Generating Let's Encrypt certificate..." | tee -a "$LOG_FILE"
  docker exec purebliss-letsencrypt certbot certonly --webroot --webroot-path=/var/www/html \
    --email admin@purebliss.app --agree-tos --no-eff-email --domains dev.purebliss.app \
    --non-interactive 2>&1 | tee -a "$LOG_FILE"

  # Check if certificate was generated successfully
  local new_cert=$(check_letsencrypt_cert)
  if [ -n "$new_cert" ]; then
    echo "[$(date)] INFO: Let's Encrypt certificate generated successfully at $new_cert." | tee -a "$LOG_FILE"

        # Phase 2: Stop simple nginx and start full nginx with Let's Encrypt certificate
    echo "[$(date)] INFO: Phase 2: Stopping simple Nginx and starting full Nginx..." | tee -a "$LOG_FILE"
    cd /opt/dev-purebliss/services/nginx

    # Stop simple nginx
    docker-compose -f nginx-simple-docker-compose.yml --env-file "$CONFIG_ENV_PATH" down 2>/dev/null || true

    # Update main nginx config to use Let's Encrypt certificate
    # Convert host path to container path
    container_cert_path=$(echo "$new_cert" | sed 's|/mnt/raid0/nginx/certs/|/etc/nginx/certs/|g')
    sed -i "s|ssl_certificate /etc/nginx/certs/dev.purebliss.app/fullchain.pem;|ssl_certificate $container_cert_path/fullchain.pem;|g" nginx.conf
    sed -i "s|ssl_certificate_key /etc/nginx/certs/dev.purebliss.app/privkey.pem;|ssl_certificate_key $container_cert_path/privkey.pem;|g" nginx.conf

    # Build and start full nginx
    docker build -f nginx-dockerfile -t purebliss-nginx . 2>/dev/null || true
    docker-compose -f nginx-docker-compose.yml --env-file "$CONFIG_ENV_PATH" up -d 2>/dev/null || true

    echo "[$(date)] INFO: Full Nginx started with Let's Encrypt certificate." | tee -a "$LOG_FILE"
    return 0
  else
    echo "[$(date)] WARNING: Let's Encrypt certificate generation failed." | tee -a "$LOG_FILE"
    return 1
  fi
}

# Generate self-signed certificate first as fallback
echo "[$(date)] INFO: Generating self-signed certificate as fallback..." | tee -a "$LOG_FILE"
generate_self_signed_cert

# Try Let's Encrypt, but keep self-signed as fallback
if ! setup_letsencrypt_cert; then
  echo "[$(date)] INFO: Let's Encrypt failed, using self-signed certificate." | tee -a "$LOG_FILE"
fi

# Ensure Nginx configuration is properly set up for the final certificate
echo "[$(date)] INFO: Finalizing Nginx SSL configuration..." | tee -a "$LOG_FILE"
cd /opt/dev-purebliss/services/nginx

# Determine which certificate to use
letsencrypt_cert_path=$(check_letsencrypt_cert)

if [ -n "$letsencrypt_cert_path" ]; then
  # Use Let's Encrypt certificate
  echo "[$(date)] INFO: Configuring Nginx to use Let's Encrypt certificate at $letsencrypt_cert_path..." | tee -a "$LOG_FILE"
  # Update the certificate paths in nginx.conf (convert host path to container path)
  container_cert_path=$(echo "$letsencrypt_cert_path" | sed 's|/mnt/raid0/nginx/certs/|/etc/nginx/certs/|g')
  sed -i "s|ssl_certificate /etc/nginx/certs/dev.purebliss.app/fullchain.pem;|ssl_certificate $container_cert_path/fullchain.pem;|g" nginx.conf
  sed -i "s|ssl_certificate_key /etc/nginx/certs/dev.purebliss.app/privkey.pem;|ssl_certificate_key $container_cert_path/privkey.pem;|g" nginx.conf
else
  # Use self-signed certificate (already configured by default)
  echo "[$(date)] INFO: Using self-signed certificate (already configured)." | tee -a "$LOG_FILE"
fi

# Build Nginx with final configuration
docker build -f nginx-dockerfile -t purebliss-nginx . 2>/dev/null || true

# Ensure nginx is running with the final configuration
if ! docker ps --format '{{.Names}}' | grep -q "purebliss-nginx"; then
  echo "[$(date)] INFO: Starting nginx with final configuration..." | tee -a "$LOG_FILE"
  cd /opt/dev-purebliss/services/nginx
  docker-compose -f nginx-docker-compose.yml --env-file "$CONFIG_ENV_PATH" up -d 2>/dev/null || true
fi

# Wait for nginx to be healthy after SSL setup
if docker ps --format '{{.Names}}' | grep -q "purebliss-nginx"; then
  for i in {1..30}; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' purebliss-nginx 2>/dev/null || echo "notfound")
    if [[ "$STATUS" == "healthy" ]]; then
      echo "[$(date)] INFO: Nginx is healthy after SSL setup." | tee -a "$LOG_FILE"
      break
    fi
    echo "[$(date)] INFO: Waiting for nginx to become healthy after SSL setup... ($i/30)" | tee -a "$LOG_FILE"
    sleep 4
  done
  if [[ "$STATUS" != "healthy" ]]; then
    echo "[$(date)] ERROR: Nginx did not become healthy after SSL setup." | tee -a "$LOG_FILE"
    exit 1
  fi
fi

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
        echo -e "FROM prom/prometheus:v2.48.1" > "$DOCKERFILE_PATH" ;;
      plane)
        echo -e "FROM makeplane/plane-space:latest" > "$DOCKERFILE_PATH" ;;
      codeserver)
        echo -e "FROM codercom/code-server:4.20.0" > "$DOCKERFILE_PATH" ;;
    esac
    echo "[$(date)] INFO: Generated $DOCKERFILE_PATH" | tee -a "$LOG_FILE"
  fi
done

# Start Nginx and Let's Encrypt first (build then up)
# Note: These might already be running from SSL setup
for svc in nginx letsencrypt; do
  if [ -d "$BASE/$svc" ]; then
    COMPOSE_VAR="$(echo ${svc^^}_DOCKER_COMPOSE_FILE | tr '-' '_')"
    COMPOSE_FILE="${!COMPOSE_VAR:-docker-compose.yml}"

    # Check if service is already running
    if docker ps --format '{{.Names}}' | grep -q "purebliss-$svc"; then
      echo "[$(date)] INFO: $svc is already running, skipping startup." | tee -a "$LOG_FILE"
      continue
    fi

    # For nginx, check if we need to use simple config for certificate acquisition
    if [ "$svc" = "nginx" ]; then
      local cert_exists=$(check_letsencrypt_cert)
      if [ -z "$cert_exists" ]; then
        echo "[$(date)] INFO: No Let's Encrypt certificate found, nginx will be started with simple config during SSL setup." | tee -a "$LOG_FILE"
        continue
      fi
    fi

    echo "[$(date)] INFO: Building $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose  --env-file "$CONFIG_ENV_PATH" -f "$COMPOSE_FILE" build) || {
      echo "[$(date)] ERROR: Failed to build $svc" | tee -a "$LOG_FILE"; exit 1;
    }
    echo "[$(date)] INFO: Starting $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$COMPOSE_FILE" up -d) || {
      echo "[$(date)] ERROR: Failed to start $svc" | tee -a "$LOG_FILE"; exit 1;
    }
  else
    echo "[$(date)] WARNING: $BASE/$svc directory not found, skipping." | tee -a "$LOG_FILE"
  fi
done

# Wait for Nginx and Let's Encrypt to be healthy before starting Vault
for svc in nginx letsencrypt; do
  # Skip nginx health check if it's not running (will be started during SSL setup)
  if [ "$svc" = "nginx" ] && ! docker ps --format '{{.Names}}' | grep -q "purebliss-nginx"; then
    echo "[$(date)] INFO: Skipping nginx health check (will be started during SSL setup)." | tee -a "$LOG_FILE"
    continue
  fi

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
    (cd "$BASE/$svc" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$COMPOSE_FILE" build) || {
      echo "[$(date)] ERROR: Failed to build $svc" | tee -a "$LOG_FILE"; exit 1;
    }
    echo "[$(date)] INFO: Starting $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$COMPOSE_FILE" up -d) || {
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
    # Execute vault-secrets.sh from host with correct Vault address and token
    VAULT_ADDR=http://localhost:8200 VAULT_TOKEN="$VAULT_DEV_ROOT_TOKEN" sudo /opt/dev-purebliss/dev_scripts/vault-secrets.sh "$svc" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: vault-secrets.sh not found or not executable, skipping $svc secret upload." | tee -a "$LOG_FILE"
  fi
done
# Restart Vault Agent to render new templates
if docker ps -q -f name=purebliss-vault-agent; then
  echo "[$(date)] INFO: Restarting Vault Agent to render latest secrets/templates..." | tee -a "$LOG_FILE"
  docker restart purebliss-vault-agent | tee -a "$LOG_FILE"
fi
# Ensure Plane AppRole credentials are provisioned before starting Plane
/opt/dev_scripts/plane-approle.sh | tee -a "$LOG_FILE"

# Start remaining services (build then up)
for svc in redis postgres keycloak grafana loki prometheus plane codeserver; do
  if [ -d "$BASE/$svc" ]; then
    COMPOSE_VAR="$(echo ${svc^^}_DOCKER_COMPOSE_FILE | tr '-' '_')"
    COMPOSE_FILE="${!COMPOSE_VAR:-docker-compose.yml}"
    echo "[$(date)] INFO: Building $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$COMPOSE_FILE" build) || {
      echo "[$(date)] ERROR: Failed to build $svc" | tee -a "$LOG_FILE"; exit 1;
    }
    echo "[$(date)] INFO: Starting $svc..." | tee -a "$LOG_FILE"
    (cd "$BASE/$svc" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$COMPOSE_FILE" up -d) || {
      echo "[$(date)] ERROR: Failed to start $svc" | tee -a "$LOG_FILE"; exit 1;
    }
  else
    echo "[$(date)] WARNING: $BASE/$svc directory not found, skipping." | tee -a "$LOG_FILE"
  fi
done

echo "[$(date)] INFO: All core services started. Checking status..." | tee -a "$LOG_FILE"
docker ps --format 'table {{.Names}}\t{{.Status}}' | tee -a "$LOG_FILE"

# Verify SSL setup
echo "[$(date)] INFO: Verifying SSL setup..." | tee -a "$LOG_FILE"
ssl_cert_found=false
for cert_path in "${NGINX_SSL_CERT_PATH}/live/dev.purebliss.app-0001" "${NGINX_SSL_CERT_PATH}/live/dev.purebliss.app"; do
  if [ -f "$cert_path/fullchain.pem" ]; then
    echo "[$(date)] INFO: ✅ Let's Encrypt SSL certificate is active at $cert_path" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: 🌐 Access your services at: https://dev.purebliss.app/" | tee -a "$LOG_FILE"
    ssl_cert_found=true
    break
  fi
done

if [ "$ssl_cert_found" = false ]; then
  if [ -f "${NGINX_SSL_CERT_PATH}/dev.purebliss.app/fullchain.pem" ]; then
    echo "[$(date)] INFO: ⚠️  Self-signed SSL certificate is active (browser will show warning)" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: 🌐 Access your services at: https://dev.purebliss.app/ (accept certificate warning)" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: No SSL certificate found!" | tee -a "$LOG_FILE"
  fi
fi

echo "[$(date)] INFO: Pure Bliss stack startup complete." | tee -a "$LOG_FILE"
