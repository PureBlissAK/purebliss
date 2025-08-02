#!/bin/bash
set -euo pipefail
# Script to upload Nginx and Let's Encrypt certs/keys to Vault for production-ready secret management
# Usage: ./vault-secrets.sh <service> (nginx|letsencrypt)

# Ensure environment variables are set correctly
export VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200}
export VAULT_TOKEN=${VAULT_TOKEN:-${VAULT_DEV_ROOT_TOKEN:-}}
CERTS_PATH=""
VAULT_SECRET_PATH=""

if [ $# -ne 1 ]; then
  echo "Usage: $0 <service> (nginx|letsencrypt)"
  exit 1
fi

SERVICE="$1"

case "$SERVICE" in
  nginx)
    # Look for self-signed certificates
    CERTS_PATH="/mnt/raid0/nginx/certs/dev.purebliss.app"
    VAULT_SECRET_PATH="secret"
    ;;
  letsencrypt)
    # Look for Let's Encrypt certificates
    CERTS_PATH=""
    VAULT_SECRET_PATH="secret"
    # Check for Let's Encrypt certificates in different possible locations
    for cert_dir in "/mnt/raid0/nginx/certs/live/dev.purebliss.app-0001" "/mnt/raid0/nginx/certs/live/dev.purebliss.app"; do
      if [ -d "$cert_dir" ]; then
        CERTS_PATH="$cert_dir"
        break
      fi
    done
    ;;
  *)
    echo "Unknown service: $SERVICE"
    exit 1
    ;;
esac

if [ ! -d "$CERTS_PATH" ]; then
  echo "Certs directory $CERTS_PATH does not exist for $SERVICE!"
  exit 1
fi

# Upload certificate files to Vault
for file in "$CERTS_PATH"/*.pem; do
  [ -f "$file" ] || continue
  key=$(basename "$file")
  echo "Uploading $key to Vault..."
  # Use base64 encoding to handle special characters in certificate files
  value=$(base64 -w 0 "$file")

    # Use curl to upload to Vault API
  response=$(curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"data\":{\"$key\":\"$value\"}}" \
    "$VAULT_ADDR/v1/secret/data/$SERVICE")

  if echo "$response" | grep -q "request_id"; then
    echo "Successfully uploaded $key"
  else
    echo "Failed to upload $key: $response"
  fi
done

echo "Uploaded certs/keys for $SERVICE to Vault at $VAULT_SECRET_PATH"
