#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# PLANE_APPROLE_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="plane-approle.sh"
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
plane_approle_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
plane_approle_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
plane_approle_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

set -euo pipefail
# Plane AppRole and Policy Provisioning Script
# Follows Vault best practices: least privilege, no hardcoded secrets, idempotent, logs actions.
# Stores credentials in /opt/my-secure-ha-stack/secrets/plane-approle-creds.env

VAULT_ADDR="http://localhost:8200"
SECRETS_DIR="/opt/my-secure-ha-stack/secrets"
PLANE_POLICY_NAME="plane-policy"
PLANE_APPROLE_NAME="plane-approle"
PLANE_SECRET_PATH="secret/data/plane/*"
PLANE_CREDS_FILE="$SECRETS_DIR/plane-approle-creds.env"

# Load root token securely
source /opt/my-secure-ha-stack/vault-unseal-keys.env
export VAULT_ADDR
export VAULT_TOKEN="${VAULT_ROOT_TOKEN:-}" # Use VAULT_ROOT_TOKEN from env file

mkdir -p "$SECRETS_DIR"

# 1. Enable AppRole auth if not already enabled
if ! vault auth list -format=json | grep -q 'approle/'; then
  echo "[INFO] Enabling AppRole auth method..."
  vault auth enable approle
else
  echo "[INFO] AppRole auth method already enabled."
fi

# 2. Create Plane policy (least privilege)
cat > /tmp/$PLANE_POLICY_NAME.hcl <<EOF
path "$PLANE_SECRET_PATH" {
  capabilities = ["create", "update", "read", "list"]
}
EOF
vault policy write "$PLANE_POLICY_NAME" /tmp/$PLANE_POLICY_NAME.hcl
rm /tmp/$PLANE_POLICY_NAME.hcl

# 3. Create or update the AppRole for Plane
if ! vault read auth/approle/role/$PLANE_APPROLE_NAME > /dev/null 2>&1; then
  echo "[INFO] Creating AppRole $PLANE_APPROLE_NAME..."
  vault write auth/approle/role/$PLANE_APPROLE_NAME policies="$PLANE_POLICY_NAME" token_ttl=1h token_max_ttl=4h
else
  echo "[INFO] AppRole $PLANE_APPROLE_NAME already exists. Updating policy..."
  vault write auth/approle/role/$PLANE_APPROLE_NAME policies="$PLANE_POLICY_NAME"
fi

# 4. Fetch RoleID and SecretID
ROLE_ID=$(vault read -field=role_id auth/approle/role/$PLANE_APPROLE_NAME/role-id)
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/$PLANE_APPROLE_NAME/secret-id)

# 5. Store credentials securely
cat > "$PLANE_CREDS_FILE" <<EOF
# Plane AppRole credentials (auto-generated)
VAULT_ADDR="$VAULT_ADDR"
PLANE_ROLE_ID="$ROLE_ID"
PLANE_SECRET_ID="$SECRET_ID"
EOF
chmod 600 "$PLANE_CREDS_FILE"

echo "[INFO] Plane AppRole credentials written to $PLANE_CREDS_FILE"
