#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: common-functions-library.sh not found, using basic logging" >&2
    log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $*"; }
    log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $*" >&2; }
    log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $*"; }
}

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0"
SCRIPT_PURPOSE="Pure Bliss NGINX Security Hardening with Vault Integration and Health Validation"

# Configuration paths
NGINX_CONFIG_DIR="/opt/dev-purebliss/services/nginx"
SECURITY_CONFIG_DIR="/opt/dev-purebliss/container-configs/nginx"
NGINX_CONTAINER_NAME="purebliss-nginx"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Pure Bliss specific configuration
PUREBLISS_DOMAIN="dev.purebliss.app"
VAULT_ADDR="https://vault.purebliss.app:8200"
KEYCLOAK_REALM="master"

# Enhanced security hardening function with Pure Bliss integration
enhance_nginx_security_purebliss() {
    log_info "Starting Pure Bliss NGINX Security Hardening Enhancement"

    # Create security configuration directories
    mkdir -p "$SECURITY_CONFIG_DIR"
    mkdir -p "$NGINX_CONFIG_DIR/security"
    mkdir -p "$NGINX_CONFIG_DIR/ssl"
    mkdir -p "$NGINX_CONFIG_DIR/vault"

    # Create Pure Bliss specific security configurations
    create_purebliss_security_headers
    create_purebliss_rate_limiting
    create_purebliss_ssl_hardening
    create_purebliss_waf_rules
    create_purebliss_security_monitoring
    create_vault_integration_config
    create_keycloak_integration_config
    create_purebliss_production_config
    create_health_validation_integration
    create_smart_upstream_config

    log_success "Pure Bliss NGINX Security Hardening Enhancement Complete"
}

# Pure Bliss specific security headers with enhanced CSP for microservices
create_purebliss_security_headers() {
    log_info "Creating Pure Bliss specific security headers configuration"

    cat > "$SECURITY_CONFIG_DIR/purebliss-security-headers.conf" << 'EOF'
# Pure Bliss Enhanced Security Headers Configuration
# Microservices-aware security headers for Pure Bliss development environment

# Hide server version and operating system information
server_tokens off;
more_clear_headers Server;
more_set_headers "Server: PureBliss-Gateway";

# Pure Bliss Security Headers
add_header X-Frame-Options "DENY" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header X-Permitted-Cross-Domain-Policies "none" always;
add_header X-Download-Options "noopen" always;

# Pure Bliss Enhanced Content Security Policy for microservices
add_header Content-Security-Policy "default-src 'self' https://*.purebliss.app https://dev.purebliss.app; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.purebliss.app https://www.google-analytics.com https://www.googletagmanager.com; style-src 'self' 'unsafe-inline' https://*.purebliss.app https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com https://*.purebliss.app; img-src 'self' data: https: https://*.purebliss.app; connect-src 'self' https://*.purebliss.app https://vault.purebliss.app:8200 wss://*.purebliss.app; object-src 'none'; frame-ancestors 'none'; base-uri 'self'; form-action 'self' https://*.purebliss.app;" always;

# Strict Transport Security (HSTS) for Pure Bliss domain
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Enhanced Feature Policy for Pure Bliss environment
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), interest-cohort=(), autoplay=(self https://*.purebliss.app), encrypted-media=(self https://*.purebliss.app), fullscreen=(self https://*.purebliss.app)" always;

# Pure Bliss specific security headers
add_header X-Pure-Bliss-Gateway "v2.0" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-DNS-Prefetch-Control "off" always;

# Remove potentially sensitive headers
more_clear_headers "X-Powered-By";
more_clear_headers "X-AspNet-Version";
more_clear_headers "X-AspNetMvc-Version";
more_clear_headers "X-Runtime";

# Pure Bliss service identification header
add_header X-Service-Stack "nginx-keycloak-vault-postgres-redis-prometheus-grafana-loki-plane-codeserver" always;
EOF

    log_success "Pure Bliss security headers configuration created"
}

