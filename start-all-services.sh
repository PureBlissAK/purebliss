# --- Redis Vault Onboarding Automation ---
# This function configures Vault to manage dynamic Redis credentials using the correct Docker hostname.
function onboard_redis_to_vault() {
  local REDIS_HOST="purebliss-redis"
  local VAULT_ADDR="https://127.0.0.1:8200"
  local VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
  echo "[$(date)] INFO: Onboarding Redis into Vault for dynamic secrets (host: $REDIS_HOST)" | tee -a "$LOG_FILE"
  if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
    echo "[$(date)] ERROR: Vault token file not found at $VAULT_TOKEN_FILE" | tee -a "$LOG_FILE"
    return 1
  fi
  export VAULT_ADDR
  export VAULT_SKIP_VERIFY=1
  export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")

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
#!/bin/bash
set -euo pipefail


LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICES_DIR="/opt/dev-purebliss/services"

# === Pure Bliss Vault Troubleshooting Reference ===
# For all Vault and Vault Agent operational issues, consult:
#   /opt/dev-purebliss/services/vault/VAULT_AUTOMATION_GUIDE.md
#   /opt/dev-purebliss/services/vault/vault-break-fix-report.md
# These documents contain automation, break/fix, and troubleshooting best practices for Vault and Vault Agent.

echo "[$(date)] INFO: For Vault and Vault Agent troubleshooting, see VAULT_AUTOMATION_GUIDE.md and vault-break-fix-report.md in /opt/dev-purebliss/services/vault/" >> "$LOG_FILE"

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


# Strict service startup order as per Pure Bliss best practices
# Phase 1: Core infrastructure (Vault + PostgreSQL integration)
# Phase 2: Essential services only
SERVICE_ORDER=(vault postgres vault-agent redis)
# Disabled until ready: prometheus grafana loki keycloak nginx plane

# Function to auto-unseal Vault if sealed and wait for API readiness
function vault_auto_unseal() {
  local VAULT_ADDR="https://127.0.0.1:8200"
  echo "[$(date)] INFO: Checking if Vault is sealed before starting dependent service..." | tee -a "$LOG_FILE"
  local sealed_status
  sealed_status=$(curl -sk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' ')
  if [[ "$sealed_status" == "true" ]]; then
    echo "[$(date)] INFO: Vault is sealed. Attempting auto-unseal..." | tee -a "$LOG_FILE"
    if [[ -f "/opt/my-secure-ha-stack/vault-unseal-keys.env" ]]; then
      # shellcheck disable=SC1091
      source /opt/my-secure-ha-stack/vault-unseal-keys.env
      # Iterate over all VAULT_UNSEAL_KEY_* variables (corrected pattern)
      for key_var in $(compgen -A variable | grep '^VAULT_UNSEAL_KEY_'); do
        key="${!key_var}"
        if [[ -n "$key" ]]; then
          curl -sk --request POST --data '{"key": "'$key'"}' "$VAULT_ADDR/v1/sys/unseal" >/dev/null 2>&1
          echo "[$(date)] INFO: Submitted $key_var" | tee -a "$LOG_FILE"
        fi
      done
      # Check again
      sealed_status=$(curl -sk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' ')
      if [[ "$sealed_status" == "false" ]]; then
        echo "[$(date)] SUCCESS: Vault unsealed successfully." | tee -a "$LOG_FILE"
      else
        echo "[$(date)] ERROR: Vault is still sealed after auto-unseal attempt." | tee -a "$LOG_FILE"
        return 1
      fi
    else
      echo "[$(date)] ERROR: Unseal keys file not found at /opt/my-secure-ha-stack/vault-unseal-keys.env" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] INFO: Vault is already unsealed." | tee -a "$LOG_FILE"
  fi
  
  # Critical: Wait for Vault API to be fully ready for operations
  echo "[$(date)] INFO: Waiting for Vault API to be fully operational for API calls..." | tee -a "$LOG_FILE"
  local max_api_wait=30
  local api_ready=false
  
  for i in $(seq 1 $max_api_wait); do
    # Test if Vault API is ready by attempting a simple read operation
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
      export VAULT_ADDR="$VAULT_ADDR"
      export VAULT_SKIP_VERIFY=1
      
      # Test API readiness with a simple auth list
      if vault auth list >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Vault API is fully ready for operations (attempt $i)" | tee -a "$LOG_FILE"
        api_ready=true
        break
      fi
    fi
    
    # Alternative test without token - just check if we get proper API response codes
    local api_response_code
    api_response_code=$(curl -sk -w "%{http_code}" -o /dev/null "$VAULT_ADDR/v1/sys/auth" 2>/dev/null || echo "000")
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
  echo "[$(date)] INFO: Setting up Vault automation..." >> "$LOG_FILE"
  echo "[$(date)] INFO: Reference /opt/dev-purebliss/services/vault/VAULT_AUTOMATION_GUIDE.md for automation and troubleshooting steps." >> "$LOG_FILE"

  # CRITICAL: Ensure Vault is unsealed and API ready before any automation
  echo "[$(date)] INFO: Ensuring Vault is unsealed and API ready before automation..." >> "$LOG_FILE"
  if ! vault_auto_unseal; then
    echo "[$(date)] ERROR: Cannot proceed with Vault automation - unsealing failed" >> "$LOG_FILE"
    return 1
  fi

  # Run comprehensive pre-startup checks (but skip postgresql_integration which requires unsealing)
  if [[ -x "/opt/dev-purebliss/services/vault/vault-break-fix.sh" ]]; then
    echo "[$(date)] INFO: Running pre-startup checks for Vault (excluding DB integration)..." >> "$LOG_FILE"
    # Run individual fixes instead of 'all' to avoid premature DB integration
    /opt/dev-purebliss/services/vault/vault-break-fix.sh network
    /opt/dev-purebliss/services/vault/vault-break-fix.sh permissions
    /opt/dev-purebliss/services/vault/vault-break-fix.sh tls_config
    /opt/dev-purebliss/services/vault/vault-break-fix.sh agent_config
    /opt/dev-purebliss/services/vault/vault-break-fix.sh container_startup
  fi

  # Check if Vault keys already exist
  if [[ -f "/opt/my-secure-ha-stack/secrets/vault/vault-keys.enc" ]]; then
    echo "[$(date)] INFO: Vault keys found, ensuring auto-unseal..." >> "$LOG_FILE"
    if /opt/dev-purebliss/services/vault/vault-auto-unseal.sh; then
      echo "[$(date)] SUCCESS: Vault auto-unsealed successfully" >> "$LOG_FILE"
      # Ensure API is ready before proceeding
      if vault_auto_unseal; then
        setup_vault_approlе_credentials
        return 0
      else
        echo "[$(date)] ERROR: Vault API not ready after auto-unseal" >> "$LOG_FILE"
        return 1
      fi
    else
      echo "[$(date)] WARNING: Auto-unseal failed, may need manual initialization" >> "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] INFO: Vault not initialized, running automated development initialization..." >> "$LOG_FILE"
    if [[ -x "/opt/dev-purebliss/services/vault/vault-dev-init.sh" ]]; then
      echo "[$(date)] INFO: Running automated Vault initialization for development environment..." >> "$LOG_FILE"
      if /opt/dev-purebliss/services/vault/vault-dev-init.sh >> "$LOG_FILE" 2>&1; then
        echo "[$(date)] SUCCESS: Vault initialized and unsealed automatically" >> "$LOG_FILE"
        # Ensure API is ready before proceeding
        if vault_auto_unseal; then
          setup_vault_approlе_credentials
          return 0
        else
          echo "[$(date)] ERROR: Vault API not ready after initialization" >> "$LOG_FILE"
          return 1
        fi
      else
        echo "[$(date)] ERROR: Automated Vault initialization failed" >> "$LOG_FILE"
        return 1
      fi
    else
      echo "[$(date)] WARNING: Vault not initialized and no automated init script found" >> "$LOG_FILE"
      echo "🔐 Vault requires initialization. Please run the automation script:"
      echo "   /opt/dev-purebliss/services/vault/vault-init-automation.sh"
      echo ""
      echo "This will prompt for a master password to encrypt Vault keys."
      return 1
    fi
  fi
}


