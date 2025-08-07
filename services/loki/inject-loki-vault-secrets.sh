#!/bin/bash
# Securely inject Vault AppRole secrets into the running Loki container for automation
# Pure Bliss Elite Stack - 2025-08-07
set -euo pipefail
SERVICE="loki"
CONTAINER="purebliss-loki"
LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Usage: ./inject-loki-vault-secrets.sh <role_id> <secret_id> [token]
ROLE_ID="${1:-}"
SECRET_ID="${2:-}"
TOKEN="${3:-}"

if [[ -z "$ROLE_ID" || -z "$SECRET_ID" ]]; then
  echo "Usage: $0 <role_id> <secret_id> [token]" >&2
  exit 2
fi

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE-SECRET-INJECT: $1" | tee -a "$LOG"
}

log "Injecting Vault AppRole secrets into $CONTAINER."

# Create a temp secrets file
TMPDIR=$(mktemp -d)
echo -n "$ROLE_ID" > "$TMPDIR/loki_role_id"
echo -n "$SECRET_ID" > "$TMPDIR/loki_secret_id"
if [[ -n "$TOKEN" ]]; then
  echo -n "$TOKEN" > "$TMPDIR/loki_token"
fi

# Copy secrets into the container (to /tmp/loki-secrets, then move to secure location)
docker exec $CONTAINER mkdir -p /tmp/loki-secrets
for f in "$TMPDIR"/*; do
  docker cp "$f" "$CONTAINER:/tmp/loki-secrets/$(basename "$f")"
done

# Move to more secure location and set permissions
docker exec $CONTAINER sh -c 'mkdir -p /etc/loki-secrets 2>/dev/null || mkdir -p /var/lib/loki-secrets'
docker exec $CONTAINER sh -c 'cp /tmp/loki-secrets/* /etc/loki-secrets/ 2>/dev/null || cp /tmp/loki-secrets/* /var/lib/loki-secrets/'
docker exec $CONTAINER sh -c 'chmod 600 /etc/loki-secrets/* 2>/dev/null || chmod 600 /var/lib/loki-secrets/*'
docker exec $CONTAINER rm -rf /tmp/loki-secrets

# Clean up temp files
rm -rf "$TMPDIR"

log "Vault AppRole secrets injected into $CONTAINER (secured location)."

# Optionally, export env vars for health/validation scripts (try both paths)
docker exec $CONTAINER sh -c 'SECRETS_DIR="/etc/loki-secrets"; [ ! -d "$SECRETS_DIR" ] && SECRETS_DIR="/var/lib/loki-secrets"; export LOKI_VAULT_ROLE_ID=$(cat $SECRETS_DIR/loki_role_id); export LOKI_VAULT_SECRET_ID=$(cat $SECRETS_DIR/loki_secret_id); [ -f $SECRETS_DIR/loki_token ] && export LOKI_VAULT_TOKEN=$(cat $SECRETS_DIR/loki_token); echo "Secrets exported for validation from $SECRETS_DIR."'

log "Injection complete. Proceed with validation."