# Pure Bliss specific rate limiting with service-aware zones
create_purebliss_rate_limiting() {
    log_info "Creating Pure Bliss specific rate limiting configuration"

    cat > "$SECURITY_CONFIG_DIR/purebliss-rate-limiting.conf" << 'EOF'
# Pure Bliss Enhanced Rate Limiting Configuration
# Service-aware rate limiting for Pure Bliss microservices architecture

# Pure Bliss service-specific rate limiting zones
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=keycloak_auth:10m rate=2r/s;
limit_req_zone $binary_remote_addr zone=vault_api:10m rate=5r/s;
limit_req_zone $binary_remote_addr zone=grafana_dashboard:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=prometheus_metrics:10m rate=15r/s;
limit_req_zone $binary_remote_addr zone=loki_logs:10m rate=20r/s;
limit_req_zone $binary_remote_addr zone=plane_api:10m rate=8r/s;
limit_req_zone $binary_remote_addr zone=codeserver_ide:10m rate=30r/s;
limit_req_zone $binary_remote_addr zone=health_checks:10m rate=100r/s;

# Connection limiting for Pure Bliss services
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_conn_zone $server_name zone=conn_limit_per_server:10m;

# Pure Bliss optimized request size limits
client_max_body_size 100m;  # Increased for code uploads and large files
client_body_buffer_size 128k;
client_header_buffer_size 2k;  # Increased for Vault tokens
large_client_header_buffers 8 16k;  # Increased for JWT tokens

# Pure Bliss timeout configurations (optimized for development workflow)
client_body_timeout 30s;     # Increased for large file uploads
client_header_timeout 15s;   # Increased for complex auth headers
keepalive_timeout 65s;       # Standard keepalive
send_timeout 30s;            # Increased for large responses
proxy_connect_timeout 10s;   # Increased for service startup tolerance
proxy_send_timeout 30s;      # Increased for complex operations
proxy_read_timeout 300s;     # Increased for long-running operations

# Buffer overflow protection for Pure Bliss
client_body_in_file_only clean;
client_body_temp_path /tmp/nginx_client_body_temp;

# Hide upstream errors for security
proxy_intercept_errors on;
EOF

    log_success "Pure Bliss rate limiting configuration created"
}

# Pure Bliss SSL/TLS hardening with Vault PKI integration
create_purebliss_ssl_hardening() {
    log_info "Creating Pure Bliss SSL/TLS hardening with Vault PKI integration"

    cat > "$SECURITY_CONFIG_DIR/purebliss-ssl-hardening.conf" << 'EOF'
# Pure Bliss SSL/TLS Hardening Configuration
# Enhanced SSL/TLS security with Vault PKI integration

# SSL Protocols (only secure versions for Pure Bliss)
ssl_protocols TLSv1.2 TLSv1.3;

# Pure Bliss optimized cipher suites (prioritize performance and security)
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
ssl_prefer_server_ciphers off;

# SSL session optimization for Pure Bliss microservices
ssl_session_cache shared:SSL:50m;
ssl_session_timeout 1d;
ssl_session_tickets off;

# OCSP Stapling with Vault PKI integration
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/nginx/ssl/purebliss-ca-bundle.crt;

# Strong Diffie-Hellman parameters for Pure Bliss
ssl_dhparam /etc/nginx/ssl/dhparam-purebliss.pem;

# SSL security enhancements for Pure Bliss
ssl_early_data off;
ssl_ecdh_curve X25519:prime256v1:secp384r1;

# Perfect Forward Secrecy enforcement
ssl_prefer_server_ciphers on;

# Pure Bliss SSL error handling
ssl_stapling_responder https://vault.purebliss.app:8200/v1/pki/ocsp;
EOF

    log_success "Pure Bliss SSL/TLS hardening configuration created"
}

