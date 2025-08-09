#!/bin/bash
set -euo pipefail

# Service-specific user IDs for permission management:
# - Grafana: 472:472
# - Prometheus: 0:0 (root)
# - Loki: 0:0 (root)

CONFIG_ENV_PATH="/opt/my-secure-ha-stack/config.env"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
UNSEAL_FILE="/opt/my-secure-ha-stack/vault-unseal-keys.env"
BASE="/opt/dev-purebliss/services"

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
    if curl -sk http://localhost/ >/dev/null 2>&1; then
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
echo "[$(date)] INFO: Starting sequential startup for all Pure Bliss core services" | tee -a "$LOG_FILE"

# Function definitions will be loaded first, then called at the end
# ============================================================================
# VAULT COMPREHENSIVE ONBOARDING FUNCTIONS
# ============================================================================

function vault_setup_environment() {
    echo "[$(date)] INFO: Setting up Vault environment variables..." | tee -a "$LOG_FILE"

    # Detect Vault mode and set appropriate environment
    if docker exec purebliss-vault vault status 2>/dev/null | grep -q "Storage Type.*file"; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_TOKEN="dev-root-token-purebliss"
        echo "[$(date)] INFO: Vault detected in dev mode (HTTP)" | tee -a "$LOG_FILE"
    else
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN="$VAULT_DEV_ROOT_TOKEN"
        echo "[$(date)] INFO: Vault detected in production mode (HTTPS)" | tee -a "$LOG_FILE"
    fi
}

