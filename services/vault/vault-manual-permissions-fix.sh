#!/bin/bash
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