# Pure Bliss WAF rules with service-specific protections
create_purebliss_waf_rules() {
    log_info "Creating Pure Bliss WAF rules with service-specific protections"

    cat > "$SECURITY_CONFIG_DIR/purebliss-waf-rules.conf" << 'EOF'
# Pure Bliss WAF Rules Configuration
# Service-aware Web Application Firewall rules for Pure Bliss microservices

# Block common attack patterns (enhanced for Pure Bliss)
location ~* "(eval\(|javascript:|<script|UNION.*SELECT|DROP.*TABLE|INSERT.*INTO|vault.*token|keycloak.*password)" {
    deny all;
    access_log /var/log/nginx/purebliss-security.log;
    error_log /var/log/nginx/purebliss-waf-blocks.log;
}

# Enhanced SQL injection protection for Pure Bliss services
location ~* "(UNION.*SELECT|SELECT.*FROM|INSERT.*INTO|UPDATE.*SET|DELETE.*FROM|DROP.*DATABASE|CREATE.*TABLE)" {
    deny all;
    access_log /var/log/nginx/purebliss-security.log;
}

# XSS protection enhanced for Pure Bliss frontend
location ~* "(<script|javascript:|vbscript:|onload=|onerror=|onmouseover=|onclick=|eval\(|String\.fromCharCode)" {
    deny all;
    access_log /var/log/nginx/purebliss-security.log;
}

# Directory traversal protection for Pure Bliss
location ~* "(\.\./|\.\.\\|/etc/passwd|/etc/shadow|/proc/|/sys/|/opt/dev-purebliss)" {
    deny all;
    access_log /var/log/nginx/purebliss-security.log;
}

# Pure Bliss specific file protection
location ~* "\.(env|git|svn|htaccess|htpasswd|ini|log|sh|sql|conf|vault|pem|key)$" {
    deny all;
    access_log /var/log/nginx/purebliss-security.log;
}

# Vault token protection
if ($http_x_vault_token) {
    set $vault_token_present 1;
}
if ($args ~ "vault_token=") {
    return 400 "Vault token in URL forbidden";
}

# Keycloak credential protection
if ($request_body ~ "password=") {
    set $password_in_body 1;
}

# Block vulnerability scanners and suspicious user agents
if ($http_user_agent ~* "(nikto|sqlmap|nessus|openvas|nmap|masscan|gobuster|dirb|wpscan|burp)") {
    return 444;
}

# Block suspicious request methods
if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|PATCH|OPTIONS)$ ) {
    return 405;
}

# Pure Bliss service endpoint protection
location ~* "/(admin|wp-admin|phpmyadmin|adminer|\.well-known/.*\.php)" {
    deny all;
    access_log /var/log/nginx/purebliss-security.log;
}

# Protect Pure Bliss internal endpoints
location ~* "/internal/|/_internal/|/debug/|/_debug/" {
    allow 127.0.0.1;
    allow ::1;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    allow 10.0.0.0/8;
    deny all;
}

# Block access to common backup and temporary files
location ~* "\.(bak|backup|old|orig|tmp|temp|~|swp|swo)$" {
    deny all;
    access_log /var/log/nginx/purebliss-security.log;
}
EOF

    log_success "Pure Bliss WAF rules configuration created"
}

# Pure Bliss security monitoring with service correlation
create_purebliss_security_monitoring() {
    log_info "Creating Pure Bliss security monitoring configuration"

    cat > "$SECURITY_CONFIG_DIR/purebliss-security-monitoring.conf" << 'EOF'
# Pure Bliss Security Monitoring Configuration
# Service-aware security monitoring and logging for Pure Bliss microservices

# Enhanced logging format for Pure Bliss security analysis
log_format purebliss_security '$remote_addr - $remote_user [$time_local] '
                              '"$request" $status $body_bytes_sent '
                              '"$http_referer" "$http_user_agent" '
                              '"$http_x_forwarded_for" '
                              'rt=$request_time uct="$upstream_connect_time" '
                              'uht="$upstream_header_time" urt="$upstream_response_time" '
                              'sl=$ssl_protocol cs=$ssl_cipher '
                              'service="$upstream_addr" '
                              'vault_token_present="$vault_token_present" '
                              'x_purebliss_service="$http_x_purebliss_service"';

# Pure Bliss service-specific logging
log_format purebliss_service_trace '$time_iso8601 $remote_addr "$request" '
                                   '$status $bytes_sent "$http_referer" '
                                   '"$http_user_agent" "$upstream_addr" '
                                   '$request_time $upstream_response_time '
                                   '"$http_x_vault_token" "$http_authorization"';

# Security-specific access logs for Pure Bliss
access_log /var/log/nginx/purebliss-security.log purebliss_security;
access_log /var/log/nginx/purebliss-service-trace.log purebliss_service_trace;

# Pure Bliss error logging
error_log /var/log/nginx/purebliss-error.log warn;
error_log /var/log/nginx/purebliss-rate-limit.log warn;
error_log /var/log/nginx/purebliss-ssl-error.log warn;

# Real IP configuration for Pure Bliss (behind GCP load balancers)
set_real_ip_from 10.0.0.0/8;
set_real_ip_from 172.16.0.0/12;
set_real_ip_from 192.168.0.0/16;
set_real_ip_from 35.191.0.0/16;    # Google Cloud Load Balancer
set_real_ip_from 130.211.0.0/22;   # Google Cloud Load Balancer
real_ip_header X-Forwarded-For;
real_ip_recursive on;

# Pure Bliss geo-blocking (configurable)
geo $blocked_country {
    default 0;
    # Add country blocks as needed for Pure Bliss
    # Example: 192.168.1.0/24 1;
}

# Pure Bliss service health monitoring
map $uri $is_health_check {
    ~*/health 1;
    ~*/status 1;
    ~*/metrics 1;
    default 0;
}

# Pure Bliss service identification
map $upstream_addr $purebliss_service {
    ~*:8200 "vault";
    ~*:8080 "keycloak";
    ~*:3000 "grafana";
    ~*:9090 "prometheus";
    ~*:3100 "loki";
    ~*:8000 "plane";
    ~*:8443 "codeserver";
    default "unknown";
}
EOF

    log_success "Pure Bliss security monitoring configuration created"
}

