#!/bin/bash
# Test script to validate Vault secret retrieval for PostgreSQL

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="https://vault.purebliss.app:8200"
VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token 2>/dev/null || echo "")

log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# Function to get secrets from Vault
get_vault_secret() {
    local secret_path="$1"
    local secret_key="$2"

    if [[ -z "$VAULT_TOKEN" ]]; then
        log "ERROR: Vault token not found. Cannot retrieve secrets."
        return 1
    fi

    local secret_value=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
        "$VAULT_ADDR/v1/$secret_path" | \
        jq -r ".data.data.${secret_key}" 2>/dev/null)

    if [[ "$secret_value" == "null" || -z "$secret_value" ]]; then
        log "WARNING: Could not retrieve $secret_key from $secret_path. Using fallback."
        return 1
    fi

    echo "$secret_value"
    return 0
}

log "INFO: Testing Vault secret retrieval..."

# Test Vault status
log "INFO: Checking Vault status..."
vault_status=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" | jq -r '.sealed' 2>/dev/null || echo "unknown")
log "INFO: Vault sealed status: $vault_status"

# Test retrieving PostgreSQL admin secrets
log "INFO: Testing PostgreSQL admin secret retrieval..."
POSTGRES_ADMIN_USER=$(get_vault_secret "secret/postgres/admin" "username" || echo "postgres")
POSTGRES_ADMIN_PASSWORD=$(get_vault_secret "secret/postgres/admin" "password" || echo "postgres")
POSTGRES_ADMIN_DB=$(get_vault_secret "secret/postgres/admin" "database" || echo "postgres")

log "INFO: Retrieved PostgreSQL admin user: $POSTGRES_ADMIN_USER"
log "INFO: Retrieved PostgreSQL admin database: $POSTGRES_ADMIN_DB"
log "INFO: PostgreSQL admin password retrieved: $([[ -n "$POSTGRES_ADMIN_PASSWORD" ]] && echo "YES" || echo "NO")"

# Test retrieving service database secrets
for service in plane vikunja keycloak grafana; do
    password=$(get_vault_secret "secret/database/$service" "password" || echo "fallback_password")
    log "INFO: Retrieved password for $service: $([[ "$password" != "fallback_password" ]] && echo "FROM_VAULT" || echo "FALLBACK")"
done

log "INFO: Vault secret retrieval test completed."
