#!/bin/bash
set -euo pipefail

# Environment variables
export VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-}"
export VAULT_ROLE_ID="${VAULT_ROLE_ID:-}"
export VAULT_SECRET_ID="${VAULT_SECRET_ID:-}"
export USE_VAULT="${USE_VAULT:-true}"
export TESTING_MODE="${TESTING_MODE:-false}"

# Log file
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Logging functions
function log_info() {
    echo "[$(date)] INFO: $1" | tee -a "$LOG_FILE"
}

function log_error() {
    echo "[$(date)] ERROR: $1" | tee -a "$LOG_FILE"
}

function log_success() {
    echo "[$(date)] SUCCESS: $1" | tee -a "$LOG_FILE"
}

function install_vault_cli() {
    log_info "Installing Vault CLI..."
    if ! command -v vault &> /dev/null; then
        apt-get update -qq
        apt-get install -y wget unzip
        wget -q -O vault.zip https://releases.hashicorp.com/vault/1.17.3/vault_1.17.3_linux_amd64.zip
        unzip -q vault.zip
        mv vault /usr/local/bin/
        chmod +x /usr/local/bin/vault
        rm vault.zip
        log_success "Vault CLI installed successfully"
    else
        log_info "Vault CLI already installed"
    fi
}

function wait_for_vault() {
    log_info "Checking Vault availability at $VAULT_ADDR..."
    local retries=30
    local count=0

    while [[ $count -lt $retries ]]; do
        if curl -s -k "$VAULT_ADDR/v1/sys/health" &> /dev/null; then
            log_success "Vault is available"
            return 0
        fi

        count=$((count + 1))
        if [[ $count -lt $retries ]]; then
            log_info "Vault not ready, waiting... (attempt $count/$retries)"
            sleep 2
        fi
    done

    log_error "Vault not available after $retries attempts"
    return 1
}

function vault_authenticate() {
    log_info "Authenticating with Vault using AppRole..."

    if [[ -z "${VAULT_ROLE_ID:-}" ]] || [[ -z "${VAULT_SECRET_ID:-}" ]]; then
        log_error "VAULT_ROLE_ID or VAULT_SECRET_ID not provided"
        return 1
    fi

    # Authenticate using AppRole
    local auth_response
    auth_response=$(curl -s -k -X POST \
        -d "{\"role_id\":\"$VAULT_ROLE_ID\",\"secret_id\":\"$VAULT_SECRET_ID\"}" \
        "$VAULT_ADDR/v1/auth/approle/login")

    if [[ $? -ne 0 ]]; then
        log_error "Failed to authenticate with Vault"
        return 1
    fi

    # Extract token from response
    local vault_token
    vault_token=$(echo "$auth_response" | jq -r '.auth.token // empty')

    if [[ -z "$vault_token" ]] || [[ "$vault_token" == "null" ]]; then
        log_error "Failed to extract Vault token from response"
        return 1
    fi

    # Set Vault token
    export VAULT_TOKEN="$vault_token"

    # Verify token works
    if vault auth -method=token "${VAULT_TOKEN:-}" &> /dev/null; then
        log_success "Vault authentication successful"
        return 0
    else
        log_error "Vault token verification failed"
        return 1
    fi
}

function setup_vault_pki() {
    log_info "Setting up Vault PKI for SSL certificates..."

    # Check if PKI is already enabled
    if vault secrets list | grep -q "pki/"; then
        log_info "PKI secrets engine already enabled"
        return 0
    fi

    # Enable PKI secrets engine
    if vault secrets enable pki; then
        log_success "PKI secrets engine enabled"

        # Configure PKI
        vault secrets tune -max-lease-ttl=87600h pki
        vault write pki/config/urls \
            issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
            crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

        log_success "PKI configuration completed"
        return 0
    else
        log_error "Failed to enable PKI secrets engine"
        return 1
    fi
}