function vault_onboard_postgres() {
    echo "[$(date)] INFO: Onboarding PostgreSQL with Vault..." | tee -a "$LOG_FILE"

    # Enable database secrets engine
    docker exec purebliss-vault vault secrets enable -path=database database 2>/dev/null || true

    # Configure PostgreSQL connection
    docker exec purebliss-vault vault write database/config/postgres-app \
        plugin_name=postgresql-database-plugin \
        allowed_roles="postgres-role" \
        connection_url="postgresql://{{username}}:{{password}}@purebliss-postgres:5432/postgres?sslmode=disable" \
        username="postgres" \
        password="postgres" 2>&1 | tee -a "$LOG_FILE" || true

    # Create PostgreSQL role for dynamic credentials
    docker exec purebliss-vault vault write database/roles/postgres-role \
        db_name=postgres-app \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
        default_ttl="1h" \
        max_ttl="24h" 2>&1 | tee -a "$LOG_FILE" || true

    # Create PostgreSQL policy
    docker exec purebliss-vault vault policy write postgres-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "database/creds/postgres-role" {
  capabilities = ["read"]
}
path "secret/data/postgres" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: PostgreSQL Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_redis() {
    echo "[$(date)] INFO: Onboarding Redis with Vault..." | tee -a "$LOG_FILE"

    # Store Redis credentials in KV store
    docker exec purebliss-vault vault kv put secret/redis \
        host="purebliss-redis" \
        port="6379" \
        password="" \
        database="0" 2>&1 | tee -a "$LOG_FILE" || true

    # Create Redis policy
    docker exec purebliss-vault vault policy write redis-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/redis" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: Redis Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_keycloak() {
    echo "[$(date)] INFO: Onboarding Keycloak with Vault..." | tee -a "$LOG_FILE"

    # Store Keycloak credentials in KV store
    docker exec purebliss-vault vault kv put secret/keycloak \
        admin_user="admin" \
        admin_password="admin123" \
        db_host="purebliss-postgres" \
        db_port="5432" \
        db_name="keycloak" \
        db_user="keycloak" \
        db_password="keycloak" 2>&1 | tee -a "$LOG_FILE" || true

    # Create Keycloak policy
    docker exec purebliss-vault vault policy write keycloak-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/keycloak" {
  capabilities = ["read"]
}
path "database/creds/postgres-role" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: Keycloak Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_nginx() {
    echo "[$(date)] INFO: Onboarding Nginx with Vault PKI..." | tee -a "$LOG_FILE"

    # Enable PKI secrets engine for Nginx
    docker exec purebliss-vault vault secrets enable -path=pki-nginx pki 2>/dev/null || true

    # Configure PKI root CA
    docker exec purebliss-vault vault write pki-nginx/root/generate/internal \
        common_name="Pure Bliss Internal CA" \
        issuer_name="purebliss-ca" \
        ttl=8760h 2>&1 | tee -a "$LOG_FILE" || true

    # Configure PKI URLs
    docker exec purebliss-vault vault write pki-nginx/config/urls \
        issuing_certificates="https://127.0.0.1:8200/v1/pki-nginx/ca" \
        crl_distribution_points="https://127.0.0.1:8200/v1/pki-nginx/crl" 2>&1 | tee -a "$LOG_FILE" || true

    # Create nginx role for certificate generation
    docker exec purebliss-vault vault write pki-nginx/roles/nginx \
        allowed_domains="dev.purebliss.app,*.dev.purebliss.app" \
        allow_subdomains=true \
        max_ttl="72h" \
        key_bits=2048 2>&1 | tee -a "$LOG_FILE" || true

    # Create Nginx policy
    docker exec purebliss-vault vault policy write nginx-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "pki-nginx/*" {
  capabilities = ["read", "list"]
}
path "pki-nginx/issue/nginx" {
  capabilities = ["create", "update"]
}
path "secret/data/nginx" {
  capabilities = ["read"]
}
EOF

    # Store existing Nginx certificates in Vault for backup
    if [ -x /opt/dev-purebliss/dev_scripts/vault-secrets.sh ]; then
        echo "[$(date)] INFO: Uploading existing nginx certs to Vault..." | tee -a "$LOG_FILE"
        VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$VAULT_TOKEN" /opt/dev-purebliss/dev_scripts/vault-secrets.sh nginx 2>&1 | tee -a "$LOG_FILE" || true
    fi

    echo "[$(date)] INFO: Nginx Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_letsencrypt() {
    echo "[$(date)] INFO: Onboarding Let's Encrypt with Vault..." | tee -a "$LOG_FILE"

    # Store Let's Encrypt credentials and config
    docker exec purebliss-vault vault kv put secret/letsencrypt \
        email="admin@purebliss.app" \
        domain="dev.purebliss.app" \
        webroot_path="/var/www/html" \
        staging="false" 2>&1 | tee -a "$LOG_FILE" || true

    # Create Let's Encrypt policy
    docker exec purebliss-vault vault policy write letsencrypt-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/letsencrypt" {
  capabilities = ["read"]
}
EOF

    # Store existing Let's Encrypt certificates if available
    if [ -x /opt/dev-purebliss/dev_scripts/vault-secrets.sh ]; then
        echo "[$(date)] INFO: Uploading existing letsencrypt certs to Vault..." | tee -a "$LOG_FILE"
        VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$VAULT_TOKEN" /opt/dev-purebliss/dev_scripts/vault-secrets.sh letsencrypt 2>&1 | tee -a "$LOG_FILE" || true
    fi

    echo "[$(date)] INFO: Let's Encrypt Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_prometheus() {
    echo "[$(date)] INFO: Onboarding Prometheus with Vault..." | tee -a "$LOG_FILE"

    # Store Prometheus configuration
    docker exec purebliss-vault vault kv put secret/prometheus \
        retention="15d" \
        scrape_interval="15s" \
        evaluation_interval="15s" \
        external_url="https://dev.purebliss.app/prometheus" \
        web_route_prefix="/prometheus" 2>&1 | tee -a "$LOG_FILE" || true

    # Create Prometheus policy
    docker exec purebliss-vault vault policy write prometheus-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/prometheus" {
  capabilities = ["read"]
}
path "sys/health" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: Prometheus Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_loki() {
    echo "[$(date)] INFO: Onboarding Loki with Vault..." | tee -a "$LOG_FILE"

    # Store Loki configuration
    docker exec purebliss-vault vault kv put secret/loki \
        retention_period="168h" \
        compactor_working_directory="/tmp/loki/compactor" \
        ingester_lifecycler_ring_kvstore_store="inmemory" 2>&1 | tee -a "$LOG_FILE" || true

    # Create Loki policy
    docker exec purebliss-vault vault policy write loki-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/loki" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: Loki Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_grafana() {
    echo "[$(date)] INFO: Onboarding Grafana with Vault..." | tee -a "$LOG_FILE"

    # Store Grafana credentials and configuration
    docker exec purebliss-vault vault kv put secret/grafana \
        admin_user="admin" \
        admin_password="admin123" \
        secret_key="$(openssl rand -base64 32)" \
        database_type="sqlite3" \
        prometheus_url="http://purebliss-prometheus:9090" \
        loki_url="http://purebliss-loki:3100" 2>&1 | tee -a "$LOG_FILE" || true

    # Create Grafana policy
    docker exec purebliss-vault vault policy write grafana-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/grafana" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: Grafana Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_plane() {
    echo "[$(date)] INFO: Onboarding Plane with Vault..." | tee -a "$LOG_FILE"

    # Store Plane configuration
    docker exec purebliss-vault vault kv put secret/plane \
        secret_key="$(openssl rand -base64 32)" \
        database_url="postgresql://plane:plane@purebliss-postgres:5432/plane" \
        redis_url="redis://purebliss-redis:6379/0" \
        web_url="https://dev.purebliss.app/plane" 2>&1 | tee -a "$LOG_FILE" || true

    # Create Plane policy
    docker exec purebliss-vault vault policy write plane-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/plane" {
  capabilities = ["read"]
}
path "database/creds/postgres-role" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: Plane Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_onboard_codeserver() {
    echo "[$(date)] INFO: Onboarding CodeServer with Vault..." | tee -a "$LOG_FILE"

    # Store CodeServer configuration
    docker exec purebliss-vault vault kv put secret/codeserver \
        password="$(openssl rand -base64 16)" \
        auth="password" \
        cert="false" \
        bind_addr="0.0.0.0:8080" \
        proxy_domain="dev.purebliss.app" 2>&1 | tee -a "$LOG_FILE" || true

    # Create CodeServer policy
    docker exec purebliss-vault vault policy write codeserver-policy - <<EOF 2>&1 | tee -a "$LOG_FILE" || true
path "secret/data/codeserver" {
  capabilities = ["read"]
}
EOF

    echo "[$(date)] INFO: CodeServer Vault onboarding completed" | tee -a "$LOG_FILE"
}

