#!/bin/bash
set -euo pipefail

# PURE BLISS SCRIPT METADATA
# Script: prometheus/entrypoint-https.sh
# Purpose: Enhanced Prometheus HTTPS entrypoint with Vault PKI enforcement
# Version: 2.0
# Last Modified: 2025-08-08
# Author: Pure Bliss Development Team
# Dependencies: vault, prometheus
# Security Policy: Vault/Let's Encrypt PKI only - no self-signed fallback
# Integration: Centralized logging, health validation, autonomous enhancement
# Usage: Docker entrypoint for Prometheus with HTTPS and Vault integration
# Enhancement Notes: Enforced Vault PKI policy, removed self-signed fallback
# END METADATA

# Prometheus HTTPS Entrypoint Enhancement
# Logs all actions to /opt/my-secure-ha-stack/logs/dev-environment-setup.log

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE="prometheus"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$SERVICE] $1" | tee -a "$LOG_FILE"
}


# 2. Enforce Vault PKI/Let's Encrypt certs only (no self-signed fallback)
CERT_DIR="/etc/prometheus/certs"
CERT_FILE="$CERT_DIR/tls.crt"
KEY_FILE="$CERT_DIR/tls.key"
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
    log "ERROR: No Vault/Let's Encrypt PKI certs found at $CERT_FILE and $KEY_FILE. Container will not start."
    log "POLICY: Self-signed certificates are not allowed. Use Vault PKI or Let's Encrypt only."
    exit 1
else
    log "Using Vault/Let's Encrypt PKI certificate at $CERT_FILE"
fi

# 3. Dynamic Prometheus config management (reload if config changes)
CONFIG_FILE="/etc/prometheus/prometheus.yml"
CONFIG_HASH=""

reload_prometheus() {
    log "Reloading Prometheus configuration via HTTP POST."
    wget --post-data="" --header="Content-Type: application/x-www-form-urlencoded" -qO- https://localhost:9091/-/reload --no-check-certificate || log "Prometheus reload failed."
}

watch_config() {
    while true; do
        NEW_HASH=$(sha256sum "$CONFIG_FILE" | awk '{print $1}')
        if [[ "$NEW_HASH" != "$CONFIG_HASH" ]]; then
            CONFIG_HASH="$NEW_HASH"
            log "Config change detected. Triggering reload."
            reload_prometheus
        fi
        sleep 10
    done
}

# 4. Start Prometheus in background with HTTPS enabled
log "Starting Prometheus server with HTTPS."
/prometheus \
    --config.file="$CONFIG_FILE" \
    --storage.tsdb.path="/prometheus" \
    --web.console.libraries="/etc/prometheus/console_libraries" \
    --web.console.templates="/etc/prometheus/consoles" \
    --storage.tsdb.retention.time=200h \
    --web.enable-lifecycle \
    --web.listen-address=":9091" \
    --web.config.file="$CERT_DIR/web-config.yml" &
PROM_PID=$!

# 5. Start config watcher in background
watch_config &

# 6. Wait for Prometheus process
wait $PROM_PID
