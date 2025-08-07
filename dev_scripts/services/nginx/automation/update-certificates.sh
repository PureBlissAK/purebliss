#!/bin/bash

# Script to update nginx certificates from Vault PKI
# This script generates new certificates from Vault and updates nginx

set -e

VAULT_ADDR="${VAULT_ADDR:-https://localhost:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
CERT_DIR="/srv/nginx/certs/dev.purebliss.app"
TEMP_DIR="/tmp/nginx_vault_certs"

echo "[$(date)] Starting Vault PKI certificate update for nginx..."

# Check if Vault token exists
if [[ ! -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
    echo "[$(date)] ERROR: Vault token file not found"
    exit 1
fi

export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
export VAULT_ADDR
export VAULT_SKIP_VERIFY

# Create temporary directory
mkdir -p "$TEMP_DIR"

echo "[$(date)] Generating new certificate from Vault PKI..."

# Generate new certificate
vault write -format=json pki-nginx/issue/nginx-role \
    common_name="dev.purebliss.app" \
    ttl="720h" > "$TEMP_DIR/nginx_cert.json"

if [[ $? -ne 0 ]]; then
    echo "[$(date)] ERROR: Failed to generate certificate from Vault"
    exit 1
fi

echo "[$(date)] Extracting certificate and private key..."

# Extract certificate and key
jq -r '.data.certificate' "$TEMP_DIR/nginx_cert.json" > "$TEMP_DIR/fullchain.pem"
jq -r '.data.private_key' "$TEMP_DIR/nginx_cert.json" > "$TEMP_DIR/privkey.pem"

# Also save the CA chain
jq -r '.data.ca_chain[]' "$TEMP_DIR/nginx_cert.json" > "$TEMP_DIR/ca_chain.pem"

# Combine certificate and CA chain for fullchain
cat "$TEMP_DIR/fullchain.pem" "$TEMP_DIR/ca_chain.pem" > "$TEMP_DIR/fullchain_complete.pem"

echo "[$(date)] Backing up current certificates..."

# Backup current certificates
docker exec purebliss-nginx cp /etc/nginx/certs/dev.purebliss.app/fullchain.pem /etc/nginx/certs/dev.purebliss.app/fullchain.pem.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
docker exec purebliss-nginx cp /etc/nginx/certs/dev.purebliss.app/privkey.pem /etc/nginx/certs/dev.purebliss.app/privkey.pem.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

echo "[$(date)] Copying new certificates to nginx container..."

# Copy new certificates to container
docker cp "$TEMP_DIR/fullchain_complete.pem" purebliss-nginx:/etc/nginx/certs/dev.purebliss.app/fullchain.pem
docker cp "$TEMP_DIR/privkey.pem" purebliss-nginx:/etc/nginx/certs/dev.purebliss.app/privkey.pem

# Set proper permissions
docker exec purebliss-nginx chmod 644 /etc/nginx/certs/dev.purebliss.app/fullchain.pem
docker exec purebliss-nginx chmod 600 /etc/nginx/certs/dev.purebliss.app/privkey.pem

echo "[$(date)] Testing nginx configuration..."

# Test nginx configuration
if docker exec purebliss-nginx nginx -t; then
    echo "[$(date)] Nginx configuration test passed. Reloading nginx..."
    docker exec purebliss-nginx nginx -s reload
    echo "[$(date)] Nginx reloaded successfully with new Vault certificates!"
else
    echo "[$(date)] ERROR: Nginx configuration test failed. Restoring backup certificates..."
    # Restore backup if available
    docker exec purebliss-nginx cp /etc/nginx/certs/dev.purebliss.app/fullchain.pem.backup.* /etc/nginx/certs/dev.purebliss.app/fullchain.pem 2>/dev/null || true
    docker exec purebliss-nginx cp /etc/nginx/certs/dev.purebliss.app/privkey.pem.backup.* /etc/nginx/certs/dev.purebliss.app/privkey.pem 2>/dev/null || true
    docker exec purebliss-nginx nginx -s reload
    exit 1
fi

# Verify certificate
echo "[$(date)] Verifying new certificate..."
CERT_SUBJECT=$(docker exec purebliss-nginx openssl x509 -in /etc/nginx/certs/dev.purebliss.app/fullchain.pem -noout -subject)
CERT_ISSUER=$(docker exec purebliss-nginx openssl x509 -in /etc/nginx/certs/dev.purebliss.app/fullchain.pem -noout -issuer)
CERT_EXPIRES=$(docker exec purebliss-nginx openssl x509 -in /etc/nginx/certs/dev.purebliss.app/fullchain.pem -noout -enddate)

echo "[$(date)] Certificate verification:"
echo "  Subject: $CERT_SUBJECT"
echo "  Issuer: $CERT_ISSUER"
echo "  Expires: $CERT_EXPIRES"

# Save certificate info for monitoring
jq -r '.data.expiration' "$TEMP_DIR/nginx_cert.json" > "$TEMP_DIR/cert_expiration"
echo "[$(date)] Certificate expiration timestamp: $(cat $TEMP_DIR/cert_expiration)"

echo "[$(date)] Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "[$(date)] Vault PKI certificate update completed successfully!"
