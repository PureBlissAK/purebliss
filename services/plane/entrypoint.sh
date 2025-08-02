#!/bin/sh
set -euo pipefail

# Wait for Vault Agent to render secrets
while [ ! -f /vault/secrets/plane-db.env ]; do
  echo "Waiting for Vault Agent to render secrets..."
  sleep 2
done

. /vault/secrets/plane-db.env

export PLANE_DB_USER
export PLANE_DB_PASSWORD
export PLANE_DB_HOST
export PLANE_DB_PORT
export PLANE_DB_NAME

exec node server.js
