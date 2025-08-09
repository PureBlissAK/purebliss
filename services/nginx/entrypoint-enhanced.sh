#!/bin/bash
set -euo pipefail

# PURE BLISS SCRIPT METADATA
# Script: nginx/entrypoint-enhanced.sh
# Purpose: Enhanced Nginx entrypoint with smart upstream logic and Vault PKI enforcement
# Version: 2.0
# Last Modified: 2025-08-08
# Author: Pure Bliss Development Team
# Dependencies: nginx, vault, upstream services
# Security Policy: Vault/Let's Encrypt PKI only - no self-signed fallback
# Integration: Smart upstream detection, centralized logging, health validation
# Usage: Docker entrypoint for Nginx with upstream intelligence and HTTPS
# Enhancement Notes: Enforced Vault PKI policy, enhanced upstream logic
# END METADATA

# Enhanced Nginx Entrypoint with Smart Upstream Logic
# Handles upstream servers that may not be available during initial container builds

# Logging functions
log_info() { echo "[$(date)] INFO: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_error() { echo "[$(date)] ERROR: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_success() { echo "[$(date)] SUCCESS: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_warn() { echo "[$(date)] WARN: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }

log_info "Enhanced Nginx entrypoint.sh started with smart upstream logic"

# Source environment variables safely (handle unbound variables)
if [[ -f /opt/my-secure-ha-stack/config.env ]]; then
    set -a
    # Source config.env with error handling for unbound variables
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            eval "export $line" 2>/dev/null || true
        fi
    done < /opt/my-secure-ha-stack/config.env
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

# Define upstream services that nginx will proxy to
declare -A UPSTREAM_SERVICES=(
    ["vault"]="purebliss-vault:8200"
    ["vault-agent"]="purebliss-vault-agent:8100"
    ["postgres"]="purebliss-postgres:5432"
    ["redis"]="purebliss-redis:6379"
    ["keycloak"]="purebliss-keycloak:8080"
    ["plane"]="purebliss-plane:3000"
    ["codeserver"]="purebliss-codeserver:8080"
    ["prometheus"]="purebliss-prometheus:9090"
    ["grafana"]="purebliss-grafana:3000"
    ["loki"]="purebliss-loki:3100"
)

# Check if upstream service is available
check_upstream_availability() {
    local service_name=$1
    local service_endpoint=$2
    local host_port=(${service_endpoint//:/ })
    local host=${host_port[0]}
    local port=${host_port[1]}

    log_info "Checking upstream availability: $service_name ($service_endpoint)"

    # Use nc (netcat) to test connection with short timeout
    if command -v nc >/dev/null 2>&1; then
        if timeout 3 nc -z "$host" "$port" >/dev/null 2>&1; then
            log_success "Upstream $service_name is available at $service_endpoint"
            return 0
        else
            log_warn "Upstream $service_name is NOT available at $service_endpoint"
            return 1
        fi
    else
        # Fallback: use curl/wget for HTTP services
        case $port in
            8080|3000|9090|3100|8200)
                if timeout 3 curl -s -f "http://$host:$port/health" >/dev/null 2>&1 || \
                   timeout 3 curl -s -f "http://$host:$port/" >/dev/null 2>&1; then
                    log_success "Upstream $service_name is available at $service_endpoint (HTTP check)"
                    return 0
                else
                    log_warn "Upstream $service_name is NOT available at $service_endpoint (HTTP check)"
                    return 1
                fi
                ;;
            *)
                log_warn "Cannot check upstream $service_name - no netcat available and not HTTP service"
                return 1
                ;;
        esac
    fi
}

# Generate upstream configuration block only for available services
generate_upstream_config() {
    local service_name=$1
    local service_endpoint=$2

    cat << EOF
    upstream $service_name {
        server $service_endpoint max_fails=3 fail_timeout=10s;
        # Generated at $(date) - Service available
    }
EOF
}

# Generate fallback upstream configuration for unavailable services
generate_fallback_upstream_config() {
    local service_name=$1

    cat << EOF
    # Upstream $service_name disabled - service not available
    # This will be enabled automatically when $service_name comes online
    # upstream $service_name {
    #     server 127.0.0.1:9999 down;  # Placeholder for unavailable service
    # }
EOF
}

# Generate location block only for available services
generate_location_config() {
    local service_name=$1
    local url_path=$2
    local is_available=$3

    if [[ "$is_available" == "true" ]]; then
        case $service_name in
            "codeserver")
                cat << EOF
        location /$url_path/ {
            proxy_pass http://$service_name/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_read_timeout 86400;
        }
EOF
                ;;
            "keycloak")
                cat << EOF
        location /$url_path/ {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://$service_name/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
        }
