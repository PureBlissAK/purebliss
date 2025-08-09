#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_ENTRYPOINT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-entrypoint.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced vault-integration script for vault operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="vault-integration"
SCRIPT_TAGS="enhancement,automation,auto-commit,vault,security"
SCRIPT_SERVICES="vault"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced vault-integration script for vault with auto-commit functionality,
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
vault_entrypoint_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_entrypoint_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_entrypoint_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
vault_entrypoint_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_entrypoint_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_entrypoint_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_entrypoint_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_entrypoint_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_entrypoint_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_entrypoint_log_info "Auto-commit system not available - manual commit required"
        vault_entrypoint_log_info "Recommended commit message: $commit_message"
        vault_entrypoint_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_entrypoint_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_entrypoint_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_entrypoint_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_entrypoint_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


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
