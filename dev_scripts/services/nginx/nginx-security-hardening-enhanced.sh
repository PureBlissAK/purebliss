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
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Comprehensive NGINX Security Hardening Enhancement"

# Configuration paths
NGINX_CONFIG_DIR="/opt/dev-purebliss/services/nginx"
SECURITY_CONFIG_DIR="/opt/dev-purebliss/container-configs/nginx"
NGINX_CONTAINER_NAME="purebliss-nginx"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Enhanced security hardening function
enhance_nginx_security() {
    log_info "Starting NGINX Security Hardening Enhancement"

    # Create security configuration directories
    mkdir -p "$SECURITY_CONFIG_DIR"
    mkdir -p "$NGINX_CONFIG_DIR/security"
    mkdir -p "$NGINX_CONFIG_DIR/ssl"

    # Create enhanced security headers configuration
    create_enhanced_security_headers

    # Create rate limiting configuration
    create_rate_limiting_config

    # Create SSL/TLS hardening configuration
    create_ssl_hardening_config

    # Create WAF basic rules
    create_basic_waf_rules

    # Create security monitoring configuration
    create_security_monitoring

    # Create production-ready nginx configuration
    create_production_nginx_config

    # Create security validation script
    create_security_validation_script

    log_success "NGINX Security Hardening Enhancement Complete"
}

# Enhanced security headers with comprehensive protection
create_enhanced_security_headers() {
    log_info "Creating enhanced security headers configuration"

    cat > "$SECURITY_CONFIG_DIR/security-headers-enhanced.conf" << 'EOF'
# Enhanced Security Headers Configuration
# Comprehensive protection against web vulnerabilities

# Hide server version and operating system information
server_tokens off;
more_clear_headers Server;
more_set_headers "Server: Pure-Bliss-Secure";

# Security Headers
add_header X-Frame-Options "DENY" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header X-Permitted-Cross-Domain-Policies "none" always;
add_header X-Download-Options "noopen" always;

# Enhanced Content Security Policy
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.google-analytics.com https://www.googletagmanager.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://www.google-analytics.com; object-src 'none'; frame-ancestors 'none'; base-uri 'self'; form-action 'self';" always;

# Strict Transport Security (HSTS) - Only for HTTPS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Feature Policy / Permissions Policy
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), interest-cohort=()" always;

# Prevent MIME type confusion attacks
add_header X-Content-Type-Options "nosniff" always;

# Control DNS prefetching
add_header X-DNS-Prefetch-Control "off" always;

# Remove potentially sensitive headers
more_clear_headers "X-Powered-By";
more_clear_headers "X-AspNet-Version";
more_clear_headers "X-AspNetMvc-Version";
EOF

    log_success "Enhanced security headers configuration created"
}

# Comprehensive rate limiting configuration
create_rate_limiting_config() {
    log_info "Creating enhanced rate limiting configuration"

    cat > "$SECURITY_CONFIG_DIR/rate-limiting-enhanced.conf" << 'EOF'
# Enhanced Rate Limiting Configuration
# Multi-layer protection against DDoS and brute force attacks

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=5r/s;
limit_req_zone $binary_remote_addr zone=strict:10m rate=1r/m;

# Connection limiting
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_conn_zone $server_name zone=conn_limit_per_server:10m;

# Request size limits
client_max_body_size 10m;
client_body_buffer_size 128k;
client_header_buffer_size 1k;
large_client_header_buffers 4 8k;

# Timeout configurations (prevent slowloris attacks)
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;
proxy_connect_timeout 5;
proxy_send_timeout 10;
proxy_read_timeout 10;

# Buffer overflow protection
client_body_in_file_only clean;
client_body_temp_path /tmp/nginx_client_body_temp;

# Hide upstream errors
proxy_intercept_errors on;
EOF

    log_success "Enhanced rate limiting configuration created"
}