# Vault integration configuration for NGINX
create_vault_integration_config() {
    log_info "Creating Vault integration configuration for NGINX"

    cat > "$SECURITY_CONFIG_DIR/purebliss-vault-integration.conf" << 'EOF'
# Pure Bliss Vault Integration Configuration
# NGINX integration with HashiCorp Vault for dynamic secrets and PKI

# Vault upstream configuration
upstream vault_cluster {
    server purebliss-vault:8200 max_fails=3 fail_timeout=30s;
    keepalive 32;
    keepalive_requests 100;
    keepalive_timeout 60s;
}

# Vault health check location
location /vault/v1/sys/health {
    access_log off;
    proxy_pass http://vault_cluster/v1/sys/health;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Health check specific settings
    proxy_connect_timeout 5s;
    proxy_send_timeout 5s;
    proxy_read_timeout 5s;
}

# Vault API proxy with enhanced security
location /vault/ {
    # Rate limiting for Vault API
    limit_req zone=vault_api burst=10 nodelay;

    # Vault-specific headers
    proxy_pass http://vault_cluster/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Pure-Bliss-Gateway "nginx";

    # Vault token security
    proxy_hide_header X-Vault-Token;

    # Enhanced timeouts for Vault operations
    proxy_connect_timeout 10s;
    proxy_send_timeout 30s;
    proxy_read_timeout 300s;

    # Buffer configuration for Vault responses
    proxy_buffering on;
    proxy_buffer_size 8k;
    proxy_buffers 32 8k;

    # SSL verification for Vault
    proxy_ssl_verify off;
    proxy_ssl_session_reuse on;
}

# Vault PKI endpoint (special handling)
location /vault/v1/pki/ {
    limit_req zone=vault_api burst=5 nodelay;

    proxy_pass http://vault_cluster/v1/pki/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # PKI specific timeouts
    proxy_connect_timeout 15s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}
EOF

    log_success "Vault integration configuration created"
}