function vault_enable_audit_logging() {
    echo "[$(date)] INFO: Enabling Vault audit logging..." | tee -a "$LOG_FILE"

    # Create audit log directory if it doesn't exist
    mkdir -p /opt/my-secure-ha-stack/logs

    # Enable audit logging (file backend)
    docker exec purebliss-vault vault audit enable file \
        file_path=/vault/logs/audit.log 2>&1 | tee -a "$LOG_FILE" || true

    echo "[$(date)] INFO: Vault audit logging enabled" | tee -a "$LOG_FILE"
}

function vault_create_service_tokens() {
    echo "[$(date)] INFO: Creating service-specific Vault tokens..." | tee -a "$LOG_FILE"

    # Create tokens for each service with appropriate policies
    local services=("postgres" "redis" "keycloak" "nginx" "letsencrypt" "prometheus" "loki" "grafana" "plane" "codeserver")

    for service in "${services[@]}"; do
        echo "[$(date)] INFO: Creating token for $service..." | tee -a "$LOG_FILE"
        token=$(docker exec purebliss-vault vault write -field=token auth/token/create \
            policies="$service-policy" \
            ttl="24h" \
            renewable="true" 2>/dev/null || echo "")

        if [[ -n "$token" ]]; then
            # Store token in a secure location for the service to use
            echo "$token" > "/opt/my-secure-ha-stack/secrets/${service}_vault_token"
            chmod 600 "/opt/my-secure-ha-stack/secrets/${service}_vault_token"
            echo "[$(date)] INFO: Token created for $service" | tee -a "$LOG_FILE"
        else
            echo "[$(date)] WARNING: Failed to create token for $service" | tee -a "$LOG_FILE"
        fi
    done
}

