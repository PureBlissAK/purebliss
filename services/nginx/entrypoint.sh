#!/bin/bash
set -euo pipefail

# Logging functions
log_info() { echo "[$(date)] INFO: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_error() { echo "[$(date)] ERROR: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_success() { echo "[$(date)] SUCCESS: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_warn() { echo "[$(date)] WARN: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }

log_info "Nginx entrypoint.sh started"

# Source environment variables
if [[ -f /opt/my-secure-ha-stack/config.env ]]; then
    set -a
    source /opt/my-secure-ha-stack/config.env
    set +a
fi

# Ensure DOMAIN is set from config.env or environment
if [[ -z "${DOMAIN:-}" ]]; then
    if [[ -f /opt/my-secure-ha-stack/config.env ]]; then
        DOMAIN=$(grep '^DOMAIN=' /opt/my-secure-ha-stack/config.env | cut -d'=' -f2)
        export DOMAIN
    fi
fi
if [[ -z "${DOMAIN:-}" ]]; then
    log_error "DOMAIN is not set. Please set DOMAIN in config.env or environment."
    exit 1
fi

function generate_fallback_certificates() {
    log_info "Generating fallback self-signed certificates for $DOMAIN..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt
    log_success "Fallback certificates generated"
}

function configure_nginx() {
    log_info "Configuring Nginx for domain $DOMAIN..."
    cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 443 ssl;
    http2 on;
    server_name DOMAIN_PLACEHOLDER;

    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location /keycloak/ {
        proxy_pass http://keycloak:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    location /loki/ { proxy_pass http://loki:3100/; }
    location /plane/ { proxy_pass http://plane:3000/; }
    location /code-server/ {
        proxy_pass http://code-server:8080/;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location / {
        return 200 "Pure Bliss Development Environment - HTTPS Active";
        add_header Content-Type text/plain;
    }
}

server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;
    return 301 https://$host$request_uri;

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # Replace placeholder with actual domain
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/conf.d/default.conf
    log_success "Nginx server block created in /etc/nginx/conf.d/default.conf"
}

function start_nginx() {
    log_info "Starting Nginx..."
    exec nginx -g 'daemon off;'
}

# Fallback mode - using self-signed certificates
log_warn "[FALLBACK] Using fallback certificate logic and Nginx startup."
log_info "[FALLBACK] Generating fallback self-signed certificates for $DOMAIN."
generate_fallback_certificates
log_info "[FALLBACK] Configuring Nginx for fallback mode."
configure_nginx
log_info "[FALLBACK] Starting Nginx with fallback certificates."
start_nginx