function generate_certificates() {
    log_info "Generating SSL certificates using Vault PKI..."

    # Create certificates directory
    mkdir -p /etc/nginx/ssl

    # Generate certificate
    local cert_response
    cert_response=$(vault write -format=json pki/issue/nginx-role \
        common_name="dev.purebliss.app" \
        ttl="720h" \
        alt_names="localhost,*.dev.purebliss.app")

    if [[ $? -eq 0 ]]; then
        # Extract certificate and key
        echo "$cert_response" | jq -r '.data.certificate' > /etc/nginx/ssl/nginx.crt
        echo "$cert_response" | jq -r '.data.private_key' > /etc/nginx/ssl/nginx.key
        echo "$cert_response" | jq -r '.data.ca_chain[]' > /etc/nginx/ssl/ca.crt

        # Set proper permissions
        chmod 600 /etc/nginx/ssl/nginx.key
        chmod 644 /etc/nginx/ssl/nginx.crt /etc/nginx/ssl/ca.crt

        log_success "SSL certificates generated successfully"
        return 0
    else
        log_error "Failed to generate SSL certificates"
        return 1
    fi
}

function generate_fallback_certificates() {
    log_info "Generating fallback self-signed certificates..."

    # Create certificates directory
    mkdir -p /etc/nginx/ssl

    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=dev.purebliss.app"

    # Set proper permissions
    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt

    log_success "Fallback certificates generated"
}

function configure_nginx() {
    log_info "Configuring Nginx..."

    # Create Nginx configuration
    cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Basic settings
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
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Upstream services
    upstream vault {
        server vault:8200;
    }

    upstream postgres {
        server postgres:5432;
    }

    upstream redis {
        server redis:6379;
    }

    upstream keycloak {
        server keycloak:8080;
    }

    upstream plane {
        server plane:3000;
    }

    upstream code-server {
        server code-server:8080;
    }

    upstream loki {
        server loki:3100;
    }

    upstream prometheus {
        server prometheus:9090;
    }

    upstream grafana {
        server grafana:3000;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name dev.purebliss.app;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Keycloak admin
        location /keycloak/ {
            proxy_pass http://keycloak/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
        }

        # Loki
        location /loki/ {
            proxy_pass http://loki/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Plane
        location /plane/ {
            proxy_pass http://plane/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Code Server
        location /code-server/ {
            proxy_pass http://code-server/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection upgrade;
            proxy_set_header Accept-Encoding gzip;
        }

        # Default location
        location / {
            return 200 'Pure Bliss Development Environment - HTTPS Active';
            add_header Content-Type text/plain;
        }
    }
}

# HTTP redirect server
server {
    listen 80;
    server_name dev.purebliss.app;
    return 301 https://$server_name$request_uri;

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Temporary HTTP access for debugging
    location / {
        return 200 'Pure Bliss Development Environment - HTTP (Redirect to HTTPS)';
        add_header Content-Type text/plain;
    }
}
EOF

    log_success "Nginx configuration created"
}

function start_nginx() {
    log_info "Starting Nginx..."
    exec nginx -g 'daemon off;'
}

# Main execution function
function main() {
    log_info "Starting Nginx container with Vault PKI integration..."

    # Install dependencies
    install_vault_cli

    # Certificate management
    if [[ "$USE_VAULT" == "true" ]]; then
        if wait_for_vault && vault_authenticate; then
            setup_vault_pki
            if generate_certificates; then
                log_success "Vault PKI certificates generated successfully"
            else
                log_error "Vault PKI certificate generation failed, using fallback"
                generate_fallback_certificates
            fi
        else
            log_error "Vault not available or authentication failed, using fallback certificates"
            generate_fallback_certificates
        fi
    else
        log_info "Vault integration disabled, using fallback certificates"
        generate_fallback_certificates
    fi

    # Configure and start Nginx
    configure_nginx
    start_nginx
}

# Error handling
trap 'log_error "Nginx entrypoint script failed at line $LINENO"' ERR

# Run main function
main "$@"
