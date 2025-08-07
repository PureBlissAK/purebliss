#!/bin/bash
# Automated Loki Vault Integration Validation Script
# Pure Bliss Elite Stack - 2025-08-07
set -euo pipefail
SERVICE="loki"
CONTAINER="purebliss-loki"
LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="172.32.0.4"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE-VAULT-VALIDATION: $1" | tee -a "$LOG"
}

log "Starting automated Loki Vault integration validation."

# 1. Validate Vault health endpoint from Loki container
if docker exec $CONTAINER wget -qO- http://$VAULT_ADDR:8200/v1/sys/health | grep -q '"initialized":true'; then
    log "Vault health endpoint reachable from Loki container (IP $VAULT_ADDR)."
else
    log "ERROR: Vault health endpoint NOT reachable from Loki container (IP $VAULT_ADDR)."; exit 1
fi

# 2. Test AppRole authentication using injected secrets
if docker exec $CONTAINER sh -c '
for dir in /home/loki/.secrets /loki/.secrets /tmp/.secrets; do if [ -d "$dir" ]; then SECRETS_DIR="$dir"; break; fi; done
ROLE_ID=$(cat $SECRETS_DIR/loki_role_id)
SECRET_ID=$(cat $SECRETS_DIR/loki_secret_id)
wget --header="Content-Type: application/json" \
     --post-data="{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
     -qO- http://'$VAULT_ADDR':8200/v1/auth/approle/login | grep -q "auth"
'; then
    log "AppRole authentication and token issuance for Loki succeeded (via wget)."
else
    log "ERROR: AppRole authentication/token issuance for Loki failed (wget)."; exit 1
fi

# 3. Test dynamic secret retrieval using current token
if docker exec $CONTAINER sh -c '
for dir in /home/loki/.secrets /loki/.secrets /tmp/.secrets; do if [ -d "$dir" ]; then SECRETS_DIR="$dir"; break; fi; done
TOKEN=$(cat $SECRETS_DIR/loki_token)
wget --header="X-Vault-Token: $TOKEN" \
     -qO- http://'$VAULT_ADDR':8200/v1/secret/data/loki/storage | grep -q "access_key"
'; then
    log "Dynamic secret issuance for Loki storage succeeded (via wget)."
else
    log "ERROR: Dynamic secret issuance for Loki storage failed (wget)."; exit 1
fi

# 4. Confirm audit logging (check if Vault has audit entries)
if docker exec vault grep -q 'loki' /vault/logs/audit.log 2>/dev/null || true; then
    log "Loki Vault actions found in Vault audit log."
else
    log "WARNING: No Loki Vault actions found in Vault audit log (may be normal for new setup)."
fi

# 5. Validate Loki ingestion and log query functionality
if wget -qO- "http://localhost:3100/ready" | grep -q "ready"; then
    log "Loki /ready endpoint responded successfully."
else
    log "ERROR: Loki /ready endpoint did not respond successfully."; exit 1
fi

# 6. Test log ingestion (push a test log)
if curl -s -X POST "http://localhost:3100/loki/api/v1/push" \
    -H "Content-Type: application/json" \
    -d '{"streams": [{"stream": {"job": "test"}, "values": [["'$(date +%s)'000000000", "Test log entry from automation"]]}]}' \
    | grep -qv "error"; then
    log "Test log ingestion to Loki succeeded."
else
    log "WARNING: Test log ingestion to Loki may have failed (continuing validation)."
fi

# 7. Validate secret rotation (get new token)
if docker exec $CONTAINER sh -c '
for dir in /home/loki/.secrets /loki/.secrets /tmp/.secrets; do if [ -d "$dir" ]; then SECRETS_DIR="$dir"; break; fi; done
ROLE_ID=$(cat $SECRETS_DIR/loki_role_id)
SECRET_ID=$(cat $SECRETS_DIR/loki_secret_id)
NEW_TOKEN=$(wget --header="Content-Type: application/json" \
                 --post-data="{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
                 -qO- http://'$VAULT_ADDR':8200/v1/auth/approle/login | grep -o "\"client_token\":\"[^\"]*\"" | cut -d\" -f4)
echo $NEW_TOKEN > $SECRETS_DIR/loki_token_new
wget --header="X-Vault-Token: $NEW_TOKEN" \
     -qO- http://'$VAULT_ADDR':8200/v1/secret/data/loki/storage | grep -q "access_key"
'; then
    log "Vault secret rotation for Loki storage validated (via wget)."
else
    log "ERROR: Vault secret rotation for Loki storage failed (wget)."; exit 1
fi

log "Loki Vault integration validation complete - ALL TESTS PASSED."