EOF
                ;;
            "plane"|"prometheus"|"grafana"|"loki")
                cat << EOF
        location /$url_path/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://$service_name/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
EOF
                ;;
            *)
                cat << EOF
        location /$url_path/ {
            proxy_pass http://$service_name/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
EOF
                ;;
        esac
    else
        cat << EOF
        # Location /$url_path/ disabled - $service_name not available
        # location /$url_path/ {
        #     return 503 "$service_name service unavailable - starting soon";
        #     add_header Content-Type text/plain;
        # }
EOF
    fi
}


# Dynamically select certificate paths: prefer Let's Encrypt/Vault PKI only
get_certificate_paths() {
    local domain_cert_dir="/etc/letsencrypt/live/$DOMAIN"
    if [[ -f "$domain_cert_dir/fullchain.pem" && -f "$domain_cert_dir/privkey.pem" ]]; then
        export NGINX_CERT="$domain_cert_dir/fullchain.pem"
        export NGINX_KEY="$domain_cert_dir/privkey.pem"
        log_success "Using Let's Encrypt/Vault PKI certificates for $DOMAIN"
    else
        log_error "ERROR: No Vault/Let's Encrypt PKI certs found for $DOMAIN. Container will not start."
        log_error "POLICY: Self-signed certificates are not allowed. Use Vault PKI or Let's Encrypt only."
        exit 1
    fi
}

# Remove self-signed certificate generation - PKI only policy enforced
# generate_fallback_certificates() function removed for security compliance


