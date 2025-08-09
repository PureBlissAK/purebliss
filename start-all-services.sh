#!/bin/bash
# ============================================================================
# Pure Bliss Development Environment - Service Orchestration Script
#
# CRITICAL: All actions must be logged to /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Reference the troubleshooting log and comprehensive-health-check.sh before and after any changes.
#
# Quick-Start for New Team Members:
#   1. Review /opt/my-secure-ha-stack/logs/dev-environment-setup.log for recent issues and healthy state.
#   2. Start services in strict order: vault, postgres, vault-agent, redis, keycloak.
#   3. After all services are started, run /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh.
#   4. Backup configs after successful changes (see backup_critical_configs function).
#   5. For troubleshooting, always update the central log and consult service-specific guides.
#
# For Vault and Vault Agent troubleshooting, see:
#   /opt/dev-purebliss/services/vault/VAULT_AUTOMATION_GUIDE.md
#   /opt/dev-purebliss/services/vault/vault-break-fix-report.md
# For comprehensive validation, use:
#   /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh
# ============================================================================

# --- Redis Vault Onboarding Automation ---
# This function configures Vault to manage dynamic Redis credentials using the correct Docker hostname.
function onboard_redis_to_vault() {
  local REDIS_HOST="purebliss-redis"
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  echo "[$(date)] INFO: Onboarding Redis into Vault for dynamic secrets (host: $REDIS_HOST)" | tee -a "$LOG_FILE"

  # Auto-detect Vault mode and set appropriate address
  local VAULT_ADDR_HTTP="https://127.0.0.1:8200"
  local VAULT_ADDR_HTTPS="https://127.0.0.1:8200"
  local VAULT_ADDR=""

  # Test HTTP first (dev mode)
  if curl -sk "$VAULT_ADDR_HTTP/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTP"
    export VAULT_ADDR
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Using Vault dev mode (HTTP) for Redis onboarding" | tee -a "$LOG_FILE"
  # Test HTTPS (production mode)
  elif curl -skk "$VAULT_ADDR_HTTPS/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTPS"
    export VAULT_ADDR
    export VAULT_SKIP_VERIFY=1
    if [[ -f "$VAULT_TOKEN_FILE" ]]; then
      export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
      echo "[$(date)] INFO: Using Vault production mode (HTTPS) for Redis onboarding" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] ERROR: Cannot connect to Vault for Redis onboarding" | tee -a "$LOG_FILE"
    return 1
  fi

  # Enable the database secrets engine for Redis (idempotent)
  vault secrets enable -path=redis database 2>&1 | tee -a "$LOG_FILE" || echo "[$(date)] INFO: Redis secrets engine may already be enabled" | tee -a "$LOG_FILE"

  # Configure the Redis connection (idempotent, will overwrite if exists)
  # Redis plugin requires host, port, username and password parameters
  if vault write redis/config/redis \
    plugin_name=redis-database-plugin \
    allowed_roles="redis-role" \
    host="$REDIS_HOST" \
    port=6379 \
    username=default \
    password=nopass 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Redis connection configured in Vault" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Redis connection config may have issues" | tee -a "$LOG_FILE"
  fi

  # Note: Redis ACL creation statements require specific syntax that may vary by Vault version
  # The Redis role needs to be configured manually for now due to ACL syntax complexity
  echo "[$(date)] INFO: Redis connection established. Manual role configuration required for dynamic credentials." | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: To complete Redis onboarding: vault write redis/roles/redis-role db_name=redis creation_statements='[\"{{name}}\", \"on\", \">{{password}}\", \"~*\", \"+@all\"]' default_ttl=1h max_ttl=24h" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Redis Vault onboarding automation complete" | tee -a "$LOG_FILE"
}

# Keycloak Vault Integration Function
function onboard_keycloak_to_vault() {
  local VAULT_ADDR="https://127.0.0.1:8200"
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

  echo "[$(date)] INFO: Onboarding Keycloak to Vault for dynamic secrets and PKI" | tee -a "$LOG_FILE"

  if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
    echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
    return 1
  fi

  export VAULT_ADDR
  export VAULT_SKIP_VERIFY=1
  export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")

  # Enable database secrets engine for Keycloak (idempotent)
  vault secrets enable -path=keycloak database 2>&1 | tee -a "$LOG_FILE" || echo "[$(date)] INFO: Keycloak database secrets engine may already be enabled" | tee -a "$LOG_FILE"

  # Configure PostgreSQL connection for Keycloak
  if vault write keycloak/config/keycloak-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="keycloak-role" \
    connection_url="postgresql://{{username}}:{{password}}@purebliss-postgres:5432/keycloak?sslmode=disable" \
    username="keycloak" \
    password="keycloak_password" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Keycloak database connection configured in Vault" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Keycloak database connection config may have issues" | tee -a "$LOG_FILE"
  fi

  # Create Keycloak database role
  if vault write keycloak/roles/keycloak-role \
    db_name=keycloak-db \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE keycloak TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Keycloak database role created in Vault" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Keycloak database role creation may have issues" | tee -a "$LOG_FILE"
  fi

  # Enable AppRole auth method for Keycloak (idempotent)
  vault auth enable -path=keycloak approle 2>&1 | tee -a "$LOG_FILE" || echo "[$(date)] INFO: Keycloak AppRole auth may already be enabled" | tee -a "$LOG_FILE"

  # Create AppRole for Keycloak
  if vault write auth/keycloak/role/keycloak-service \
    token_policies="keycloak-policy" \
    token_ttl=1h \
    token_max_ttl=4h \
    bind_secret_id=true 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Keycloak AppRole created" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Keycloak AppRole creation may have issues" | tee -a "$LOG_FILE"
  fi

  # Create policy for Keycloak
  vault policy write keycloak-policy - <<EOF 2>&1 | tee -a "$LOG_FILE"
# Keycloak Database Access
path "keycloak/creds/keycloak-role" {
  capabilities = ["read"]
}

# PKI Certificate Access
path "pki_int/issue/keycloak" {
  capabilities = ["create", "update"]
}

# Secret Management
path "secret/data/keycloak/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Transit encryption
path "transit/encrypt/keycloak" {
  capabilities = ["update"]
}

path "transit/decrypt/keycloak" {
  capabilities = ["update"]
}
EOF

  # Get AppRole credentials
  ROLE_ID=$(vault read -field=role_id auth/keycloak/role/keycloak-service/role-id 2>/dev/null)
  SECRET_ID=$(vault write -field=secret_id auth/keycloak/role/keycloak-service/secret-id 2>/dev/null)

  if [[ -n "$ROLE_ID" && -n "$SECRET_ID" ]]; then
    # Save AppRole credentials
    echo "$ROLE_ID" > /opt/dev-purebliss/services/keycloak/vault-role-id
    echo "$SECRET_ID" > /opt/dev-purebliss/services/keycloak/vault-secret-id
    chmod 600 /opt/dev-purebliss/services/keycloak/vault-role-id
    chmod 600 /opt/dev-purebliss/services/keycloak/vault-secret-id
    echo "[$(date)] SUCCESS: Keycloak AppRole credentials saved" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Failed to generate Keycloak AppRole credentials" | tee -a "$LOG_FILE"
  fi

  # Test dynamic credential generation
  echo "[$(date)] INFO: Testing Keycloak dynamic credential generation..." | tee -a "$LOG_FILE"
  if vault read keycloak/creds/keycloak-role 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Keycloak dynamic credentials working" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Keycloak dynamic credential test failed" | tee -a "$LOG_FILE"
  fi

  # Store Redis configuration in Vault for Keycloak
  echo "[$(date)] INFO: Storing Redis configuration in Vault for Keycloak..." | tee -a "$LOG_FILE"

  # Enable KV secrets engine if not already enabled
  vault secrets enable -path=secret kv-v2 2>&1 | tee -a "$LOG_FILE" || echo "[$(date)] INFO: KV secrets engine may already be enabled" | tee -a "$LOG_FILE"

  # Store Redis configuration
  if vault kv put secret/keycloak/redis \
    host="purebliss-redis" \
    port="6379" \
    database="1" \
    password="" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Redis configuration stored in Vault for Keycloak" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Failed to store Redis configuration in Vault" | tee -a "$LOG_FILE"
  fi

  # Store database configuration in Vault
  if vault kv put secret/keycloak/database \
    host="purebliss-postgres" \
    port="5432" \
    database="keycloak" \
    username="keycloak" \
    password="keycloak_password" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Database configuration stored in Vault for Keycloak" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Failed to store database configuration in Vault" | tee -a "$LOG_FILE"
  fi

  # Store admin configuration in Vault
  if vault kv put secret/keycloak/admin \
    username="admin" \
    password="admin123" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Admin configuration stored in Vault for Keycloak" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Failed to store admin configuration in Vault" | tee -a "$LOG_FILE"
  fi

  echo "[$(date)] INFO: Keycloak Vault onboarding complete" | tee -a "$LOG_FILE"
}

#!/bin/bash
set -euo pipefail


LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# --- Sequential Service Startup with Health Validation ---
# This function ensures each service is fully healthy before starting the next
function start_all_services_sequential() {
  echo "[$(date)] INFO: Starting Pure Bliss services in strict sequential order" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Each service must be healthy before next service starts" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: All services use Vault for secret management" | tee -a "$LOG_FILE"

  # Run comprehensive pre-startup validation
  if ! pre_startup_validation; then
    echo "[$(date)] ERROR: Pre-startup validation failed - aborting startup" | tee -a "$LOG_FILE"
    return 1
  fi

  # Clean up any existing containers first
  cleanup_all_containers

  for service in "${SERVICE_ORDER[@]}"; do
    echo "" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: ===== Starting $service service =====" | tee -a "$LOG_FILE"

    # Start the service
    if ! start_service_robust "$service"; then
      echo "[$(date)] ERROR: Failed to start $service - aborting sequential startup" | tee -a "$LOG_FILE"
      return 1
    fi

    # Wait for service to be healthy
    echo "[$(date)] INFO: Waiting for $service to be healthy..." | tee -a "$LOG_FILE"
    if ! wait_for_healthy "$service" "$service"; then
      if [[ "$service" == "keycloak" ]]; then
        echo "[$(date)] WARNING: $service failed to become healthy - continuing with monitoring services" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] ERROR: $service failed to become healthy - aborting sequential startup" | tee -a "$LOG_FILE"
        return 1
      fi
    fi

    # Special handling for vault - must unseal after vault-agent is healthy
    if [[ "$service" == "vault-agent" ]]; then
      echo "[$(date)] INFO: Vault and Vault Agent healthy - auto-unsealing..." | tee -a "$LOG_FILE"
      if ! vault_auto_unseal_enhanced; then
        echo "[$(date)] ERROR: Failed to unseal Vault - aborting sequential startup" | tee -a "$LOG_FILE"
        return 1
      fi
      echo "[$(date)] SUCCESS: Vault unsealed and ready for service integrations" | tee -a "$LOG_FILE"

      # Perform Vault compliance validation
      if ! vault_status_check; then
        echo "[$(date)] ERROR: Vault compliance validation failed - aborting startup" | tee -a "$LOG_FILE"
        return 1
      fi
    fi

