#!/bin/bash
set -euxo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
INSTALL_DIR="/opt/vault_stress_testing/bin"
K6_VERSION="v0.50.0"
K6_ARCH="linux-amd64"
K6_URL="https://github.com/grafana/k6/releases/download/${K6_VERSION}/k6-${K6_VERSION}-${K6_ARCH}.tar.gz"
K6_BINARY_PATH="${INSTALL_DIR}/k6"

echo "[$(date)] [k6_install] Starting k6 local installation." | tee -a $LOG_FILE

# Check if k6 is already installed and executable
if [ -x "$K6_BINARY_PATH" ]; then
    echo "[$(date)] [k6_install] INFO: k6 is already installed and executable at ${K6_BINARY_PATH}." | tee -a $LOG_FILE
    echo "[$(date)] [k6_install] k6 version: $("$K6_BINARY_PATH" version)" | tee -a $LOG_FILE
    exit 0
fi

echo "[$(date)] [k6_install] INFO: k6 not found or not executable. Proceeding with local installation..." | tee -a $LOG_FILE

# Create installation directory
mkdir -p "$INSTALL_DIR"
echo "[$(date)] [k6_install] INFO: Ensured installation directory exists: ${INSTALL_DIR}" | tee -a $LOG_FILE

# Download k6
echo "[$(date)] [k6_install] INFO: Downloading k6 from ${K6_URL}..." | tee -a $LOG_FILE
if ! curl -fL "$K6_URL" -o /tmp/k6.tar.gz; then
    echo "[$(date)] [k6_install] ERROR: Failed to download k6 archive from ${K6_URL}." | tee -a $LOG_FILE
    exit 1
fi
echo "[$(date)] [k6_install] INFO: Download complete." | tee -a $LOG_FILE

# Extract k6
echo "[$(date)] [k6_install] INFO: Extracting k6 to ${INSTALL_DIR}..." | tee -a $LOG_FILE
if ! tar -xzf /tmp/k6.tar.gz -C "$INSTALL_DIR" --strip-components=1 "k6-${K6_VERSION}-${K6_ARCH}/k6"; then
    echo "[$(date)] [k6_install] ERROR: Failed to extract k6 binary." | tee -a $LOG_FILE
    echo "[$(date)] [k6_install] DEBUG: Listing contents of /tmp/k6.tar.gz:" | tee -a $LOG_FILE
    tar -tzf /tmp/k6.tar.gz | tee -a $LOG_FILE
    exit 1
fi
echo "[$(date)] [k6_install] INFO: Extraction complete." | tee -a $LOG_FILE

# Clean up
rm /tmp/k6.tar.gz
echo "[$(date)] [k6_install] INFO: Cleaned up temporary archive." | tee -a $LOG_FILE

# Verify installation and set permissions
if [ -f "$K6_BINARY_PATH" ]; then
    chmod +x "$K6_BINARY_PATH"
    echo "[$(date)] [k6_install] SUCCESS: k6 installation successful." | tee -a $LOG_FILE
    echo "[$(date)] [k6_install] k6 version: $("$K6_BINARY_PATH" version)" | tee -a $LOG_FILE
else
    echo "[$(date)] [k6_install] ERROR: k6 binary not found at ${K6_BINARY_PATH} after extraction." | tee -a $LOG_FILE
    exit 1
fi
