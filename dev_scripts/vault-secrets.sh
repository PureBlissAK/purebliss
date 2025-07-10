#!/bin/bash
set -euo pipefail
# Script to upload Nginx and Let's Encrypt certs/keys to Vault for production-ready secret management
# Usage: ./vault-secrets.sh <service> (nginx|letsencrypt)

VAULT_ADDR=${VAULT_ADDR:-http://127.0.0.1:8200}
VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN:-}
CERTS_PATH=""
VAULT_SECRET_PATH=""

if [ $# -ne 1 ]; then
  echo "Usage: $0 <service> (nginx|letsencrypt)"
  exit 1
fi

SERVICE="$1"

case "$SERVICE" in
  nginx)
    CERTS_PATH="/mnt/raid0/nginx/certs"
    VAULT_SECRET_PATH="secret/nginx/certs"
    ;;
  letsencrypt)
    CERTS_PATH="/mnt/raid0/nginx/certs/live"
    VAULT_SECRET_PATH="secret/letsencrypt/certs"
    ;;
  *)
    echo "Unknown service: $SERVICE"
    exit 1
    ;;
esac

if [ ! -d "$CERTS_PATH" ]; then
  echo "Certs directory $CERTS_PATH does not exist!"
  exit 1
fi

for file in "$CERTS_PATH"/*; do
  [ -f "$file" ] || continue
  key=$(basename "$file")
  value=$(cat "$file")
  vault kv put "$VAULT_SECRET_PATH" "$key"="$value"
done

echo "Uploaded certs/keys for $SERVICE to Vault at $VAULT_SECRET_PATH"