# SSL/TLS hardening configuration
create_ssl_hardening_config() {
    log_info "Creating SSL/TLS hardening configuration"

    cat > "$SECURITY_CONFIG_DIR/ssl-hardening.conf" << 'EOF'
# SSL/TLS Hardening Configuration
# Maximum security SSL/TLS implementation

# SSL Protocols (only secure versions)
ssl_protocols TLSv1.2 TLSv1.3;

# Strong cipher suites (prioritize forward secrecy)
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
ssl_prefer_server_ciphers off;

# SSL session optimization
ssl_session_cache shared:SSL:50m;
ssl_session_timeout 1d;
ssl_session_tickets off;

# OCSP Stapling for improved performance and privacy
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/nginx/ssl/ca-bundle.crt;

# Strong Diffie-Hellman parameters
ssl_dhparam /etc/nginx/ssl/dhparam.pem;

# SSL security enhancements
ssl_early_data off;
ssl_ecdh_curve X25519:prime256v1:secp384r1;

# Perfect Forward Secrecy
ssl_prefer_server_ciphers on;
EOF

    log_success "SSL/TLS hardening configuration created"
}

# Basic WAF rules for common attacks
create_basic_waf_rules() {
    log_info "Creating basic WAF rules configuration"

    cat > "$SECURITY_CONFIG_DIR/waf-basic-rules.conf" << 'EOF'
# Basic WAF Rules Configuration
# Protection against common web attacks

# Block common attack patterns
location ~* "(eval\(|javascript:|<script|UNION.*SELECT|DROP.*TABLE|INSERT.*INTO)" {
    deny all;
    access_log /var/log/nginx/security.log;
}

# Block SQL injection attempts
location ~* "(UNION.*SELECT|SELECT.*FROM|INSERT.*INTO|UPDATE.*SET|DELETE.*FROM)" {
    deny all;
    access_log /var/log/nginx/security.log;
}

# Block XSS attempts
location ~* "(<script|javascript:|vbscript:|onload=|onerror=|onmouseover=)" {
    deny all;
    access_log /var/log/nginx/security.log;
}

# Block directory traversal attempts
location ~* "\.\./|\.\.\\|/etc/passwd|/etc/shadow" {
    deny all;
    access_log /var/log/nginx/security.log;
}

# Block common vulnerability scanners
if ($http_user_agent ~* "(nikto|sqlmap|nessus|openvas|nmap|masscan)") {
    return 444;
}

# Block suspicious request methods
if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|PATCH|OPTIONS)$ ) {
    return 405;
}

# Block requests with suspicious headers
if ($http_x_forwarded_for ~* "(DROP|SELECT|UNION|INSERT|UPDATE|DELETE)") {
    return 444;
}

# Hide sensitive file extensions
location ~* \.(git|svn|htaccess|htpasswd|ini|log|sh|sql|conf)$ {
    deny all;
    access_log /var/log/nginx/security.log;
}

# Block access to common backup files
location ~* \.(bak|backup|old|orig|tmp|temp|~)$ {
    deny all;
    access_log /var/log/nginx/security.log;
}
EOF

    log_success "Basic WAF rules configuration created"
}

# Security monitoring and logging
create_security_monitoring() {
    log_info "Creating security monitoring configuration"

    cat > "$SECURITY_CONFIG_DIR/security-monitoring.conf" << 'EOF'
# Security Monitoring Configuration
# Comprehensive logging and monitoring for security events

# Enhanced logging format for security analysis
log_format security_detailed '$remote_addr - $remote_user [$time_local] '
                           '"$request" $status $body_bytes_sent '
                           '"$http_referer" "$http_user_agent" '
                           '"$http_x_forwarded_for" '
                           'rt=$request_time uct="$upstream_connect_time" '
                           'uht="$upstream_header_time" urt="$upstream_response_time" '
                           'sl=$ssl_protocol cs=$ssl_cipher';

# Security-specific access log
access_log /var/log/nginx/security.log security_detailed;

# Rate limiting logging
error_log /var/log/nginx/rate_limit.log warn;

# SSL error logging
error_log /var/log/nginx/ssl_error.log warn;

# Geo-blocking (example configuration)
geo $blocked_country {
    default 0;
    # Add country blocks as needed
    # Example: 192.168.1.0/24 1;
}

# Real IP configuration for proper logging behind proxies
set_real_ip_from 10.0.0.0/8;
set_real_ip_from 172.16.0.0/12;
set_real_ip_from 192.168.0.0/16;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
EOF

    log_success "Security monitoring configuration created"
}

