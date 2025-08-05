#!/bin/bash
set -euo pipefail

# Nginx Vault Integration Entrypoint
# Manages PKI certificates and SSL configuration via Vault

VAULT_ADDR="${VAULT_ADDR:-https://purebliss-vault:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
DOMAIN="${DOMAIN:-dev.purebliss.app}"
CERT_PATH="/etc/nginx/certs"

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
        echo "$CERT_RESPONSE" | jq -r '.data.certificate' > "$CERT_PATH/nginx.crt"
        echo "$CERT_RESPONSE" | jq -r '.data.private_key' > "$CERT_PATH/nginx.key"
        echo "$CERT_RESPONSE" | jq -r '.data.issuing_ca' > "$CERT_PATH/ca.crt"
        
        # Set proper permissions
        chmod 644 "$CERT_PATH/nginx.crt" "$CERT_PATH/ca.crt"
        chmod 600 "$CERT_PATH/nginx.key"
        
        echo "SSL certificates successfully generated and saved"
        echo "Certificate: $CERT_PATH/nginx.crt"
        echo "Private Key: $CERT_PATH/nginx.key"
        echo "CA Certificate: $CERT_PATH/ca.crt"
        
        # Verify certificate
        if openssl x509 -in "$CERT_PATH/nginx.crt" -text -noout >/dev/null 2>&1; then
            echo "Certificate validation successful"
        else
            echo "ERROR: Certificate validation failed"
            exit 1
        fi
    else
        echo "ERROR: Failed to generate certificate from Vault PKI"
        # Fallback to self-signed certificate
        generate_fallback_certificate
    fi
else
    echo "ERROR: Vault token not found at /vault-token"
    # Fallback to self-signed certificate
    generate_fallback_certificate
fi

# Update Nginx configuration with certificate paths
update_nginx_ssl_config

echo "Nginx Vault PKI integration initialization completed"

# Test Nginx configuration
if nginx -t; then
    echo "Nginx configuration test passed"
else
    echo "ERROR: Nginx configuration test failed"
    exit 1
fi

# Start Nginx
exec nginx -g "daemon off;"

function generate_fallback_certificate() {
    echo "Generating fallback self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_PATH/nginx.key" \
        -out "$CERT_PATH/nginx.crt" \
        -subj "/C=US/ST=State/L=City/O=PureBliss/OU=IT/CN=$DOMAIN" \
        -addext "subjectAltName=DNS:$DOMAIN,DNS:*.$DOMAIN,DNS:localhost"
    
    cp "$CERT_PATH/nginx.crt" "$CERT_PATH/ca.crt"
    chmod 644 "$CERT_PATH/nginx.crt" "$CERT_PATH/ca.crt"
    chmod 600 "$CERT_PATH/nginx.key"
    echo "Fallback certificate generated"
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
