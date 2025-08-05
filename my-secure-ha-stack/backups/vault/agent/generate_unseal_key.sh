#!/bin/bash
set -euo pipefail
VAULT_CONTAINER="purebliss-vault"
UNSEAL_DIR="/opt/my-secure-ha-stack/vault/unseal"
mkdir -p "$UNSEAL_DIR"
# Set Vault address to HTTP
# Initialize Vault if not already initialized
if ! docker exec $VAULT_CONTAINER env VAULT_ADDR="http://127.0.0.1:8200" vault status | grep -q 'Initialized.*true'; then
  INIT_JSON=$(docker exec $VAULT_CONTAINER env VAULT_ADDR="http://127.0.0.1:8200" vault operator init -key-shares=1 -key-threshold=1 -format=json)
  UNSEAL_KEY=$(echo "$INIT_JSON" | jq -r '.unseal_keys_b64[0]')
  echo "{\"unseal_key\": \"$UNSEAL_KEY\"}" > "$UNSEAL_DIR/unseal_key.json"
  echo "$INIT_JSON" > "$UNSEAL_DIR/init_output.json"
  echo "Vault initialized and unseal key stored."
else
  echo "Vault already initialized."
fi