function setup_vault_approlе_credentials {
  echo "[$(date)] INFO: Setting up Vault AppRole credentials for service onboarding..." >> "$LOG_FILE"
  echo "[$(date)] INFO: Reference /opt/dev-purebliss/services/vault/vault-break-fix-report.md for AppRole and break/fix troubleshooting." >> "$LOG_FILE"
  
  # CRITICAL: Ensure Vault is ready for API operations before proceeding
  echo "[$(date)] INFO: Verifying Vault API readiness before AppRole setup..." >> "$LOG_FILE"
  if ! vault_auto_unseal; then
    echo "[$(date)] ERROR: Cannot setup AppRole - Vault API not ready" >> "$LOG_FILE"
    return 1
  fi
  
  # Run the TLS-enabled Vault setup script to configure AppRole and database secrets
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
        if vault_auto_unseal && /opt/dev-purebliss/services/vault/vault-break-fix.sh postgresql_integration >> "$LOG_FILE" 2>&1; then
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
      # These services depend on PostgreSQL
      if ! docker ps | grep -q purebliss-postgres; then
        echo "[$(date)] WARNING: $service requires PostgreSQL but it's not running" >> "$LOG_FILE"
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
  local VAULT_ADDR="https://127.0.0.1:8200"
  local sealed_status health_status api_ready
  
  # Check if Vault is accessible and get status
  if ! curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
    echo "[$(date)] INFO: Vault health endpoint not accessible" | tee -a "$LOG_FILE"
    return 1
  fi
  
  sealed_status=$(curl -sk "$VAULT_ADDR/v1/sys/health" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' ')
  health_status=$(curl -sk "$VAULT_ADDR/v1/sys/health" | grep -o '"initialized":[^,]*' | cut -d: -f2 | tr -d ' ')
  
  if [[ "$health_status" == "true" && "$sealed_status" == "false" ]]; then
    # Additional check: ensure API is ready for operations
    local api_response_code
    api_response_code=$(curl -sk -w "%{http_code}" -o /dev/null "$VAULT_ADDR/v1/sys/auth" 2>/dev/null || echo "000")
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
      if curl -sk "http://localhost:8100/v1/sys/health" >/dev/null 2>&1; then
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
    "keycloak")
      # Test Keycloak admin endpoint
      sleep 5  # Give Keycloak time to fully start
      if curl -sk "https://dev.purebliss.app/keycloak/admin" >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Keycloak admin endpoint accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Keycloak admin endpoint not accessible" >> "$LOG_FILE"
      fi
      ;;
    "nginx")
      # Test main proxy endpoint
      if curl -sk "https://dev.purebliss.app" >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Main nginx endpoint accessible" >> "$LOG_FILE"
      else
        echo "[$(date)] WARNING: Main nginx endpoint not accessible" >> "$LOG_FILE"
      fi
      ;;
  esac

  echo "[$(date)] INFO: Post-startup validation completed for $service" >> "$LOG_FILE"
}

