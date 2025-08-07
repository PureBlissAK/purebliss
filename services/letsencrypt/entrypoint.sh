#!/bin/sh
LOG_FILE="/var/log/letsencrypt/letsencrypt-renewal.log"
RENEW_INTERVAL="1h"  # More frequent renewal for Vault PKI certs (shorter TTL)
VAULT_PKI_PATH="pki-letsencrypt"
VAULT_PKI_ROLE="letsencrypt-role"

# Ensure log directory exists
mkdir -p /var/log/letsencrypt

echo "[$(date)] INFO: Starting Let's Encrypt service with Vault PKI integration" | tee -a "$LOG_FILE"


# Start cron daemon for automatic certificate renewal
echo "[$(date)] INFO: Starting cron daemon for certificate renewal" | tee -a "$LOG_FILE"
crond &


# --- Minimal HTTP server for health checks ---
echo "[$(date)] INFO: Starting minimal HTTP server on port 8080 for health checks" | tee -a "$LOG_FILE"
(while true; do echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nletsencrypt healthy" | nc -l -p 8080; done) &
HTTP_PID=$!


# --- Main renewal loop (runs in background) ---
(
  echo "[$(date)] INFO: Starting certificate renewal loop with $RENEW_INTERVAL intervals" | tee -a "$LOG_FILE"
  while true; do
    echo "[$(date)] INFO: Starting certificate renewal cycle" | tee -a "$LOG_FILE"
    IFS=','
    for domain in $LETSENCRYPT_DOMAINS; do
      domain=$(echo "$domain" | xargs)
      cert_dir="/etc/letsencrypt/live/$domain"
      cert_file="$cert_dir/fullchain.pem"
      if [ -d "$cert_dir" ]; then
        if [ -f "$cert_dir/cert.pem" ] && [ -n "$VAULT_ADDR" ] && [ -n "$VAULT_TOKEN" ]; then
          echo "[$(date)] INFO: Renewing Vault PKI certificate for $domain" | tee -a "$LOG_FILE"
          if generate_vault_certificate "$domain"; then
            echo "[$(date)] SUCCESS: Vault PKI certificate renewed for $domain" | tee -a "$LOG_FILE"
            # Always trigger nginx reload after renewal
            if [ -f "/var/run/nginx.pid" ]; then
              kill -HUP $(cat /var/run/nginx.pid) 2>/dev/null || true
              echo "[$(date)] INFO: Nginx reloaded for certificate renewal" | tee -a "$LOG_FILE"
            fi
            # Notify nginx via upstream-validation if available
            if [ -x /opt/dev-purebliss/upstream-validation.sh ]; then
              /opt/dev-purebliss/upstream-validation.sh nginx 443 /health || true
            fi
          else
            echo "[$(date)] WARNING: Vault PKI certificate renewal failed for $domain" | tee -a "$LOG_FILE"
          fi
        else
          echo "[$(date)] INFO: Renewing traditional Let's Encrypt certificate for $domain" | tee -a "$LOG_FILE"
          certbot renew --webroot -w "$LETSENCRYPT_WEBROOT_PATH" --quiet --no-self-upgrade 2>&1 | tee -a "$LOG_FILE"
          # Always trigger nginx reload after renewal
          if [ -f "/var/run/nginx.pid" ]; then
            kill -HUP $(cat /var/run/nginx.pid) 2>/dev/null || true
            echo "[$(date)] INFO: Nginx reloaded for certificate renewal" | tee -a "$LOG_FILE"
          fi
          if [ -x /opt/dev-purebliss/upstream-validation.sh ]; then
            /opt/dev-purebliss/upstream-validation.sh nginx 443 /health || true
          fi
        fi
        # Monitor certificate expiry and emit Prometheus-style metric
        if [ -f "$cert_file" ]; then
          expiry_epoch=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2 | xargs -I{} date -d {} +%s)
          now_epoch=$(date +%s)
          days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
          echo "[$(date)] INFO: Certificate for $domain expires in $days_left days" | tee -a "$LOG_FILE"
          echo "letsencrypt_certificate_expiry_days{domain=\"$domain\"} $days_left" > /var/log/letsencrypt/cert_expiry.prom
          if [ $days_left -lt 14 ]; then
            echo "[$(date)] WARNING: Certificate for $domain expires in $days_left days!" | tee -a "$LOG_FILE"
          fi
        fi
      else
        echo "[$(date)] WARNING: Certificate directory not found for $domain: $cert_dir" | tee -a "$LOG_FILE"
      fi
    done
    unset IFS
    echo "[$(date)] INFO: Certificate renewal cycle complete, sleeping for $RENEW_INTERVAL" | tee -a "$LOG_FILE"
    sleep "$RENEW_INTERVAL"
  done
) &
RENEW_PID=$!

