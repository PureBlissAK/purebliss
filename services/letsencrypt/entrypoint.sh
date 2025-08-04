#!/bin/sh
LOG_FILE="/var/log/letsencrypt/letsencrypt-renewal.log"
RENEW_INTERVAL="12h"

# Ensure log directory exists
mkdir -p /var/log/letsencrypt


# --- Vault integration for secrets ---
# If VAULT_ADDR and VAULT_TOKEN are set, fetch secrets from Vault KV
if [ -n "$VAULT_ADDR" ] && [ -n "$VAULT_TOKEN" ]; then
  echo "[$(date)] INFO: Attempting to fetch secrets from Vault..." | tee -a "$LOG_FILE"
  export VAULT_SKIP_VERIFY=1
  # Fetch secrets from Vault KV (assume kv v2 at secret/letsencrypt)
  export LETSENCRYPT_EMAIL=$(vault kv get -field=email secret/letsencrypt 2>/dev/null || true)
  export LETSENCRYPT_DOMAINS=$(vault kv get -field=domains secret/letsencrypt 2>/dev/null || true)
  export LETSENCRYPT_WEBROOT_PATH=$(vault kv get -field=webroot_path secret/letsencrypt 2>/dev/null || true)
fi

# Fallback: Load from .env if present
if [ -z "$LETSENCRYPT_EMAIL" ] || [ -z "$LETSENCRYPT_DOMAINS" ] || [ -z "$LETSENCRYPT_WEBROOT_PATH" ]; then
  if [ -f /opt/dev-purebliss/services/letsencrypt/.env ]; then
    . /opt/dev-purebliss/services/letsencrypt/.env
  fi
fi

# Fallback: Load from config.env if present
if [ -z "$LETSENCRYPT_EMAIL" ] || [ -z "$LETSENCRYPT_DOMAINS" ] || [ -z "$LETSENCRYPT_WEBROOT_PATH" ]; then
  if [ -f /opt/my-secure-ha-stack/config.env ]; then
    . /opt/my-secure-ha-stack/config.env
  fi
fi

# Required env vars
[ -n "$LETSENCRYPT_EMAIL" ] || { echo "LETSENCRYPT_EMAIL not set (Vault, .env, config.env)"; exit 1; }
[ -n "$LETSENCRYPT_DOMAINS" ] || { echo "LETSENCRYPT_DOMAINS not set (Vault, .env, config.env)"; exit 1; }
[ -n "$LETSENCRYPT_WEBROOT_PATH" ] || { echo "LETSENCRYPT_WEBROOT_PATH not set (Vault, .env, config.env)"; exit 1; }

# Ensure webroot exists
if [ ! -d "$LETSENCRYPT_WEBROOT_PATH" ]; then
  echo "Webroot $LETSENCRYPT_WEBROOT_PATH does not exist or is not a directory" | tee -a "$LOG_FILE"
  exit 1
fi

# Convert comma-separated domains to multiple -d args (POSIX sh)
DOMAIN_ARGS=""
FIRST_DOMAIN=""
IFS=','
for d in $LETSENCRYPT_DOMAINS; do
  [ -z "$FIRST_DOMAIN" ] && FIRST_DOMAIN="$d"
  DOMAIN_ARGS="$DOMAIN_ARGS -d $d"
done
unset IFS

# Initial cert obtain if needed (idempotent)
if [ ! -d "/etc/letsencrypt/live/$FIRST_DOMAIN" ]; then
  echo "[$(date)] INFO: No cert found for $FIRST_DOMAIN, running certbot certonly..." | tee -a "$LOG_FILE"
  certbot certonly --webroot -w "$LETSENCRYPT_WEBROOT_PATH" --email "$LETSENCRYPT_EMAIL" --agree-tos --no-eff-email --non-interactive  $DOMAIN_ARGS 2>&1 | tee -a "$LOG_FILE"
else
  echo "[$(date)] INFO: Cert already exists for $FIRST_DOMAIN, skipping initial obtain." | tee -a "$LOG_FILE"
fi

echo "[$(date)] INFO: Starting certbot renewal loop" | tee -a "$LOG_FILE"
while true; do
  certbot renew --webroot -w "$LETSENCRYPT_WEBROOT_PATH" --quiet --no-self-upgrade 2>&1 | tee -a "$LOG_FILE"
  sleep "$RENEW_INTERVAL"
done
