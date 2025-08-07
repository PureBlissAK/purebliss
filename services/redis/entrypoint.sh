#!/bin/bash
set -euo pipefail

# Define log file paths
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
FALLBACK_LOG="/tmp/redis-entrypoint.log"

# Function for robust logging
log_msg() {
    local message="$1"
    local log_entry="[$(date +'%Y-%m-%dT%H:%M:%S%z')] [redis-entrypoint] $message"

    # Attempt to write to the primary log file, fallback if it fails
    if ! echo "$log_entry" >> "$LOG_FILE" 2>/dev/null; then
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

    if [ -z "${VAULT_ADDR}" ]; then
        log_msg "ERROR: VAULT_ADDR not set. Disabling Vault integration."
        USE_VAULT="false"
    else
        wait_for_service "$(echo "$VAULT_ADDR" | awk -F[/:] '{print $4}')" "$(echo "$VAULT_ADDR" | awk -F[/:] '{print $5}')" "Vault"

        log_msg "INFO: Authenticating to Vault using AppRole."
        if [ -z "${REDIS_VAULT_ROLE_ID}" ] || [ -z "${REDIS_VAULT_SECRET_ID}" ]; then
            log_msg "ERROR: Vault AppRole credentials not set. Disabling Vault integration."
            USE_VAULT="false"
        else
            VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id="$REDIS_VAULT_ROLE_ID" secret_id="$REDIS_VAULT_SECRET_ID")
            if [ -z "$VAULT_TOKEN" ]; then
                log_msg "ERROR: Vault AppRole login failed. Disabling Vault integration."
                USE_VAULT="false"
            else
                log_msg "SUCCESS: Vault AppRole login successful."
                export VAULT_TOKEN

                log_msg "INFO: Retrieving Redis password from Vault."
                REDIS_PASSWORD=$(vault kv get -field=password secret/redis)
                if [ -z "$REDIS_PASSWORD" ]; then
                    log_msg "WARNING: Failed to retrieve Redis password. Proceeding without authentication."
                else
                    log_msg "SUCCESS: Redis password retrieved from Vault."
                fi
            fi
        fi
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