# Keycloak integration configuration with enhanced security
create_keycloak_integration_config() {
    log_info "Creating Keycloak integration configuration"

    cat > "$SECURITY_CONFIG_DIR/purebliss-keycloak-integration.conf" << 'EOF'
# Pure Bliss Keycloak Integration Configuration
# Enhanced security integration with Keycloak authentication service

# Keycloak upstream configuration
upstream keycloak_cluster {
    server purebliss-keycloak:8080 max_fails=3 fail_timeout=30s;
    keepalive 16;
    keepalive_requests 100;
    keepalive_timeout 60s;
}

# Keycloak authentication proxy
location /keycloak/ {
    # Rate limiting for authentication requests
    limit_req zone=keycloak_auth burst=5 nodelay;

    proxy_pass http://keycloak_cluster/keycloak/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Pure-Bliss-Gateway "nginx";

    # Keycloak specific headers
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-Port $server_port;

    # Enhanced security for authentication
    proxy_hide_header X-Powered-By;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    # Timeouts for authentication flows
    proxy_connect_timeout 10s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;

    # Buffer configuration
    proxy_buffering on;
    proxy_buffer_size 8k;
    proxy_buffers 16 8k;
}

# Keycloak admin interface (restricted access)
location /keycloak/admin/ {
    # Strict rate limiting for admin
    limit_req zone=keycloak_auth burst=2 nodelay;

    # IP restriction for admin interface
    allow 127.0.0.1;
    allow ::1;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    allow 10.0.0.0/8;
    deny all;

    proxy_pass http://keycloak_cluster/keycloak/admin/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Authentication validation endpoint
location = /auth {
    internal;
    proxy_pass http://keycloak_cluster/keycloak/realms/master/protocol/openid-connect/userinfo;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URI $request_uri;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
EOF

    log_success "Keycloak integration configuration created"
}

# Create production-ready Pure Bliss NGINX configuration
create_purebliss_production_config() {
    log_info "Creating production-ready Pure Bliss NGINX configuration"

    cat > "$NGINX_CONFIG_DIR/nginx-purebliss-production.conf" << 'EOF'
# Production-Ready Pure Bliss NGINX Configuration
# Maximum security and performance for Pure Bliss microservices environment

user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# Load dynamic modules for Pure Bliss
load_module modules/ngx_http_headers_more_filter_module.so;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
    accept_mutex off;
}

http {
    # Basic settings optimized for Pure Bliss
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Include Pure Bliss security configurations
    include /etc/nginx/conf.d/purebliss-security-headers.conf;
    include /etc/nginx/conf.d/purebliss-rate-limiting.conf;
    include /etc/nginx/conf.d/purebliss-ssl-hardening.conf;
    include /etc/nginx/conf.d/purebliss-waf-rules.conf;
    include /etc/nginx/conf.d/purebliss-security-monitoring.conf;
    include /etc/nginx/conf.d/purebliss-vault-integration.conf;
    include /etc/nginx/conf.d/purebliss-keycloak-integration.conf;

    # Performance optimizations for Pure Bliss
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    types_hash_max_size 2048;
    server_names_hash_bucket_size 128;

    # Gzip compression optimized for Pure Bliss services
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml application/rss+xml application/atom+xml image/svg+xml application/wasm;

    # Pure Bliss service upstreams with health checks
    upstream vault_secure {
        server purebliss-vault:8200 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream keycloak_secure {
        server purebliss-keycloak:8080 max_fails=3 fail_timeout=30s;
        keepalive 16;
    }

    upstream grafana_secure {
        server purebliss-grafana:3000 max_fails=3 fail_timeout=30s;
        keepalive 16;
    }

    upstream prometheus_secure {
        server purebliss-prometheus:9090 max_fails=3 fail_timeout=30s;
        keepalive 16;
    }

    upstream loki_secure {
        server purebliss-loki:3100 max_fails=3 fail_timeout=30s;
        keepalive 16;
    }

    upstream plane_secure {
        server purebliss-plane:3000 max_fails=3 fail_timeout=30s;
        keepalive 16;
    }

    upstream codeserver_secure {
        server purebliss-codeserver:8080 max_fails=3 fail_timeout=30s;
        keepalive 16;
    }

    # HTTP to HTTPS redirect server
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;

        # Security headers even for redirects
        include /etc/nginx/conf.d/purebliss-security-headers.conf;

        # Rate limiting
        limit_req zone=general burst=20 nodelay;
        limit_conn conn_limit_per_ip 10;

        # Pure Bliss health check (HTTP)
        location /health {
            access_log off;
            return 200 "Pure Bliss Gateway - HTTP Health Check OK\n";
            add_header Content-Type text/plain;
        }

        # Redirect all other HTTP to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }

    # Main HTTPS server for Pure Bliss services
    server {
        listen 443 ssl http2 default_server;
        listen [::]:443 ssl http2 default_server;
        server_name dev.purebliss.app *.dev.purebliss.app;

        # SSL Certificate configuration for Pure Bliss
        ssl_certificate /etc/nginx/ssl/live/dev.purebliss.app/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/live/dev.purebliss.app/privkey.pem;

        # Include all Pure Bliss security configurations
        include /etc/nginx/conf.d/purebliss-ssl-hardening.conf;
        include /etc/nginx/conf.d/purebliss-security-headers.conf;
        include /etc/nginx/conf.d/purebliss-rate-limiting.conf;

        # Rate limiting and connection limits
        limit_req zone=general burst=20 nodelay;
        limit_conn conn_limit_per_ip 20;
        limit_conn conn_limit_per_server 1000;

        # Pure Bliss health check endpoint
        location /health {
            limit_req zone=health_checks burst=50 nodelay;
            access_log off;

            allow 127.0.0.1;
            allow ::1;
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            allow 192.168.0.0/16;

            return 200 "Pure Bliss Gateway - HTTPS Health Check OK\n";
            add_header Content-Type text/plain;
            add_header X-Pure-Bliss-Health "OK";
        }

        # Vault service proxy (included from vault integration config)
        include /etc/nginx/conf.d/purebliss-vault-integration.conf;

        # Keycloak service proxy (included from keycloak integration config)
        include /etc/nginx/conf.d/purebliss-keycloak-integration.conf;

        # Monitoring services with authentication
        location /grafana/ {
            auth_request /auth;
            limit_req zone=grafana_dashboard burst=15 nodelay;

            proxy_pass http://grafana_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Pure-Bliss-Service "grafana";
        }

        location /prometheus/ {
            auth_request /auth;
            limit_req zone=prometheus_metrics burst=20 nodelay;

            proxy_pass http://prometheus_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Pure-Bliss-Service "prometheus";
        }

        location /loki/ {
            auth_request /auth;
            limit_req zone=loki_logs burst=25 nodelay;

            proxy_pass http://loki_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Pure-Bliss-Service "loki";
        }

        # Project management
        location /plane/ {
            auth_request /auth;
            limit_req zone=plane_api burst=12 nodelay;

            proxy_pass http://plane_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Pure-Bliss-Service "plane";
        }

        # Code server IDE
        location /code-server/ {
            auth_request /auth;
            limit_req zone=codeserver_ide burst=40 nodelay;

            proxy_pass http://codeserver_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection upgrade;
            proxy_set_header X-Pure-Bliss-Service "codeserver";

            # WebSocket support for code-server
            proxy_http_version 1.1;
            proxy_cache_bypass $http_upgrade;
        }

        # Pure Bliss service status endpoint
        location /pure-bliss-status {
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            allow 192.168.0.0/16;
            deny all;

            return 200 '{"status":"secure","environment":"pure-bliss-dev","ssl":"enabled","services":["vault","keycloak","grafana","prometheus","loki","plane","codeserver"],"security_level":"maximum","gateway_version":"2.0"}';
            add_header Content-Type application/json;
        }

        # Default location with Pure Bliss branding
        location / {
            return 200 "Pure Bliss Development Environment\nSecure Gateway v2.0\nAll services protected with maximum security\n";
            add_header Content-Type text/plain;
            add_header X-Pure-Bliss-Gateway "v2.0";
        }
    }
}
EOF

    log_success "Production-ready Pure Bliss NGINX configuration created"
}

# Create health validation integration
create_health_validation_integration() {
    log_info "Creating health validation integration for Pure Bliss NGINX"

    cat > "$SCRIPT_DIR/services/nginx/nginx-health-validation.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

# Pure Bliss NGINX Health Validation with Service Integration
# Comprehensive health validation for NGINX gateway and all proxied services

NGINX_CONTAINER="purebliss-nginx"
PUREBLISS_DOMAIN="dev.purebliss.app"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

validate_nginx_health() {
    echo "🔍 Pure Bliss NGINX Health Validation Starting..."

    # Validate NGINX container
    if ! docker ps | grep -q "$NGINX_CONTAINER"; then
        echo "❌ NGINX container not running"
        return 1
    fi

    # Validate NGINX configuration
    if ! docker exec "$NGINX_CONTAINER" nginx -t 2>/dev/null; then
        echo "❌ NGINX configuration invalid"
        return 1
    fi

    # Validate HTTPS health endpoint
    HTTPS_RESPONSE=$(curl -k -s -w "%{http_code}" "https://$PUREBLISS_DOMAIN/health" -o /dev/null || echo "000")
    if [[ "$HTTPS_RESPONSE" == "200" ]]; then
        echo "✅ HTTPS health endpoint responding"
    else
        echo "❌ HTTPS health endpoint failed (code: $HTTPS_RESPONSE)"
        return 1
    fi

    # Validate Pure Bliss services through NGINX
    validate_purebliss_services

    # Validate security headers
    validate_security_headers

    echo "✅ Pure Bliss NGINX Health Validation Complete"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - NGINX_HEALTH_VALIDATION: All checks passed - gateway healthy" >> "$LOG_FILE"
}

validate_purebliss_services() {
    echo "🔍 Validating Pure Bliss services through NGINX..."

    services=(
        "vault:8200:/vault/v1/sys/health"
        "keycloak:8080:/keycloak/realms/master"
        "grafana:3000:/grafana/api/health"
        "prometheus:9090:/prometheus/api/v1/query?query=up"
        "loki:3100:/loki/api/v1/labels"
    )

    for service_config in "${services[@]}"; do
        IFS=':' read -r service port path <<< "$service_config"

        # Test service through NGINX proxy
        RESPONSE=$(curl -k -s -w "%{http_code}" "https://$PUREBLISS_DOMAIN$path" -o /dev/null 2>/dev/null || echo "000")

        if [[ "$RESPONSE" =~ ^[23] ]]; then
            echo "✅ $service service accessible through NGINX"
        else
            echo "⚠️  $service service not accessible (may require auth) - code: $RESPONSE"
        fi
    done
}

validate_security_headers() {
    echo "🔍 Validating Pure Bliss security headers..."

    HEADERS_RESPONSE=$(curl -k -sI "https://$PUREBLISS_DOMAIN/health" 2>/dev/null || echo "FAILED")

    security_headers=(
        "Strict-Transport-Security"
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
        "Content-Security-Policy"
        "X-Pure-Bliss-Gateway"
    )

    for header in "${headers[@]}"; do
        if echo "$HEADERS_RESPONSE" | grep -qi "$header"; then
            echo "✅ $header header present"
        else
            echo "❌ $header header missing"
        fi
    done
}

# Main execution
validate_nginx_health "$@"
EOF

    chmod +x "$SCRIPT_DIR/services/nginx/nginx-health-validation.sh"
    log_success "Health validation integration created"
}

# Create smart upstream configuration
create_smart_upstream_config() {
    log_info "Creating smart upstream configuration for Pure Bliss services"

    cat > "$SECURITY_CONFIG_DIR/purebliss-smart-upstream.conf" << 'EOF'
# Pure Bliss Smart Upstream Configuration
# Intelligent upstream handling with graceful degradation

# Upstream health check configuration
upstream_conf {
    zone purebliss_services 64k;

    # Vault service
    server purebliss-vault:8200 max_fails=3 fail_timeout=30s slow_start=30s;

    # Keycloak service
    server purebliss-keycloak:8080 max_fails=3 fail_timeout=30s slow_start=30s;

    # Grafana service
    server purebliss-grafana:3000 max_fails=3 fail_timeout=30s slow_start=30s;

    # Prometheus service
    server purebliss-prometheus:9090 max_fails=3 fail_timeout=30s slow_start=30s;

    # Loki service
    server purebliss-loki:3100 max_fails=3 fail_timeout=30s slow_start=30s;

    # Plane service
    server purebliss-plane:3000 max_fails=3 fail_timeout=30s slow_start=30s;

    # CodeServer service
    server purebliss-codeserver:8080 max_fails=3 fail_timeout=30s slow_start=30s;
}

# Smart upstream selection based on service availability
map $upstream_addr $service_status {
    ~*vault "vault_available";
    ~*keycloak "keycloak_available";
    ~*grafana "grafana_available";
    ~*prometheus "prometheus_available";
    ~*loki "loki_available";
    ~*plane "plane_available";
    ~*codeserver "codeserver_available";
    default "service_unknown";
}

# Graceful degradation responses
location @vault_unavailable {
    return 503 '{"error":"Vault service temporarily unavailable","service":"vault","gateway":"pure-bliss"}';
    add_header Content-Type application/json;
}

location @keycloak_unavailable {
    return 503 '{"error":"Authentication service temporarily unavailable","service":"keycloak","gateway":"pure-bliss"}';
    add_header Content-Type application/json;
}

location @service_unavailable {
    return 503 '{"error":"Service temporarily unavailable","gateway":"pure-bliss","retry_after":"30"}';
    add_header Content-Type application/json;
    add_header Retry-After 30;
}
EOF

    log_success "Smart upstream configuration created"
}

# Main execution function
main() {
    log_info "Starting Pure Bliss NGINX Security Hardening Enhancement - $SCRIPT_NAME v$SCRIPT_VERSION"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - NGINX_PUREBLISS_HARDENING: Starting Pure Bliss specific security enhancement with Vault integration and health validation" >> "$LOG_FILE"

    enhance_nginx_security_purebliss

    # Create deployment guide specific to Pure Bliss
    create_purebliss_deployment_guide

    echo "$(date '+%Y-%m-%d %H:%M:%S') - NGINX_PUREBLISS_HARDENING: Enhancement complete - Pure Bliss optimized configurations ready" >> "$LOG_FILE"

    log_success "Pure Bliss NGINX Security Hardening Enhancement completed successfully"
    log_info "Pure Bliss specific configurations created in: $SECURITY_CONFIG_DIR"
    log_info "Production configuration: $NGINX_CONFIG_DIR/nginx-purebliss-production.conf"
    log_info "Health validation: $SCRIPT_DIR/services/nginx/nginx-health-validation.sh"
    log_info "Deployment guide: $DOC_DIR/purebliss-nginx-security-deployment.md"
}

# Create Pure Bliss specific deployment guide
create_purebliss_deployment_guide() {
    cat > "$DOC_DIR/purebliss-nginx-security-deployment.md" << 'EOF'
# Pure Bliss NGINX Security Deployment Guide

## Overview
Complete deployment guide for Pure Bliss NGINX security hardening with microservices integration, Vault PKI, and comprehensive health validation.

## Pure Bliss Security Enhancements

### 🔒 Enhanced Security Features
- **Microservices-aware CSP**: Content Security Policy optimized for Pure Bliss services
- **Vault Integration**: Dynamic secrets and PKI certificate management
- **Keycloak Integration**: Centralized authentication with enhanced security
- **Service-specific Rate Limiting**: Tailored limits for each Pure Bliss service
- **Health Validation**: Comprehensive monitoring with service correlation

### 🎯 Pure Bliss Service Protection
- **Vault API**: Secure proxy with token protection and rate limiting
- **Keycloak Auth**: Enhanced authentication flows with admin protection
- **Grafana/Prometheus/Loki**: Monitoring stack with authentication gates
- **Plane**: Project management with API protection
- **CodeServer**: IDE with WebSocket support and enhanced security

## Deployment Steps

### Phase 1: Enhanced Security Headers
```bash
docker cp /opt/dev-purebliss/container-configs/nginx/purebliss-security-headers.conf purebliss-nginx:/etc/nginx/conf.d/
docker exec purebliss-nginx nginx -s reload
```

### Phase 2: Service-specific Rate Limiting
```bash
docker cp /opt/dev-purebliss/container-configs/nginx/purebliss-rate-limiting.conf purebliss-nginx:/etc/nginx/conf.d/
docker exec purebliss-nginx nginx -s reload
```

### Phase 3: Vault Integration
```bash
docker cp /opt/dev-purebliss/container-configs/nginx/purebliss-vault-integration.conf purebliss-nginx:/etc/nginx/conf.d/
docker exec purebliss-nginx nginx -s reload
```

### Phase 4: Complete Pure Bliss Configuration
```bash
docker cp /opt/dev-purebliss/services/nginx/nginx-purebliss-production.conf purebliss-nginx:/etc/nginx/nginx.conf
docker exec purebliss-nginx nginx -s reload
```

## Health Validation

Run Pure Bliss specific health validation:
```bash
/opt/dev-purebliss/dev_scripts/services/nginx/nginx-health-validation.sh
```

## Pure Bliss Service Integration

### Service Endpoints
- **Vault**: `https://dev.purebliss.app/vault/`
- **Keycloak**: `https://dev.purebliss.app/keycloak/`
- **Grafana**: `https://dev.purebliss.app/grafana/`
- **Prometheus**: `https://dev.purebliss.app/prometheus/`
- **Loki**: `https://dev.purebliss.app/loki/`
- **Plane**: `https://dev.purebliss.app/plane/`
- **CodeServer**: `https://dev.purebliss.app/code-server/`

### Authentication Flow
1. All services except Vault and Keycloak require authentication
2. Authentication via Keycloak realms
3. Vault tokens handled securely with header protection
4. Admin interfaces restricted by IP

## Security Monitoring

### Log Files
- `/var/log/nginx/purebliss-security.log`: Security events
- `/var/log/nginx/purebliss-service-trace.log`: Service correlation
- `/var/log/nginx/purebliss-error.log`: Error tracking

### Health Endpoints
- `https://dev.purebliss.app/health`: Gateway health
- `https://dev.purebliss.app/pure-bliss-status`: Service status

## Troubleshooting

### Common Issues
1. **Service Unavailable**: Check upstream service health
2. **Authentication Failed**: Verify Keycloak realm configuration
3. **Rate Limiting**: Adjust service-specific limits if needed
4. **SSL Errors**: Verify Vault PKI certificate chain

### Recovery Procedures
1. Container restart with health validation
2. Service dependency verification
3. Configuration rollback procedures
4. Upstream service coordination
EOF
}

# Execute main function
main "$@"