function start_all_services_sequential() {
    echo "[$(date)] INFO: 🎯 Starting all services in strict sequential order with health validation..." | tee -a "$LOG_FILE"

    # Define the strict service order - vault-agent is included with vault startup
    local SERVICE_ORDER=(
        "vault"
        "postgres"
        "redis"
        "keycloak"
        "letsencrypt"
        "nginx"
        "prometheus"
        "loki"
        "grafana"
    )

    local failed_services=()

    for service in "${SERVICE_ORDER[@]}"; do
        echo "[$(date)] INFO: ===============================================" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: 🎯 Processing service: $service" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: ===============================================" | tee -a "$LOG_FILE"

        # Check if service is already running and healthy
        if docker ps --format '{{.Names}}' | grep -q "purebliss-$service"; then
            local current_health
            current_health=$(docker inspect --format='{{.State.Health.Status}}' "purebliss-$service" 2>/dev/null || echo "no_healthcheck")
            local current_status
            current_status=$(docker inspect --format='{{.State.Status}}' "purebliss-$service" 2>/dev/null || echo "unknown")

            if [[ "$current_health" == "healthy" ]] || [[ "$current_health" == "no_healthcheck" && "$current_status" == "running" ]]; then
                echo "[$(date)] INFO: ✅ $service is already running and healthy, skipping startup" | tee -a "$LOG_FILE"
                continue
            else
                echo "[$(date)] INFO: ⚠️  $service is running but not healthy ($current_health/$current_status), restarting..." | tee -a "$LOG_FILE"
                docker stop "purebliss-$service" 2>/dev/null || true
                docker rm "purebliss-$service" 2>/dev/null || true
            fi
        fi

        # Determine compose file
        local compose_var="$(echo ${service^^}_DOCKER_COMPOSE_FILE | tr '-' '_')"
        local compose_file="${!compose_var:-docker-compose.yml}"

        # Start the service
        if start_service_sequential "$service" "$compose_file"; then
            echo "[$(date)] INFO: ✅ $service started successfully and is healthy" | tee -a "$LOG_FILE"

            # Special handling for Vault initialization and onboarding (only after first vault startup)
            if [[ "$service" == "vault" ]]; then
                echo "[$(date)] INFO: 🔐 Performing Vault initialization and onboarding..." | tee -a "$LOG_FILE"
                vault_initialize_and_unseal

                # Validate vault-agent health (since it starts with vault)
                echo "[$(date)] INFO: 🔍 Validating vault-agent health..." | tee -a "$LOG_FILE"
                wait_for_service_health "purebliss-vault-agent" 60 || {
                    echo "[$(date)] ERROR: vault-agent failed health check" | tee -a "$LOG_FILE"
                    return 1
                }
                echo "[$(date)] INFO: ✅ vault-agent is healthy" | tee -a "$LOG_FILE"

                vault_comprehensive_onboarding
            fi

        else
            echo "[$(date)] ERROR: ❌ $service failed to start or become healthy" | tee -a "$LOG_FILE"
            failed_services+=("$service")

            # Show logs for debugging
            echo "[$(date)] INFO: 📋 Last 20 lines of $service logs:" | tee -a "$LOG_FILE"
            docker logs "purebliss-$service" --tail 20 2>&1 | tee -a "$LOG_FILE" || true

            # Decide whether to continue or fail - ALL services are critical for proper testing
            echo "[$(date)] ERROR: 🛑 Service $service failed, stopping startup for debugging" | tee -a "$LOG_FILE"
            return 1
        fi

        echo ""
    done

    # Final status report
    echo "[$(date)] INFO: ===============================================" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: 📊 SEQUENTIAL STARTUP SUMMARY" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: ===============================================" | tee -a "$LOG_FILE"

    if [ ${#failed_services[@]} -eq 0 ]; then
        echo "[$(date)] INFO: 🎉 ALL SERVICES STARTED SUCCESSFULLY!" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: ❌ Failed services: ${failed_services[*]}" | tee -a "$LOG_FILE"
        return 1
    fi
}

function vault_comprehensive_onboarding() {
    echo "[$(date)] INFO: Starting comprehensive Vault onboarding..." | tee -a "$LOG_FILE"

    # Ensure secrets directory exists
    mkdir -p /opt/my-secure-ha-stack/secrets
    chmod 700 /opt/my-secure-ha-stack/secrets

    # Setup Vault environment
    vault_setup_environment

    # Wait for Vault to be fully ready
    for i in {1..30}; do
        if docker exec purebliss-vault vault status >/dev/null 2>&1; then
            echo "[$(date)] INFO: Vault is ready for onboarding" | tee -a "$LOG_FILE"
            break
        fi
        echo "[$(date)] INFO: Waiting for Vault to be ready... ($i/30)" | tee -a "$LOG_FILE"
        sleep 2
    done

    # Enable audit logging first
    vault_enable_audit_logging

    # Onboard all services
    vault_onboard_postgres
    vault_onboard_redis
    vault_onboard_keycloak
    vault_onboard_nginx
    vault_onboard_letsencrypt
    vault_onboard_prometheus
    vault_onboard_loki
    vault_onboard_grafana
    vault_onboard_plane
    vault_onboard_codeserver

    # Create service tokens
    vault_create_service_tokens

    echo "[$(date)] INFO: Comprehensive Vault onboarding completed" | tee -a "$LOG_FILE"
}

# ============================================================================
# STARTUP HELPER FUNCTIONS
# ============================================================================

function wait_for_service_health() {
    local service_name="$1"
    local timeout="${2:-60}"
    local counter=0

    echo "[$(date)] INFO: Waiting for $service_name to become healthy..." | tee -a "$LOG_FILE"

    while [ $counter -lt $timeout ]; do
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "no_healthcheck")
        local container_status
        container_status=$(docker inspect --format='{{.State.Status}}' "$service_name" 2>/dev/null || echo "unknown")

        case "$health_status" in
            "healthy")
                echo "[$(date)] INFO: ✅ $service_name is healthy" | tee -a "$LOG_FILE"
                return 0
                ;;
            "no_healthcheck")
                if [[ "$container_status" == "running" ]]; then
                    echo "[$(date)] INFO: ✅ $service_name is running (no health check defined)" | tee -a "$LOG_FILE"
                    return 0
                fi
                ;;
            "starting"|"unhealthy")
                echo "[$(date)] INFO: ⏳ $service_name status: $health_status ($container_status) - waiting... ($counter/$timeout)" | tee -a "$LOG_FILE"
                ;;
            *)
                echo "[$(date)] WARNING: $service_name status: $health_status ($container_status)" | tee -a "$LOG_FILE"
                ;;
        esac

        sleep 2
        ((counter += 2))
    done

    echo "[$(date)] ERROR: ❌ $service_name did not become healthy within $timeout seconds" | tee -a "$LOG_FILE"
    return 1
}