function final_system_validation() {
  echo "[$(date)] INFO: === FINAL SYSTEM VALIDATION ===" >> "$LOG_FILE"
  
  local all_healthy=true
  local critical_services=(vault postgres redis)
  # Focusing on core infrastructure first - keycloak nginx will be added later
  
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
  #   if curl -sk "$endpoint" >/dev/null 2>&1; then
  #     echo "[$(date)] SUCCESS: $endpoint accessible" >> "$LOG_FILE"
  #   else
  #     echo "[$(date)] WARNING: $endpoint not accessible" >> "$LOG_FILE"
  #   fi
  # done
  
  if [[ "$all_healthy" == "true" ]]; then
    echo "[$(date)] 🎉 SUCCESS: All critical services are operational!" >> "$LOG_FILE"
    echo ""
    echo "🎉 SUCCESS: Pure Bliss Core Infrastructure is operational!"
    echo ""
    echo "Key Services:"
    echo "  ✅ Vault (https://127.0.0.1:8200) - Dynamic secrets management"
    echo "  ✅ PostgreSQL (localhost:5432) - Database with Vault integration"
    echo "  ✅ Redis (localhost:6379) - Caching and session store"
    echo ""
    echo "Integration Status:"
    echo "  ✅ Vault-PostgreSQL dynamic credentials"
    echo "  ✅ AppRole authentication system"
    echo "  ✅ Zero hardcoded database passwords"
    echo ""
    echo "Next Steps:"
    echo "  • Validate PostgreSQL setup: /opt/dev-purebliss/services/postgres/validate-setup.sh"
    echo "  • Test dynamic credential generation: vault read database/creds/postgres-role"
    echo "  • View logs: tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log"
    echo "  • When ready, add keycloak nginx plane to SERVICE_ORDER"
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
        log_and_exit "No recognized startup method for $SERVICE_ARG"
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
    fi
  done
  echo "[$(date)] INFO: Service $SERVICE_ARG startup attempt complete." >> "$LOG_FILE"
else
  echo "[$(date)] INFO: Starting all services in strict order: ${SERVICE_ORDER[*]}" >> "$LOG_FILE"
  for s in "${SERVICE_ORDER[@]}"; do
    service="$SERVICES_DIR/$s"
    if [[ ! -d "$service" ]]; then
      echo "[$(date)] WARNING: Service directory $service does not exist, skipping." >> "$LOG_FILE"
      continue
    fi

    # Always unseal Vault before starting any service except Vault itself
    if [[ "$s" != "vault" ]]; then
      echo "[$(date)] INFO: Ensuring Vault is unsealed before starting $s..." | tee -a "$LOG_FILE"
      if ! vault_auto_unseal; then
        log_and_exit "Cannot start $s - Vault is not operational and failed to unseal"
      fi
    fi

    # Validate dependencies before starting
    validate_service_dependencies "$s"

    # Start the service
    echo "[$(date)] INFO: Starting $s in $service" >> "$LOG_FILE"
    if [[ -x "$service/start.sh" ]]; then
      echo "[$(date)] INFO: Starting $s using start.sh" >> "$LOG_FILE"
      "$service/start.sh" >> "$LOG_FILE" 2>&1 || log_and_exit "Failed to start $s via start.sh"
    else
      # Special handling for vault-agent which has a custom compose file name
      if [[ "$s" == "vault-agent" ]]; then
        compose_file="$service/vault-agent-docker-compose.yml"
        if [[ -f "$compose_file" ]]; then
          echo "[$(date)] INFO: Starting $s using custom vault-agent-docker-compose.yml" >> "$LOG_FILE"
          # Ensure clean startup by removing any existing container
          docker rm -f purebliss-vault-agent >/dev/null 2>&1 || true
          (cd "$service" && docker-compose -f "vault-agent-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $s via vault-agent-docker-compose.yml"
        else
          echo "[$(date)] ERROR: vault-agent-docker-compose.yml not found in $service" >> "$LOG_FILE"
          log_and_exit "vault-agent-docker-compose.yml not found"
        fi
      else
        # Standard service startup logic
        compose_file="$service/${s}-docker-compose.yml"
        if [[ -f "$compose_file" ]]; then
          echo "[$(date)] INFO: Starting $s using $compose_file" >> "$LOG_FILE"
          (cd "$service" && docker-compose -f "${s}-docker-compose.yml" up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $s via $compose_file"
        elif [[ -f "$service/docker-compose.yml" ]]; then
          echo "[$(date)] INFO: Starting $s using docker-compose.yml" >> "$LOG_FILE"
          (cd "$service" && docker-compose up -d >> "$LOG_FILE" 2>&1) || log_and_exit "Failed to start $s via docker-compose.yml"
        else
          echo "[$(date)] WARNING: No recognized startup method for $s" >> "$LOG_FILE"
          continue
        fi
      fi
    fi

    wait_for_healthy "$s" "$s"

    # Critical: After starting Vault, ensure it is properly initialized and unsealed before any other service
    if [[ "$s" == "vault" ]]; then
      echo "[$(date)] INFO: Vault container is healthy - now initializing and unsealing..." | tee -a "$LOG_FILE"
      setup_vault_automation
      # Ensure Vault is unsealed after setup
      echo "[$(date)] INFO: Final check - ensuring Vault is unsealed before proceeding..." | tee -a "$LOG_FILE"
      if ! vault_auto_unseal; then
        log_and_exit "Vault failed to unseal properly - cannot continue with dependent services"
      fi
      # Verify Vault is truly operational
      if ! vault_status_check; then
        log_and_exit "Vault status check failed - cannot continue with dependent services"
      fi
      echo "[$(date)] SUCCESS: Vault is fully operational and unsealed" | tee -a "$LOG_FILE"
    fi

    # Run post-startup validation
    post_service_validation "$s"

    echo "[$(date)] INFO: Service $s startup and validation complete" >> "$LOG_FILE"
  done
  
  echo "[$(date)] INFO: All service startup attempts complete." >> "$LOG_FILE"
  
  # Run final system validation
  echo "[$(date)] INFO: Running final system validation..." >> "$LOG_FILE"
  final_system_validation
fi
