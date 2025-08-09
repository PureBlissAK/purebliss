#!/bin/bash
set -euo pipefail

# Automated Vault CLI and /vault-token integration for container Dockerfiles and compose files
# Pure Bliss Elite Framework v3.0
# Usage: ./automate-vault-integration.sh <service> <dockerfile> <compose-file>
# Example: ./automate-vault-integration.sh nginx /opt/dev-purebliss/services/nginx/nginx-dockerfile /opt/my-secure-ha-stack/docker-compose.yml

SERVICE_NAME="$1"
DOCKERFILE="$2"
COMPOSE_FILE="$3"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [AUTOMATE_VAULT_INTEGRATION][$SERVICE_NAME]: $1" | tee -a "$LOG_FILE"
}

# Patch Dockerfile to install Vault CLI if not present
if ! grep -q 'vault' "$DOCKERFILE"; then
    log "Patching $DOCKERFILE to install Vault CLI..."
    sed -i '/apt-get clean/a \\n# Install Vault CLI (Pure Bliss standard)\nRUN VAULT_VERSION="1.13.3" \\n    && wget -q https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \\n    && unzip vault_${VAULT_VERSION}_linux_amd64.zip \\n    && mv vault /usr/local/bin/ \\n    && chmod +x /usr/local/bin/vault \\n    && rm vault_${VAULT_VERSION}_linux_amd64.zip' "$DOCKERFILE"
    log "Vault CLI installation added to $DOCKERFILE."
else
    log "Vault CLI already present in $DOCKERFILE. Skipping patch."
fi

# Patch compose file to mount /vault-token if not present
if ! grep -q '/vault-token' "$COMPOSE_FILE"; then
    log "Patching $COMPOSE_FILE to mount /vault-token..."
    sed -i '/volumes:/a \\n      - ./secrets/vault_token:/vault-token:ro' "$COMPOSE_FILE"
    log "/vault-token mount added to $COMPOSE_FILE."
else
    log "/vault-token already mounted in $COMPOSE_FILE. Skipping patch."
fi

log "Vault CLI and /vault-token integration automation complete for $SERVICE_NAME."

# Health validation checkpoint
/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$SERVICE_NAME" automate-vault-integration
VALIDATION_RESULT=$?
if [ "$VALIDATION_RESULT" -eq 0 ]; then
    log "Health validation PASSED for $SERVICE_NAME after Vault integration automation."
else
    log "Health validation FAILED for $SERVICE_NAME after Vault integration automation. Remediation required."
    exit 1
fi

# Auto-commit integration
/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh "container-enhancement" "Automated Vault CLI and /vault-token integration" "$SERVICE_NAME"
log "Auto-commit triggered for $SERVICE_NAME Vault integration enhancement."