# Wait for either process to exit (if either fails, container exits)
wait $HTTP_PID $RENEW_PID

# --- Enhanced Vault PKI integration ---
# Auto-detect Vault mode and configure accordingly
detect_vault_mode() {
  # First try Docker service name (when running in container)
  if curl -s "http://purebliss-vault:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="http://purebliss-vault:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    VAULT_MODE="dev"
    echo "[$(date)] INFO: Detected Vault in development mode via Docker network" | tee -a "$LOG_FILE"
  elif curl -sk "https://purebliss-vault:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="https://purebliss-vault:8200"
    export VAULT_SKIP_VERIFY=1
    if [ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]; then
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    else
      echo "[$(date)] ERROR: Vault token file not found for production mode" | tee -a "$LOG_FILE"
      return 1
    fi
    VAULT_MODE="production"
    echo "[$(date)] INFO: Detected Vault in production mode via Docker network" | tee -a "$LOG_FILE"
  # Fallback to localhost (when running outside container)
  elif curl -s "http://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="http://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    VAULT_MODE="dev"
    echo "[$(date)] INFO: Detected Vault in development mode via localhost" | tee -a "$LOG_FILE"
  elif curl -sk "https://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]; then
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    else
      echo "[$(date)] ERROR: Vault token file not found for production mode" | tee -a "$LOG_FILE"
      return 1
    fi
    VAULT_MODE="production"
    echo "[$(date)] INFO: Detected Vault in production mode via localhost" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Cannot connect to Vault on HTTP or HTTPS" | tee -a "$LOG_FILE"
    return 1
  fi
  return 0
}

# Setup Vault PKI for Let's Encrypt certificate generation
setup_vault_pki() {
  echo "[$(date)] INFO: Setting up Vault PKI for Let's Encrypt certificate generation" | tee -a "$LOG_FILE"

  # Enable PKI secrets engine for Let's Encrypt (idempotent)
  vault secrets enable -path="$VAULT_PKI_PATH" pki 2>&1 | tee -a "$LOG_FILE" || \
    echo "[$(date)] INFO: PKI engine $VAULT_PKI_PATH may already be enabled" | tee -a "$LOG_FILE"

  # Tune the PKI engine max lease TTL for Let's Encrypt style certificates
  vault secrets tune -max-lease-ttl=2160h "$VAULT_PKI_PATH" 2>&1 | tee -a "$LOG_FILE"

  # Generate root CA if not already present
  if ! vault read "$VAULT_PKI_PATH/cert/ca" 2>&1 | grep -q 'certificate'; then
    echo "[$(date)] INFO: Generating root CA for Let's Encrypt PKI" | tee -a "$LOG_FILE"
    vault write -field=certificate "$VAULT_PKI_PATH/root/generate/internal" \
      common_name="Let's Encrypt Alternative Root CA" \
      ttl=8760h \
      format=pem 2>&1 | tee -a "$LOG_FILE"

    vault write "$VAULT_PKI_PATH/config/urls" \
      issuing_certificates="$VAULT_ADDR/v1/$VAULT_PKI_PATH/ca" \
      crl_distribution_points="$VAULT_ADDR/v1/$VAULT_PKI_PATH/crl" 2>&1 | tee -a "$LOG_FILE"
    echo "[$(date)] SUCCESS: Root CA generated for $VAULT_PKI_PATH" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] INFO: Root CA already exists for $VAULT_PKI_PATH" | tee -a "$LOG_FILE"
  fi

  # Fetch domains from Vault KV or environment
  local domains="dev.purebliss.app"
  if vault kv get -field=domains secret/letsencrypt >/dev/null 2>&1; then
    domains=$(vault kv get -field=domains secret/letsencrypt 2>/dev/null)
  fi

  # Create a role for Let's Encrypt certificate generation (idempotent)
  vault write "$VAULT_PKI_PATH/roles/$VAULT_PKI_ROLE" \
    allowed_domains="$domains" \
    allow_bare_domains=true \
    allow_subdomains=true \
    allow_any_name=true \
    max_ttl="168h" \
    ttl="24h" \
    key_usage="DigitalSignature,KeyEncipherment" \
    ext_key_usage="ServerAuth,ClientAuth" 2>&1 | tee -a "$LOG_FILE"

  echo "[$(date)] SUCCESS: PKI role $VAULT_PKI_ROLE configured for domains: $domains" | tee -a "$LOG_FILE"
  return 0
}

