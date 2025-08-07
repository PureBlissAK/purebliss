#!/bin/bash
set -euo pipefail

# Nginx Vault Integration Entrypoint
# Manages PKI certificates and SSL configuration via Vault

VAULT_ADDR="${VAULT_ADDR:-https://purebliss-vault:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
DOMAIN="${DOMAIN:-dev.purebliss.app}"
# Use path expected by nginx-ssl-only.conf
CERT_PATH="/etc/nginx/certs/live/$DOMAIN"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
for i in {1..30}; do
    if curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
        echo "Vault is ready"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo "ERROR: Vault not ready after 30 attempts"
        exit 1
    fi
    sleep 2
done

# Setup certificate directory
mkdir -p "$CERT_PATH"
echo "[$(date)] NGINX_ENTRYPOINT: Ensuring cert path $CERT_PATH exists" >> "$LOG_FILE"

# Fetch PKI certificates from Vault
echo "Fetching SSL certificates from Vault PKI..."
if [[ -f "/vault-token" ]]; then
    VAULT_TOKEN=$(cat /vault-token)
    export VAULT_TOKEN
    
    # Request certificate from Vault PKI
    CERT_RESPONSE=$(vault write -format=json pki/issue/purebliss-role \
        common_name="$DOMAIN" \
        alt_names="*.${DOMAIN},localhost" \
        ttl=8760h 2>/dev/null || echo '{}')
    
    if [[ "$CERT_RESPONSE" != '{}' ]]; then
        # Extract and save certificates
        echo "$CERT_RESPONSE" | jq -r '.data.certificate' > "$CERT_PATH/fullchain.pem"
        echo "$CERT_RESPONSE" | jq -r '.data.private_key' > "$CERT_PATH/privkey.pem"
        echo "$CERT_RESPONSE" | jq -r '.data.issuing_ca' > "$CERT_PATH/ca.pem"
        
        # Set proper permissions
        chmod 644 "$CERT_PATH/fullchain.pem" "$CERT_PATH/ca.pem"
        chmod 600 "$CERT_PATH/privkey.pem"
        
        echo "SSL certificates successfully generated and saved"
        echo "Certificate: $CERT_PATH/fullchain.pem"
        echo "Private Key: $CERT_PATH/privkey.pem"
        echo "CA Certificate: $CERT_PATH/ca.pem"
        echo "[$(date)] NGINX_ENTRYPOINT: SSL certs written to $CERT_PATH (Vault PKI)" >> "$LOG_FILE"
        
        # Verify certificate
        if openssl x509 -in "$CERT_PATH/fullchain.pem" -text -noout >/dev/null 2>&1; then
            echo "Certificate validation successful"
            echo "[$(date)] NGINX_ENTRYPOINT: Certificate validation successful" >> "$LOG_FILE"
        else
            echo "ERROR: Certificate validation failed"
            echo "[$(date)] NGINX_ENTRYPOINT: ERROR: Certificate validation failed" >> "$LOG_FILE"
            exit 1
        fi
    else
        echo "ERROR: Failed to generate certificate from Vault PKI"
        echo "[$(date)] NGINX_ENTRYPOINT: ERROR: Failed to generate certificate from Vault PKI, using fallback" >> "$LOG_FILE"
        generate_fallback_certificate
    fi
else
    echo "ERROR: Vault token not found at /vault-token"
    echo "[$(date)] NGINX_ENTRYPOINT: ERROR: Vault token not found at /vault-token, using fallback" >> "$LOG_FILE"
    generate_fallback_certificate
fi


# Ensure /etc/nginx exists before copying config
NGINX_CONF_SRC="/opt/dev-purebliss/services/nginx/nginx-ssl-only.conf"
NGINX_CONF_DEST="/etc/nginx/nginx.conf"
if [[ ! -d "/etc/nginx" ]]; then
    mkdir -p /etc/nginx
    echo "[$(date)] NGINX_ENTRYPOINT: Created /etc/nginx directory" >> "$LOG_FILE"
fi
if [[ -f "$NGINX_CONF_SRC" ]]; then
    cp "$NGINX_CONF_SRC" "$NGINX_CONF_DEST"
    echo "[$(date)] NGINX_ENTRYPOINT: Copied $NGINX_CONF_SRC to $NGINX_CONF_DEST for HTTPS enforcement" >> "$LOG_FILE"
else
    echo "[$(date)] NGINX_ENTRYPOINT: ERROR: $NGINX_CONF_SRC not found, cannot enforce HTTPS" >> "$LOG_FILE"
fi

echo "Nginx Vault PKI integration initialization completed"
echo "[$(date)] NGINX_ENTRYPOINT: Nginx Vault PKI integration initialization completed" >> "$LOG_FILE"


# Test Nginx configuration
if nginx -t; then
    echo "Nginx configuration test passed"
    echo "[$(date)] NGINX_ENTRYPOINT: Nginx configuration test passed" >> "$LOG_FILE"
else
    echo "ERROR: Nginx configuration test failed"
    echo "[$(date)] NGINX_ENTRYPOINT: ERROR: Nginx configuration test failed" >> "$LOG_FILE"
    exit 1
fi


# Start Nginx
echo "[$(date)] NGINX_ENTRYPOINT: Starting nginx with enforced HTTPS" >> "$LOG_FILE"
exec nginx -g "daemon off;"

function generate_fallback_certificate() {
    echo "Generating fallback self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_PATH/privkey.pem" \
        -out "$CERT_PATH/fullchain.pem" \
        -subj "/C=US/ST=State/L=City/O=PureBliss/OU=IT/CN=$DOMAIN" \
        -addext "subjectAltName=DNS:$DOMAIN,DNS:*.$DOMAIN,DNS:localhost"
    cp "$CERT_PATH/fullchain.pem" "$CERT_PATH/ca.pem"
    chmod 644 "$CERT_PATH/fullchain.pem" "$CERT_PATH/ca.pem"
    chmod 600 "$CERT_PATH/privkey.pem"
    echo "Fallback certificate generated"
    echo "[$(date)] NGINX_ENTRYPOINT: Fallback self-signed certificate generated at $CERT_PATH" >> "$LOG_FILE"
}

function update_nginx_ssl_config() {
    echo "Updating Nginx SSL configuration..."
    
    # Create SSL configuration snippet
    cat > /etc/nginx/conf.d/ssl.conf << SSLEOF
# SSL Configuration for Pure Bliss
ssl_certificate $CERT_PATH/nginx.crt;
ssl_certificate_key $CERT_PATH/nginx.key;
ssl_trusted_certificate $CERT_PATH/ca.crt;

# SSL Security Settings
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# HSTS (HTTP Strict Transport Security)
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

# Additional Security Headers
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
SSLEOF

    echo "SSL configuration updated"
}
