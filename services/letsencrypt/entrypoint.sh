#!/bin/sh
LOG_FILE="/var/log/letsencrypt/letsencrypt-renewal.log"
RENEW_INTERVAL="12h"

# Ensure log directory exists
mkdir -p /var/log/letsencrypt

# Load environment variables from .env if present
if [ -f /opt/dev-purebliss/services/letsencrypt/.env ]; then
  . /opt/dev-purebliss/services/letsencrypt/.env
fi

# Required env vars
[ -n "$LETSENCRYPT_EMAIL" ] || { echo "LETSENCRYPT_EMAIL not set"; exit 1; }
[ -n "$LETSENCRYPT_DOMAINS" ] || { echo "LETSENCRYPT_DOMAINS not set"; exit 1; }
[ -n "$LETSENCRYPT_WEBROOT_PATH" ] || { echo "LETSENCRYPT_WEBROOT_PATH not set"; exit 1; }

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
  certbot certonly --webroot -w "$LETSENCRYPT_WEBROOT_PATH" --email "$LETSENCRYPT_EMAIL" --agree-tos --no-eff-email --non-interactive $DOMAIN_ARGS 2>&1 | tee -a "$LOG_FILE"
else
  echo "[$(date)] INFO: Cert already exists for $FIRST_DOMAIN, skipping initial obtain." | tee -a "$LOG_FILE"
fi

echo "[$(date)] INFO: Starting certbot renewal loop" | tee -a "$LOG_FILE"
while true; do
  certbot renew --webroot -w "$LETSENCRYPT_WEBROOT_PATH" --quiet --no-self-upgrade 2>&1 | tee -a "$LOG_FILE"
  sleep "$RENEW_INTERVAL"
done
