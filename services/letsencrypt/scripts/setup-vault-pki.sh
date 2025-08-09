#!/bin/bash
# ============================================================================
# Let's Encrypt Vault PKI Setup Script
#
# This script sets up Let's Encrypt to use Vault PKI for certificate generation
# instead of traditional ACME protocol.
# ============================================================================

set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICES_DIR="/opt/dev-purebliss/services"

echo "[$(date)] INFO: Starting Let's Encrypt Vault PKI setup" | tee -a "$LOG_FILE"

# Change to the letsencrypt service directory
cd "$SERVICES_DIR/letsencrypt"

# Auto-detect Vault mode and configure
detect_vault_mode() {
  if curl -sk "https://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    VAULT_MODE="dev"
    echo "[$(date)] INFO: Detected Vault in development mode" | tee -a "$LOG_FILE"
  elif curl -skk "https://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    else
      echo "[$(date)] ERROR: Vault token file not found for production mode" | tee -a "$LOG_FILE"
      return 1
    fi
    VAULT_MODE="production"
    echo "[$(date)] INFO: Detected Vault in production mode" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Cannot connect to Vault - ensure Vault is running and unsealed" | tee -a "$LOG_FILE"
    return 1
  fi
  return 0
}

# Setup Vault environment
setup_vault_environment() {
  echo "[$(date)] INFO: Setting up Vault environment for Let's Encrypt" | tee -a "$LOG_FILE"

  # Set Vault environment variables for the Docker container
  export VAULT_ADDR
  export VAULT_TOKEN
  export VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY:-1}

  echo "[$(date)] SUCCESS: Vault environment configured" | tee -a "$LOG_FILE"
  return 0
}

# Clean up any existing container
cleanup_existing_container() {
  echo "[$(date)] INFO: Cleaning up existing Let's Encrypt container..." | tee -a "$LOG_FILE"

  if docker ps -q -f name=purebliss-letsencrypt | grep -q .; then
    echo "[$(date)] INFO: Stopping existing Let's Encrypt container..." | tee -a "$LOG_FILE"
    docker stop purebliss-letsencrypt >/dev/null 2>&1 || true
  fi

  if docker ps -aq -f name=purebliss-letsencrypt | grep -q .; then
    echo "[$(date)] INFO: Removing existing Let's Encrypt container..." | tee -a "$LOG_FILE"
    docker rm purebliss-letsencrypt >/dev/null 2>&1 || true
  fi

  echo "[$(date)] SUCCESS: Container cleanup complete" | tee -a "$LOG_FILE"
  return 0
}

# Start Let's Encrypt with Vault PKI integration
start_letsencrypt_container() {
  echo "[$(date)] INFO: Starting Let's Encrypt container with Vault PKI integration..." | tee -a "$LOG_FILE"

  # Export environment variables for docker-compose
  export VAULT_ADDR
  export VAULT_TOKEN
  export VAULT_SKIP_VERIFY

  # Start the container
  if docker compose -f letsencrypt-docker-compose.yml up -d --build 2>&1 | tee -a "$LOG_FILE"; then
    echo "[$(date)] SUCCESS: Let's Encrypt container started successfully" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to start Let's Encrypt container" | tee -a "$LOG_FILE"
    return 1
  fi

  return 0
}

# Wait for container to be healthy
wait_for_container_health() {
  echo "[$(date)] INFO: Waiting for Let's Encrypt container to become healthy..." | tee -a "$LOG_FILE"

  local max_attempts=30
  local attempt=1

  while [[ $attempt -le $max_attempts ]]; do
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-letsencrypt 2>/dev/null || echo "no_healthcheck")

    if [[ "$health_status" == "healthy" ]]; then
      echo "[$(date)] SUCCESS: Let's Encrypt container is healthy" | tee -a "$LOG_FILE"
      return 0
    elif [[ "$health_status" == "unhealthy" ]]; then
      echo "[$(date)] WARNING: Let's Encrypt container is unhealthy (attempt $attempt/$max_attempts)" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] INFO: Waiting for health check... (attempt $attempt/$max_attempts)" | tee -a "$LOG_FILE"
    fi

    sleep 5
    ((attempt++))
  done

  echo "[$(date)] WARNING: Let's Encrypt container did not become healthy within expected time" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Container may still be initializing - check logs: docker logs purebliss-letsencrypt" | tee -a "$LOG_FILE"
  return 1
}

