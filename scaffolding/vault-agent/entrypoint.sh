#!/bin/bash
set -euo pipefail

# Entrypoint for Vault Agent container (LetsEncrypt PKI integration)
# Expects role_id and secret_id to be mounted at /vault/approle/

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
ROLE_ID_FILE="/vault/approle/role_id"
SECRET_ID_FILE="/vault/approle/secret_id"

if [[ ! -f "$ROLE_ID_FILE" || ! -f "$SECRET_ID_FILE" ]]; then
  echo "[$(date)] - VAULT_AGENT_ENTRYPOINT: Missing AppRole credentials (role_id/secret_id)" | tee -a "$LOG_FILE"
  exit 1
fi

echo "[$(date)] - VAULT_AGENT_ENTRYPOINT: Starting Vault Agent with AppRole auth for LetsEncrypt PKI" | tee -a "$LOG_FILE"

exec vault agent -config=/etc/vault-agent-config.hcl
