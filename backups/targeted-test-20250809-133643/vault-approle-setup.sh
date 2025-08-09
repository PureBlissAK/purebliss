#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_APPROLE_SETUP_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-approle-setup.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi
if [[ -f "$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "$SCRIPT_DIR/utilities/retry-utils.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
vault_approle_setup_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_approle_setup_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_approle_setup_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

set -euo pipefail
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="https://127.0.0.1:8200"
POSTGRES_SERVICE_DIR="/opt/dev-purebliss/services/postgres"

function log_action() {
    echo "[$(date)] VAULT_POSTGRES_SETUP: $1" | tee -a "$LOG_FILE"
}

log_action "Checking Vault status..."
if ! curl -sk "$VAULT_ADDR/v1/sys/health" | grep '"sealed":false' >/dev/null; then
    log_action "ERROR: Vault is sealed or unavailable. Unseal Vault before running this script."
    exit 1
fi

log_action "Enabling database secrets engine..."
VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault/vault-root-token 2>/dev/null || echo "")
if [[ -z "$VAULT_TOKEN" ]]; then
    log_action "ERROR: Vault root token not found. Place it at /opt/my-secure-ha-stack/secrets/vault/vault-root-token."
    exit 1
fi

export VAULT_ADDR
export VAULT_TOKEN

vault secrets enable -path=database database || log_action "Database secrets engine already enabled."

log_action "Configuring Postgres plugin and connection..."
vault write database/config/postgres-app \
    plugin_name=postgresql-database-plugin \
    allowed_roles="postgres-app" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/postgres?sslmode=disable" \
    username="vaultadmin" \
    password="vaultadminpassword"

log_action "Creating Postgres role for dynamic credentials..."
vault write database/roles/postgres-app \
    db_name=postgres-app \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE postgres TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

log_action "Creating Vault policy for Postgres dynamic secrets..."
cat > "$POSTGRES_SERVICE_DIR/postgres-approle-policy.hcl" <<EOF
path "database/creds/postgres-app" {
  capabilities = ["read"]
}
EOF
vault policy write postgres-approle "$POSTGRES_SERVICE_DIR/postgres-approle-policy.hcl"

log_action "Creating AppRole for Postgres..."
vault auth enable approle || log_action "AppRole already enabled."
vault write auth/approle/role/postgres-role \
    token_policies="postgres-approle" \
    secret_id_ttl="24h" \
    token_ttl="1h" \
    token_max_ttl="24h"

log_action "Fetching AppRole credentials..."
vault read -field=role_id auth/approle/role/postgres-role/role_id > "$POSTGRES_SERVICE_DIR/role_id"
vault write -f -field=secret_id auth/approle/role/postgres-role/secret_id > "$POSTGRES_SERVICE_DIR/secret_id"
chmod 600 "$POSTGRES_SERVICE_DIR/role_id" "$POSTGRES_SERVICE_DIR/secret_id"

log_action "Vault AppRole setup for Postgres complete."
