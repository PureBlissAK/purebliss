#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
FALLBACK_LOG="/tmp/keycloak-entrypoint.log"

# Logging function with fallback
log_msg() {
    local msg="$1"
    echo "[$(date)] $msg"
    if [ -d "$(dirname "$LOG_FILE")" ] && [ -w "$(dirname "$LOG_FILE")" ]; then
        echo "[$(date)] $msg" >> "$LOG_FILE" 2>/dev/null || echo "[$(date)] $msg" >> "$FALLBACK_LOG"
    else
        echo "[$(date)] $msg" >> "$FALLBACK_LOG"
    fi
}


log_msg "INFO: Starting Keycloak container setup"




# Enhanced dependency checks with diagnostics and exponential backoff using bash /dev/tcp
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local max_attempts=60
    local attempt=1
    local delay=2
    log_msg "INFO: Waiting for $service_name at $host:$port (up to $((max_attempts*delay/60)) minutes)..."
    while [ $attempt -le $max_attempts ]; do
        if bash -c "> /dev/tcp/$host/$port" 2>/dev/null; then
            log_msg "INFO: $service_name is available after $attempt attempts."
            return 0
        else
            log_msg "WARN: Attempt $attempt: $service_name not available at $host:$port. /dev/tcp connection failed."
        fi
        sleep $delay
        attempt=$((attempt + 1))
        # Exponential backoff every 10 attempts
        if (( attempt % 10 == 0 )); then
            delay=$((delay * 2))
            if (( delay > 30 )); then delay=30; fi
        fi
    done
    log_msg "ERROR: $service_name not available after $((max_attempts*delay/60)) minutes. /dev/tcp connection failed."
    exit 1
}

wait_for_service "purebliss-postgres" "5432" "PostgreSQL"
wait_for_service "purebliss-redis" "6379" "Redis"

# Vault integration with development mode fallback
if [ "${USE_VAULT:-false}" == "true" ]; then
    log_msg "INFO: Vault integration enabled. Attempting to retrieve database credentials."

    # Check for AppRole credential files if env vars are not set
    if [ -z "${VAULT_ROLE_ID:-}" ] && [ -f "/opt/dev-purebliss/services/keycloak/vault-role-id" ]; then
        log_msg "INFO: Loading VAULT_ROLE_ID from file."
        export VAULT_ROLE_ID=$(cat /opt/dev-purebliss/services/keycloak/vault-role-id)
    fi
    if [ -z "${VAULT_SECRET_ID:-}" ] && [ -f "/opt/dev-purebliss/services/keycloak/vault-secret-id" ]; then
        log_msg "INFO: Loading VAULT_SECRET_ID from file."
        export VAULT_SECRET_ID=$(cat /opt/dev-purebliss/services/keycloak/vault-secret-id)
    fi

    # Check if Vault is accessible
    if vault status >/dev/null 2>&1; then
        log_msg "INFO: Vault is accessible. Proceeding with credential retrieval."

        # AppRole login to get a client token
        if [ -n "${VAULT_ROLE_ID:-}" ] && [ -n "${VAULT_SECRET_ID:-}" ]; then
            VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id="$VAULT_ROLE_ID" secret_id="$VAULT_SECRET_ID" 2>/dev/null || echo "")
            if [ -n "$VAULT_TOKEN" ]; then
                export VAULT_TOKEN
                log_msg "INFO: Successfully authenticated with Vault using AppRole."
            else
                log_msg "WARN: AppRole authentication failed. Falling back to development mode."
            fi
        else
            log_msg "WARN: VAULT_ROLE_ID or VAULT_SECRET_ID not set. Using VAULT_TOKEN if available."
        fi

        # Try to retrieve credentials if we have a token
        if [ -n "${VAULT_TOKEN:-}" ]; then
            db_creds=$(vault read -format=json keycloak/creds/keycloak-role 2>/dev/null || echo "")
            if [ -n "$db_creds" ] && [ "$db_creds" != "null" ]; then
                KC_DB_USERNAME=$(echo "$db_creds" | jq -r .data.username 2>/dev/null || echo "")
                KC_DB_PASSWORD=$(echo "$db_creds" | jq -r .data.password 2>/dev/null || echo "")

                if [ -n "$KC_DB_USERNAME" ] && [ -n "$KC_DB_PASSWORD" ] && [ "$KC_DB_USERNAME" != "null" ] && [ "$KC_DB_PASSWORD" != "null" ]; then
                    export KC_DB_USERNAME
                    export KC_DB_PASSWORD
                    log_msg "INFO: Successfully retrieved database credentials from Vault."
                else
                    log_msg "WARN: Failed to parse database credentials from Vault. Using development defaults."
                    export KC_DB_USERNAME=${KC_DB_USERNAME:-keycloak}
                    export KC_DB_PASSWORD=${KC_DB_PASSWORD:-keycloak_secure_password}
                fi
            else
                log_msg "WARN: Failed to retrieve database credentials from Vault. Using development defaults."
                export KC_DB_USERNAME=${KC_DB_USERNAME:-keycloak}
                export KC_DB_PASSWORD=${KC_DB_PASSWORD:-keycloak_secure_password}
            fi
        else
            log_msg "WARN: No Vault token available. Using development defaults."
            export KC_DB_USERNAME=${KC_DB_USERNAME:-keycloak}
            export KC_DB_PASSWORD=${KC_DB_PASSWORD:-keycloak_secure_password}
        fi
    else
        log_msg "WARN: Vault is not accessible. Using development defaults."
        export KC_DB_USERNAME=${KC_DB_USERNAME:-keycloak}
        export KC_DB_PASSWORD=${KC_DB_PASSWORD:-keycloak_secure_password}
    fi
