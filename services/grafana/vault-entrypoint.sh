#!/bin/bash
set -euo pipefail

CERT_DIR="/etc/grafana/certs"
CERT_FILE="$CERT_DIR/tls.crt"
KEY_FILE="$CERT_DIR/tls.key"

# Generate self-signed cert if missing (Vault PKI integration can be added here)
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
  echo "$(date -Iseconds) [grafana][https] No certs found, generating self-signed certificate..." | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
  mkdir -p "$CERT_DIR"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" -out "$CERT_FILE" \
    -subj "/CN=dev.purebliss.app"
  chmod 600 "$CERT_FILE" "$KEY_FILE"
  echo "$(date -Iseconds) [grafana][https] Self-signed certificate generated at $CERT_FILE and $KEY_FILE" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
else
  echo "$(date -Iseconds) [grafana][https] Using existing certificate at $CERT_FILE" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
fi

# Start Grafana with HTTPS
exec /run.sh
