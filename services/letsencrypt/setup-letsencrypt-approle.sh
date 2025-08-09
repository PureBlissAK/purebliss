#!/bin/bash
set -euo pipefail

# LetsEncrypt AppRole and Policy Provisioning Script
# Creates AppRole credentials for LetsEncrypt PKI integration
# Based on vault-agent pattern used in earlier iterations

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    echo "Warning: common-functions-library.sh not found, using basic logging"
    log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
    log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
    log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
}

VAULT_ADDR="http://localhost:8201"  # Dedicated LetsEncrypt Vault
SECRETS_DIR="/opt/my-secure-ha-stack/secrets"
LETSENCRYPT_POLICY_NAME="letsencrypt-policy"
LETSENCRYPT_APPROLE_NAME="letsencrypt-approle"
LETSENCRYPT_CREDS_FILE="$SECRETS_DIR/letsencrypt-approle-creds.env"

log_info "LETSENCRYPT_APPROLE_SETUP: Starting AppRole configuration for LetsEncrypt PKI integration"

# Check if dedicated Vault is running
if ! docker ps --format "table {{.Names}}" | grep -q "vault-dev-letsencrypt"; then
    log_error "Dedicated vault-dev-letsencrypt container is not running"
    exit 1
fi

# Set up environment for dedicated Vault
export VAULT_ADDR
export VAULT_TOKEN="dev-root-token-letsencrypt"  # Dev token for dedicated Vault
export VAULT_SKIP_VERIFY=1

mkdir -p "$SECRETS_DIR"

log_info "Connecting to dedicated LetsEncrypt Vault at $VAULT_ADDR"

# Verify Vault connectivity
if ! vault status &>/dev/null; then
    log_error "Cannot connect to Vault at $VAULT_ADDR"
    exit 1
fi

# 1. Enable AppRole auth if not already enabled
log_info "Checking AppRole auth method..."
if ! vault auth list -format=json | grep -q 'approle/'; then
    log_info "Enabling AppRole auth method..."
    vault auth enable approle
else
    log_info "AppRole auth method already enabled"
fi

# 2. Create LetsEncrypt policy for PKI operations

# Create LetsEncrypt PKI policy file and ensure it exists before writing
log_info "Creating LetsEncrypt PKI policy..."
POLICY_FILE="$(pwd)/$LETSENCRYPT_POLICY_NAME.hcl"
cat > "$POLICY_FILE" <<EOF
# PKI engine access for certificate operations
path "pki-letsencrypt/issue/letsencrypt-role" {
  capabilities = ["create", "update"]
}

path "pki-letsencrypt/cert/ca" {
  capabilities = ["read"]
}

path "pki-letsencrypt/certs" {
  capabilities = ["list"]
}

# Token self-management
path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

# Debug: List /tmp and show policy file contents
ls -l "$(pwd)" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
if [[ -f "$POLICY_FILE" ]]; then
  echo "--- POLICY FILE CONTENTS ---" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
  cat "$POLICY_FILE" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
  echo "--- END POLICY FILE ---" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
  # Copy policy file into container
  docker cp "$POLICY_FILE" vault-dev-letsencrypt:/tmp/letsencrypt-policy.hcl
  # Run policy write inside container
  docker exec vault-dev-letsencrypt env VAULT_ADDR="https://127.0.0.1:8200" vault policy write letsencrypt-policy /tmp/letsencrypt-policy.hcl 2>&1 | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
  POLICY_STATUS=${PIPESTATUS[0]}
  # Clean up policy file from host and container
  rm -f "$POLICY_FILE"
  docker exec vault-dev-letsencrypt rm -f /tmp/letsencrypt-policy.hcl
  if [[ $POLICY_STATUS -eq 0 ]]; then
    log_success "LetsEncrypt PKI policy created"
  else
    log_error "vault policy write failed with exit code $POLICY_STATUS. See log for details."
    exit 2
  fi
else
  log_error "Failed to create LetsEncrypt PKI policy file at $POLICY_FILE"
  exit 1
fi

if [[ -f "$POLICY_FILE" ]]; then
  log_info "DEBUG: POLICY_FILE created at $POLICY_FILE, attempting vault policy write..."
  export VAULT_ADDR="http://localhost:8201"
  export VAULT_TOKEN="dev-root-token-letsencrypt"
  vault policy write "$LETSENCRYPT_POLICY_NAME" "$POLICY_FILE" 2>&1 | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
  POLICY_STATUS=${PIPESTATUS[0]}
  rm -f "$POLICY_FILE"
  if [[ $POLICY_STATUS -eq 0 ]]; then
    log_success "LetsEncrypt PKI policy created"
  else
    log_error "vault policy write failed with exit code $POLICY_STATUS. See log for details."
    exit 2
  fi
else
  log_error "Failed to create LetsEncrypt PKI policy file at $POLICY_FILE"
  exit 1
fi

# 3. Create or update the AppRole for LetsEncrypt
log_info "Creating/updating LetsEncrypt AppRole..."
if ! vault read auth/approle/role/$LETSENCRYPT_APPROLE_NAME > /dev/null 2>&1; then
    log_info "Creating AppRole $LETSENCRYPT_APPROLE_NAME..."
    vault write auth/approle/role/$LETSENCRYPT_APPROLE_NAME \
        token_policies="$LETSENCRYPT_POLICY_NAME" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true \
        secret_id_ttl=0 \
        secret_id_num_uses=0
else
    log_info "AppRole $LETSENCRYPT_APPROLE_NAME already exists. Updating policy..."
    vault write auth/approle/role/$LETSENCRYPT_APPROLE_NAME \
        token_policies="$LETSENCRYPT_POLICY_NAME"
fi

# 4. Fetch RoleID and SecretID
log_info "Generating AppRole credentials..."
ROLE_ID=$(vault read -field=role_id auth/approle/role/$LETSENCRYPT_APPROLE_NAME/role-id)
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/$LETSENCRYPT_APPROLE_NAME/secret-id)

# 5. Store credentials securely
log_info "Storing LetsEncrypt AppRole credentials..."
cat > "$LETSENCRYPT_CREDS_FILE" <<EOF
# LetsEncrypt AppRole credentials (auto-generated)
# Used by vault-agent for PKI certificate operations
VAULT_ADDR="$VAULT_ADDR"
LETSENCRYPT_ROLE_ID="$ROLE_ID"
LETSENCRYPT_SECRET_ID="$SECRET_ID"
EOF
chmod 600 "$LETSENCRYPT_CREDS_FILE"

log_success "LetsEncrypt AppRole credentials written to $LETSENCRYPT_CREDS_FILE"

# 6. Test AppRole authentication
log_info "Testing AppRole authentication..."
AUTH_RESPONSE=$(vault write -format=json auth/approle/login \
    role_id="$ROLE_ID" \
    secret_id="$SECRET_ID")

if echo "$AUTH_RESPONSE" | jq -r '.auth.client_token' > /dev/null 2>&1; then
    log_success "AppRole authentication test successful"
    TEST_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.auth.client_token')

    # Test PKI access with the new token
    log_info "Testing PKI access with AppRole token..."
    VAULT_TOKEN="$TEST_TOKEN" vault write pki-letsencrypt/issue/letsencrypt-role \
        common_name="test.dev.purebliss.app" \
        ttl="1h" > /dev/null

    log_success "PKI certificate generation test successful with AppRole token"
else
    log_error "AppRole authentication test failed"
    exit 1
fi

log_success "LETSENCRYPT_APPROLE_SETUP: Complete - AppRole credentials ready for vault-agent integration"
log_info "Next steps: Configure vault-agent to use role_id and secret_id for automated PKI operations"