# Smart nginx configuration generation based on available services and dynamic certs
configure_nginx_smart() {
    log_info "Generating smart Nginx configuration for domain $DOMAIN based on available services and dynamic certificates..."

    # Check which services are available
    declare -A AVAILABLE_SERVICES

    for service in "${!UPSTREAM_SERVICES[@]}"; do
        if check_upstream_availability "$service" "${UPSTREAM_SERVICES[$service]}"; then
            AVAILABLE_SERVICES[$service]="true"
        else
            AVAILABLE_SERVICES[$service]="false"
        fi
    done

    # Get cert/key paths
    get_certificate_paths

    # Generate nginx configuration
    cat > /etc/nginx/conf.d/default.conf <<EOF_NGINX_CONFIG
# Smart Nginx Configuration - Generated based on available upstream services
# Generated at: $(date)

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format main '[32m$remote_addr - $remote_user [$time_local] "$request" '
                    '[0m$status $body_bytes_sent "$http_referer" '
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

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # UPSTREAM_CONFIGS_PLACEHOLDER

    # HTTPS Server
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name $DOMAIN *.$DOMAIN;

        # SSL/TLS settings
        ssl_certificate $NGINX_CERT;
        ssl_certificate_key $NGINX_KEY;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

        # LOCATION_CONFIGS_PLACEHOLDER

        # Health check endpoint (always available)
        location /health {
            access_log off;
            return 200 "nginx healthy - AVAILABLE_SERVICES_COUNT services available\n";
            add_header Content-Type text/plain;
        }

        # Service status endpoint
        location /status {
            access_log off;
            return 200 "NGINX_STATUS_PLACEHOLDER";
            add_header Content-Type application/json;
        }

        # Default location
        location / {
            return 200 "Pure Bliss Development Environment - HTTPS Active\nAvailable services: AVAILABLE_SERVICES_LIST";
            add_header Content-Type text/plain;
        }
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        listen [::]:80;
        server_name $DOMAIN *.$DOMAIN;

        # Health check for HTTP
        location /health {
            access_log off;
            return 200 "nginx healthy (HTTP)\n";
            add_header Content-Type text/plain;
        }

        # Redirect everything else to HTTPS
        location / {
            return 301 https://$server_name$request_uri;
        }
    }
}
EOF_NGINX_CONFIG

    # Generate upstream/location configs as before
    local upstream_configs=""
    local location_configs=""
    local available_count=0
    local available_list=""

    for service in "${!UPSTREAM_SERVICES[@]}"; do
        if [[ "${AVAILABLE_SERVICES[$service]}" == "true" ]]; then
            upstream_configs+="$(generate_upstream_config "$service" "${UPSTREAM_SERVICES[$service]}")"$'\n'

            # Determine URL path for service
            local url_path=""
            case $service in
                "codeserver") url_path="code-server" ;;
                *) url_path="$service" ;;
            esac

            location_configs+="$(generate_location_config "$service" "$url_path" "true")"$'\n'
            available_count=$((available_count + 1))
            available_list+="$service "
        else
            upstream_configs+="$(generate_fallback_upstream_config "$service")"$'\n'

            # Determine URL path for service
            local url_path=""
            case $service in
                "codeserver") url_path="code-server" ;;
                *) url_path="$service" ;;
            esac

            location_configs+="$(generate_location_config "$service" "$url_path" "false")"$'\n'
        fi
    done

    # Replace placeholders with generated content
    sed -i "s|# UPSTREAM_CONFIGS_PLACEHOLDER|$upstream_configs|" /etc/nginx/conf.d/default.conf
    sed -i "s|        # LOCATION_CONFIGS_PLACEHOLDER|$location_configs|" /etc/nginx/conf.d/default.conf
    sed -i "s/AVAILABLE_SERVICES_COUNT/$available_count/" /etc/nginx/conf.d/default.conf
    sed -i "s/AVAILABLE_SERVICES_LIST/$available_list/" /etc/nginx/conf.d/default.conf

    # Generate status JSON
    local status_json="{\"nginx_status\":\"healthy\",\"available_services\":[${available_count}],\"services\":{"
    for service in "${!UPSTREAM_SERVICES[@]}"; do
        status_json+="\"$service\":\"${AVAILABLE_SERVICES[$service]}","
    done
    status_json="${status_json%,}},\"timestamp\":\"$(date -Iseconds)\"}"
    sed -i "s|NGINX_STATUS_PLACEHOLDER|$status_json|" /etc/nginx/conf.d/default.conf

    log_success "Smart Nginx configuration generated with $available_count available services: $available_list and cert: $NGINX_CERT"
}

# Test nginx configuration
test_nginx_configuration() {
    log_info "Testing Nginx configuration..."

    if nginx -t 2>/dev/null; then
        log_success "Nginx configuration test passed"
        return 0
    else
        log_error "Nginx configuration test failed:"
        nginx -t 2>&1 | while read line; do
            log_error "Config test: $line"
        done
        return 1
    fi
}

# Create upstream availability check script for running container
create_upstream_check_script() {
    log_info "Creating upstream availability check script..."

    cat > /opt/scripts/check-upstream-services.sh << 'EOF'
#!/bin/bash
# Upstream Service Availability Checker
# This script can be called by upstream services to trigger nginx reconfiguration

set -euo pipefail

NGINX_PID_FILE="/var/run/nginx.pid"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_message() {
    echo "[$(date)] UPSTREAM_CHECK: $1" | tee -a "$LOG_FILE"
}

# Check if this script is being called by a service that just came online
SERVICE_NAME="${1:-unknown}"
log_message "Upstream service check requested by: $SERVICE_NAME"

# Check if nginx is running
if [[ -f "$NGINX_PID_FILE" ]] && kill -0 "$(cat "$NGINX_PID_FILE")" 2>/dev/null; then
    log_message "Nginx is running, triggering configuration reload..."

    # Regenerate configuration with current service availability
    if /entrypoint.sh --reload-config; then
        log_message "Nginx configuration reloaded successfully for $SERVICE_NAME"

        # Send HUP signal to reload nginx gracefully
        if kill -HUP "$(cat "$NGINX_PID_FILE")" 2>/dev/null; then
            log_message "Nginx gracefully reloaded configuration"
        else
            log_message "Failed to reload nginx configuration"
        fi
    else
        log_message "Failed to regenerate nginx configuration"
    fi
else
    log_message "Nginx is not running, configuration will be generated on next start"
fi
EOF

    chmod +x /opt/scripts/check-upstream-services.sh
    log_success "Upstream check script created at /opt/scripts/check-upstream-services.sh"
}

