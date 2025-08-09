#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# UPDATE_CERTIFICATES_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="update-certificates.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced automation script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced automation script for development with auto-commit functionality,
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
update_certificates_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
update_certificates_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
update_certificates_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
update_certificates_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    update_certificates_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        update_certificates_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            update_certificates_log_success "Validation passed - proceeding with auto-commit"
        else
            update_certificates_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        update_certificates_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        update_certificates_log_info "Auto-commit system not available - manual commit required"
        update_certificates_log_info "Recommended commit message: $commit_message"
        update_certificates_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
update_certificates_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    update_certificates_log_success "$final_message"
    
    # Execute auto-commit wrapper
    update_certificates_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    update_certificates_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Script to update nginx certificates from Vault PKI
# This script generates new certificates from Vault and updates nginx


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