else
    log_msg "INFO: Vault integration disabled. Using development defaults."
    export KC_DB_USERNAME=${KC_DB_USERNAME:-keycloak}
    export KC_DB_PASSWORD=${KC_DB_PASSWORD:-keycloak_secure_password}
fi


# Set up database connection URL based on environment variables
export KC_DB=postgres
export KC_DB_URL=jdbc:postgresql://purebliss-postgres:5432/keycloak
export KC_DB_NAME=keycloak

# Log all relevant environment variables for diagnostics
log_msg "INFO: Environment variables before Keycloak start:"
env | grep -E 'KC_|VAULT_|POSTGRES|REDIS' | while read line; do log_msg "ENV: $line"; done

# Remove unsupported cache env vars for Keycloak 24+
unset KC_CACHE_STACK
unset KC_CACHE_REDIS_HOST
unset KC_CACHE_REDIS_PORT

# Upstream notification function for nginx integration
notify_upstream_when_ready() {
    local service="keycloak"
    local port="8080"
    local health_path="/realms/master"
    local max_attempts=30
    local attempt=1
    
    log_msg "INFO: Starting upstream notification workflow for $service"
    
    # Start Keycloak in background to enable health monitoring
    /opt/keycloak/bin/kc.sh start-dev &
    local keycloak_pid=$!
    
    # Wait for Keycloak to become healthy
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s --connect-timeout 5 --max-time 10 "http://localhost:${port}${health_path}" > /dev/null 2>&1; then
            log_msg "INFO: Keycloak is healthy, notifying nginx upstream"
            
            # Call upstream validation tool as specified in project plan
            if [ -f "/opt/dev-purebliss/upstream-validation.sh" ]; then
                /opt/dev-purebliss/upstream-validation.sh "$service" "$port" "$health_path" || log_msg "WARN: Upstream notification failed"
            else
                log_msg "WARN: Upstream validation tool not found at /opt/dev-purebliss/upstream-validation.sh"
            fi
            
            log_msg "INFO: Keycloak upstream notification completed"
            break
        fi
        
        log_msg "INFO: Waiting for Keycloak health, attempt $attempt/$max_attempts"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    # Wait for Keycloak process to complete
    wait $keycloak_pid
}

log_msg "INFO: Starting Keycloak with upstream notification workflow..."
notify_upstream_when_ready