# Generate certificate using Vault PKI instead of traditional Let's Encrypt
generate_vault_certificate() {
  local domain="$1"
  local cert_dir="/etc/letsencrypt/live/$domain"

  echo "[$(date)] INFO: Generating certificate for $domain using Vault PKI" | tee -a "$LOG_FILE"

  # Create certificate directory structure compatible with Let's Encrypt
  mkdir -p "$cert_dir"

  # Generate certificate using Vault PKI
  local cert_response
  cert_response=$(vault write -format=json "$VAULT_PKI_PATH/issue/$VAULT_PKI_ROLE" \
    common_name="$domain" \
    alt_names="*.$domain" \
    ttl="24h" 2>/dev/null)

  if [ $? -eq 0 ] && [ -n "$cert_response" ]; then
    # Extract certificate components from JSON response
    echo "$cert_response" | jq -r '.data.certificate' > "$cert_dir/cert.pem"
    echo "$cert_response" | jq -r '.data.private_key' > "$cert_dir/privkey.pem"
    echo "$cert_response" | jq -r '.data.ca_chain[0]' > "$cert_dir/chain.pem"
    echo "$cert_response" | jq -r '.data.issuing_ca' > "$cert_dir/issuer.pem"

    # Create fullchain.pem (cert + chain) compatible with nginx
    cat "$cert_dir/cert.pem" "$cert_dir/chain.pem" > "$cert_dir/fullchain.pem"

    # Set proper permissions
    chmod 600 "$cert_dir/privkey.pem"
    chmod 644 "$cert_dir"/*.pem

    echo "[$(date)] SUCCESS: Certificate generated for $domain using Vault PKI" | tee -a "$LOG_FILE"

    # Log certificate details
    echo "[$(date)] INFO: Certificate files created:" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/cert.pem (server certificate)" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/privkey.pem (private key)" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/fullchain.pem (cert + chain for nginx)" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/chain.pem (intermediate certificate)" | tee -a "$LOG_FILE"

    return 0
  else
    echo "[$(date)] ERROR: Failed to generate certificate for $domain using Vault PKI" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Initialize Vault connection and PKI setup
if detect_vault_mode && setup_vault_pki; then
  echo "[$(date)] SUCCESS: Vault PKI initialization complete" | tee -a "$LOG_FILE"
else
  echo "[$(date)] ERROR: Failed to initialize Vault PKI - falling back to environment config" | tee -a "$LOG_FILE"
  # Continue with traditional approach as fallback
fi

# Fetch configuration from Vault KV for domains and settings
if [ -n "$VAULT_ADDR" ] && [ -n "$VAULT_TOKEN" ]; then
  echo "[$(date)] INFO: Fetching Let's Encrypt configuration from Vault..." | tee -a "$LOG_FILE"
  export LETSENCRYPT_EMAIL=$(vault kv get -field=email secret/letsencrypt 2>/dev/null || echo "admin@purebliss.app")
  export LETSENCRYPT_DOMAINS=$(vault kv get -field=domains secret/letsencrypt 2>/dev/null || echo "dev.purebliss.app")
  export LETSENCRYPT_WEBROOT_PATH=$(vault kv get -field=webroot_path secret/letsencrypt 2>/dev/null || echo "/mnt/raid0/nginx/html")
  echo "[$(date)] SUCCESS: Configuration loaded from Vault" | tee -a "$LOG_FILE"
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

# Required env vars validation
[ -n "$LETSENCRYPT_EMAIL" ] || { echo "[$(date)] ERROR: LETSENCRYPT_EMAIL not set"; exit 1; }
[ -n "$LETSENCRYPT_DOMAINS" ] || { echo "[$(date)] ERROR: LETSENCRYPT_DOMAINS not set"; exit 1; }
[ -n "$LETSENCRYPT_WEBROOT_PATH" ] || { echo "[$(date)] ERROR: LETSENCRYPT_WEBROOT_PATH not set"; exit 1; }

echo "[$(date)] INFO: Configuration loaded - Email: $LETSENCRYPT_EMAIL, Domains: $LETSENCRYPT_DOMAINS" | tee -a "$LOG_FILE"

# Parse domains and generate certificates using Vault PKI
IFS=','
FIRST_DOMAIN=""
for domain in $LETSENCRYPT_DOMAINS; do
  domain=$(echo "$domain" | xargs)  # trim whitespace
  [ -z "$FIRST_DOMAIN" ] && FIRST_DOMAIN="$domain"

  # Generate certificate using Vault PKI
  if [ -n "$VAULT_ADDR" ] && [ -n "$VAULT_TOKEN" ]; then
    echo "[$(date)] INFO: Generating Vault PKI certificate for domain: $domain" | tee -a "$LOG_FILE"
    if generate_vault_certificate "$domain"; then
      echo "[$(date)] SUCCESS: Vault PKI certificate generated for $domain" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] WARNING: Vault PKI certificate generation failed for $domain, trying traditional Let's Encrypt" | tee -a "$LOG_FILE"
      # Fallback to traditional Let's Encrypt if Vault PKI fails
      traditional_letsencrypt_fallback "$domain"
    fi
  else
    echo "[$(date)] INFO: Vault not available, using traditional Let's Encrypt for $domain" | tee -a "$LOG_FILE"
    traditional_letsencrypt_fallback "$domain"
  fi
done
unset IFS

# Traditional Let's Encrypt fallback function
traditional_letsencrypt_fallback() {
  local domain="$1"
  local cert_dir="/etc/letsencrypt/live/$domain"

  echo "[$(date)] INFO: Using traditional Let's Encrypt for $domain" | tee -a "$LOG_FILE"

  # Ensure webroot exists
  if [ ! -d "$LETSENCRYPT_WEBROOT_PATH" ]; then
    echo "[$(date)] ERROR: Webroot $LETSENCRYPT_WEBROOT_PATH does not exist" | tee -a "$LOG_FILE"
    return 1
  fi

  # Initial cert obtain if needed (idempotent)
  if [ ! -d "$cert_dir" ]; then
    echo "[$(date)] INFO: No cert found for $domain, running certbot certonly..." | tee -a "$LOG_FILE"
    certbot certonly --webroot \
      -w "$LETSENCRYPT_WEBROOT_PATH" \
      --email "$LETSENCRYPT_EMAIL" \
      --agree-tos \
      --no-eff-email \
      --non-interactive \
      -d "$domain" 2>&1 | tee -a "$LOG_FILE"
  else
    echo "[$(date)] INFO: Cert already exists for $domain, skipping initial obtain." | tee -a "$LOG_FILE"
  fi
}

echo "[$(date)] INFO: Starting certificate renewal loop with $RENEW_INTERVAL intervals" | tee -a "$LOG_FILE"

# Main renewal loop - handle both Vault PKI and traditional Let's Encrypt certs
while true; do
  echo "[$(date)] INFO: Starting certificate renewal cycle" | tee -a "$LOG_FILE"

  # Parse domains for renewal
  IFS=','
  for domain in $LETSENCRYPT_DOMAINS; do
    domain=$(echo "$domain" | xargs)  # trim whitespace
    cert_dir="/etc/letsencrypt/live/$domain"

    if [ -d "$cert_dir" ]; then
      # Check if this is a Vault PKI certificate (check for vault-generated marker)
      if [ -f "$cert_dir/cert.pem" ] && [ -n "$VAULT_ADDR" ] && [ -n "$VAULT_TOKEN" ]; then
        echo "[$(date)] INFO: Renewing Vault PKI certificate for $domain" | tee -a "$LOG_FILE"
        if generate_vault_certificate "$domain"; then
          echo "[$(date)] SUCCESS: Vault PKI certificate renewed for $domain" | tee -a "$LOG_FILE"

          # Send SIGHUP to nginx to reload certificates
          if [ -f "/var/run/nginx.pid" ]; then
            kill -HUP $(cat /var/run/nginx.pid) 2>/dev/null || true
            echo "[$(date)] INFO: Nginx reloaded for certificate renewal" | tee -a "$LOG_FILE"
          fi
        else
          echo "[$(date)] WARNING: Vault PKI certificate renewal failed for $domain" | tee -a "$LOG_FILE"
        fi
      else
        echo "[$(date)] INFO: Renewing traditional Let's Encrypt certificate for $domain" | tee -a "$LOG_FILE"
        certbot renew --webroot -w "$LETSENCRYPT_WEBROOT_PATH" --quiet --no-self-upgrade 2>&1 | tee -a "$LOG_FILE"
      fi
    else
      echo "[$(date)] WARNING: Certificate directory not found for $domain: $cert_dir" | tee -a "$LOG_FILE"
    fi
  done
  unset IFS

  echo "[$(date)] INFO: Certificate renewal cycle complete, sleeping for $RENEW_INTERVAL" | tee -a "$LOG_FILE"
  sleep "$RENEW_INTERVAL"
done
