#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh" || true
source "$SCRIPT_DIR/utilities/retry-utils.sh" || true
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh" || true

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Vault entrypoint wrapper: starts Vault, waits for /vault-dev-init.sh, executes it, then foregrounds Vault."

log_info "[$SCRIPT_NAME] Starting Vault server in background..."
vault server -config=/vault/config/vault-server.hcl &
VAULT_PID=$!

# Wait for Vault to start listening
for i in {1..10}; do
  if ss -ltn | grep -q ':8200'; then
    log_info "Vault is listening on 8200."
    break
  fi
  sleep 1
done

# Wait for /vault-dev-init.sh to exist and be executable
for i in {1..10}; do
  if [ -x /vault-dev-init.sh ]; then
    log_info "/vault-dev-init.sh is present and executable."
    break
  fi
  sleep 1
done

if [ ! -x /vault-dev-init.sh ]; then
  log_error "/vault-dev-init.sh not found or not executable after waiting. Exiting."
  exit 1
fi

log_info "Executing /vault-dev-init.sh..."
/vault-dev-init.sh

log_info "Foregrounding Vault process (PID $VAULT_PID)..."
wait $VAULT_PID
