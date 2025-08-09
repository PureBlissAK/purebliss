#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_MANUAL_PERMISSIONS_FIX_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-manual-permissions-fix.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi
if [[ -f "$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "$SCRIPT_DIR/utilities/retry-utils.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
vault_manual_permissions_fix_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_manual_permissions_fix_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_manual_permissions_fix_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

set -euo pipefail

# Manual Vault Permissions Fix Script
# Run this script with sudo privileges to fix Vault permission issues
# Usage: sudo ./vault-manual-permissions-fix.sh

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_SERVICE_DIR="/opt/dev-purebliss/services/vault"

function log_action() {
    echo "[$(date)] VAULT_MANUAL_PERMS: $1" | tee -a "$LOG_FILE"
}

function main() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ This script must be run with sudo privileges"
        echo "Usage: sudo $0"
        exit 1
    fi

    log_action "Starting manual permissions fix..."

    # Fix cert permissions
    log_action "Fixing certificate permissions..."
    chown -R 1000:1000 "$VAULT_SERVICE_DIR/certs/" 2>/dev/null || true
    chmod 644 "$VAULT_SERVICE_DIR/certs/selfsigned/"*.pem 2>/dev/null || true

    # Fix host vault directory permissions
    log_action "Fixing host vault directory permissions..."
    chown -R 1000:1000 /opt/my-secure-ha-stack/vault/ 2>/dev/null || true

    # Fix secrets directory
    log_action "Fixing secrets directory permissions..."
    mkdir -p /opt/my-secure-ha-stack/secrets/vault
    chown -R "$SUDO_USER:$SUDO_USER" /opt/my-secure-ha-stack/secrets/vault
    chmod 700 /opt/my-secure-ha-stack/secrets/vault

    # Fix data directory permissions inside container if running
    if docker ps | grep -q purebliss-vault; then
        log_action "Fixing Vault data directory permissions inside container..."
        docker exec purebliss-vault chown vault:vault /vault/data 2>/dev/null || true
    fi

    log_action "Manual permissions fix completed successfully"
    echo "✅ All Vault permissions have been fixed"
    echo "💡 You can now run the automated scripts without permission issues"
}

main "$@"