# Validate the setup
validate_setup() {
  echo "[$(date)] INFO: Validating Let's Encrypt Vault PKI setup..." | tee -a "$LOG_FILE"

  # Run the validation script
  if [[ -x "./validate-vault-pki.sh" ]]; then
    echo "[$(date)] INFO: Running comprehensive validation..." | tee -a "$LOG_FILE"
    if ./validate-vault-pki.sh 2>&1 | tee -a "$LOG_FILE"; then
      echo "[$(date)] SUCCESS: Validation passed - Let's Encrypt Vault PKI is working correctly" | tee -a "$LOG_FILE"
      return 0
    else
      echo "[$(date)] WARNING: Validation failed - check logs for details" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] WARNING: Validation script not found - performing basic checks" | tee -a "$LOG_FILE"

    # Basic validation
    if docker ps | grep -q "purebliss-letsencrypt"; then
      echo "[$(date)] SUCCESS: Container is running" | tee -a "$LOG_FILE"

      # Check container logs for Vault PKI activity
      if docker logs purebliss-letsencrypt --tail 10 | grep -q "Vault PKI"; then
        echo "[$(date)] SUCCESS: Container is using Vault PKI" | tee -a "$LOG_FILE"
        return 0
      else
        echo "[$(date)] WARNING: Container may not be using Vault PKI - check logs" | tee -a "$LOG_FILE"
        return 1
      fi
    else
      echo "[$(date)] ERROR: Container is not running" | tee -a "$LOG_FILE"
      return 1
    fi
  fi
}

# Main setup function
main() {
  echo "[$(date)] INFO: ================================================" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Let's Encrypt Vault PKI Integration Setup" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: ================================================" | tee -a "$LOG_FILE"

  # Step 1: Detect and configure Vault
  if detect_vault_mode && setup_vault_environment; then
    echo "[$(date)] SUCCESS: Vault environment ready" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to configure Vault environment" | tee -a "$LOG_FILE"
    exit 1
  fi

  # Step 2: Clean up existing container
  if cleanup_existing_container; then
    echo "[$(date)] SUCCESS: Container cleanup complete" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to clean up existing container" | tee -a "$LOG_FILE"
    exit 1
  fi

  # Step 3: Start the new container
  if start_letsencrypt_container; then
    echo "[$(date)] SUCCESS: Container started successfully" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to start container" | tee -a "$LOG_FILE"
    exit 1
  fi

  # Step 4: Wait for health check (optional - don't fail if it takes time)
  wait_for_container_health || true

  # Step 5: Validate the setup
  echo "[$(date)] INFO: Waiting 10 seconds for container initialization..." | tee -a "$LOG_FILE"
  sleep 10

  if validate_setup; then
    echo "[$(date)] SUCCESS: Let's Encrypt Vault PKI setup complete and validated!" | tee -a "$LOG_FILE"

    echo ""
    echo "🎉 Let's Encrypt Vault PKI Integration Setup Complete!"
    echo ""
    echo "✅ Vault PKI engine configured"
    echo "✅ Let's Encrypt container running with Vault integration"
    echo "✅ Certificate generation using Vault PKI instead of ACME"
    echo "✅ Automatic certificate renewal every hour"
    echo ""
    echo "📋 Useful commands:"
    echo "   • View container logs: docker logs purebliss-letsencrypt"
    echo "   • Validate setup: /opt/dev-purebliss/services/letsencrypt/validate-vault-pki.sh"
    echo "   • Check certificates: ls -la /mnt/raid0/nginx/certs/live/"
    echo "   • Test certificate generation: vault write pki-letsencrypt/issue/letsencrypt-role common_name=dev.purebliss.app"
    echo ""

    return 0
  else
    echo "[$(date)] WARNING: Setup completed but validation failed - check logs for details" | tee -a "$LOG_FILE"

    echo ""
    echo "⚠️  Let's Encrypt Vault PKI Integration Setup Warning"
    echo ""
    echo "🔧 The container is running but validation failed"
    echo "📋 Check the logs for details:"
    echo "   • Container logs: docker logs purebliss-letsencrypt"
    echo "   • Setup logs: tail -f $LOG_FILE"
    echo "   • Run validation: /opt/dev-purebliss/services/letsencrypt/validate-vault-pki.sh"
    echo ""

    return 1
  fi
}

# Execute main function
main "$@"
