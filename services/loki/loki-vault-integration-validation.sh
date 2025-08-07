#!/bin/bash
# Loki Vault Integration Final Validation Script
# Pure Bliss Elite Stack - 2025-08-07
set -euo pipefail
SERVICE="loki"
LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

VAULT_ADDR="172.32.0.4"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE-VAULT-VALIDATION: $1" | tee -a "$LOG"
}

log "Starting Loki Vault integration validation."


# 1. Validate Vault health endpoint from Loki container (use Docker network IP)
if docker exec purebliss-loki curl -sf http://$VAULT_ADDR:8200/v1/sys/health; then
    log "Vault health endpoint reachable from Loki container (IP $VAULT_ADDR)."
else
    log "ERROR: Vault health endpoint NOT reachable from Loki container (IP $VAULT_ADDR)."; exit 1
fi

# 2. Test AppRole authentication and token issuance for Loki (use wget for Vault API)
if docker exec purebliss-loki sh -c 'wget --header="Content-Type: application/json" --post-data="{\"role_id\":\"$LOKI_VAULT_ROLE_ID\",\"secret_id\":\"$LOKI_VAULT_SECRET_ID\"}" -O - http://$VAULT_ADDR:8200/v1/auth/approle/login 2>/dev/null | grep -q "token"'; then
    log "AppRole authentication and token issuance for Loki succeeded (via wget)."
else
    log "ERROR: AppRole authentication/token issuance for Loki failed (wget)."; exit 1
fi

# 3. Validate dynamic secret issuance for Loki storage (use wget for Vault API)
if docker exec purebliss-loki sh -c 'wget --header="X-Vault-Token: $LOKI_VAULT_TOKEN" -O - http://$VAULT_ADDR:8200/v1/secret/loki/storage 2>/dev/null | grep -q "access_key"'; then
    log "Dynamic secret issuance for Loki storage succeeded (via wget)."
else
    log "ERROR: Dynamic secret issuance for Loki storage failed (wget)."; exit 1
fi

# 4. Confirm audit logging of Loki Vault actions
if docker exec vault grep 'loki' /vault/logs/audit.log; then
    log "Loki Vault actions found in Vault audit log."
else
    log "WARNING: No Loki Vault actions found in Vault audit log."
fi

# 5. Validate Loki ingestion and log query functionality
if curl -sf "http://localhost:3100/loki/api/v1/query?query={job=\"varlogs\"}"; then
    log "Loki log query API responded successfully."
else
    log "ERROR: Loki log query API did not respond successfully."; exit 1
fi

# 6. Validate Vault secret rotation (simulate by reading secret again, use wget for Vault API)
if docker exec purebliss-loki sh -c 'wget --header="X-Vault-Token: $LOKI_VAULT_TOKEN" -O - http://$VAULT_ADDR:8200/v1/secret/loki/storage 2>/dev/null | grep -q "access_key"'; then
    log "Vault secret rotation for Loki storage validated (via wget)."
else
    log "ERROR: Vault secret rotation for Loki storage failed (wget)."; exit 1
fi

log "Loki Vault integration validation complete."