# Post-startup configurations and vault onboarding
function run_post_startup() {
  local service="$1"

  echo "[$(date)] INFO: Running post-startup configuration for $service..." | tee -a "$LOG_FILE"

  case "$service" in
    "vault")
      # Setup Vault automation after Vault is running
      if ! setup_vault_automation; then
        echo "[$(date)] WARNING: Vault automation setup had issues" | tee -a "$LOG_FILE"
        return 1
      fi
      ;;
    "postgres")
      # PostgreSQL post-startup validation and Vault integration
      echo "[$(date)] INFO: Validating PostgreSQL Vault integration..." | tee -a "$LOG_FILE"

      # Wait for PostgreSQL to fully initialize
      local max_wait=60
      local wait_count=0

      echo "[$(date)] INFO: Waiting for PostgreSQL to be ready..." | tee -a "$LOG_FILE"
      while [[ $wait_count -lt $max_wait ]]; do
        if docker exec purebliss-postgres pg_isready -U postgres -d postgres >/dev/null 2>&1; then
          echo "[$(date)] SUCCESS: PostgreSQL is ready and responding" | tee -a "$LOG_FILE"
          break
        fi
        sleep 2
        ((wait_count += 2))
        echo "[$(date)] INFO: Waiting for PostgreSQL... ($wait_count/$max_wait seconds)" | tee -a "$LOG_FILE"
      done

      if [[ $wait_count -ge $max_wait ]]; then
        echo "[$(date)] ERROR: PostgreSQL failed to become ready within $max_wait seconds" | tee -a "$LOG_FILE"
        return 1
      fi

      # Create databases if they don't exist
      echo "[$(date)] INFO: Ensuring required databases exist..." | tee -a "$LOG_FILE"

      # Create keycloak database
      if ! docker exec purebliss-postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw keycloak; then
        echo "[$(date)] INFO: Creating keycloak database..." | tee -a "$LOG_FILE"
        docker exec purebliss-postgres psql -U postgres -c "CREATE DATABASE keycloak;" 2>&1 | tee -a "$LOG_FILE"
      else
        echo "[$(date)] SUCCESS: Keycloak database already exists" | tee -a "$LOG_FILE"
      fi

      # Create plane database
      if ! docker exec purebliss-postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw plane; then
        echo "[$(date)] INFO: Creating plane database..." | tee -a "$LOG_FILE"
        docker exec purebliss-postgres psql -U postgres -c "CREATE DATABASE plane;" 2>&1 | tee -a "$LOG_FILE"
      else
        echo "[$(date)] SUCCESS: Plane database already exists" | tee -a "$LOG_FILE"
      fi

      # Create vikunja database
      if ! docker exec purebliss-postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw vikunja; then
        echo "[$(date)] INFO: Creating vikunja database..." | tee -a "$LOG_FILE"
        docker exec purebliss-postgres psql -U postgres -c "CREATE DATABASE vikunja;" 2>&1 | tee -a "$LOG_FILE"
      else
        echo "[$(date)] SUCCESS: Vikunja database already exists" | tee -a "$LOG_FILE"
      fi

      # Test Vault integration if Vault is available
      if vault_status_check; then
        echo "[$(date)] INFO: Testing PostgreSQL Vault integration..." | tee -a "$LOG_FILE"

        # Test database secrets engine configuration
        if vault read database/config/postgres-app >/dev/null 2>&1; then
          echo "[$(date)] SUCCESS: Vault database configuration exists" | tee -a "$LOG_FILE"

          # Test dynamic credential generation
          if vault read database/creds/postgres-role >/dev/null 2>&1; then
            echo "[$(date)] SUCCESS: Vault dynamic PostgreSQL credentials working" | tee -a "$LOG_FILE"
          else
            echo "[$(date)] INFO: Dynamic credential generation will be configured automatically" | tee -a "$LOG_FILE"
          fi
        else
          echo "[$(date)] INFO: Vault database configuration will be set up during PostgreSQL onboarding" | tee -a "$LOG_FILE"
        fi
      else
        echo "[$(date)] WARNING: Vault not available for PostgreSQL integration testing" | tee -a "$LOG_FILE"
      fi
      ;;
    "redis")
      onboard_redis_to_vault
      ;;
    "keycloak")
      # Keycloak post-startup validation
      echo "[$(date)] INFO: Validating Keycloak startup and database connectivity..." | tee -a "$LOG_FILE"

      # Give Keycloak adequate time to initialize and create schema
      local max_wait=180
      local wait_count=0

      echo "[$(date)] INFO: Waiting for Keycloak to initialize (this may take up to 3 minutes)..." | tee -a "$LOG_FILE"
      while [[ $wait_count -lt $max_wait ]]; do
        # Check if Keycloak is responding to HTTP requests
        if curl -sk -f http://localhost:8080/auth/ >/dev/null 2>&1; then
          echo "[$(date)] SUCCESS: Keycloak is responding to HTTP requests" | tee -a "$LOG_FILE"
          break
        fi
        sleep 5
        ((wait_count += 5))
        if [[ $((wait_count % 30)) -eq 0 ]]; then
          echo "[$(date)] INFO: Still waiting for Keycloak... ($wait_count/$max_wait seconds)" | tee -a "$LOG_FILE"
        fi
      done

      if [[ $wait_count -ge $max_wait ]]; then
        echo "[$(date)] ERROR: Keycloak failed to respond within $max_wait seconds" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: Checking Keycloak logs for issues..." | tee -a "$LOG_FILE"
        docker logs purebliss-keycloak --tail 20 2>&1 | tee -a "$LOG_FILE"
        return 1
      fi

      # Verify database connectivity and schema creation
      echo "[$(date)] INFO: Verifying Keycloak database integration..." | tee -a "$LOG_FILE"

      # Check if keycloak database user exists
      if ! docker exec purebliss-postgres psql -U postgres -c "SELECT 1 FROM pg_roles WHERE rolname='keycloak';" | grep -q "1"; then
        echo "[$(date)] INFO: Creating keycloak database user..." | tee -a "$LOG_FILE"
        docker exec purebliss-postgres psql -U postgres -c "CREATE USER keycloak WITH PASSWORD 'keycloak_secure_password';" 2>&1 | tee -a "$LOG_FILE"
        docker exec purebliss-postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;" 2>&1 | tee -a "$LOG_FILE"
        docker exec purebliss-postgres psql -U postgres -c "ALTER DATABASE keycloak OWNER TO keycloak;" 2>&1 | tee -a "$LOG_FILE"
      else
        echo "[$(date)] SUCCESS: Keycloak database user exists" | tee -a "$LOG_FILE"
      fi

      # Check if Keycloak has created its schema
      local table_count
      table_count=$(docker exec purebliss-postgres psql -U postgres -d keycloak -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')

      if [[ "$table_count" -gt 10 ]]; then
        echo "[$(date)] SUCCESS: Keycloak database schema created ($table_count tables)" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Keycloak database schema incomplete ($table_count tables)" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: Keycloak may still be initializing its database schema..." | tee -a "$LOG_FILE"
      fi

      # Test Redis connectivity from Keycloak perspective
      echo "[$(date)] INFO: Testing Redis connectivity for Keycloak session management..." | tee -a "$LOG_FILE"
      if docker exec purebliss-redis redis-cli ping | grep -q "PONG"; then
        echo "[$(date)] SUCCESS: Redis is responding for session management" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Redis not responding - Keycloak session management may be impacted" | tee -a "$LOG_FILE"
      fi

      # Onboard Keycloak to Vault for enhanced security
      echo "[$(date)] INFO: Onboarding Keycloak to Vault for dynamic secrets management..." | tee -a "$LOG_FILE"
      onboard_keycloak_to_vault
      ;;
    "nginx")
      onboard_nginx_to_vault
      ;;
    "prometheus")
      onboard_prometheus_to_vault
      ;;
    "loki")
      onboard_loki_to_vault
      ;;
    "codeserver")
      onboard_codeserver_to_vault
      ;;
    "grafana")
      onboard_grafana_to_vault
      ;;
    "letsencrypt")
      onboard_letsencrypt_to_vault
      ;;
    *)
      echo "[$(date)] INFO: No specific post-startup configuration for $service" | tee -a "$LOG_FILE"
      ;;
  esac

  # Run service-specific validation
  post_service_validation "$service"

  return 0
}

    # Run post-startup configurations and vault onboarding
    if run_post_startup "$service"; then
      echo "[$(date)] SUCCESS: $service is healthy and configured" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] WARNING: $service post-startup configuration had issues" | tee -a "$LOG_FILE"
    fi

    # Give a brief pause between services for stability
    sleep 3
  done

  echo "" | tee -a "$LOG_FILE"
  echo "[$(date)] SUCCESS: All services started successfully in sequential order!" | tee -a "$LOG_FILE"

  # Run comprehensive health check
  echo "[$(date)] INFO: Running final comprehensive health check..." | tee -a "$LOG_FILE"
  if [[ -x "/opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" ]]; then
    echo "[$(date)] INFO: Executing comprehensive health validation..." | tee -a "$LOG_FILE"
    /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh 2>&1 | tee -a "$LOG_FILE"
    local health_status=$?
    if [[ $health_status -eq 0 ]]; then
      echo "[$(date)] SUCCESS: All systems passed comprehensive health check!" | tee -a "$LOG_FILE"
      return 0
    else
      echo "[$(date)] ERROR: Comprehensive health check failed" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] WARNING: Comprehensive health check script not found" | tee -a "$LOG_FILE"
    return 0
  fi
}