function start_service_sequential() {
    local service="$1"
    local compose_file="${2:-docker-compose.yml}"
    local service_dir="$BASE/$service"

    # Handle vault-agent specially (it's part of vault's compose file)
    if [ "$service" = "vault-agent" ]; then
        service_dir="$BASE/vault"
        compose_file="vault-docker-compose.yml"
        echo "[$(date)] INFO: 🚀 Starting $service (using vault compose file)..." | tee -a "$LOG_FILE"

        # Check if vault-agent container already exists and is running
        if docker ps -q -f name=purebliss-vault-agent | grep -q .; then
            echo "[$(date)] INFO: vault-agent container already running, checking health..." | tee -a "$LOG_FILE"
            # Wait for health check
            wait_for_service_health "purebliss-$service" 60 || {
                echo "[$(date)] ERROR: $service failed health check" | tee -a "$LOG_FILE"
                return 1
            }
            return 0
        fi

        # If vault-agent exists but stopped, start the specific service
        if docker ps -aq -f name=purebliss-vault-agent | grep -q .; then
            echo "[$(date)] INFO: Starting existing vault-agent container..." | tee -a "$LOG_FILE"
            docker start purebliss-vault-agent || {
                echo "[$(date)] ERROR: Failed to start existing vault-agent container" | tee -a "$LOG_FILE"
                return 1
            }
            wait_for_service_health "purebliss-$service" 60 || {
                echo "[$(date)] ERROR: $service failed health check" | tee -a "$LOG_FILE"
                return 1
            }
            return 0
        fi

        # If neither container exists, this should not happen in our workflow
        echo "[$(date)] ERROR: vault-agent should be created when vault starts" | tee -a "$LOG_FILE"
        return 1
    fi

    if [ ! -d "$service_dir" ]; then
        echo "[$(date)] WARNING: $service_dir directory not found, skipping $service" | tee -a "$LOG_FILE"
        return 1
    fi

    echo "[$(date)] INFO: 🚀 Starting $service..." | tee -a "$LOG_FILE"

    # Determine the correct compose file for vault
    if [ "$service" = "vault" ]; then
        compose_file="vault-docker-compose.yml"
    fi

    # Build the service(s)
    echo "[$(date)] INFO: Building $service..." | tee -a "$LOG_FILE"
    (cd "$service_dir" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$compose_file" build) || {
        echo "[$(date)] ERROR: Failed to build $service" | tee -a "$LOG_FILE"
        return 1
    }

    # Start the service(s) - for vault this starts both vault and vault-agent
    echo "[$(date)] INFO: Starting $service..." | tee -a "$LOG_FILE"
    if ! (cd "$service_dir" && docker-compose --env-file "$CONFIG_ENV_PATH" -f "$compose_file" up -d) 2>/dev/null; then
        echo "[$(date)] WARNING: Docker Compose startup had issues, checking if containers are already running..." | tee -a "$LOG_FILE"
        # Check if the main service container is running
        if docker ps -q -f name=purebliss-$service | grep -q .; then
            echo "[$(date)] INFO: $service container already running, proceeding with health check..." | tee -a "$LOG_FILE"
        else
            echo "[$(date)] ERROR: Failed to start $service and container is not running" | tee -a "$LOG_FILE"
            return 1
        fi
    fi

    # Wait for health check
    wait_for_service_health "purebliss-$service" 60 || {
        echo "[$(date)] ERROR: $service failed health check" | tee -a "$LOG_FILE"
        return 1
    }

    return 0
}



