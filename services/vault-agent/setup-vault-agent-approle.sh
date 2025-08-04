#!/bin/bash
set -euo pipefail

# Script to generate Vault Agent AppRole credentials
# This should be run after Vault is initialized and unsealed

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="https://127.0.0.1:8200"
VAULT_SKIP_VERIFY=1

echo "[$(date)] VAULT_AGENT_SETUP: Generating AppRole credentials for Vault Agent..." | tee -a "$LOG_FILE"

# Check if Vault token exists
if [[ ! -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
    echo "[$(date)] ERROR: Vault token not found. Please ensure Vault is initialized and unsealed." | tee -a "$LOG_FILE"
    exit 1
fi

export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
export VAULT_ADDR
export VAULT_SKIP_VERIFY

# Create AppRole for Vault Agent if it doesn't exist
echo "[$(date)] VAULT_AGENT_SETUP: Creating AppRole for Vault Agent..." | tee -a "$LOG_FILE"

# Create policy for Vault Agent
echo "[$(date)] VAULT_AGENT_SETUP: Creating policy for Vault Agent..." | tee -a "$LOG_FILE"

vault policy write vault-agent-policy - << EOF
# Allow reading database credentials
path "database/creds/postgres-role" {
  capabilities = ["read"]
}

# Allow reading static secrets
path "secret/data/*" {
  capabilities = ["read"]
}

# Allow token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow token lookup-self
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

# Create AppRole
vault write auth/approle/role/vault-agent \
    token_policies="vault-agent-policy" \
    token_ttl=1h \
    token_max_ttl=4h \
    bind_secret_id=true \
    secret_id_ttl=0 \
    secret_id_num_uses=0

# Get role ID and save it
ROLE_ID=$(vault read -field=role_id auth/approle/role/vault-agent/role-id)
echo "$ROLE_ID" > "/opt/my-secure-ha-stack/secrets/vault-agent-role-id/role_id"
chmod 600 "/opt/my-secure-ha-stack/secrets/vault-agent-role-id/role_id"

# Generate secret ID and save it
SECRET_ID=$(vault write -force -field=secret_id auth/approle/role/vault-agent/secret-id)
echo "$SECRET_ID" > "/opt/my-secure-ha-stack/secrets/vault-agent-secret-id/secret_id"
chmod 600 "/opt/my-secure-ha-stack/secrets/vault-agent-secret-id/secret_id"

echo "[$(date)] VAULT_AGENT_SETUP: SUCCESS - AppRole credentials generated for Vault Agent" | tee -a "$LOG_FILE"
echo "[$(date)] VAULT_AGENT_SETUP: Role ID saved to /opt/my-secure-ha-stack/secrets/vault-agent-role-id/role_id" | tee -a "$LOG_FILE"
echo "[$(date)] VAULT_AGENT_SETUP: Secret ID saved to /opt/my-secure-ha-stack/secrets/vault-agent-secret-id/secret_id" | tee -a "$LOG_FILE"
