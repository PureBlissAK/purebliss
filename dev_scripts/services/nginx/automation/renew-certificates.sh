#!/bin/bash
set -euo pipefail

# Nginx Certificate Renewal via Vault PKI
# Automatically renews certificates before expiration

VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
DOMAIN="${DOMAIN:-dev.purebliss.app}"
CERT_PATH="/etc/nginx/certs"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] NGINX_CERT_RENEWAL: $1" | tee -a "$LOG_FILE"
}

function check_certificate_expiry() {
    if [[ ! -f "$CERT_PATH/nginx.crt" ]]; then
        log_action "Certificate not found, requesting new certificate"
        return 1
    fi
    
    # Check if certificate expires within 30 days
    if openssl x509 -checkend 2592000 -noout -in "$CERT_PATH/nginx.crt" >/dev/null 2>&1; then
        log_action "Certificate is valid for more than 30 days"
        return 0
    else
        log_action "Certificate expires within 30 days, renewal needed"
        return 1
    fi
}

function renew_certificate() {
    log_action "Renewing SSL certificate via Vault PKI..."
    
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    
    # Request new certificate
    CERT_RESPONSE=$(vault write -format=json pki/issue/purebliss-role \
        common_name="$DOMAIN" \
        alt_names="*.${DOMAIN},localhost" \
        ttl=8760h 2>/dev/null || echo '{}')
    
    if [[ "$CERT_RESPONSE" != '{}' ]]; then
        # Backup existing certificates
        if [[ -f "$CERT_PATH/nginx.crt" ]]; then
            cp "$CERT_PATH/nginx.crt" "$CERT_PATH/nginx.crt.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$CERT_PATH/nginx.key" "$CERT_PATH/nginx.key.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Save new certificates
        echo "$CERT_RESPONSE" | jq -r '.data.certificate' > "$CERT_PATH/nginx.crt"
        echo "$CERT_RESPONSE" | jq -r '.data.private_key' > "$CERT_PATH/nginx.key"
        echo "$CERT_RESPONSE" | jq -r '.data.issuing_ca' > "$CERT_PATH/ca.crt"
        
        # Set proper permissions
        chmod 644 "$CERT_PATH/nginx.crt" "$CERT_PATH/ca.crt"
        chmod 600 "$CERT_PATH/nginx.key"
        
        log_action "Certificate renewed successfully"
        
        # Test nginx configuration and reload
        if nginx -t; then
            nginx -s reload
            log_action "Nginx reloaded with new certificate"
        else
            log_action "ERROR: Nginx configuration test failed"
            return 1
        fi
    else
        log_action "ERROR: Failed to renew certificate"
        return 1
    fi
}

# Main execution
if ! check_certificate_expiry; then
    renew_certificate
fi