function vault_initialize_and_unseal() {
    echo "[$(date)] INFO: 🔐 Initializing and unsealing Vault..." | tee -a "$LOG_FILE"

    # Initialize Vault if needed and write unseal keys/root token
    if ! docker exec purebliss-vault vault status | grep -q 'Initialized.*true'; then
        echo "[$(date)] INFO: Initializing Vault..." | tee -a "$LOG_FILE"
        INIT_OUTPUT=$(docker exec purebliss-vault vault operator init -key-shares=3 -key-threshold=2 -format=json)
        VAULT_DEV_UNSEAL_KEY_1=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
        VAULT_DEV_UNSEAL_KEY_2=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[1]')
        VAULT_DEV_UNSEAL_KEY_3=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[2]')
        VAULT_DEV_ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
    else
        echo "[$(date)] INFO: Vault already initialized. Loading unseal keys/root token from $UNSEAL_FILE if present..." | tee -a "$LOG_FILE"
        if [ -f "$UNSEAL_FILE" ]; then
            set -a
            . "$UNSEAL_FILE"
            set +a
        fi
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

    echo "[$(date)] INFO: ✅ Vault initialization and unsealing completed" | tee -a "$LOG_FILE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "[$(date)] INFO: All core services started. Checking final status..." | tee -a "$LOG_FILE"
docker ps --format 'table {{.Names}}\t{{.Status}}' | tee -a "$LOG_FILE"

# Run comprehensive health check at the end
if [ -x /opt/comprehensive-health-check.sh ]; then
    echo "[$(date)] INFO: 🔍 Running comprehensive health check..." | tee -a "$LOG_FILE"
    /opt/comprehensive-health-check.sh | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: comprehensive-health-check.sh not found, skipping final health check" | tee -a "$LOG_FILE"
fi

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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Use sequential startup with health validation
start_all_services_sequential || {
    echo "[$(date)] ERROR: 🛑 Sequential startup failed" | tee -a "$LOG_FILE"
    exit 1
}
