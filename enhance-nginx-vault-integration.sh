#!/bin/bash
set -euo pipefail

# Nginx Vault Integration Enhancement Script
# Configures Nginx with Vault PKI certificates and SSL configuration
# Priority: Critical - Edge service requiring TLS/SSL management
# Last Updated: August 5, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] NGINX_ENHANCE: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] NGINX_ENHANCE: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] NGINX_ENHANCE: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

function main() {
    log_action "Starting Nginx Vault integration enhancement..."

    # Use universal enhancement script with PKI configuration
    if [[ -x "/opt/dev-purebliss/enhance-container-with-vault.sh" ]]; then
        /opt/dev-purebliss/enhance-container-with-vault.sh nginx pki_certificates
    else
        log_error "Universal enhancement script not found"
        exit 1
    fi

    # Nginx-specific post-enhancement configuration
    log_action "Applying Nginx-specific configurations..."

    # Create Nginx Vault entrypoint with PKI certificate management
    create_nginx_vault_entrypoint

    # Create Nginx configuration template with Vault integration
    create_nginx_vault_config

    # Create SSL certificate renewal automation
    create_nginx_cert_renewal

    log_success "Nginx Vault integration enhancement completed!"
}

function create_nginx_vault_entrypoint() {
    log_action "Creating Nginx Vault entrypoint with PKI certificate management..."

    local nginx_dir="/opt/dev-purebliss/services/nginx"
    mkdir -p "$nginx_dir/certs"

    local entrypoint_file="$nginx_dir/nginx-vault-entrypoint.sh"

    cat > "$entrypoint_file" << 'EOF'
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
EOF

    chmod +x "$entrypoint_file"
    log_success "Nginx Vault entrypoint created"
}

function create_nginx_vault_config() {
    log_action "Creating Nginx configuration with Vault integration..."

    local nginx_dir="/opt/dev-purebliss/services/nginx"
    local config_file="$nginx_dir/nginx.conf"

    cat > "$config_file" << 'EOF'
# Nginx Configuration with Vault PKI Integration
# Optimized for Pure Bliss Microservices Architecture

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

# Optimize for high concurrency
worker_rlimit_nofile 65535;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/geo+json
        application/javascript
        application/x-javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rdf+xml
        application/rss+xml
        application/xhtml+xml
        application/xml
        font/eot
        font/otf
        font/ttf
        image/svg+xml
        text/css
        text/javascript
        text/plain
        text/xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # SSL Configuration (loaded from ssl.conf)
    include /etc/nginx/conf.d/ssl.conf;

    # Pure Bliss Services Configuration
    upstream codeserver {
        server purebliss-codeserver:8080;
    }

    upstream keycloak {
        server purebliss-keycloak:8080;
    }

    upstream plane {
        server purebliss-plane:3000;
    }

    upstream grafana {
        server purebliss-grafana:3000;
    }

    upstream prometheus {
        server purebliss-prometheus:9090;
    }

    # HTTPS Server
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name dev.purebliss.app *.dev.purebliss.app;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

        # CodeServer
        location /code-server/ {
            proxy_pass http://codeserver/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400;
        }

        # Keycloak
        location /keycloak/ {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://keycloak/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Plane
        location /plane/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://plane/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Grafana
        location /grafana/ {
            proxy_pass http://grafana/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Prometheus
        location /prometheus/ {
            limit_req zone=api burst=10 nodelay;
            proxy_pass http://prometheus/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Default location
        location / {
            return 301 https://$server_name/code-server/;
        }
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        listen [::]:80;
        server_name dev.purebliss.app *.dev.purebliss.app;
        return 301 https://$server_name$request_uri;
    }
}
EOF

    log_success "Nginx configuration with Vault integration created"
}

function create_nginx_cert_renewal() {
    log_action "Creating SSL certificate renewal automation..."

    local nginx_dir="/opt/dev-purebliss/services/nginx"
    local renewal_script="$nginx_dir/renew-certificates.sh"

    cat > "$renewal_script" << 'EOF'
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
EOF

    chmod +x "$renewal_script"

    # Create cron job for automatic renewal
    local cron_file="$nginx_dir/nginx-cert-renewal.cron"
    cat > "$cron_file" << 'EOF'
# Nginx Certificate Renewal - Check daily at 2 AM
0 2 * * * /opt/dev-purebliss/services/nginx/renew-certificates.sh
EOF

    log_success "SSL certificate renewal automation created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
