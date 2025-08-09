#!/bin/sh


set -euo pipefail

log() {
  echo "[entrypoint.sh] $1" | tee -a /opt/my-secure-ha-stack/logs/plane-entrypoint.log
}

# Prefer Vault secrets if present, else fallback to .env
if [ -f /vault/secrets/plane-db.env ]; then
  log "Vault secrets detected. Waiting for Vault Agent to render secrets..."
  while [ ! -f /vault/secrets/plane-db.env ]; do
    sleep 2
  done
  . /vault/secrets/plane-db.env
  export PLANE_DB_USER
  export PLANE_DB_PASSWORD
  export PLANE_DB_HOST
  export PLANE_DB_PORT
  export PLANE_DB_NAME
  log "Vault secrets loaded."
elif [ -f .env ]; then
  log ".env file detected. Loading environment variables."
  set -a
  . .env
  set +a
  log ".env variables loaded."
else
  log "No Vault secrets or .env found. Proceeding with defaults."
fi

# Start Plane Node.js app if present
if [ -f server.js ]; then
  log "Starting Plane app (Node.js server.js)"
  exec node server.js
fi

# Fallback: run health endpoint for scaffolding/validation
log "No application binary found, running health-endpoint.sh for scaffolding/validation"
exec /health-endpoint.sh