# Handle script arguments
case "${1:-start}" in
    "--reload-config")
        log_info "Reloading nginx configuration based on current upstream availability"
        configure_nginx_smart
        exit 0
        ;;
    "--test-config")
        log_info "Testing current nginx configuration"
        test_nginx_configuration
        exit $?
        ;;
    "--upstream-check")
        log_info "Checking upstream service availability"
        for service in "${!UPSTREAM_SERVICES[@]}"; do
            check_upstream_availability "$service" "${UPSTREAM_SERVICES[$service]}"
        done
        exit 0
        ;;
    "start"|"nginx"|*)
        # Normal startup flow
        log_info "Starting nginx with smart upstream logic..."
        ;;
esac

# Create necessary directories
mkdir -p /opt/scripts /var/log/nginx /etc/nginx/conf.d

# Install netcat if available (for upstream checking)
if command -v apt-get >/dev/null 2>&1; then
    apt-get update >/dev/null 2>&1 && apt-get install -y netcat-openbsd >/dev/null 2>&1 || true
elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache netcat-openbsd >/dev/null 2>&1 || true
fi

# Generate fallback certificates (for minimal startup)
generate_fallback_certificates

# Generate smart nginx configuration based on available services
configure_nginx_smart

# Test configuration before starting
if ! test_nginx_configuration; then
    log_error "Configuration test failed, attempting minimal fallback configuration"

    # Generate minimal configuration that will start successfully
    cat > /etc/nginx/conf.d/default.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        location /health {
            return 200 "nginx minimal mode - upstream services not available";
            add_header Content-Type text/plain;
        }
        location / {
            return 503 "Services starting - please wait";
            add_header Content-Type text/plain;
        }
    }
}
EOF

    log_warn "Using minimal fallback configuration"
fi

# Create upstream check script for other services to use
create_upstream_check_script

# Monitor certificate expiry and log warning if <14 days
monitor_certificate_expiry() {
    local cert_file="$NGINX_CERT"
    if [[ -f "$cert_file" ]]; then
        local expiry_epoch=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2 | xargs -I{} date -d {} +%s)
        local now_epoch=$(date +%s)
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        if (( days_left < 14 )); then
            log_warn "Certificate for $DOMAIN expires in $days_left days!"
        else
            log_info "Certificate for $DOMAIN is valid for $days_left more days."
        fi
    else
        log_warn "No certificate found at $cert_file for expiry monitoring."
    fi
}

# Main startup logic
get_certificate_paths  # PKI cert validation only - no fallback generation
configure_nginx_smart
monitor_certificate_expiry

# Test configuration before starting
if ! test_nginx_configuration; then
    log_error "Configuration test failed, attempting minimal fallback configuration"

    # Generate minimal configuration that will start successfully
    cat > /etc/nginx/conf.d/default.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        location /health {
            return 200 "nginx minimal mode - upstream services not available";
            add_header Content-Type text/plain;
        }
        location / {
            return 503 "Services starting - please wait";
            add_header Content-Type text/plain;
        }
    }
}
EOF

    log_warn "Using minimal fallback configuration"
fi

# Create upstream check script for other services to use
create_upstream_check_script

# Start nginx
log_info "Starting Nginx with smart upstream configuration and dynamic certificate loading..."
exec nginx -g 'daemon off;'