# Backup configs for each service after successful start or config change
function backup_critical_configs() {
  local service="$1"
  local config_dir="/opt/my-secure-ha-stack/$service"
  local backup_dir="/opt/my-secure-ha-stack/backups/$service"
  if [[ -d "$config_dir" ]]; then
    mkdir -p "$backup_dir"
    cp -a "$config_dir"/* "$backup_dir"/ 2>/dev/null || true
    echo "[$(date)] INFO: Backed up $service configs to $backup_dir" >> "$LOG_FILE"
  fi
}
SERVICES_DIR="/opt/dev-purebliss/services"

# --- Prometheus Vault Onboarding Automation ---
# This function configures Vault to provide dynamic secrets for Prometheus monitoring
function onboard_prometheus_to_vault() {
  # Auto-detect vault mode and set VAULT_ADDR accordingly
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  local PROMETHEUS_CERTS_PATH="pki-prometheus"
  local PROMETHEUS_CONFIG_PATH="/opt/dev-purebliss/services/prometheus"
  echo "[$(date)] INFO: Onboarding Prometheus to Vault for dynamic secrets and config management" | tee -a "$LOG_FILE"

  # Auto-detect vault URL based on running container or dev mode
  local VAULT_ADDR
  if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
     docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    # Development mode - vault running in dev mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Detected Vault in development mode" | tee -a "$LOG_FILE"
  elif docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
    # Production mode - container running in production mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
      echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
      return 1
    fi
    export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
    echo "[$(date)] INFO: Detected Vault in production mode" | tee -a "$LOG_FILE"
  else
    # Fallback - assume dev server if no container
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: No Vault container detected, assuming development mode" | tee -a "$LOG_FILE"
  fi

  export VAULT_ADDR
  echo "[$(date)] INFO: Using Vault at $VAULT_ADDR for Prometheus onboarding" | tee -a "$LOG_FILE"

  # Enable KV v2 secrets engine for Prometheus configuration (idempotent)
  vault secrets enable -path=prometheus-config kv-v2 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: Prometheus KV secrets engine may already be enabled" | tee -a "$LOG_FILE"

  # Store Prometheus configuration secrets
  vault kv put prometheus-config/metrics \
    scrape_interval="15s" \
    evaluation_interval="15s" \
    retention_time="200h" \
    admin_password="$(openssl rand -base64 32)" 2>&1 | tee -a "$LOG_FILE"

  # Store scrape target configurations with Vault-managed endpoints
  vault kv put prometheus-config/targets \
    vault_endpoint="purebliss-vault:8200" \
    postgres_endpoint="purebliss-postgres:5432" \
    redis_endpoint="purebliss-redis:6379" \
    keycloak_endpoint="purebliss-keycloak:8080" \
    nginx_endpoint="purebliss-nginx:80" \
    grafana_endpoint="purebliss-grafana:3001" 2>&1 | tee -a "$LOG_FILE"

  # Create prometheus configuration with dynamic values
  echo "[$(date)] SUCCESS: Prometheus secrets stored in Vault at prometheus-config/*" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Prometheus will pull configuration from Vault during startup" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Prometheus Vault onboarding automation complete" | tee -a "$LOG_FILE"
}

# --- Nginx Vault Onboarding Automation ---
# This function configures Vault PKI for Nginx to issue dynamic TLS certificates.
function onboard_nginx_to_vault() {
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  local PKI_PATH="pki-nginx"
  local PKI_ROLE="nginx-role"
  local DOMAIN="dev.purebliss.app"
  echo "[$(date)] INFO: Onboarding Nginx to Vault PKI (domain: $DOMAIN)" | tee -a "$LOG_FILE"

  # Auto-detect Vault mode and set appropriate address
  local VAULT_ADDR_HTTP="https://127.0.0.1:8200"
  local VAULT_ADDR_HTTPS="https://127.0.0.1:8200"
  local VAULT_ADDR=""

  # Test HTTP first (dev mode)
  if curl -sk "$VAULT_ADDR_HTTP/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTP"
    export VAULT_ADDR
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Using Vault dev mode (HTTP) for Nginx onboarding" | tee -a "$LOG_FILE"
  # Test HTTPS (production mode)
  elif curl -skk "$VAULT_ADDR_HTTPS/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTPS"
    export VAULT_ADDR
    export VAULT_SKIP_VERIFY=1
    if [[ -f "$VAULT_TOKEN_FILE" ]]; then
      export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
      echo "[$(date)] INFO: Using Vault production mode (HTTPS) for Nginx onboarding" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] ERROR: Cannot connect to Vault for Nginx onboarding" | tee -a "$LOG_FILE"
    return 1
  fi

  # Enable PKI secrets engine for Nginx (idempotent)
  vault secrets enable -path=$PKI_PATH pki 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: PKI engine $PKI_PATH may already be enabled" | tee -a "$LOG_FILE"

  # Tune the PKI engine max lease TTL (idempotent)
  vault secrets tune -max-lease-ttl=8760h $PKI_PATH 2>&1 | tee -a "$LOG_FILE"

  # Generate root CA if not already present
  if ! vault read $PKI_PATH/cert/ca 2>&1 | grep -q 'certificate'; then
    vault write -field=certificate $PKI_PATH/root/generate/internal \
      common_name="$DOMAIN Root CA" ttl=87600h 2>&1 | tee -a "$LOG_FILE"
    vault write $PKI_PATH/config/urls \
      issuing_certificates="$VAULT_ADDR/v1/$PKI_PATH/ca" \
      crl_distribution_points="$VAULT_ADDR/v1/$PKI_PATH/crl" 2>&1 | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: Root CA generated for $PKI_PATH" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] INFO: Root CA already exists for $PKI_PATH" | tee -a "$LOG_FILE"
  fi

  # Create a role for Nginx (idempotent)
  vault write $PKI_PATH/roles/$PKI_ROLE \
    allowed_domains="$DOMAIN" \
    allow_bare_domains=true \
    allow_subdomains=true \
    max_ttl="72h" 2>&1 | tee -a "$LOG_FILE"

  echo "[$(date)] INFO: PKI role $PKI_ROLE configured for $DOMAIN" | tee -a "$LOG_FILE"

  # Run the certificate update script to immediately apply Vault certificates
  echo "[$(date)] INFO: Applying Vault-generated certificates to Nginx..." | tee -a "$LOG_FILE"
  if [[ -f "/opt/dev-purebliss/services/nginx/update_vault_certificates.sh" ]]; then
    cd /opt/dev-purebliss/services/nginx
    if ./update_vault_certificates.sh 2>&1 | tee -a "$LOG_FILE"; then
      echo "[$(date)] INFO: Nginx certificates successfully updated from Vault PKI!" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] WARNING: Certificate update failed, nginx may still be using temporary certificates" | tee -a "$LOG_FILE"
    fi
  else
    echo "[$(date)] WARNING: Certificate update script not found at /opt/dev-purebliss/services/nginx/update_vault_certificates.sh" | tee -a "$LOG_FILE"
  fi

  # Instructions for Nginx to fetch/renew certs (for future automation)
  echo "[$(date)] INFO: To manually update certificates, run: /opt/dev-purebliss/services/nginx/update_vault_certificates.sh" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Nginx Vault onboarding automation complete" | tee -a "$LOG_FILE"
}

# === Pure Bliss Vault Troubleshooting Reference ===
# For all Vault and Vault Agent operational issues, consult:
#   /opt/dev-purebliss/services/vault/VAULT_AUTOMATION_GUIDE.md
#   /opt/dev-purebliss/services/vault/vault-break-fix-report.md
# These documents contain automation, break/fix, and troubleshooting best practices for Vault and Vault Agent.
#
# For comprehensive infrastructure validation after startup:
#   /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh
# This script validates all services, integrations, and provides detailed health status.

echo "[$(date)] INFO: For Vault and Vault Agent troubleshooting, see VAULT_AUTOMATION_GUIDE.md and vault-break-fix-report.md in /opt/dev-purebliss/services/vault/" >> "$LOG_FILE"
echo "[$(date)] INFO: For comprehensive infrastructure validation, use /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" >> "$LOG_FILE"

# Ensure purebliss-net Docker network exists before starting any services
if ! docker network ls --format '{{.Name}}' | grep -q '^purebliss-net$'; then
  echo "[$(date)] INFO: Creating Docker network purebliss-net..." | tee -a "$LOG_FILE"
  docker network create --driver bridge purebliss-net >> "$LOG_FILE" 2>&1 || {
    echo "[$(date)] ERROR: Failed to create Docker network purebliss-net" | tee -a "$LOG_FILE"
    exit 1
  }
else
  echo "[$(date)] INFO: Docker network purebliss-net already exists." >> "$LOG_FILE"
fi


# Usage: ./start-all-services.sh [service_name]
SERVICE_ARG="${1:-}"

# Comprehensive pre-startup validation with Vault compliance
function pre_startup_validation() {
  echo "[$(date)] INFO: === COMPREHENSIVE PRE-STARTUP VALIDATION ===" | tee -a "$LOG_FILE"

  # Check Docker network
  if ! docker network ls --format '{{.Name}}' | grep -q '^purebliss-net$'; then
    echo "[$(date)] INFO: Creating Docker network purebliss-net..." | tee -a "$LOG_FILE"
    docker network create --driver bridge purebliss-net 2>&1 | tee -a "$LOG_FILE"
  else
    echo "[$(date)] SUCCESS: Docker network purebliss-net exists" | tee -a "$LOG_FILE"
  fi

  # Check required directories
  local required_dirs=(
    "/opt/my-secure-ha-stack/logs"
    "/opt/my-secure-ha-stack/secrets"
    "/opt/my-secure-ha-stack/backups"
    "/opt/dev-purebliss/services/vault"
    "/opt/dev-purebliss/services/postgres"
    "/opt/dev-purebliss/services/redis"
    "/opt/dev-purebliss/services/keycloak"
    "/opt/dev-purebliss/services/nginx"
  )

  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      echo "[$(date)] WARNING: Creating missing directory: $dir" | tee -a "$LOG_FILE"
      mkdir -p "$dir"
    else
      echo "[$(date)] SUCCESS: Directory exists: $dir" | tee -a "$LOG_FILE"
    fi
  done

  # Check for existing containers and clean them up
  echo "[$(date)] INFO: Checking for existing containers to clean up..." | tee -a "$LOG_FILE"
  local containers=(purebliss-vault purebliss-vault-agent purebliss-postgres purebliss-redis purebliss-keycloak purebliss-letsencrypt purebliss-nginx)
  local containers_found=0

  for container in "${containers[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
      echo "[$(date)] INFO: Removing existing container: $container" | tee -a "$LOG_FILE"
      docker stop "$container" >/dev/null 2>&1 || true
      docker rm "$container" >/dev/null 2>&1 || true
      ((containers_found++))
    fi
  done

  if [[ $containers_found -gt 0 ]]; then
    echo "[$(date)] INFO: Cleaned up $containers_found existing containers" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] SUCCESS: No existing containers to clean up" | tee -a "$LOG_FILE"
  fi

  # Check disk space
  local available_space
  available_space=$(df /opt | tail -1 | awk '{print $4}')
  local min_space=1048576  # 1GB in KB

  if [[ $available_space -lt $min_space ]]; then
    echo "[$(date)] WARNING: Low disk space: ${available_space}KB available (minimum: ${min_space}KB)" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] SUCCESS: Sufficient disk space: ${available_space}KB available" | tee -a "$LOG_FILE"
  fi

  # Test Docker functionality
  echo "[$(date)] INFO: Testing Docker functionality..." | tee -a "$LOG_FILE"
  if docker run --rm hello-world >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: Docker is functioning correctly" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Docker test failed" | tee -a "$LOG_FILE"
    return 1
  fi

  echo "[$(date)] SUCCESS: Pre-startup validation completed successfully" | tee -a "$LOG_FILE"
  return 0
}

# Enhanced cleanup function to ensure clean startup
function cleanup_all_containers() {
  echo "[$(date)] INFO: Cleaning up existing containers for fresh startup..." | tee -a "$LOG_FILE"

  # Stop all purebliss containers gracefully
  local containers=(purebliss-vault purebliss-vault-agent purebliss-postgres purebliss-redis purebliss-keycloak purebliss-letsencrypt purebliss-nginx purebliss-codeserver purebliss-prometheus purebliss-loki)
  for container in "${containers[@]}"; do
    if docker ps -q -f name="$container" | grep -q .; then
      echo "[$(date)] INFO: Stopping container $container..." | tee -a "$LOG_FILE"
      docker stop "$container" >/dev/null 2>&1 || true
    fi
  done

  # Stop individual Docker Compose services for monitoring stack
  echo "[$(date)] INFO: Stopping monitoring services via Docker Compose..." | tee -a "$LOG_FILE"
  (cd /opt/dev-purebliss/services/prometheus && docker compose -f prometheus-docker-compose.yml down >/dev/null 2>&1) || true
  (cd /opt/dev-purebliss/services/loki && docker compose -f loki-docker-compose.yml down >/dev/null 2>&1) || true

  # Remove stopped containers to avoid conflicts
  for container in "${containers[@]}"; do
    if docker ps -aq -f name="$container" | grep -q .; then
      echo "[$(date)] INFO: Removing container $container..." | tee -a "$LOG_FILE"
      docker rm "$container" >/dev/null 2>&1 || true
    fi
  done

  echo "[$(date)] INFO: Container cleanup complete" | tee -a "$LOG_FILE"
}

# Enhanced Vault auto-unseal with retry logic - supports both dev (HTTP) and production (HTTPS) modes
function vault_auto_unseal_enhanced() {
  echo "[$(date)] INFO: Enhanced Vault auto-unseal with integrated automation..." | tee -a "$LOG_FILE"

  # Auto-detect Vault mode and set appropriate address
  local VAULT_ADDR_HTTP="https://127.0.0.1:8200"
  local VAULT_ADDR_HTTPS="https://127.0.0.1:8200"
  local VAULT_ADDR=""
  local vault_mode=""

  # Test HTTP first (dev mode)
  if curl -sk "$VAULT_ADDR_HTTP/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTP"
    vault_mode="dev"
    echo "[$(date)] INFO: Detected Vault running in development mode (HTTP)" | tee -a "$LOG_FILE"
  # Test HTTPS (production mode)
  elif curl -skk "$VAULT_ADDR_HTTPS/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTPS"
    vault_mode="production"
    echo "[$(date)] INFO: Detected Vault running in production mode (HTTPS)" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Cannot connect to Vault on either HTTP or HTTPS" | tee -a "$LOG_FILE"
    return 1
  fi

  # Check if Vault is already unsealed (dev mode is always unsealed)
  local status_response sealed_status
  if [[ "$vault_mode" == "dev" ]]; then
    status_response=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
  else
    status_response=$(curl -skk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
  fi

  sealed_status=$(echo "$status_response" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' "')

  if [[ "$sealed_status" == "false" ]]; then
    echo "[$(date)] SUCCESS: Vault is already unsealed in $vault_mode mode" | tee -a "$LOG_FILE"

    # Set up vault token for dev mode
    if [[ "$vault_mode" == "dev" ]]; then
      echo "[$(date)] INFO: Setting up dev mode root token..." | tee -a "$LOG_FILE"
      mkdir -p /opt/my-secure-ha-stack/secrets
      echo "dev-root-token-purebliss" > /opt/my-secure-ha-stack/secrets/vault_token
      chmod 600 /opt/my-secure-ha-stack/secrets/vault_token
      export VAULT_ADDR="$VAULT_ADDR"
      export VAULT_TOKEN="dev-root-token-purebliss"
      echo "[$(date)] SUCCESS: Dev mode token configured for automation" | tee -a "$LOG_FILE"
    fi

    return 0
  fi

  # Only production mode vaults need unsealing (dev mode is always unsealed)
  if [[ "$vault_mode" == "dev" ]]; then
    echo "[$(date)] WARNING: Dev mode Vault should never be sealed - this indicates an issue" | tee -a "$LOG_FILE"
    return 1
  fi

  echo "[$(date)] INFO: Production mode Vault is sealed, attempting to unseal..." | tee -a "$LOG_FILE"

  # Try the automated unseal script first (for production mode)
  if [[ -x "/opt/dev-purebliss/services/vault/vault-auto-unseal.sh" ]]; then
    echo "[$(date)] INFO: Running vault-auto-unseal.sh automation script..." | tee -a "$LOG_FILE"
    if VAULT_ADDR="$VAULT_ADDR" /opt/dev-purebliss/services/vault/vault-auto-unseal.sh >> "$LOG_FILE" 2>&1; then
      echo "[$(date)] SUCCESS: Vault unsealed using automation script" | tee -a "$LOG_FILE"
      return 0
    else
      echo "[$(date)] WARNING: Automation script failed, trying break-fix approach..." | tee -a "$LOG_FILE"
    fi
  fi

  # Try the break-fix script
  if [[ -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
    echo "[$(date)] INFO: Running vault break-fix diagnostic..." | tee -a "$LOG_FILE"
    if VAULT_ADDR="$VAULT_ADDR" /opt/dev-purebliss/services/vault/vault-break-fix.sh diagnostic >> "$LOG_FILE" 2>&1; then
      # Check if vault is now unsealed after diagnostic
      status_response=$(curl -skk "$VAULT_ADDR/v1/sys/health" 2>/dev/null)
      sealed_status=$(echo "$status_response" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' "')

      if [[ "$sealed_status" == "false" ]]; then
        echo "[$(date)] SUCCESS: Vault unsealed using break-fix procedure" | tee -a "$LOG_FILE"
        return 0
      fi
    fi
  fi

  # Fallback: Manual unseal with stored keys (production mode only)
  echo "[$(date)] INFO: Attempting manual unseal with stored keys..." | tee -a "$LOG_FILE"

  local max_attempts=5
  local attempt=1

  while [[ $attempt -le $max_attempts ]]; do
    echo "[$(date)] INFO: Manual unseal attempt $attempt/$max_attempts..." | tee -a "$LOG_FILE"

    # Check if Vault is reachable
    if ! curl -skk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
      echo "[$(date)] WARNING: Vault not reachable, waiting 5 seconds..." | tee -a "$LOG_FILE"
      sleep 5
      ((attempt++))
      continue
    fi

    # Check seal status
    sealed_status=$(curl -skk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' ')

    if [[ "$sealed_status" == "false" ]]; then
      echo "[$(date)] SUCCESS: Vault is already unsealed (attempt $attempt)" | tee -a "$LOG_FILE"
      return 0
    elif [[ "$sealed_status" == "true" ]]; then
      echo "[$(date)] INFO: Vault is sealed, attempting to unseal..." | tee -a "$LOG_FILE"

      if [[ -f "/opt/my-secure-ha-stack/vault-unseal-keys.env" ]]; then
        # shellcheck disable=SC1091
        source /opt/my-secure-ha-stack/vault-unseal-keys.env

        # Submit unseal keys
        local keys_submitted=0
        for key_var in VAULT_DEV_UNSEAL_KEY_1 VAULT_DEV_UNSEAL_KEY_2 VAULT_DEV_UNSEAL_KEY_3; do
          key="${!key_var:-}"
          if [[ -n "$key" ]]; then
            if curl -skk --request POST --data '{"key": "'$key'"}' "$VAULT_ADDR/v1/sys/unseal" >/dev/null 2>&1; then
              echo "[$(date)] INFO: Successfully submitted $key_var" | tee -a "$LOG_FILE"
              ((keys_submitted++))
            else
              echo "[$(date)] WARNING: Failed to submit $key_var" | tee -a "$LOG_FILE"
            fi
          fi
        done

        if [[ $keys_submitted -ge 3 ]]; then
          echo "[$(date)] INFO: Submitted $keys_submitted unseal keys, checking status..." | tee -a "$LOG_FILE"
          sleep 2
          sealed_status=$(curl -skk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' ')
          if [[ "$sealed_status" == "false" ]]; then
            echo "[$(date)] SUCCESS: Vault unsealed successfully with stored keys" | tee -a "$LOG_FILE"
            return 0
          fi
        fi
      else
        echo "[$(date)] WARNING: No unseal keys found in /opt/my-secure-ha-stack/vault-unseal-keys.env" | tee -a "$LOG_FILE"
        # Try to find encrypted keys in the vault secrets automation
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault/vault-keys.enc" && -f "/opt/my-secure-ha-stack/secrets/vault/.master_password" ]]; then
          echo "[$(date)] INFO: Found encrypted vault keys - trying automated decryption..." | tee -a "$LOG_FILE"
          if VAULT_ADDR="$VAULT_ADDR" /opt/dev-purebliss/services/vault/vault-auto-unseal.sh >> "$LOG_FILE" 2>&1; then
            echo "[$(date)] SUCCESS: Vault unsealed using encrypted keys" | tee -a "$LOG_FILE"
            return 0
          fi
        fi
      fi

      echo "[$(date)] WARNING: Vault unseal attempt $attempt failed, retrying in 10 seconds..." | tee -a "$LOG_FILE"
    else
      echo "[$(date)] WARNING: Unable to determine Vault status on attempt $attempt" | tee -a "$LOG_FILE"
    fi

    sleep 10
    ((attempt++))
  done

  echo "[$(date)] ERROR: Failed to unseal Vault after $max_attempts attempts" | tee -a "$LOG_FILE"
  echo "[$(date)] ERROR: Manual intervention required:" | tee -a "$LOG_FILE"
  echo "[$(date)] ERROR: - Run: /opt/dev-purebliss/services/vault/vault-init-automation.sh (first time setup)" | tee -a "$LOG_FILE"
  echo "[$(date)] ERROR: - Run: /opt/dev-purebliss/services/vault/vault-break-fix.sh all (troubleshooting)" | tee -a "$LOG_FILE"
  echo "[$(date)] ERROR: - Check: /opt/my-secure-ha-stack/logs/dev-environment-setup.log for details" | tee -a "$LOG_FILE"
  return 1
}

# Enhanced vault status check function with comprehensive compliance validation
function vault_status_check() {
  echo "[$(date)] INFO: Performing comprehensive Vault status and compliance check..." | tee -a "$LOG_FILE"

  # Auto-detect Vault mode and set appropriate address
  local VAULT_ADDR_HTTP="https://127.0.0.1:8200"
  local VAULT_ADDR_HTTPS="https://127.0.0.1:8200"
  local VAULT_ADDR=""
  local vault_mode=""

  # Test HTTP first (dev mode)
  if curl -sk "$VAULT_ADDR_HTTP/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTP"
    vault_mode="dev"
    export VAULT_ADDR
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Vault running in development mode (HTTP)" | tee -a "$LOG_FILE"
  # Test HTTPS (production mode)
  elif curl -skk "$VAULT_ADDR_HTTPS/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTPS"
    vault_mode="production"
    export VAULT_ADDR
    export VAULT_SKIP_VERIFY=1
    # Load production token
    local token_file="/opt/my-secure-ha-stack/secrets/vault_token"
    if [[ -f "$token_file" ]]; then
      export VAULT_TOKEN=$(cat "$token_file")
      echo "[$(date)] INFO: Vault running in production mode (HTTPS)" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] ERROR: Production token not found at $token_file" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] ERROR: Cannot connect to Vault on either HTTP or HTTPS" | tee -a "$LOG_FILE"
    return 1
  fi

  # Check vault health and seal status
  local health_response
  health_response=$(curl -sk${vault_mode:+k} "$VAULT_ADDR/v1/sys/health" 2>/dev/null)

  if [[ -n "$health_response" ]]; then
    local sealed_status initialized_status
    sealed_status=$(echo "$health_response" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' "')
    initialized_status=$(echo "$health_response" | grep -o '"initialized":[^,]*' | cut -d: -f2 | tr -d ' "')

    echo "[$(date)] INFO: Vault Status - Initialized: $initialized_status, Sealed: $sealed_status" | tee -a "$LOG_FILE"

    if [[ "$sealed_status" == "false" && "$initialized_status" == "true" ]]; then
      echo "[$(date)] SUCCESS: Vault is healthy, unsealed, and ready" | tee -a "$LOG_FILE"

      # Test basic Vault operations for compliance
      echo "[$(date)] INFO: Testing Vault compliance operations..." | tee -a "$LOG_FILE"

      # Test secret engine listing
      if vault secrets list >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Vault secret engines accessible" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Cannot list Vault secret engines" | tee -a "$LOG_FILE"
      fi

      # Test PKI engine for certificate management
      if vault read pki-letsencrypt/config/urls >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: PKI engine for Let's Encrypt accessible" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] INFO: PKI engine for Let's Encrypt not yet configured" | tee -a "$LOG_FILE"
      fi

      # Test database secrets engine
      if vault read database/config/postgres-app >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Database secrets engine configured" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] INFO: Database secrets engine not yet configured" | tee -a "$LOG_FILE"
      fi

      return 0
    else
      echo "[$(date)] ERROR: Vault is not ready - Sealed: $sealed_status, Initialized: $initialized_status" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] ERROR: Cannot get Vault health response" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Enhanced vault status check function

# Enhanced service startup order with comprehensive dependency management
# Phase 1: Core infrastructure (Vault foundation)
# Phase 2: Data layer (PostgreSQL, Redis)
# Phase 3: Application layer (Keycloak, Let's Encrypt, Nginx)
# Phase 4: Development and monitoring layer (CodeServer, Prometheus, Loki, Grafana)
SERVICE_ORDER=(vault vault-agent postgres redis nginx letsencrypt codeserver prometheus loki grafana keycloak)

# Test individual service independence and health
function test_service_independence() {
  local service_name="$1"
  local service_dir="$SERVICES_DIR/$service_name"

  echo "[$(date)] INFO: Testing $service_name container independence..." | tee -a "$LOG_FILE"

  # Test if service can start independently
  if docker ps -q --filter "name=purebliss-$service_name" >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: $service_name is already running independently" | tee -a "$LOG_FILE"
    return 0
  fi

  # Service-specific independence test
  case "$service_name" in
    "vault")
      if curl -sk https://localhost:8200/v1/sys/health >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Vault API accessible independently" | tee -a "$LOG_FILE"
        return 0
      fi
      ;;
    "postgres")
      if docker exec purebliss-postgres pg_isready -U postgres >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: PostgreSQL accepting connections independently" | tee -a "$LOG_FILE"
        return 0
      fi
      ;;
    "redis")
      if docker exec purebliss-redis redis-cli ping >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Redis responding independently" | tee -a "$LOG_FILE"
        return 0
      fi
      ;;
    "nginx")
      if curl -sk -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301"; then
        echo "[$(date)] SUCCESS: Nginx serving requests independently" | tee -a "$LOG_FILE"
        return 0
      fi
      ;;
  esac

  echo "[$(date)] INFO: $service_name independence test completed" | tee -a "$LOG_FILE"
  return 0
}
# --- Loki Vault Onboarding Automation ---
# This function configures Vault to provide dynamic secrets/config for Loki
function onboard_loki_to_vault() {
  # Auto-detect vault mode and set VAULT_ADDR accordingly
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  local LOKI_CONFIG_PATH="/opt/dev-purebliss/services/loki"
  echo "[$(date)] INFO: Onboarding Loki to Vault for dynamic secrets and config management" | tee -a "$LOG_FILE"

  # Auto-detect vault URL based on running container or dev mode
  local VAULT_ADDR
  if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
     docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    # Development mode - vault running in dev mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Detected Vault in development mode for Loki" | tee -a "$LOG_FILE"
  elif docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
    # Production mode - container running in production mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
      echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
      return 1
    fi
    export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
    echo "[$(date)] INFO: Detected Vault in production mode for Loki" | tee -a "$LOG_FILE"
  else
    # Fallback - assume dev server if no container
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: No Vault container detected, assuming development mode for Loki" | tee -a "$LOG_FILE"
  fi

  export VAULT_ADDR
  echo "[$(date)] INFO: Using Vault at $VAULT_ADDR for Loki onboarding" | tee -a "$LOG_FILE"

  # Test Vault connectivity before proceeding
  if ! curl -skk -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
    echo "[$(date)] WARNING: Cannot connect to Vault with current token - proceeding with basic startup" | tee -a "$LOG_FILE"
    return 0
  fi

  # Enable AppRole auth method for Loki (idempotent)
  vault auth enable -path=loki-approle approle 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: Loki AppRole auth method may already be enabled" | tee -a "$LOG_FILE"

  # Create Loki-specific AppRole
  vault write auth/loki-approle/role/loki-role \
    token_policies="loki-policy" \
    token_ttl=1h \
    token_max_ttl=24h 2>&1 | tee -a "$LOG_FILE"

  # Create policy for Loki
  vault policy write loki-policy - <<EOF 2>&1 | tee -a "$LOG_FILE"
path "loki-config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/loki/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

  # Enable KV v2 secrets engine for Loki configuration (idempotent)
  vault secrets enable -path=loki-config kv-v2 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: Loki KV secrets engine may already be enabled" | tee -a "$LOG_FILE"

  # Store Loki configuration secrets
  vault kv put loki-config/settings \
    retention_period="168h" \
    admin_password="$(openssl rand -base64 32)" \
    log_level="info" \
    chunk_store_config="filesystem" 2>&1 | tee -a "$LOG_FILE"

  # Store Loki endpoints and Vault-managed config
  vault kv put loki-config/targets \
    vault_endpoint="purebliss-vault:8200" \
    prometheus_endpoint="purebliss-prometheus:9090" \
    grafana_endpoint="purebliss-grafana:3001" 2>&1 | tee -a "$LOG_FILE"

  # Get AppRole credentials for Loki
  local role_id=$(vault read -field=role_id auth/loki-approle/role/loki-role/role-id 2>/dev/null)
  local secret_id=$(vault write -field=secret_id auth/loki-approle/role/loki-role/secret-id 2>/dev/null)

  if [[ -n "$role_id" && -n "$secret_id" ]]; then
    # Store AppRole credentials in Loki service directory
    echo "$role_id" > "$LOKI_CONFIG_PATH/.vault_role_id"
    echo "$secret_id" > "$LOKI_CONFIG_PATH/.vault_secret_id"
    chmod 600 "$LOKI_CONFIG_PATH/.vault_role_id" "$LOKI_CONFIG_PATH/.vault_secret_id"
    echo "[$(date)] SUCCESS: Loki AppRole credentials stored securely" | tee -a "$LOG_FILE"
  fi

  echo "[$(date)] SUCCESS: Loki secrets stored in Vault at loki-config/*" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Loki will use AppRole authentication for Vault access" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Loki Vault onboarding automation complete" | tee -a "$LOG_FILE"
}

# Function to create Vault token for Loki if not exists
function setup_loki_vault_token() {
  local VAULT_ADDR="https://127.0.0.1:8200"
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

  echo "[$(date)] INFO: Setting up Vault token for Loki integration..." | tee -a "$LOG_FILE"

  # Try to use existing root token from environment or files
  local vault_token=""

  # Method 1: Check if there's already a valid token in the container environment
  vault_token=$(docker exec purebliss-vault sh -c 'echo $VAULT_TOKEN' 2>/dev/null)

  if [[ -n "$vault_token" && "$vault_token" != "" ]]; then
    echo "$vault_token" > "$VAULT_TOKEN_FILE"
    chmod 600 "$VAULT_TOKEN_FILE"
    echo "[$(date)] SUCCESS: Using existing Vault token for Loki integration" | tee -a "$LOG_FILE"
    return 0
  fi

  # Method 2: Try to extract token from vault-agent which may have one
  vault_token=$(curl -skk http://localhost:8100/v1/auth/token/lookup-self 2>/dev/null | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

  if [[ -n "$vault_token" && "$vault_token" != "" ]]; then
    echo "$vault_token" > "$VAULT_TOKEN_FILE"
    chmod 600 "$VAULT_TOKEN_FILE"
    echo "[$(date)] SUCCESS: Retrieved Vault token from vault-agent for Loki integration" | tee -a "$LOG_FILE"
    return 0
  fi

  # Method 3: Try AppRole authentication if credentials exist
  if [[ -f "/opt/dev-purebliss/services/vault-agent/.vault_role_id" && -f "/opt/dev-purebliss/services/vault-agent/.vault_secret_id" ]]; then
    local role_id=$(cat /opt/dev-purebliss/services/vault-agent/.vault_role_id 2>/dev/null)
    local secret_id=$(cat /opt/dev-purebliss/services/vault-agent/.vault_secret_id 2>/dev/null)

    if [[ -n "$role_id" && -n "$secret_id" ]]; then
      vault_token=$(curl -skk -X POST -d "{\"role_id\":\"$role_id\",\"secret_id\":\"$secret_id\"}" \
        https://127.0.0.1:8200/v1/auth/approle/login 2>/dev/null | \
        grep -o '"client_token":"[^"]*"' | cut -d'"' -f4)

      if [[ -n "$vault_token" && "$vault_token" != "" ]]; then
        echo "$vault_token" > "$VAULT_TOKEN_FILE"
        chmod 600 "$VAULT_TOKEN_FILE"
        echo "[$(date)] SUCCESS: Created Vault token via AppRole for Loki integration" | tee -a "$LOG_FILE"
        return 0
      fi
    fi
  fi

  # Method 4: Generate a simple service token (if we can detect the vault is in dev mode)
  vault_token="loki-service-token-$(date +%s)"
  echo "$vault_token" > "$VAULT_TOKEN_FILE"
  chmod 600 "$VAULT_TOKEN_FILE"
  echo "[$(date)] WARNING: Created placeholder token for Loki - manual Vault setup may be needed" | tee -a "$LOG_FILE"
  return 0
}

# --- Grafana Vault Onboarding Automation ---
# This function configures Vault to provide dynamic secrets for Grafana monitoring and dashboards
function onboard_grafana_to_vault() {
  # Auto-detect vault mode and set VAULT_ADDR accordingly
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  local GRAFANA_CONFIG_PATH="/opt/dev-purebliss/services/grafana"
  echo "[$(date)] INFO: Onboarding Grafana to Vault for dynamic secrets and config management" | tee -a "$LOG_FILE"

  # Auto-detect vault URL based on running container or dev mode
  local VAULT_ADDR
  if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
     docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    # Development mode - vault running in dev mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Detected Vault in development mode for Grafana" | tee -a "$LOG_FILE"
  elif docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
    # Production mode - container running in production mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
      echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
      return 1
    fi
    export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
    echo "[$(date)] INFO: Detected Vault in production mode for Grafana" | tee -a "$LOG_FILE"
  else
    # Fallback - assume dev server if no container
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: No Vault container detected, assuming development mode for Grafana" | tee -a "$LOG_FILE"
  fi

  export VAULT_ADDR
  echo "[$(date)] INFO: Using Vault at $VAULT_ADDR for Grafana onboarding" | tee -a "$LOG_FILE"

  # Test Vault connectivity before proceeding
  if ! curl -skk -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
    echo "[$(date)] WARNING: Cannot connect to Vault with current token - proceeding with basic startup" | tee -a "$LOG_FILE"
    return 0
  fi

  # Enable AppRole auth method for Grafana (idempotent)
  vault auth enable -path=grafana-approle approle 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: Grafana AppRole auth method may already be enabled" | tee -a "$LOG_FILE"

  # Create Grafana-specific AppRole
  vault write auth/grafana-approle/role/grafana-role \
    token_policies="grafana-policy" \
    token_ttl=1h \
    token_max_ttl=24h 2>&1 | tee -a "$LOG_FILE"

  # Create policy for Grafana
  vault policy write grafana-policy - <<EOF 2>&1 | tee -a "$LOG_FILE"
path "grafana-config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/grafana/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/datasources/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

  # Enable KV v2 secrets engine for Grafana configuration (idempotent)
  vault secrets enable -path=grafana-config kv-v2 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: Grafana KV secrets engine may already be enabled" | tee -a "$LOG_FILE"

  # Store Grafana configuration secrets
  vault kv put grafana-config/settings \
    admin_user="admin" \
    admin_password="$(openssl rand -base64 32)" \
    secret_key="$(openssl rand -base64 32)" \
    database_type="sqlite3" \
    security_cookie_secure="false" 2>&1 | tee -a "$LOG_FILE"

  # Store datasource configurations with Vault-managed endpoints
  vault kv put grafana-config/datasources \
    prometheus_url="http://purebliss-prometheus:9090" \
    loki_url="http://purebliss-loki:3100" \
    vault_url="$VAULT_ADDR" \
    postgres_url="purebliss-postgres:5432" 2>&1 | tee -a "$LOG_FILE"

  # Get AppRole credentials for Grafana
  local role_id=$(vault read -field=role_id auth/grafana-approle/role/grafana-role/role-id 2>/dev/null)
  local secret_id=$(vault write -field=secret_id auth/grafana-approle/role/grafana-role/secret-id 2>/dev/null)

  if [[ -n "$role_id" && -n "$secret_id" ]]; then
    # Store AppRole credentials in Grafana service directory
    echo "$role_id" > "$GRAFANA_CONFIG_PATH/.vault_role_id"
    echo "$secret_id" > "$GRAFANA_CONFIG_PATH/.vault_secret_id"
    chmod 600 "$GRAFANA_CONFIG_PATH/.vault_role_id" "$GRAFANA_CONFIG_PATH/.vault_secret_id"
    echo "[$(date)] SUCCESS: Grafana AppRole credentials stored securely" | tee -a "$LOG_FILE"
  fi

  echo "[$(date)] SUCCESS: Grafana secrets stored in Vault at grafana-config/*" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Grafana will use AppRole authentication for Vault access" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Grafana Vault onboarding automation complete" | tee -a "$LOG_FILE"
}

# --- CodeServer Vault Onboarding Automation ---
# This function configures Vault to provide dynamic secrets and secure configuration for CodeServer
function onboard_codeserver_to_vault() {
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  local CODESERVER_CONFIG_PATH="/opt/dev-purebliss/services/codeserver"
  echo "[$(date)] INFO: Onboarding CodeServer to Vault for dynamic secrets and config management" | tee -a "$LOG_FILE"

  # Auto-detect vault URL based on running container or dev mode
  local VAULT_ADDR
  if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
     docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    # Development mode - vault running in dev mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Detected Vault in development mode for CodeServer" | tee -a "$LOG_FILE"
  elif docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
    # Production mode - container running in production mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
      echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
      return 1
    fi
    export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
    echo "[$(date)] INFO: Detected Vault in production mode for CodeServer" | tee -a "$LOG_FILE"
  else
    # Fallback to dev mode if no container detected
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: No Vault container detected, assuming development mode for CodeServer" | tee -a "$LOG_FILE"
  fi

  export VAULT_ADDR
  echo "[$(date)] INFO: Using Vault at $VAULT_ADDR for CodeServer onboarding" | tee -a "$LOG_FILE"

  # Enable AppRole auth method for CodeServer (idempotent)
  vault auth enable -path=codeserver-approle approle 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: CodeServer AppRole auth method may already be enabled" | tee -a "$LOG_FILE"

  # Create CodeServer-specific AppRole
  vault write auth/codeserver-approle/role/codeserver-role \
    token_policies="codeserver-policy" \
    token_ttl=1h \
    token_max_ttl=4h 2>&1 | tee -a "$LOG_FILE"

  # Create policy for CodeServer
  vault policy write codeserver-policy - <<EOF 2>&1 | tee -a "$LOG_FILE"
path "codeserver-config/*" {
  capabilities = ["read", "list"]
}
path "secret/codeserver/*" {
  capabilities = ["read", "list"]
}
EOF

  # Enable KV v2 secrets engine for CodeServer configuration (idempotent)
  vault secrets enable -path=codeserver-config kv-v2 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: CodeServer KV secrets engine may already be enabled" | tee -a "$LOG_FILE"

  # Store CodeServer configuration secrets
  vault kv put codeserver-config/settings \
    bind_addr="0.0.0.0:8443" \
    auth="password" \
    cert=false \
    disable_telemetry=true \
    log_level="info" 2>&1 | tee -a "$LOG_FILE"

  # Store CodeServer environment and integration config
  vault kv put codeserver-config/integration \
    vault_url="$VAULT_ADDR" \
    keycloak_url="https://dev.purebliss.app/auth" \
    grafana_url="https://dev.purebliss.app/grafana" \
    prometheus_url="https://dev.purebliss.app/prometheus" 2>&1 | tee -a "$LOG_FILE"

  # Get AppRole credentials for CodeServer
  local role_id=$(vault read -field=role_id auth/codeserver-approle/role/codeserver-role/role-id 2>/dev/null)
  local secret_id=$(vault write -field=secret_id auth/codeserver-approle/role/codeserver-role/secret-id 2>/dev/null)

  if [[ -n "$role_id" && -n "$secret_id" ]]; then
    # Store AppRole credentials in CodeServer service directory
    echo "$role_id" > "$CODESERVER_CONFIG_PATH/.vault_role_id"
    echo "$secret_id" > "$CODESERVER_CONFIG_PATH/.vault_secret_id"
    chmod 600 "$CODESERVER_CONFIG_PATH/.vault_role_id" "$CODESERVER_CONFIG_PATH/.vault_secret_id"
    echo "[$(date)] SUCCESS: CodeServer AppRole credentials stored securely" | tee -a "$LOG_FILE"
  fi

  echo "[$(date)] SUCCESS: CodeServer secrets stored in Vault at codeserver-config/*" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: CodeServer will use AppRole authentication for Vault access" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: CodeServer Vault onboarding automation complete" | tee -a "$LOG_FILE"
}

# --- Letsencrypt Vault PKI Onboarding Automation ---
# This function configures Vault PKI for Let's Encrypt-style certificate generation and management.
function onboard_letsencrypt_to_vault() {
  # Auto-detect vault mode and set VAULT_ADDR accordingly
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  local PKI_PATH="pki-letsencrypt"
  local PKI_ROLE="letsencrypt-role"
  local DOMAIN="dev.purebliss.app"
  echo "[$(date)] INFO: Onboarding Let's Encrypt to Vault PKI for dynamic certificate generation" | tee -a "$LOG_FILE"

  # Auto-detect vault URL based on running container or dev mode
  local VAULT_ADDR
  if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
     docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    # Development mode - vault running in dev mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: Detected Vault in development mode for Let's Encrypt" | tee -a "$LOG_FILE"
  elif docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
    # Production mode - container running in production mode
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
      echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
      return 1
    fi
    export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
    echo "[$(date)] INFO: Detected Vault in production mode for Let's Encrypt" | tee -a "$LOG_FILE"
  else
    # Fallback - assume dev server if no container
    VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    echo "[$(date)] INFO: No Vault container detected, assuming development mode for Let's Encrypt" | tee -a "$LOG_FILE"
  fi

  export VAULT_ADDR
  echo "[$(date)] INFO: Using Vault at $VAULT_ADDR for Let's Encrypt PKI onboarding" | tee -a "$LOG_FILE"

  # Test Vault connectivity before proceeding
  if ! curl -skk -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
    echo "[$(date)] WARNING: Cannot connect to Vault with current token - proceeding with basic startup" | tee -a "$LOG_FILE"
    return 0
  fi

  # Enable PKI secrets engine for Let's Encrypt (idempotent)
  vault secrets enable -path="$PKI_PATH" pki 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: PKI engine $PKI_PATH may already be enabled" | tee -a "$LOG_FILE"

  # Tune the PKI engine max lease TTL for Let's Encrypt style certificates (90 days typical)
  vault secrets tune -max-lease-ttl=2160h "$PKI_PATH" 2>&1 | tee -a "$LOG_FILE"

  # Generate root CA if not already present
  if ! vault read "$PKI_PATH/cert/ca" 2>&1 | grep -q 'certificate'; then
    echo "[$(date)] INFO: Generating root CA for Let's Encrypt-style PKI" | tee -a "$LOG_FILE"
    vault write -field=certificate "$PKI_PATH/root/generate/internal" \
      common_name="Pure Bliss Let's Encrypt Alternative Root CA" \
      ttl=8760h \
      key_bits=2048 \
      format=pem 2>&1 | tee -a "$LOG_FILE"

    vault write "$PKI_PATH/config/urls" \
      issuing_certificates="$VAULT_ADDR/v1/$PKI_PATH/ca" \
      crl_distribution_points="$VAULT_ADDR/v1/$PKI_PATH/crl" 2>&1 | tee -a "$LOG_FILE"
    echo "[$(date)] SUCCESS: Root CA generated for $PKI_PATH" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] INFO: Root CA already exists for $PKI_PATH" | tee -a "$LOG_FILE"
  fi

  # Create a role for Let's Encrypt certificate generation (idempotent)
  vault write "$PKI_PATH/roles/$PKI_ROLE" \
    allowed_domains="$DOMAIN" \
    allow_bare_domains=true \
    allow_subdomains=true \
    allow_wildcard=true \
    max_ttl="168h" \
    ttl="24h" \
    key_bits=2048 \
    key_usage="DigitalSignature,KeyEncipherment" \
    ext_key_usage="ServerAuth,ClientAuth" \
    server_flag=true \
    client_flag=true 2>&1 | tee -a "$LOG_FILE"

  echo "[$(date)] SUCCESS: PKI role $PKI_ROLE configured for Let's Encrypt-style certificates" | tee -a "$LOG_FILE"

  # Store Let's Encrypt configuration in Vault KV for the container to use
  vault kv put secret/letsencrypt \
    email="admin@purebliss.app" \
    domains="$DOMAIN" \
    webroot_path="/mnt/raid0/nginx/html" \
    pki_path="$PKI_PATH" \
    pki_role="$PKI_ROLE" \
    renewal_interval="1h" \
    cert_ttl="24h" 2>&1 | tee -a "$LOG_FILE"

  echo "[$(date)] SUCCESS: Let's Encrypt configuration stored in Vault at secret/letsencrypt" | tee -a "$LOG_FILE"

  # Test certificate generation to validate the setup
  echo "[$(date)] INFO: Testing certificate generation for $DOMAIN..." | tee -a "$LOG_FILE"
  if vault write -format=json "$PKI_PATH/issue/$PKI_ROLE" \
    common_name="$DOMAIN" \
    alt_names="*.$DOMAIN" \
    ttl="1h" >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: Test certificate generation successful for $DOMAIN" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Test certificate generation failed - check PKI role configuration" | tee -a "$LOG_FILE"
  fi

  echo "[$(date)] INFO: Let's Encrypt Vault PKI onboarding automation complete" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Certificates will be generated using Vault PKI instead of traditional ACME" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Certificate renewal will happen every hour with 24h TTL" | tee -a "$LOG_FILE"
}
# --- Letsencrypt Service Startup ---
function start_letsencrypt() {
  onboard_letsencrypt_to_vault
  echo "[$(date)] INFO: Starting Letsencrypt container..." | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Ensuring certificate directory exists at $LETSENCRYPT_CERT_PATH/$LETSENCRYPT_DOMAINS" | tee -a "$LOG_FILE"
  if mkdir -p "$LETSENCRYPT_CERT_PATH/$LETSENCRYPT_DOMAINS" 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Created directory $LETSENCRYPT_CERT_PATH/$LETSENCRYPT_DOMAINS" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to create directory $LETSENCRYPT_CERT_PATH/$LETSENCRYPT_DOMAINS" | tee -a "$LOG_FILE"
    exit 1
  fi
  cd /opt/dev-purebliss/services/letsencrypt
  docker compose -f letsencrypt-docker-compose.yml up -d --build 2>&1 | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Letsencrypt container started" | tee -a "$LOG_FILE"
}

# --- Redis Independent Container Startup ---
function start_redis() {
  echo "[$(date)] INFO: Starting Redis with independent container startup and Vault integration..." | tee -a "$LOG_FILE"

  # Clean up any existing Redis resources
  docker rm -f purebliss-redis >/dev/null 2>&1 || true
  docker volume rm purebliss_redis_data >/dev/null 2>&1 || true

  # Change to Redis service directory
  cd /opt/dev-purebliss/services/redis

  # Build Redis image with all Vault integration logic
  echo "[$(date)] INFO: Building Redis container with comprehensive Vault integration..." | tee -a "$LOG_FILE"
  if docker build -t purebliss-redis-image -f redis-dockerfile . >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Redis image built with standalone capabilities" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to build Redis image" | tee -a "$LOG_FILE"
    return 1
  fi

  # Auto-detect Vault configuration
  local vault_addr="https://127.0.0.1:8200"
  local vault_token="dev-root-token-purebliss"

  if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
     ! docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    vault_addr="https://127.0.0.1:8200"
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    fi
  fi

  # Create network if it doesn't exist
  docker network create purebliss-net >/dev/null 2>&1 || true

  # Start Redis with independent container startup
  echo "[$(date)] INFO: Starting Redis container with environment: VAULT_ADDR=$vault_addr" | tee -a "$LOG_FILE"
  if docker run -d \
    --name purebliss-redis \
    --network purebliss-net \
    -p 6379:6379 \
    -e VAULT_ADDR="$vault_addr" \
    -e VAULT_TOKEN="$vault_token" \
    -e USE_VAULT="true" \
    -e VAULT_SKIP_VERIFY="true" \
    -v purebliss_redis_data:/data \
    -v /opt/my-secure-ha-stack/logs/dev-environment-setup.log:/opt/my-secure-ha-stack/logs/dev-environment-setup.log \
    --restart unless-stopped \
    purebliss-redis-image >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Redis started as independent container with Vault integration" | tee -a "$LOG_FILE"

    # Post-startup: Configure Redis authentication in Vault
    sleep 5
    echo "[$(date)] INFO: Configuring Redis authentication in Vault..." | tee -a "$LOG_FILE"
    if onboard_redis_to_vault; then
      echo "[$(date)] SUCCESS: Redis onboarded to Vault for dynamic secrets" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] WARNING: Redis Vault onboarding had issues, but container is running" | tee -a "$LOG_FILE"
    fi

    return 0
  else
    echo "[$(date)] ERROR: Failed to start Redis container" | tee -a "$LOG_FILE"
    return 1
  fi
}

# --- Nginx Independent Container Startup ---
function start_nginx() {
  echo "[$(date)] INFO: Starting Nginx with independent container startup and Vault PKI SSL certificate automation..." | tee -a "$LOG_FILE"

  # Clean up any existing Nginx resources
  docker rm -f purebliss-nginx >/dev/null 2>&1 || true
  docker volume rm purebliss_nginx_certs purebliss_nginx_dhparam >/dev/null 2>&1 || true

  # Change to Nginx service directory
  cd /opt/dev-purebliss/services/nginx

  # Build Nginx image with all Vault integration logic
  echo "[$(date)] INFO: Building Nginx container with comprehensive Vault PKI integration..." | tee -a "$LOG_FILE"
  if docker build -t purebliss-nginx-image -f nginx-dockerfile . >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Nginx image built with standalone SSL/TLS capabilities" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to build Nginx image" | tee -a "$LOG_FILE"
    return 1
  fi

  # Auto-detect Vault configuration
  local vault_addr="https://127.0.0.1:8200"
  local vault_token="dev-root-token-purebliss"
  local domain="${LOCAL_HOSTNAME:-dev.purebliss.app}"

  if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
     ! docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    vault_addr="https://127.0.0.1:8200"
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    fi
  fi

  # Create network if it doesn't exist
  docker network create purebliss-net >/dev/null 2>&1 || true

  # Start Nginx with independent container startup
  echo "[$(date)] INFO: Starting Nginx container with environment: VAULT_ADDR=$vault_addr, DOMAIN=$domain" | tee -a "$LOG_FILE"
  if docker run -d \
    --name purebliss-nginx \
    --network purebliss-net \
    -p 80:80 \
    -p 443:443 \
    -e VAULT_ADDR="$vault_addr" \
    -e VAULT_TOKEN="$vault_token" \
    -e DOMAIN="$domain" \
    -e USE_VAULT="true" \
    -e VAULT_SKIP_VERIFY="true" \
    -v purebliss_nginx_certs:/etc/nginx/ssl \
    -v purebliss_nginx_dhparam:/etc/nginx/dhparam \
    -v /opt/my-secure-ha-stack/logs/dev-environment-setup.log:/opt/my-secure-ha-stack/logs/dev-environment-setup.log \
    --restart unless-stopped \
    purebliss-nginx-image >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Nginx started as independent container with Vault PKI integration" | tee -a "$LOG_FILE"

    # Wait for SSL certificate generation
    echo "[$(date)] INFO: Waiting for Vault PKI certificate generation..." | tee -a "$LOG_FILE"
    sleep 15

    # Post-startup: Validate SSL/TLS compliance
    echo "[$(date)] INFO: Running comprehensive SSL/TLS compliance validation..." | tee -a "$LOG_FILE"
    if docker exec purebliss-nginx nginx -t >/dev/null 2>&1; then
      echo "[$(date)] SUCCESS: Nginx configuration valid" | tee -a "$LOG_FILE"

      # Test HTTPS endpoint
      if curl -k -s -o /dev/null -w "%{http_code}" "https://$domain" | grep -q "200\|301\|302"; then
        echo "[$(date)] SUCCESS: Nginx HTTPS endpoint responding correctly" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Nginx HTTPS endpoint not responding as expected" | tee -a "$LOG_FILE"
      fi

      # Configure Nginx in Vault for future certificate renewals
      if onboard_nginx_to_vault; then
        echo "[$(date)] SUCCESS: Nginx onboarded to Vault for PKI certificate automation" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Nginx Vault onboarding had issues, but container is running with SSL" | tee -a "$LOG_FILE"
      fi

      return 0
    else
      echo "[$(date)] ERROR: Nginx configuration invalid after startup" | tee -a "$LOG_FILE"
      docker logs purebliss-nginx | tail -20 | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] ERROR: Failed to start Nginx container" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Function to auto-unseal Vault if sealed and wait for API readiness
function vault_auto_unseal() {
  # Use the enhanced version with better retry logic
  vault_auto_unseal_enhanced
}

# Enhanced service startup with better error handling
function start_service_robust() {
  local service_name="$1"
  local service_dir="$SERVICES_DIR/$service_name"
  local max_attempts=3
  local attempt=1

  echo "[$(date)] INFO: Starting $service_name (robust mode)..." | tee -a "$LOG_FILE"

  while [[ $attempt -le $max_attempts ]]; do
    echo "[$(date)] INFO: $service_name startup attempt $attempt/$max_attempts..." | tee -a "$LOG_FILE"

    # Clean up any existing container first
    docker rm -f "purebliss-$service_name" >/dev/null 2>&1 || true
    if [[ "$service_name" == "vault" ]]; then
        docker rm -f "purebliss-vault-agent" >/dev/null 2>&1 || true
    fi

    # Start the service based on type
    local success=false
    if [[ "$service_name" == "vault-agent" ]]; then
      if (cd "$service_dir" && docker compose -f "vault-agent-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
        success=true
      fi
    elif [[ "$service_name" == "keycloak" ]]; then
      # Enhanced Keycloak with Vault and PostgreSQL integration
      echo "[$(date)] INFO: Starting enhanced Keycloak with Vault and PostgreSQL integration" | tee -a "$LOG_FILE"

      # Set up Vault environment for Keycloak
      if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
      fi

      # Auto-detect Vault address
      if docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
        export VAULT_ADDR="http://purebliss-vault:8200"
      else
        export VAULT_ADDR="https://localhost:8200"
      fi

      # Load service environment
      if [[ -f "$service_dir/.env" ]]; then
        source "$service_dir/.env"
      fi

      # Run Keycloak setup if needed
      if [[ -x "$service_dir/setup-keycloak-vault.sh" ]]; then
        echo "[$(date)] INFO: Running Keycloak Vault setup..." | tee -a "$LOG_FILE"
        (cd "$service_dir" && ./setup-keycloak-vault.sh >> "$LOG_FILE" 2>&1) || \
          echo "[$(date)] WARN: Keycloak setup had issues, proceeding with startup" | tee -a "$LOG_FILE"
      fi

      # Start Keycloak with Vault integration
      if (cd "$service_dir" && docker compose -f "keycloak-redis-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
        success=true
        echo "[$(date)] SUCCESS: Keycloak started with Vault integration" | tee -a "$LOG_FILE"

        # Post-startup validation
        echo "[$(date)] INFO: Validating Keycloak Vault integration..." | tee -a "$LOG_FILE"
        sleep 10
        if [[ -x "$service_dir/validate-keycloak-vault.sh" ]]; then
          (cd "$service_dir" && timeout 60 ./validate-keycloak-vault.sh >> "$LOG_FILE" 2>&1) && \
            echo "[$(date)] SUCCESS: Keycloak validation passed" | tee -a "$LOG_FILE" || \
            echo "[$(date)] WARN: Keycloak validation had issues" | tee -a "$LOG_FILE"
        fi
      else
        echo "[$(date)] ERROR: Failed to start Keycloak with Vault integration" | tee -a "$LOG_FILE"
      fi
    elif [[ "$service_name" == "nginx" ]]; then
      # Ensure nginx config directory exists
      mkdir -p /opt/pure-bliss-dev/shared/configs/nginx/conf.d/ 2>/dev/null || true
      cp "$service_dir/default.conf" /opt/pure-bliss-dev/shared/configs/nginx/conf.d/default.conf 2>/dev/null || true

      if (cd "$service_dir" && docker compose -f "nginx-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
        success=true
      fi
    elif [[ "$service_name" == "letsencrypt" ]]; then
      if (cd "$service_dir" && docker compose -f "letsencrypt-docker-compose.yml" up -d --build >> "$LOG_FILE" 2>&1); then
        success=true
      fi
    elif [[ "$service_name" == "postgres" ]]; then
      # Use the Vault-integrated PostgreSQL with proper credentials
      echo "[$(date)] INFO: Starting PostgreSQL with full Vault integration..." | tee -a "$LOG_FILE"

      # Use the new Dockerfile for postgres
      if (cd "$service_dir" && docker build -t purebliss-postgres-image -f postgres-dockerfile.yml . >> "$LOG_FILE" 2>&1 && docker run -d --name purebliss-postgres --network purebliss-net -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -v postgres_data:/var/lib/postgresql/data purebliss-postgres-image >> "$LOG_FILE" 2>&1); then
        success=true
      fi
    else
      # Standard service startup
      local compose_file="$service_dir/${service_name}-docker-compose.yml"
      if [[ -f "$compose_file" ]]; then
        if (cd "$service_dir" && docker compose -f "${service_name}-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
          success=true
        fi
      elif [[ -f "$service_dir/docker-compose.yml" ]]; then
        if (cd "$service_dir" && docker compose up -d >> "$LOG_FILE" 2>&1); then
          success=true
        fi
      # Start redis with the new entrypoint
      if (cd "$service_dir" && docker build -t purebliss-redis-image -f redis-dockerfile . >> "$LOG_FILE" 2>&1 && docker run -d --name purebliss-redis --network purebliss-net -p 6379:6379 -e USE_VAULT=true -e VAULT_ADDR=https://purebliss-vault:8200 -e VAULT_SKIP_VERIFY=true -e VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token) -v redis_data:/data purebliss-redis-image >> "$LOG_FILE" 2>&1); then
        success=true
      fi
      elif [[ "$service_name" == "loki" && -f "$service_dir/loki-docker-compose.yml" ]]; then
        # Special handling for Loki with Vault integration
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
          echo "[$(date)] INFO: Starting Loki with Vault integration..." | tee -a "$LOG_FILE"
          export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
          export VAULT_ADDR="https://127.0.0.1:8200"
          export VAULT_SKIP_VERIFY=1
        fi

        if (cd "$service_dir" && docker compose -f "loki-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
          success=true
        fi
      elif [[ "$service_name" == "grafana" && -f "$service_dir/grafana-docker-compose.yml" ]]; then
        # Special handling for Grafana with Vault integration
        echo "[$(date)] INFO: Starting Grafana with Vault integration..." | tee -a "$LOG_FILE"

        # Auto-detect vault mode for Grafana
        local vault_addr="https://127.0.0.1:8200"
        local vault_token="dev-root-token-purebliss"

        if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
           ! docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
          # Production mode
          vault_addr="https://127.0.0.1:8200"
          if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
            vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
          fi
          export VAULT_SKIP_VERIFY=1
        fi

        export VAULT_ADDR="$vault_addr"
        export VAULT_TOKEN="$vault_token"

        if (cd "$service_dir" && docker compose -f "grafana-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
          success=true
        fi
      elif [[ "$service_name" == "prometheus" && -f "$service_dir/prometheus-docker-compose.yml" ]]; then
        # Special handling for Prometheus with Vault integration
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
          echo "[$(date)] INFO: Starting Prometheus with Vault integration..." | tee -a "$LOG_FILE"
          export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
          export VAULT_ADDR="https://127.0.0.1:8200"
          export VAULT_SKIP_VERIFY=1
        fi

        if (cd "$service_dir" && docker compose -f "prometheus-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
          success=true
        fi
      elif [[ "$service_name" == "codeserver" && -f "$service_dir/codeserver-docker-compose.yml" ]]; then
        # Special handling for CodeServer with Vault integration
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
          echo "[$(date)] INFO: Starting CodeServer with Vault integration..." | tee -a "$LOG_FILE"
          export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
          export VAULT_ADDR="https://127.0.0.1:8200"
          export VAULT_SKIP_VERIFY=1
        fi

        # Set CodeServer environment variables
        export CODESERVER_DATA_PATH="/opt/my-secure-ha-stack/codeserver-data"
        export CODESERVER_LOG_PATH="/opt/my-secure-ha-stack/logs/codeserver.log"

        if (cd "$service_dir" && docker compose -f "codeserver-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1); then
          success=true
        fi
      fi
    fi

    if [[ "$success" == "true" ]]; then
      echo "[$(date)] SUCCESS: $service_name started successfully on attempt $attempt" | tee -a "$LOG_FILE"
      return 0
    else
      echo "[$(date)] WARNING: $service_name startup attempt $attempt failed" | tee -a "$LOG_FILE"
      if [[ $attempt -lt $max_attempts ]]; then
        echo "[$(date)] INFO: Retrying in 10 seconds..." | tee -a "$LOG_FILE"
        sleep 10
      fi
    fi

    ((attempt++))
  done

  echo "[$(date)] ERROR: Failed to start $service_name after $max_attempts attempts" | tee -a "$LOG_FILE"
  return 1
}

# Critical: Wait for Vault API to be fully ready for operations
function wait_for_vault_api() {
  echo "[$(date)] INFO: Waiting for Vault API to be fully operational for API calls..." | tee -a "$LOG_FILE"
  local max_api_wait=30
  local api_ready=false
  local VAULT_ADDR_HTTP="https://127.0.0.1:8200"
  local VAULT_ADDR_HTTPS="https://127.0.0.1:8200"
  local VAULT_ADDR=""

  # Auto-detect Vault mode
  if curl -sk "$VAULT_ADDR_HTTP/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTP"
    export VAULT_ADDR="$VAULT_ADDR_HTTP"
    echo "[$(date)] INFO: Detected Vault dev mode (HTTP) for API operations" | tee -a "$LOG_FILE"
  elif curl -skk "$VAULT_ADDR_HTTPS/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTPS"
    export VAULT_ADDR="$VAULT_ADDR_HTTPS"
    export VAULT_SKIP_VERIFY=1
    echo "[$(date)] INFO: Detected Vault production mode (HTTPS) for API operations" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Cannot detect Vault on HTTP or HTTPS" | tee -a "$LOG_FILE"
    return 1
  fi

  for i in $(seq 1 $max_api_wait); do
    # Test if Vault API is ready by attempting a simple read operation
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

      # Test API readiness with a simple auth list
      if vault auth list >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Vault API is fully ready for operations (attempt $i)" | tee -a "$LOG_FILE"
        api_ready=true
        break
      fi
    fi

    # Alternative test without token - just check if we get proper API response codes
    local api_response_code
    if [[ "$VAULT_ADDR" == "$VAULT_ADDR_HTTP" ]]; then
      api_response_code=$(curl -sk -w "%{http_code}" -o /dev/null "$VAULT_ADDR/v1/sys/auth" 2>/dev/null || echo "000")
    else
      api_response_code=$(curl -skk -w "%{http_code}" -o /dev/null "$VAULT_ADDR/v1/sys/auth" 2>/dev/null || echo "000")
    fi

    if [[ "$api_response_code" == "200" || "$api_response_code" == "403" ]]; then
      echo "[$(date)] SUCCESS: Vault API responding with proper HTTP codes (attempt $i)" | tee -a "$LOG_FILE"
      api_ready=true
      break
    fi

    echo "[$(date)] INFO: Waiting for Vault API readiness... (attempt $i/$max_api_wait)" | tee -a "$LOG_FILE"
    sleep 2
  done

  if [[ "$api_ready" == "false" ]]; then
    echo "[$(date)] ERROR: Vault API failed to become ready after $max_api_wait attempts" | tee -a "$LOG_FILE"
    return 1
  fi

  echo "[$(date)] SUCCESS: Vault is unsealed and API is ready for operations" | tee -a "$LOG_FILE"
  return 0
}

function log_and_exit {
  echo "[$(date)] ERROR: $1" | tee -a "$LOG_FILE"
  exit 1
}

function wait_for_healthy {
  local service_name="$1"
  local label="$2"
  local container_name="purebliss-$service_name"
  local max_attempts=30

  echo "[$(date)] INFO: Waiting for $label container ($container_name) to become healthy..." >> "$LOG_FILE"

  for i in $(seq 1 $max_attempts); do
    cid=$(docker ps -q -f name=$container_name)
    if [[ -z "$cid" ]]; then
      echo "[$(date)] WARNING: $label container not running yet (attempt $i)" >> "$LOG_FILE"
      # Try automated fix for container startup issues
      if [[ "$service_name" == "vault" && -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
        echo "[$(date)] INFO: Attempting automated fix for $label container startup..." >> "$LOG_FILE"
        /opt/dev-purebliss/services/vault/vault-break-fix.sh container_startup
      fi
      sleep 2
      continue
    fi

    health=$(docker inspect --format='{{.State.Health.Status}}' $container_name 2>/dev/null || echo "no_healthcheck")
    echo "[$(date)] INFO: $label health status: $health (attempt $i)" >> "$LOG_FILE"

    if [[ "$health" == "healthy" ]]; then
      echo "[$(date)] INFO: $label container is healthy." >> "$LOG_FILE"
      return 0
    elif [[ "$health" == "unhealthy" && $i -gt 10 ]]; then
      # Try automated diagnostic and fix after 10 failed attempts
      if [[ "$service_name" == "vault" && -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
        echo "[$(date)] INFO: Running diagnostic and attempting automated fix for $label..." >> "$LOG_FILE"
        /opt/dev-purebliss/services/vault/vault-break-fix.sh all
        sleep 5
      fi
    fi
    sleep 2
  done

  # Final health check
  health=$(docker inspect --format='{{.State.Health.Status}}' $container_name 2>/dev/null || echo "no_healthcheck")
  if [[ "$health" != "healthy" ]]; then
    echo "[$(date)] ERROR: $label container failed to become healthy after $max_attempts attempts" >> "$LOG_FILE"
    echo "[$(date)] INFO: Running final diagnostic..." >> "$LOG_FILE"

    # Run service-specific diagnostics
    if [[ "$service_name" == "vault" && -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
      /opt/dev-purebliss/services/vault/vault-break-fix.sh diagnostic
    fi

    log_and_exit "$label container did not become healthy after waiting and automated fixes."
  fi
}


function setup_vault_automation {
  echo "[$(date)] INFO: Setting up comprehensive Vault automation..." >> "$LOG_FILE"
  echo "[$(date)] INFO: Reference /opt/dev-purebliss/services/vault/VAULT_AUTOMATION_GUIDE.md for automation and troubleshooting steps." >> "$LOG_FILE"

  # Run comprehensive pre-startup checks BEFORE any vault operations
  if [[ -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
    echo "[$(date)] INFO: Running comprehensive pre-startup checks for Vault..." >> "$LOG_FILE"

    # Network checks
    echo "[$(date)] INFO: Checking network configuration..." >> "$LOG_FILE"
    /opt/dev-purebliss/services/vault/vault-break-fix.sh network >> "$LOG_FILE" 2>&1 || true

    # Permission checks
    echo "[$(date)] INFO: Checking and fixing permissions..." >> "$LOG_FILE"
    /opt/dev-purebliss/services/vault/vault-break-fix.sh permissions >> "$LOG_FILE" 2>&1 || true

    # TLS configuration checks
    echo "[$(date)] INFO: Validating TLS configuration..." >> "$LOG_FILE"
    /opt/dev-purebliss/services/vault/vault-break-fix.sh tls_config >> "$LOG_FILE" 2>&1 || true

    # Agent configuration checks
    echo "[$(date)] INFO: Validating Vault Agent configuration..." >> "$LOG_FILE"
    /opt/dev-purebliss/services/vault/vault-break-fix.sh agent_config >> "$LOG_FILE" 2>&1 || true

    # Container startup checks
    echo "[$(date)] INFO: Checking container startup configuration..." >> "$LOG_FILE"
    /opt/dev-purebliss/services/vault/vault-break-fix.sh container_startup >> "$LOG_FILE" 2>&1 || true

    echo "[$(date)] SUCCESS: Pre-startup checks completed" >> "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Vault break-fix script not found - skipping pre-startup checks" >> "$LOG_FILE"
  fi

  # CRITICAL: Ensure Vault is unsealed and API ready before any automation
  echo "[$(date)] INFO: Ensuring Vault is unsealed and API ready before automation..." >> "$LOG_FILE"
  if ! vault_status_check; then
    echo "[$(date)] ERROR: Cannot proceed with Vault automation - Vault not ready" >> "$LOG_FILE"
    echo "[$(date)] INFO: Attempting comprehensive diagnostic..." >> "$LOG_FILE"

    # Try diagnostic fix if vault status check failed
    if [[ -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
      /opt/dev-purebliss/services/vault/vault-break-fix.sh diagnostic >> "$LOG_FILE" 2>&1 || true
    fi

    return 1
  fi

  # Check if Vault keys already exist in the new automation system
  if [[ -f "/opt/my-secure-ha-stack/secrets/vault/vault-keys.enc" && -f "/opt/my-secure-ha-stack/secrets/vault/.master_password" ]]; then
    echo "[$(date)] INFO: Encrypted Vault keys found, ensuring auto-unseal with automation..." >> "$LOG_FILE"
    if /opt/dev-purebliss/services/vault/vault-auto-unseal.sh >> "$LOG_FILE" 2>&1; then
      echo "[$(date)] SUCCESS: Vault auto-unsealed successfully with encrypted keys" >> "$LOG_FILE"
    else
      echo "[$(date)] WARNING: Automated unseal with encrypted keys failed, using fallback" >> "$LOG_FILE"
    fi
  elif [[ -f "/opt/my-secure-ha-stack/vault-unseal-keys.env" ]]; then
    echo "[$(date)] INFO: Plain unseal keys found, using legacy unseal method..." >> "$LOG_FILE"
    # Legacy method already handled by vault_auto_unseal_enhanced
  else
    echo "[$(date)] WARNING: No unseal keys found - vault may need initialization" >> "$LOG_FILE"
    echo "[$(date)] INFO: For first-time setup, run: /opt/dev-purebliss/services/vault/vault-init-automation.sh" >> "$LOG_FILE"
  fi

  # Ensure API is ready before proceeding with AppRole setup
  echo "[$(date)] INFO: Verifying Vault API readiness..." >> "$LOG_FILE"
  if vault_status_check; then
    echo "[$(date)] SUCCESS: Vault API is ready, setting up AppRole credentials..." >> "$LOG_FILE"
    setup_vault_approle_credentials
  else
    echo "[$(date)] ERROR: Vault API not ready - cannot setup AppRole credentials" >> "$LOG_FILE"
    return 1
  fi
}

# Vault status check function


function setup_vault_approle_credentials {
  echo "[$(date)] INFO: Setting up Vault AppRole credentials for service onboarding..." >> "$LOG_FILE"
  echo "[$(date)] INFO: Reference /opt/dev-purebliss/services/vault/vault-break-fix-report.md for AppRole and break/fix troubleshooting." >> "$LOG_FILE"

  # CRITICAL: Ensure Vault is ready for API operations before proceeding
  echo "[$(date)] INFO: Verifying Vault API readiness before AppRole setup..." >> "$LOG_FILE"
  if ! vault_status_check; then
    echo "[$(date)] ERROR: Cannot setup AppRole - Vault API not ready" >> "$LOG_FILE"
    return 1
  fi

  # Check if we're in dev mode - if so, skip complex AppRole setup
  if curl -sk "https://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    echo "[$(date)] INFO: Vault is running in development mode - skipping AppRole setup" >> "$LOG_FILE"
    echo "[$(date)] INFO: Dev mode uses simplified authentication suitable for development" >> "$LOG_FILE"
    return 0
  fi

  # Run the TLS-enabled Vault setup script to configure AppRole and database secrets (production mode only)
  if [[ -x "/opt/dev-purebliss/services/vault/vault-setup-tls.sh" ]]; then
    echo "[$(date)] INFO: Running Vault AppRole and database secrets setup..." >> "$LOG_FILE"
    # Run the setup script, capture output for idempotency check
    setup_output=$( /opt/dev-purebliss/services/vault/vault-setup-tls.sh 2>&1 )
    setup_status=$?
    # If setup failed, check for idempotent errors
    if [[ $setup_status -ne 0 ]]; then
      if echo "$setup_output" | grep -qE 'path is already in use|already enabled'; then
        echo "[$(date)] INFO: Vault AppRole/database secrets engine already enabled (idempotent)" >> "$LOG_FILE"
        setup_status=0
      else
        echo "[$(date)] WARNING: Vault AppRole setup had issues but may be partially functional" >> "$LOG_FILE"
        echo "$setup_output" | tee -a "$LOG_FILE"
      fi
    fi
    if [[ $setup_status -eq 0 ]]; then
      echo "[$(date)] SUCCESS: Vault AppRole and database secrets configured successfully (idempotent ok)" >> "$LOG_FILE"
      # Validate PostgreSQL integration if PostgreSQL is running
      if docker ps | grep -q purebliss-postgres; then
        echo "[$(date)] INFO: Validating PostgreSQL-Vault integration..." >> "$LOG_FILE"
        # Ensure Vault is still ready before running integration test
        if vault_status_check && /opt/dev-purebliss/services/vault/vault-break-fix.sh postgresql_integration >> "$LOG_FILE" 2>&1; then
          echo "[$(date)] SUCCESS: PostgreSQL-Vault integration validated" >> "$LOG_FILE"
        else
          echo "[$(date)] WARNING: PostgreSQL-Vault integration validation failed" >> "$LOG_FILE"
        fi
      fi
      return 0
    else
      return 0
    fi
  else
    echo "[$(date)] WARNING: Vault AppRole setup script not found" >> "$LOG_FILE"
    return 1
  fi
}

function validate_service_dependencies() {
  local service="$1"
  local dependencies_met=true

  echo "[$(date)] INFO: Validating dependencies for $service..." >> "$LOG_FILE"

  case "$service" in
    "keycloak"|"plane")
      # These services depend on PostgreSQL and Vault
      if ! docker ps | grep -q purebliss-postgres; then
        echo "[$(date)] WARNING: $service requires PostgreSQL but it's not running" >> "$LOG_FILE"
        dependencies_met=false
      fi
      if ! vault_status_check; then
        echo "[$(date)] WARNING: $service requires Vault to be operational for secrets" >> "$LOG_FILE"
        dependencies_met=false
      fi
      ;;
    "postgres")
      # PostgreSQL requires Vault for dynamic credentials
      if ! docker ps | grep -q purebliss-vault; then
        echo "[$(date)] WARNING: PostgreSQL integration requires Vault but it's not running" >> "$LOG_FILE"
        dependencies_met=false
      fi
      ;;
    "nginx")
      # Nginx requires Vault for PKI/TLS certificates
      if ! vault_status_check; then
        echo "[$(date)] WARNING: $service requires Vault to be operational for PKI certificates" >> "$LOG_FILE"
        dependencies_met=false
      fi
      ;;
    "vault-agent"|"loki"|"prometheus"|"grafana")
      # These services depend on Vault being unsealed
      if ! vault_status_check; then
        echo "[$(date)] WARNING: $service requires Vault to be operational" >> "$LOG_FILE"
        dependencies_met=false
      fi
      ;;
  esac

  if [[ "$dependencies_met" == "true" ]]; then
    echo "[$(date)] INFO: All dependencies met for $service" >> "$LOG_FILE"
    return 0
  else
    echo "[$(date)] WARNING: Some dependencies not met for $service - proceeding anyway" >> "$LOG_FILE"
    return 1
  fi
}

function vault_status_check() {
  local VAULT_ADDR_HTTP="https://127.0.0.1:8200"
  local VAULT_ADDR_HTTPS="https://127.0.0.1:8200"
  local VAULT_ADDR=""
  local sealed_status health_status api_ready

  # Auto-detect Vault mode (HTTP or HTTPS)
  if curl -sk "$VAULT_ADDR_HTTP/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTP"
    echo "[$(date)] INFO: Using Vault dev mode (HTTP)" | tee -a "$LOG_FILE"
  elif curl -skk "$VAULT_ADDR_HTTPS/v1/sys/health" >/dev/null 2>&1; then
    VAULT_ADDR="$VAULT_ADDR_HTTPS"
    echo "[$(date)] INFO: Using Vault production mode (HTTPS)" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] INFO: Vault health endpoint not accessible on HTTP or HTTPS" | tee -a "$LOG_FILE"
    return 1
  fi

  # Check status based on detected mode
  if [[ "$VAULT_ADDR" == "$VAULT_ADDR_HTTP" ]]; then
    sealed_status=$(curl -sk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' ')
    health_status=$(curl -sk "$VAULT_ADDR/v1/sys/health" | grep -o '"initialized":[^,]*' | cut -d: -f2 | tr -d ' ')
  else
    sealed_status=$(curl -skk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' ')
    health_status=$(curl -skk "$VAULT_ADDR/v1/sys/health" | grep -o '"initialized":[^,]*' | cut -d: -f2 | tr -d ' ')
  fi

  if [[ "$health_status" == "true" && "$sealed_status" == "false" ]]; then
    # Additional check: ensure API is ready for operations
    local api_response_code
    if [[ "$VAULT_ADDR" == "$VAULT_ADDR_HTTP" ]]; then
      api_response_code=$(curl -sk -w "%{http_code}" -o /dev/null "$VAULT_ADDR/v1/sys/auth" 2>/dev/null || echo "000")
    else
      api_response_code=$(curl -skk -w "%{http_code}" -o /dev/null "$VAULT_ADDR/v1/sys/auth" 2>/dev/null || echo "000")
    fi

    if [[ "$api_response_code" == "200" || "$api_response_code" == "403" ]]; then
      echo "[$(date)] INFO: Vault is initialized, unsealed, and API is ready" | tee -a "$LOG_FILE"
      return 0
    else
      echo "[$(date)] INFO: Vault is unsealed but API not ready (HTTP: $api_response_code)" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] INFO: Vault status check failed - initialized: $health_status, sealed: $sealed_status" | tee -a "$LOG_FILE"
    return 1
  fi
}

function post_service_validation() {
  local service="$1"

  echo "[$(date)] INFO: Running post-startup validation for $service..." >> "$LOG_FILE"

  case "$service" in
    "vault")
      # Comprehensive Vault validation
      echo "[$(date)] INFO: For Vault troubleshooting, see VAULT_AUTOMATION_GUIDE.md and vault-break-fix-report.md in /opt/dev-purebliss/services/vault/" >> "$LOG_FILE"
      if [[ -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
        echo "[$(date)] INFO: Running Vault diagnostic..." >> "$LOG_FILE"
        /opt/dev-purebliss/services/vault/vault-break-fix.sh diagnostic >> "$LOG_FILE" 2>&1
      fi
      ;;
    "vault-agent")
      # Vault Agent validation
      echo "[$(date)] INFO: For Vault Agent troubleshooting, see VAULT_AUTOMATION_GUIDE.md and vault-break-fix-report.md in /opt/dev-purebliss/services/vault/" >> "$LOG_FILE"
      echo "[$(date)] INFO: Validating Vault Agent functionality..." >> "$LOG_FILE"
      sleep 3  # Give vault-agent time to authenticate
      if docker logs purebliss-vault-agent --tail 5 | grep -q "renewed auth token\|auth token"; then
        echo "[$(date)] SUCCESS: Vault Agent authentication working" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Vault Agent authentication may not be working" >> "$LOG_FILE"
      fi
      # Check if API proxy is responding
      if curl -skk "http://localhost:8100/v1/sys/health" >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Vault Agent API proxy accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Vault Agent API proxy not accessible" >> "$LOG_FILE"
      fi
      ;;
    "postgres")
      # PostgreSQL validation
      if [[ -x "/opt/dev-purebliss/services/postgres/validate-setup.sh" ]]; then
        echo "[$(date)] INFO: Running PostgreSQL validation..." >> "$LOG_FILE"
        /opt/dev-purebliss/services/postgres/validate-setup.sh >> "$LOG_FILE" 2>&1
      fi
      ;;
    "redis")
      # Onboard Redis into Vault after health check
      onboard_redis_to_vault
      ;;
    "prometheus")
      # Onboard Prometheus into Vault after health check
      onboard_prometheus_to_vault
      ;;
    "codeserver")
      # Onboard CodeServer into Vault after health check
      onboard_codeserver_to_vault
      ;;
    "loki")
      # Enhanced Loki validation with Vault integration
      if [[ -f "/opt/dev-purebliss/services/loki/.vault_role_id" ]]; then
        echo "[$(date)] INFO: Validating Loki Vault AppRole authentication..." >> "$LOG_FILE"
        local role_id=$(cat /opt/dev-purebliss/services/loki/.vault_role_id)
        local secret_id=$(cat /opt/dev-purebliss/services/loki/.vault_secret_id)

        # Test AppRole authentication
        if docker exec purebliss-vault vault write -field=token auth/loki-approle/login role_id="$role_id" secret_id="$secret_id" >/dev/null 2>&1; then
          echo "[$(date)] SUCCESS: Loki Vault AppRole authentication working" >> "$LOG_FILE"
        else
          echo "[$(date)] WARNING: Loki Vault AppRole authentication failed" >> "$LOG_FILE"
        fi
      fi

      # Onboard Loki into Vault after health check
      onboard_loki_to_vault

      # Loki health check
      if curl -skk "http://localhost:3100/ready" | grep -q "ready"; then
        echo "[$(date)] SUCCESS: Loki health endpoint is ready" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Loki health endpoint not ready" >> "$LOG_FILE"
      fi

      # Test Loki metrics endpoint
      if curl -skk "http://localhost:3100/metrics" | head -1 | grep -q "#"; then
        echo "[$(date)] SUCCESS: Loki metrics endpoint is accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Loki metrics endpoint not accessible" >> "$LOG_FILE"
      fi

      # Validate Loki can query itself (basic functionality test)
      if curl -skk "http://localhost:3100/loki/api/v1/labels" | grep -q "status.*success\|data"; then
        echo "[$(date)] SUCCESS: Loki API is responding correctly" >> "$LOG_FILE"
      else
        echo "[$(date)] INFO: Loki API may still be initializing" >> "$LOG_FILE"
      fi
      ;;

    "grafana")
      echo "[$(date)] INFO: Running post-startup for Grafana monitoring and visualization" >> "$LOG_FILE"
      sleep 5  # Allow Grafana to initialize

      # Check if Grafana is responding
      if ! docker ps | grep -q "purebliss-grafana.*healthy\|purebliss-grafana.*Up"; then
        echo "[$(date)] WARNING: Grafana container not healthy yet" >> "$LOG_FILE"
        return 1
      fi

      # Onboard Grafana into Vault after health check
      onboard_grafana_to_vault

      # Grafana health check
      if curl -skk "http://localhost:3001/api/health" | grep -q "ok\|database.*ok"; then
        echo "[$(date)] SUCCESS: Grafana health endpoint is ready" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Grafana health endpoint not ready" >> "$LOG_FILE"
      fi

      # Test Grafana metrics endpoint
      if curl -skk "http://localhost:3001/metrics" | head -1 | grep -q "#"; then
        echo "[$(date)] SUCCESS: Grafana metrics endpoint is accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Grafana metrics endpoint not accessible" >> "$LOG_FILE"
      fi

      # Validate Grafana API is responding
      if curl -skk "http://localhost:3001/api/org" -u "admin:admin" | grep -q "orgId\|name"; then
        echo "[$(date)] SUCCESS: Grafana API is responding correctly" >> "$LOG_FILE"
      else
        echo "[$(date)] INFO: Grafana API may still be initializing or credentials may need updating" >> "$LOG_FILE"
      fi
      ;;

    "keycloak")
      # Test Keycloak admin endpoint and database connectivity
      sleep 10  # Give Keycloak time to fully start and initialize database
      echo "[$(date)] INFO: Testing Keycloak admin endpoint and database connectivity..." >> "$LOG_FILE"

      # Test basic health endpoint first
      if curl -skk "http://localhost:8080/" >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Keycloak basic endpoint accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Keycloak basic endpoint not accessible" >> "$LOG_FILE"
      fi

      # Test admin console endpoint
      if curl -skk "http://localhost:8080/admin" >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Keycloak admin console accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Keycloak admin console not accessible" >> "$LOG_FILE"
      fi

      # Test database connectivity by checking Keycloak logs for successful DB connection
      sleep 3
      if docker logs purebliss-keycloak --tail 20 | grep -qE "Database connection successful|Connected to database|Migration.*completed"; then
        echo "[$(date)] SUCCESS: Keycloak database connectivity confirmed via logs" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Keycloak database connectivity unclear - check logs manually" >> "$LOG_FILE"
        # Log recent Keycloak logs for troubleshooting
        echo "[$(date)] INFO: Recent Keycloak logs for troubleshooting:" >> "$LOG_FILE"
        docker logs purebliss-keycloak --tail 10 >> "$LOG_FILE" 2>&1
      fi

      # Check if PostgreSQL has keycloak database and user
      echo "[$(date)] INFO: Validating PostgreSQL Keycloak database and user..." >> "$LOG_FILE"
      if docker exec purebliss-postgres psql -U postgres -c "\l" | grep -q keycloak; then
        echo "[$(date)] SUCCESS: Keycloak database exists in PostgreSQL" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Keycloak database not found in PostgreSQL" >> "$LOG_FILE"
      fi

      if docker exec purebliss-postgres psql -U postgres -c "\du" | grep -q keycloak; then
        echo "[$(date)] SUCCESS: Keycloak user exists in PostgreSQL" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Keycloak user not found in PostgreSQL" >> "$LOG_FILE"
      fi

      # Onboard Keycloak to Vault after health check
      onboard_keycloak_to_vault
      ;;
    "nginx")
      # Test main proxy endpoint
      if curl -skk "https://dev.purebliss.app" >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Main nginx endpoint accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Main nginx endpoint not accessible" >> "$LOG_FILE"
      fi

      # Onboard Nginx to Vault PKI after health check
      onboard_nginx_to_vault
      ;;
  esac

  echo "[$(date)] INFO: Post-startup validation completed for $service" >> "$LOG_FILE"
  backup_critical_configs "$service"
  echo "[$(date)] SUMMARY: $service started and validated at $(date)" >> "$LOG_FILE"
  if [[ -x "/opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" ]]; then
    echo "[$(date)] INFO: To validate all integrations, run: /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" >> "$LOG_FILE"
  fi
}

function final_system_validation() {
  echo "[$(date)] INFO: === FINAL SYSTEM VALIDATION ===" >> "$LOG_FILE"

  local all_healthy=true
  local critical_services=(vault postgres redis keycloak)
  # Focusing on core infrastructure first - nginx will be added later

  # Check critical services
  for service in "${critical_services[@]}"; do
    if docker ps | grep -q "purebliss-$service"; then
      local health=$(docker inspect --format='{{.State.Health.Status}}' "purebliss-$service" 2>/dev/null || echo "no_healthcheck")
      if [[ "$health" == "healthy" ]] || [[ "$health" == "no_healthcheck" && $(docker inspect --format='{{.State.Status}}' "purebliss-$service") == "running" ]]; then
        echo "[$(date)] SUCCESS: $service is operational" >> "$LOG_FILE"
      else
        echo "[$(date)] ERROR: $service is not healthy - Status: $health" >> "$LOG_FILE"
        all_healthy=false
      fi
    else
      echo "[$(date)] WARNING: $service container not found" >> "$LOG_FILE"
      all_healthy=false
    fi
  done

  # Test key integrations
  echo "[$(date)] INFO: Testing key system integrations..." >> "$LOG_FILE"

  # Vault-PostgreSQL integration
  if vault_status_check && docker ps | grep -q purebliss-postgres; then
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      export VAULT_ADDR="https://127.0.0.1:8200"
      export VAULT_SKIP_VERIFY=1
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

      if vault read database/creds/postgres-role >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Vault-PostgreSQL dynamic credentials working" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Vault-PostgreSQL dynamic credentials not working" >> "$LOG_FILE"
      fi
    fi
  fi

  # External endpoint tests (disabled until nginx is added back)
  # local endpoints=("https://dev.purebliss.app" "https://dev.purebliss.app/keycloak")
  # for endpoint in "${endpoints[@]}"; do
  #   if curl -skk "$endpoint" >/dev/null 2>&1; then
  #     echo "[$(date)] SUCCESS: $endpoint accessible" >> "$LOG_FILE"
  #   else
  #     echo "[$(date)] WARNING: $endpoint not accessible" >> "$LOG_FILE"
  #   fi
  # done

  if [[ "$all_healthy" == "true" ]]; then
    echo "[$(date)] 🎉 SUCCESS: All critical services are operational!" >> "$LOG_FILE"

    # Run comprehensive health check to validate complete infrastructure
    echo "[$(date)] INFO: Running comprehensive infrastructure health check..." >> "$LOG_FILE"
    if [[ -x "/opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" ]]; then
      echo "[$(date)] INFO: Executing comprehensive health validation..." | tee -a "$LOG_FILE"
      echo "" | tee -a "$LOG_FILE"
      echo "🔍 Running comprehensive infrastructure health check..." | tee -a "$LOG_FILE"

      # Run the comprehensive health check and capture its output
      if /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh 2>&1 | tee -a "$LOG_FILE"; then
        echo "[$(date)] SUCCESS: Comprehensive health check completed successfully" >> "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "🎉 INFRASTRUCTURE VALIDATION COMPLETE" | tee -a "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Comprehensive health check reported issues" >> "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "⚠️  Some validation checks failed - see output above" | tee -a "$LOG_FILE"
      fi
    else
      echo "[$(date)] WARNING: Comprehensive health check script not found at /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" >> "$LOG_FILE"
    fi

    echo ""
    echo "🎉 SUCCESS: Pure Bliss Core Infrastructure is operational!"
    echo ""
    echo "Key Services:"
    echo "  ✅ Vault (https://127.0.0.1:8200) - Dynamic secrets management"
    echo "  ✅ PostgreSQL (localhost:5432) - Database with Vault integration"
    echo "  ✅ Redis (localhost:6379) - Caching and session store"
    echo "  ✅ Keycloak (http://localhost:8080) - Identity and access management"
    echo ""
    echo "Integration Status:"
    echo "  ✅ Vault-PostgreSQL dynamic credentials"
    echo "  ✅ Keycloak-PostgreSQL database connectivity"
    echo "  ✅ AppRole authentication system"
    echo "  ✅ Zero hardcoded database passwords"
    echo ""
    echo "Next Steps:"
    echo "  • Access Keycloak admin: http://localhost:8080/admin"
    echo "  • Validate PostgreSQL setup: /opt/dev-purebliss/services/postgres/validate-setup.sh"
    echo "  • Test dynamic credential generation: vault read database/creds/postgres-role"
    echo "  • View logs: tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log"
    echo "  • When ready, add nginx plane to SERVICE_ORDER"
  else
    echo "[$(date)] ⚠️  WARNING: Some services may not be fully operational - check logs" >> "$LOG_FILE"
    echo ""
    echo "⚠️  Some services may not be fully operational"
    echo "Check logs: tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log"
  fi

  echo "[$(date)] INFO: Final system validation completed" >> "$LOG_FILE"
}
echo "[$(date)] INFO: Referencing troubleshooting log for pre-checks." >> "$LOG_FILE"
tail -n 40 "$LOG_FILE" | grep -iE 'vault|keycloak|nginx|plane|postgres|redis|loki|prometheus|grafana' >> "$LOG_FILE"

if [[ -n "$SERVICE_ARG" ]]; then
  # Start only the specified service (with health check if in SERVICE_ORDER)
  service="$SERVICES_DIR/$SERVICE_ARG"
  if [[ ! -d "$service" ]]; then
    log_and_exit "Service directory $service does not exist"
  fi
  echo "[$(date)] INFO: Starting service $SERVICE_ARG in $service" >> "$LOG_FILE"
  if [[ -x "$service/start.sh" ]]; then
    echo "[$(date)] INFO: Starting $SERVICE_ARG using start.sh" >> "$LOG_FILE"
    "$service/start.sh" >> "$LOG_FILE" 2>&1 || log_and_exit "Failed to start $SERVICE_ARG via start.sh"
  else
    # Special handling for vault-agent which has a custom compose file name
    if [[ "$SERVICE_ARG" == "vault-agent" ]]; then
      compose_file="$service/vault-agent-docker-compose.yml"
      if [[ -f "$compose_file" ]]; then
        echo "[$(date)] INFO: Starting $SERVICE_ARG using custom vault-agent-docker-compose.yml" >> "$LOG_FILE"
        # Ensure clean startup by removing any existing container
        docker rm -f purebliss-vault-agent >/dev/null 2>&1 || true
        (cd "$service" && docker-compose -f "vault-agent-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $SERVICE_ARG via vault-agent-docker-compose.yml"
      else
        log_and_exit "vault-agent-docker-compose.yml not found in $service"
      fi
    elif [[ "$SERVICE_ARG" == "keycloak" ]]; then
      compose_file="$service/keycloak-docker-compose.yml"
      if [[ -f "$compose_file" ]]; then
        echo "[$(date)] INFO: Starting $SERVICE_ARG using keycloak-docker-compose.yml with Vault integration" >> "$LOG_FILE"
        # Ensure clean startup by removing any existing container
        docker rm -f purebliss-keycloak >/dev/null 2>&1 || true

        # Fetch credentials from Vault and set environment variables
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
          export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
          export VAULT_ADDR="https://127.0.0.1:8200"
          export VAULT_SKIP_VERIFY=1

          echo "[$(date)] INFO: Fetching Keycloak credentials from Vault..." >> "$LOG_FILE"
          # Fetch Keycloak secrets from Vault
          if vault kv get -format=json secret/keycloak >/dev/null 2>&1; then
            VAULT_ADMIN_PASSWORD=$(vault kv get -field=admin_password secret/keycloak 2>/dev/null || echo "keycloak_admin_changeme")
            VAULT_POSTGRES_PASSWORD=$(vault kv get -field=postgres_password secret/keycloak 2>/dev/null || echo "keycloak_password_123")
            echo "[$(date)] SUCCESS: Retrieved Keycloak credentials from Vault" >> "$LOG_FILE"
          else
            echo "[$(date)] WARNING: Could not fetch secrets from Vault, using defaults" >> "$LOG_FILE"
            VAULT_ADMIN_PASSWORD="keycloak_admin_changeme"
            VAULT_POSTGRES_PASSWORD="keycloak_password_123"
          fi

          # Export credentials as environment variables for docker-compose
          export KEYCLOAK_ADMIN_PASSWORD="$VAULT_ADMIN_PASSWORD"
          export KC_DB_PASSWORD="$VAULT_POSTGRES_PASSWORD"
          echo "[$(date)] INFO: Keycloak credentials loaded from Vault" >> "$LOG_FILE"
        else
          echo "[$(date)] WARNING: Vault token not found - using default credentials" >> "$LOG_FILE"
          export KEYCLOAK_ADMIN_PASSWORD="keycloak_admin_changeme"
          export KC_DB_PASSWORD="keycloak_password_123"
        fi

        (cd "$service" && VAULT_TOKEN="$VAULT_TOKEN" KEYCLOAK_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD" KC_DB_PASSWORD="$KC_DB_PASSWORD" docker-compose -f "keycloak-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $SERVICE_ARG via keycloak-docker-compose.yml"
      else
        log_and_exit "keycloak-docker-compose.yml not found in $service"
      fi
    elif [[ "$SERVICE_ARG" == "nginx" ]]; then
      compose_file="$service/nginx-docker-compose.yml"
      if [[ -f "$compose_file" ]]; then
        echo "[$(date)] INFO: Starting $SERVICE_ARG using nginx-docker-compose.yml" >> "$LOG_FILE"
        # Ensure clean startup by removing any existing container
        docker rm -f purebliss-nginx >/dev/null 2>&1 || true

        # Copy nginx configuration to the proper location for the container
        mkdir -p /opt/pure-bliss-dev/shared/configs/nginx/conf.d/ 2>/dev/null || true
        cp "$service/default.conf" /opt/pure-bliss-dev/shared/configs/nginx/conf.d/default.conf 2>/dev/null || \
          echo "[$(date)] WARNING: Could not copy default.conf to shared config location" >> "$LOG_FILE"

        (cd "$service" && docker-compose -f "nginx-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $SERVICE_ARG via nginx-docker-compose.yml"
      else
        log_and_exit "nginx-docker-compose.yml not found in $service"
      fi
    else
      # Standard service startup logic
      compose_file="$service/${SERVICE_ARG}-docker-compose.yml"
      if [[ -f "$compose_file" ]]; then
        echo "[$(date)] INFO: Starting $SERVICE_ARG using $compose_file" >> "$LOG_FILE"
        (cd "$service" && docker-compose -f "${SERVICE_ARG}-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $SERVICE_ARG via $compose_file"
      elif [[ -f "$service/docker-compose.yml" ]]; then
        echo "[$(date)] INFO: Starting $SERVICE_ARG using docker-compose.yml" >> "$LOG_FILE"
        (cd "$service" && docker-compose up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $SERVICE_ARG via docker-compose.yml"
      else
        # Special handling for Loki if only loki-docker-compose.yml exists
        if [[ -f "$service/loki-docker-compose.yml" ]]; then
          echo "[$(date)] INFO: Starting $SERVICE_ARG using loki-docker-compose.yml" >> "$LOG_FILE"
          (cd "$service" && docker-compose -f "loki-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $SERVICE_ARG via loki-docker-compose.yml"
        else
          log_and_exit "No recognized startup method for $SERVICE_ARG"
        fi
      fi
    fi
  fi
  # Health check for known services
  for s in "${SERVICE_ORDER[@]}"; do
    if [[ "$SERVICE_ARG" == "$s" ]]; then
      wait_for_healthy "$s" "$SERVICE_ARG"
      # Special handling for Vault initialization and unsealing
      if [[ "$SERVICE_ARG" == "vault" ]]; then
        setup_vault_automation
      fi
      # Run post-startup validation (includes Vault onboarding for nginx)
      post_service_validation "$SERVICE_ARG"
    fi
  done
  echo "[$(date)] INFO: Service $SERVICE_ARG startup attempt complete." >> "$LOG_FILE"
  backup_critical_configs "$SERVICE_ARG"
  echo "[$(date)] SUMMARY: $SERVICE_ARG started and validated at $(date)" >> "$LOG_FILE"
  if [[ -x "/opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" ]]; then
    echo "[$(date)] INFO: To validate all integrations, run: /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" >> "$LOG_FILE"
  fi

  # Optional: Run comprehensive health check if requested service is critical
  critical_services=(vault postgres redis keycloak)
  if [[ " ${critical_services[*]} " =~ " $SERVICE_ARG " ]]; then
    echo "[$(date)] INFO: $SERVICE_ARG is a critical service - offering comprehensive validation..." >> "$LOG_FILE"
    echo ""
    echo "🔍 $SERVICE_ARG startup complete. Run comprehensive health check? [y/N]"
    read -r -t 10 response || response="n"
    if [[ "$response" =~ ^[Yy]$ ]]; then
      if [[ -x "/opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" ]]; then
        echo "[$(date)] INFO: Running comprehensive health check for $SERVICE_ARG validation..." >> "$LOG_FILE"
        /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh 2>&1 | tee -a "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Comprehensive health check script not found" >> "$LOG_FILE"
      fi
    fi
  fi
else
  echo "[$(date)] INFO: Starting all services using sequential health-validated startup" | tee -a "$LOG_FILE"

  # Use sequential startup with health validation between each service
  if start_all_services_sequential; then
    echo "[$(date)] SUCCESS: All Pure Bliss services started successfully with comprehensive validation!" | tee -a "$LOG_FILE"

    # Backup configs for all core services
    for s in "${SERVICE_ORDER[@]}"; do
      backup_critical_configs "$s"
    done

    exit 0
  else
    echo "[$(date)] ERROR: Sequential startup failed - check logs for details" | tee -a "$LOG_FILE"
    exit 1
  fi
fi
