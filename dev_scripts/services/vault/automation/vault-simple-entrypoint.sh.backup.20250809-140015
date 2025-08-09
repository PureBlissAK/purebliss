#!/bin/bash
set -euo pipefail

echo "Starting Vault server in background..."
vault server -config=/vault/config/vault-server.hcl &
VAULT_PID=$!

# Wait for Vault to start listening
for i in {1..10}; do
  if netstat -ln | grep -q ':8200' || ss -ltn | grep -q ':8200'; then
    echo "Vault is listening on port 8200."
    break
  fi
  echo "Waiting for Vault to start... ($i/10)"
  sleep 2
done

# Wait for /vault-dev-init.sh to exist and be executable
for i in {1..10}; do
  if [ -x /vault-dev-init.sh ]; then
    echo "/vault-dev-init.sh is present and executable."
    break
  fi
  echo "Waiting for /vault-dev-init.sh... ($i/10)"
  sleep 1
done

if [ ! -x /vault-dev-init.sh ]; then
  echo "ERROR: /vault-dev-init.sh not found or not executable after waiting. Exiting."
  exit 1
fi

echo "Executing /vault-dev-init.sh..."
/vault-dev-init.sh

echo "Foregrounding Vault process (PID $VAULT_PID)..."
wait $VAULT_PID