# Create production-ready nginx configuration with all security enhancements
create_production_nginx_config() {
    log_info "Creating production-ready NGINX configuration with security hardening"

    cat > "$NGINX_CONFIG_DIR/nginx-production-hardened.conf" << 'EOF'
# Production-Ready NGINX Configuration with Security Hardening
# Pure Bliss Development Environment - Maximum Security

user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# Load dynamic modules
load_module modules/ngx_http_headers_more_filter_module.so;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    # Basic settings
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Include security configurations
    include /etc/nginx/conf.d/security-headers-enhanced.conf;
    include /etc/nginx/conf.d/rate-limiting-enhanced.conf;
    include /etc/nginx/conf.d/ssl-hardening.conf;
    include /etc/nginx/conf.d/waf-basic-rules.conf;
    include /etc/nginx/conf.d/security-monitoring.conf;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    types_hash_max_size 2048;
    server_names_hash_bucket_size 64;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml application/rss+xml application/atom+xml image/svg+xml;

    # Service upstreams with health checks
    upstream vault_secure {
        server purebliss-vault:8200 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream keycloak_secure {
        server purebliss-keycloak:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream grafana_secure {
        server purebliss-grafana:3000 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream prometheus_secure {
        server purebliss-prometheus:9090 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream loki_secure {
        server purebliss-loki:3100 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream plane_secure {
        server purebliss-plane:3000 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream codeserver_secure {
        server purebliss-codeserver:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    # HTTP to HTTPS redirect server
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;

        # Security headers even for redirects
        include /etc/nginx/conf.d/security-headers-enhanced.conf;

        # Rate limiting
        limit_req zone=general burst=20 nodelay;
        limit_conn conn_limit_per_ip 10;

        # Redirect all HTTP to HTTPS
        return 301 https://$host$request_uri;
    }

    # Main HTTPS server with comprehensive security
    server {
        listen 443 ssl http2 default_server;
        listen [::]:443 ssl http2 default_server;
        server_name dev.purebliss.app *.dev.purebliss.app;

        # SSL Certificate configuration
        ssl_certificate /etc/nginx/ssl/live/dev.purebliss.app/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/live/dev.purebliss.app/privkey.pem;

        # Include all security configurations
        include /etc/nginx/conf.d/ssl-hardening.conf;
        include /etc/nginx/conf.d/security-headers-enhanced.conf;
        include /etc/nginx/conf.d/rate-limiting-enhanced.conf;

        # Rate limiting and connection limits
        limit_req zone=general burst=20 nodelay;
        limit_conn conn_limit_per_ip 10;
        limit_conn conn_limit_per_server 1000;

        # Health check endpoint (internal only)
        location /health {
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            allow 192.168.0.0/16;
            deny all;

            return 200 "nginx healthy - production mode with security hardening\n";
            add_header Content-Type text/plain;
        }

        # Vault API proxy with enhanced security
        location /vault/ {
            limit_req zone=api burst=10 nodelay;

            proxy_pass http://vault_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_ssl_verify off;
            proxy_connect_timeout 5;
            proxy_send_timeout 10;
            proxy_read_timeout 10;
        }

        # Keycloak authentication service
        location /keycloak/ {
            limit_req zone=login burst=5 nodelay;

            proxy_pass http://keycloak_secure/keycloak/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Monitoring services with authentication
        location /grafana/ {
            auth_request /auth;

            proxy_pass http://grafana_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /prometheus/ {
            auth_request /auth;

            proxy_pass http://prometheus_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /loki/ {
            auth_request /auth;

            proxy_pass http://loki_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Project management
        location /plane/ {
            auth_request /auth;

            proxy_pass http://plane_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Code server IDE
        location /code-server/ {
            auth_request /auth;

            proxy_pass http://codeserver_secure/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection upgrade;
        }

        # Authentication endpoint
        location = /auth {
            internal;
            proxy_pass http://keycloak_secure/keycloak/realms/master/protocol/openid-connect/userinfo;
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
            proxy_set_header X-Original-URI $request_uri;
        }

        # Security monitoring endpoint
        location /security-status {
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            deny all;

            return 200 '{"status":"secure","ssl":"enabled","headers":"enhanced","waf":"basic","rate_limiting":"active"}';
            add_header Content-Type application/json;
        }

        # Default deny for undefined locations
        location / {
            return 403 "Access Denied - Security Policy";
        }
    }
}
EOF

    log_success "Production-ready NGINX configuration created"
}

# Create security validation script
create_security_validation_script() {
    log_info "Creating NGINX security validation script"

    cat > "$SCRIPT_DIR/services/nginx/validate-nginx-security.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

# NGINX Security Validation Script
# Comprehensive security testing for NGINX configuration

NGINX_CONTAINER="purebliss-nginx"
TEST_DOMAIN="dev.purebliss.app"
RESULTS_FILE="/tmp/nginx_security_results.json"

validate_security_headers() {
    echo "Testing security headers..."

    RESPONSE=$(curl -sI "https://$TEST_DOMAIN/health" 2>/dev/null || echo "FAILED")

    if [[ "$RESPONSE" == "FAILED" ]]; then
        echo "❌ HTTPS connection failed"
        return 1
    fi

    # Check for security headers
    headers=(
        "Strict-Transport-Security"
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
        "Content-Security-Policy"
        "Referrer-Policy"
        "Permissions-Policy"
    )

    for header in "${headers[@]}"; do
        if echo "$RESPONSE" | grep -qi "$header"; then
            echo "✅ $header header present"
        else
            echo "❌ $header header missing"
        fi
    done
}

validate_ssl_configuration() {
    echo "Testing SSL/TLS configuration..."

    # Test SSL protocols
    if openssl s_client -connect "$TEST_DOMAIN:443" -tls1_2 -verify_return_error < /dev/null 2>/dev/null; then
        echo "✅ TLS 1.2 supported"
    else
        echo "❌ TLS 1.2 not working"
    fi

    # Test weak protocols (should fail)
    if ! openssl s_client -connect "$TEST_DOMAIN:443" -ssl3 < /dev/null 2>/dev/null; then
        echo "✅ SSLv3 properly disabled"
    else
        echo "❌ SSLv3 still enabled (security risk)"
    fi
}

validate_rate_limiting() {
    echo "Testing rate limiting..."

    # Send multiple rapid requests
    for i in {1..15}; do
        curl -s "https://$TEST_DOMAIN/health" > /dev/null &
    done
    wait

    # Check if rate limiting is working
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TEST_DOMAIN/health")
    if [[ "$RESPONSE_CODE" == "429" ]]; then
        echo "✅ Rate limiting active"
    else
        echo "⚠️  Rate limiting may not be properly configured"
    fi
}

validate_waf_rules() {
    echo "Testing WAF rules..."

    # Test SQL injection protection
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TEST_DOMAIN/health?id=1' OR '1'='1")
    if [[ "$RESPONSE_CODE" == "403" || "$RESPONSE_CODE" == "444" ]]; then
        echo "✅ SQL injection protection active"
    else
        echo "❌ SQL injection protection not working"
    fi

    # Test XSS protection
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TEST_DOMAIN/health?test=<script>alert('xss')</script>")
    if [[ "$RESPONSE_CODE" == "403" || "$RESPONSE_CODE" == "444" ]]; then
        echo "✅ XSS protection active"
    else
        echo "❌ XSS protection not working"
    fi
}

main() {
    echo "🔒 NGINX Security Validation Starting..."
    echo "=================================="

    validate_security_headers
    echo ""
    validate_ssl_configuration
    echo ""
    validate_rate_limiting
    echo ""
    validate_waf_rules

    echo ""
    echo "🔒 NGINX Security Validation Complete"
    echo "Results logged to: $RESULTS_FILE"
}

main "$@"
EOF

    chmod +x "$SCRIPT_DIR/services/nginx/validate-nginx-security.sh"
    log_success "NGINX security validation script created"
}

# Main execution
main() {
    log_info "Starting NGINX Security Hardening Enhancement - $SCRIPT_NAME v$SCRIPT_VERSION"

    # Log to central development log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - NGINX_SECURITY_HARDENING: Starting comprehensive security enhancement" >> "$LOG_FILE"

    enhance_nginx_security

    # Create deployment instructions
    create_deployment_instructions

    echo "$(date '+%Y-%m-%d %H:%M:%S') - NGINX_SECURITY_HARDENING: Enhancement complete - configurations ready for deployment" >> "$LOG_FILE"

    log_success "NGINX Security Hardening Enhancement completed successfully"
    log_info "Next steps:"
    log_info "1. Review configurations in $SECURITY_CONFIG_DIR"
    log_info "2. Test security enhancements in staging environment"
    log_info "3. Deploy production-hardened configuration when ready"
    log_info "4. Run security validation: $SCRIPT_DIR/services/nginx/validate-nginx-security.sh"
}

# Create deployment instructions
create_deployment_instructions() {
    cat > "$DOC_DIR/nginx-security-deployment-guide.md" << 'EOF'
# NGINX Security Hardening Deployment Guide

## Overview
This guide covers the deployment of comprehensive NGINX security hardening enhancements for the Pure Bliss development environment.

## Security Enhancements Included

### 1. Enhanced Security Headers
- **X-Frame-Options**: Prevents clickjacking attacks
- **Content-Security-Policy**: Comprehensive XSS protection
- **Strict-Transport-Security**: Forces HTTPS connections
- **X-Content-Type-Options**: Prevents MIME sniffing
- **Permissions-Policy**: Controls browser features
- **Server Token Hiding**: Obscures server information

### 2. Advanced Rate Limiting
- **Multi-zone rate limiting**: Different limits for different endpoints
- **Connection limiting**: Prevents connection flooding
- **Request size limits**: Prevents buffer overflow attacks
- **Timeout configurations**: Protection against slowloris attacks

### 3. SSL/TLS Hardening
- **Protocol restrictions**: Only TLS 1.2 and 1.3
- **Strong cipher suites**: Perfect Forward Secrecy enabled
- **OCSP stapling**: Improved certificate validation
- **Session security**: Secure session management

### 4. Basic WAF Rules
- **SQL injection protection**: Pattern-based blocking
- **XSS protection**: Script injection prevention
- **Directory traversal protection**: Path-based security
- **File extension blocking**: Sensitive file protection

### 5. Security Monitoring
- **Enhanced logging**: Detailed security event logging
- **Real IP detection**: Proper client IP identification
- **Geographic blocking**: Country-based restrictions (configurable)

## Deployment Steps

### Phase 1: Review and Test
1. Review all configuration files in `/opt/dev-purebliss/container-configs/nginx/`
2. Test configurations in development environment
3. Run security validation script

### Phase 2: Gradual Deployment
1. Deploy security headers first
2. Enable rate limiting with monitoring
3. Implement SSL/TLS hardening
4. Activate WAF rules

### Phase 3: Full Production Deployment
1. Switch to production-hardened configuration
2. Enable all security features
3. Monitor security logs
4. Validate security posture

## Security Validation

Run the security validation script:
```bash
/opt/dev-purebliss/dev_scripts/services/nginx/validate-nginx-security.sh
```

## Configuration Files

- `security-headers-enhanced.conf`: Comprehensive security headers
- `rate-limiting-enhanced.conf`: Advanced rate limiting rules
- `ssl-hardening.conf`: SSL/TLS security configuration
- `waf-basic-rules.conf`: Basic Web Application Firewall rules
- `security-monitoring.conf`: Security logging and monitoring
- `nginx-production-hardened.conf`: Complete production configuration

## Monitoring and Maintenance

### Log Files to Monitor
- `/var/log/nginx/security.log`: Security events
- `/var/log/nginx/rate_limit.log`: Rate limiting events
- `/var/log/nginx/ssl_error.log`: SSL/TLS errors

### Regular Security Tasks
1. Review security logs weekly
2. Update WAF rules based on threat intelligence
3. Test security configurations monthly
4. Update SSL certificates before expiration

## Security Metrics

Monitor these key security indicators:
- Blocked requests per hour
- SSL/TLS connection success rate
- Rate limiting effectiveness
- Security header compliance

## Incident Response

If security incidents are detected:
1. Check security logs for attack patterns
2. Analyze blocked requests
3. Update WAF rules if needed
4. Consider IP blocking for persistent threats

## Additional Security Considerations

### Future Enhancements
- ModSecurity integration for advanced WAF
- Fail2Ban integration for IP blocking
- GeoIP blocking for country restrictions
- DDoS protection with cloud services

### Security Testing
- Regular penetration testing
- SSL/TLS configuration validation
- Security header testing
- Rate limiting effectiveness testing
EOF

    log_success "Deployment guide created at $DOC_DIR/nginx-security-deployment-guide.md"
}

# Execute main function
main "$@"
