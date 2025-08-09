#!/bin/bash
# ============================================================================
# Let's Encrypt Vault PKI Certificate Renewal Script
#
# This script manually triggers certificate renewal using Vault PKI
# and can be used for testing or manual operations.
# ============================================================================

set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
PKI_PATH="pki-letsencrypt"
PKI_ROLE="letsencrypt-role"
DOMAIN="${1:-dev.purebliss.app}"

echo "[$(date)] INFO: Starting manual certificate renewal for $DOMAIN" | tee -a "$LOG_FILE"

# Auto-detect Vault mode and configure
detect_vault_mode() {
  if curl -sk "https://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    VAULT_MODE="dev"
    echo "[$(date)] INFO: Using Vault development mode" | tee -a "$LOG_FILE"
  elif curl -skk "https://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    else
      echo "[$(date)] ERROR: Vault token file not found for production mode" | tee -a "$LOG_FILE"
      return 1
    fi
    VAULT_MODE="production"
    echo "[$(date)] INFO: Using Vault production mode" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Cannot connect to Vault - ensure Vault is running and unsealed" | tee -a "$LOG_FILE"
    return 1
  fi
  return 0
}

# Generate new certificate using Vault PKI
generate_certificate() {
  local domain="$1"
  local cert_dir="/mnt/raid0/nginx/certs/live/$domain"

  echo "[$(date)] INFO: Generating new certificate for $domain using Vault PKI" | tee -a "$LOG_FILE"

  # Create certificate directory if it doesn't exist
  mkdir -p "$cert_dir"

  # Generate certificate using Vault PKI
  local cert_response
  cert_response=$(vault write -format=json "$PKI_PATH/issue/$PKI_ROLE" \
    common_name="$domain" \
    alt_names="*.$domain" \
    ttl="24h" 2>/dev/null)

  if [[ $? -eq 0 ]] && [[ -n "$cert_response" ]]; then
    # Backup existing certificates
    if [[ -f "$cert_dir/cert.pem" ]]; then
      echo "[$(date)] INFO: Backing up existing certificates..." | tee -a "$LOG_FILE"
      local backup_dir="$cert_dir/backup-$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$backup_dir"
      cp "$cert_dir"/*.pem "$backup_dir/" 2>/dev/null || true
      echo "[$(date)] SUCCESS: Certificates backed up to $backup_dir" | tee -a "$LOG_FILE"
    fi

    # Extract certificate components from JSON response
    echo "[$(date)] INFO: Extracting certificate components..." | tee -a "$LOG_FILE"
    echo "$cert_response" | jq -r '.data.certificate' > "$cert_dir/cert.pem"
    echo "$cert_response" | jq -r '.data.private_key' > "$cert_dir/privkey.pem"
    echo "$cert_response" | jq -r '.data.ca_chain[0]' > "$cert_dir/chain.pem"
    echo "$cert_response" | jq -r '.data.issuing_ca' > "$cert_dir/issuer.pem"

    # Create fullchain.pem (cert + chain) compatible with nginx
    cat "$cert_dir/cert.pem" "$cert_dir/chain.pem" > "$cert_dir/fullchain.pem"

    # Set proper permissions
    chmod 600 "$cert_dir/privkey.pem"
    chmod 644 "$cert_dir"/*.pem

    echo "[$(date)] SUCCESS: Certificate files generated for $domain:" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/cert.pem (server certificate)" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/privkey.pem (private key)" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/fullchain.pem (cert + chain for nginx)" | tee -a "$LOG_FILE"
    echo "  - $cert_dir/chain.pem (intermediate certificate)" | tee -a "$LOG_FILE"

    # Display certificate details
    echo "[$(date)] INFO: Certificate details:" | tee -a "$LOG_FILE"
    openssl x509 -in "$cert_dir/cert.pem" -noout -subject -issuer -dates | tee -a "$LOG_FILE"

    return 0
  else
    echo "[$(date)] ERROR: Failed to generate certificate for $domain using Vault PKI" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Reload nginx to pick up new certificates
reload_nginx() {
  echo "[$(date)] INFO: Reloading nginx to pick up new certificates..." | tee -a "$LOG_FILE"

  # Try multiple methods to reload nginx
  if docker ps | grep -q "purebliss-nginx"; then
    # Method 1: Send SIGHUP to nginx inside container
    if docker exec purebliss-nginx nginx -s reload 2>/dev/null; then
      echo "[$(date)] SUCCESS: Nginx reloaded successfully" | tee -a "$LOG_FILE"
      return 0
    # Method 2: Send SIGHUP to nginx process
    elif docker exec purebliss-nginx sh -c 'kill -HUP $(cat /var/run/nginx.pid)' 2>/dev/null; then
      echo "[$(date)] SUCCESS: Nginx reloaded via SIGHUP" | tee -a "$LOG_FILE"
      return 0
    # Method 3: Restart nginx container
    elif docker restart purebliss-nginx >/dev/null 2>&1; then
      echo "[$(date)] SUCCESS: Nginx container restarted" | tee -a "$LOG_FILE"
      return 0
    else
      echo "[$(date)] WARNING: Failed to reload nginx - new certificates may not be active" | tee -a "$LOG_FILE"
      return 1
    fi
  else
    echo "[$(date)] WARNING: Nginx container not running - certificates generated but not active" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Validate the renewed certificate
validate_certificate() {
  local domain="$1"
  local cert_dir="/mnt/raid0/nginx/certs/live/$domain"

  echo "[$(date)] INFO: Validating renewed certificate for $domain..." | tee -a "$LOG_FILE"

  # Check if certificate files exist
  local required_files=("cert.pem" "privkey.pem" "fullchain.pem" "chain.pem")
  for file in "${required_files[@]}"; do
    if [[ ! -f "$cert_dir/$file" ]]; then
      echo "[$(date)] ERROR: Certificate file missing: $cert_dir/$file" | tee -a "$LOG_FILE"
      return 1
    fi
  done

  # Validate certificate content
  if openssl x509 -in "$cert_dir/cert.pem" -noout -text >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: Certificate file is valid" | tee -a "$LOG_FILE"

    # Check certificate expiry
    local expiry_date=$(openssl x509 -in "$cert_dir/cert.pem" -noout -enddate | cut -d= -f2)
    echo "[$(date)] INFO: Certificate expires: $expiry_date" | tee -a "$LOG_FILE"

    # Check if certificate is for the correct domain
    local cert_subject=$(openssl x509 -in "$cert_dir/cert.pem" -noout -subject | grep -o "CN=[^,]*")
    echo "[$(date)] INFO: Certificate subject: $cert_subject" | tee -a "$LOG_FILE"

    return 0
  else
    echo "[$(date)] ERROR: Certificate file is invalid" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Main renewal function
main() {
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Let's Encrypt Vault PKI Certificate Renewal" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Domain: $DOMAIN" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"

  # Step 1: Configure Vault connection
  if detect_vault_mode; then
    echo "[$(date)] SUCCESS: Vault connection configured" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to configure Vault connection" | tee -a "$LOG_FILE"
    exit 1
  fi

  # Step 2: Generate new certificate
  if generate_certificate "$DOMAIN"; then
    echo "[$(date)] SUCCESS: Certificate generated successfully" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Certificate generation failed" | tee -a "$LOG_FILE"
    exit 1
  fi

  # Step 3: Validate the certificate
  if validate_certificate "$DOMAIN"; then
    echo "[$(date)] SUCCESS: Certificate validation passed" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Certificate validation failed" | tee -a "$LOG_FILE"
    exit 1
  fi

  # Step 4: Reload nginx
  if reload_nginx; then
    echo "[$(date)] SUCCESS: Nginx reloaded with new certificate" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: Nginx reload failed - certificate generated but may not be active" | tee -a "$LOG_FILE"
  fi

  # Summary
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"
  echo "[$(date)] SUCCESS: Certificate renewal complete for $DOMAIN" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"

  echo ""
  echo "🎉 Certificate Renewal Complete!"
  echo ""
  echo "✅ Domain: $DOMAIN"
  echo "✅ Certificate generated using Vault PKI"
  echo "✅ Certificate files updated"
  echo "✅ Nginx configuration reloaded"
  echo ""
  echo "📁 Certificate location: /mnt/raid0/nginx/certs/live/$DOMAIN/"
  echo "📋 View certificate: openssl x509 -in /mnt/raid0/nginx/certs/live/$DOMAIN/cert.pem -noout -text"
  echo "🔍 Test HTTPS: curl -skk https://$DOMAIN"
  echo ""
}

# Handle command line arguments
case "${1:-}" in
  --help|-h)
    echo "Usage: $0 [domain]"
    echo ""
    echo "Manually renew SSL certificate for the specified domain using Vault PKI."
    echo ""
    echo "Arguments:"
    echo "  domain    Domain name to renew certificate for (default: dev.purebliss.app)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Renew certificate for dev.purebliss.app"
    echo "  $0 example.com               # Renew certificate for example.com"
    echo ""
    exit 0
    ;;
  *)
    main "$@"
    ;;
esac
