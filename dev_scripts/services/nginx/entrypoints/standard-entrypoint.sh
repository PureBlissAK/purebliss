#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# STANDARD_ENTRYPOINT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="standard-entrypoint.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
standard_entrypoint_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
standard_entrypoint_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
standard_entrypoint_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
standard_entrypoint_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    standard_entrypoint_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        standard_entrypoint_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            standard_entrypoint_log_success "Validation passed - proceeding with auto-commit"
        else
            standard_entrypoint_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        standard_entrypoint_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        standard_entrypoint_log_info "Auto-commit system not available - manual commit required"
        standard_entrypoint_log_info "Recommended commit message: $commit_message"
        standard_entrypoint_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
standard_entrypoint_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    standard_entrypoint_log_success "$final_message"
    
    # Execute auto-commit wrapper
    standard_entrypoint_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    standard_entrypoint_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Logging functions
log_info() { echo "[$(date)] INFO: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_error() { echo "[$(date)] ERROR: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_success() { echo "[$(date)] SUCCESS: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
log_warn() { echo "[$(date)] WARN: $1" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }


log_info "Nginx entrypoint.sh started"

# Ensure nginx temp/cache directories exist and are writable
for d in /var/cache/nginx /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp; do
    mkdir -p "$d"
    chmod 777 "$d"
    log_info "Ensured directory $d exists and is writable (chmod 777)"
done

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


# Try to fetch/generate SSL certs from Vault PKI, fallback to self-signed if needed
SSL_DIR="/etc/nginx/ssl"
mkdir -p "$SSL_DIR"

# Try Vault PKI first
VAULT_CERT_OK=0
if command -v vault >/dev/null 2>&1 && [[ -n "${VAULT_TOKEN:-}" ]]; then
    log_info "Attempting to fetch SSL cert from Vault PKI for $DOMAIN..."
    if vault write -format=json pki-nginx/issue/nginx-role common_name="$DOMAIN" ttl="24h" > "$SSL_DIR/vault_cert.json" 2>/dev/null; then
        cat "$SSL_DIR/vault_cert.json" | jq -r .data.certificate > "$SSL_DIR/nginx.crt"
        cat "$SSL_DIR/vault_cert.json" | jq -r .data.issuing_ca >> "$SSL_DIR/nginx.crt"
        cat "$SSL_DIR/vault_cert.json" | jq -r .data.private_key > "$SSL_DIR/nginx.key"
        chmod 600 "$SSL_DIR/nginx.key"
        chmod 644 "$SSL_DIR/nginx.crt"
        VAULT_CERT_OK=1
        log_success "Fetched SSL cert from Vault PKI."
    else
        log_warn "Vault PKI cert fetch failed, will use fallback."
    fi
else
    log_warn "Vault CLI or token not available, skipping Vault PKI."
fi

if [[ $VAULT_CERT_OK -ne 1 ]]; then
    generate_fallback_certificates
fi

configure_nginx

# Ensure both HTTP and HTTPS server blocks are present
cat > /etc/nginx/conf.d/https.conf <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;
    ssl_certificate $SSL_DIR/nginx.crt;
    ssl_certificate_key $SSL_DIR/nginx.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    location / {
        return 200 "Pure Bliss Development Environment - HTTPS Active";
        add_header Content-Type text/plain;
    }
}
EOF

log_info "Reloading Nginx to activate HTTPS..."
nginx -s reload || start_nginx

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT USAGE EXAMPLES - PURE BLISS ELITE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════════
#
# 📚 COMPLETE GUIDE: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md
#
# BASIC AUTO-COMMIT ON SUCCESS:
# Add this at the end of your main script logic:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed successfully"
#
# AUTO-COMMIT WITH VALIDATION:
# Add validation command to ensure script worked correctly:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed with validation" "docker ps | grep -q my-service"
#
# MANUAL AUTO-COMMIT TRIGGER:
# Use auto-commit wrapper directly with custom message:
#   ${WRAPPER_PREFIX}_auto_commit_wrapper "Custom commit: Feature implemented successfully"
#
# DIRECT PURE BLISS ELITE SYSTEM (Recommended):
# Use the official auto-commit trigger system:
#   /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
#       "${SCRIPT_CATEGORY}" "Description of accomplishment" "${SCRIPT_NAME}"
#
# CONDITIONAL AUTO-COMMIT:
# Only commit if certain conditions are met:
#   if [[ \$SUCCESS_FLAG == "true" ]]; then
#       ${WRAPPER_PREFIX}_auto_commit_wrapper "Conditional commit: Success flag set"
#   fi
#
# VALIDATION COMMAND EXAMPLES:
# - Container health check: "docker ps | grep -q healthy"
# - File existence: "test -f /path/to/expected/file"
# - Service response: "curl -s http://service/health | grep -q ok"
# - Custom function: "my_validation_function"
#
# ELITE COMMIT MESSAGE FORMAT:
# The Pure Bliss Elite system automatically generates comprehensive commit messages
# following the standard format with safety guarantees, validation results, and
# proper documentation references. See the AUTO_COMMIT_SYSTEM_GUIDE.md for details.
#
# ═══════════════════════════════════════════════════════════════════════════════════
