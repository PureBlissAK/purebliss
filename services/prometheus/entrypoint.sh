#!/bin/bash
set -euo pipefail
# Prometheus Entrypoint Enhancement: Service Discovery, Vault AppRole, HTTPS, Config Management
# Logs all actions to /opt/my-secure-ha-stack/logs/dev-environment-setup.log

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE="prometheus"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$SERVICE] $1" | tee -a "$LOG_FILE"
}


# 2. Dynamic Prometheus config management (reload if config changes)
CONFIG_FILE="/etc/prometheus/prometheus.yml"
CONFIG_HASH=""

reload_prometheus() {
    log "Reloading Prometheus configuration via HTTP POST."
    wget --post-data="" --header="Content-Type: application/x-www-form-urlencoded" -qO- http://localhost:9090/-/reload || log "Prometheus reload failed."
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

# 3. Start Prometheus in background
log "Starting Prometheus server."
/prometheus \
    --config.file="$CONFIG_FILE" \
    --storage.tsdb.path="/prometheus" \
    --web.console.libraries="/etc/prometheus/console_libraries" \
    --web.console.templates="/etc/prometheus/consoles" \
    --storage.tsdb.retention.time=200h \
    --web.enable-lifecycle &
PROM_PID=$!

# 4. Start config watcher in background
watch_config &

# 5. Wait for Prometheus process
wait $PROM_PID
