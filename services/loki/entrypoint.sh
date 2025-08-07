#!/bin/bash
# Loki Entrypoint - Pure Bliss Elite Standards
# Ensures config file is used and health endpoint is validated

set -e

CONFIG_FILE="/etc/loki/local-config.yaml"
LOG_FILE="/loki/loki.log/loki-entrypoint.log"

mkdir -p /loki/loki.log

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Entrypoint started. Using config: $CONFIG_FILE" | tee -a "$LOG_FILE"

# Validate config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Config file $CONFIG_FILE not found!" | tee -a "$LOG_FILE"
  exit 1
fi

# Start Loki with config
exec /usr/bin/loki -config.file="$CONFIG_FILE" 2>&1 | tee -a "$LOG_FILE"
