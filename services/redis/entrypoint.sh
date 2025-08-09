#!/bin/bash
set -euo pipefail


# Define log file paths
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
FALLBACK_LOG="/tmp/redis-entrypoint.log"



log_msg() {
    local message="$1"
    local log_entry="[$(date +'%Y-%m-%dT%H:%M:%S%z')] [redis-entrypoint] $message"

    # Only log to LOG_FILE if directory is writable, else always use FALLBACK_LOG
    if [ -w "$(dirname "$LOG_FILE")" ]; then
        echo "$log_entry" >> "$LOG_FILE"
    else
        echo "$log_entry" >> "$FALLBACK_LOG"
    fi
}

log_msg "INFO: Redis container starting up."

# Dependency check function
wait_for_service() {
    local host="$1"
    local port="$2"
    local service_name="$3"
    log_msg "INFO: Waiting for $service_name at $host:$port..."
    for i in {1..30}; do
        if nc -z "$host" "$port"; then
            log_msg "SUCCESS: $service_name is available."
            return 0
        fi
        sleep 2
    done
    log_msg "ERROR: $service_name not available after 60 seconds."
    exit 1
}

# Vault integration

if [[ "${USE_VAULT:-true}" == "true" ]]; then
    log_msg "INFO: Vault integration enabled."

    if [ -z "${VAULT_ADDR:-}" ]; then
        log_msg "ERROR: VAULT_ADDR not set. Disabling Vault integration."
        USE_VAULT="false"
    else
        wait_for_service "$(echo "$VAULT_ADDR" | awk -F[/:] '{print $4}')" "$(echo "$VAULT_ADDR" | awk -F[/:] '{print $5}')" "Vault"

        log_msg "INFO: Authenticating to Vault using AppRole."

    fi
fi

if [[ "${USE_VAULT:-true}" != "true" ]]; then
    log_msg "INFO: Vault integration disabled. Starting Redis without authentication."
    REDIS_PASSWORD=""
fi

# Configure Redis
log_msg "INFO: Configuring Redis."
{
    echo "appendonly yes"
    echo "dir /data"
    if [ -n "${REDIS_PASSWORD-}" ]; then
        echo "requirepass $REDIS_PASSWORD"
    fi
} > /usr/local/etc/redis/redis.conf

log_msg "INFO: Starting Redis server."
exec redis-server /usr/local/etc/redis/redis.conf
