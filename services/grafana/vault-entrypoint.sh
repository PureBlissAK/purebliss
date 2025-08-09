#!/bin/bash
set -euo pipefail

# PURE BLISS SCRIPT METADATA
# Script: grafana/vault-entrypoint.sh
# Purpose: Grafana container entrypoint with Vault PKI enforcement
# Version: 2.0
# Last Modified: 2025-08-08
# Author: Pure Bliss Development Team
# Dependencies: grafana, vault PKI
# Security Policy: Vault/Let's Encrypt PKI only - no self-signed fallback
# Integration: Centralized logging, health validation, autonomous enhancement
# Usage: Docker entrypoint for Grafana with HTTPS and Vault PKI integration
# Enhancement Notes: Enforced Vault PKI policy, removed self-signed fallback
# END METADATA

CERT_DIR="/etc/grafana/certs"
CERT_FILE="$CERT_DIR/tls.crt"
KEY_FILE="$CERT_DIR/tls.key"

# Ensure log directory exists
mkdir -p /opt/my-secure-ha-stack/logs

# Enforce Vault PKI/Let's Encrypt certs only (no self-signed fallback)
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
  echo "$(date -Iseconds) [grafana][https] ERROR: No Vault/Let's Encrypt PKI certs found at $CERT_FILE and $KEY_FILE. Container will not start." | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
  exit 1
else
  echo "$(date -Iseconds) [grafana][https] Using Vault/Let's Encrypt PKI certificate at $CERT_FILE" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
fi

# Start Grafana with HTTPS
exec /run.sh
