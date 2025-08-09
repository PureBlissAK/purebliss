#!/bin/bash
set -euo pipefail

# Enhanced Keycloak Vault Integration Entrypoint
# Comprehensive integration with Vault for secrets management and PostgreSQL integration
# Author: PureBliss Development Team
# Date: $(date)

LOG_PREFIX="[KEYCLOAK-VAULT-ENHANCED]"
VAULT_RETRY_MAX=10
VAULT_RETRY_INTERVAL=5

log_info() {
    echo "$LOG_PREFIX INFO: $1" >&2
    echo "[$(date)] INFO: Keycloak-Vault: $1" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log || true
}

log_error() {
    echo "$LOG_PREFIX ERROR: $1" >&2
    echo "[$(date)] ERROR: Keycloak-Vault: $1" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log || true
}

log_warn() {
    echo "$LOG_PREFIX WARN: $1" >&2
    echo "[$(date)] WARN: Keycloak-Vault: $1" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log || true
}

# Detect if we're running in Docker and set Vault address accordingly
detect_vault_address() {
    if [ -n "${VAULT_ADDR:-}" ]; then
        log_info "Using provided VAULT_ADDR: $VAULT_ADDR"
        return
    fi

    # Try Docker service name first
    if getent hosts purebliss-vault > /dev/null 2>&1; then
        export VAULT_ADDR="http://purebliss-vault:8200"
        log_info "Detected Docker environment, using Vault at: $VAULT_ADDR"
    else
        export VAULT_ADDR="https://localhost:8200"
        log_info "Using localhost Vault address: $VAULT_ADDR"
    fi
}

# Wait for Vault to be available
wait_for_vault() {
    local retries=0
    while [ $retries -lt $VAULT_RETRY_MAX ]; do
        if curl -sk -o /dev/null -w "%{http_code}" "$VAULT_ADDR/v1/sys/health" | grep -q "200\|429\|473\|503"; then
            log_info "Vault is available at $VAULT_ADDR"
            return 0
        fi

        retries=$((retries + 1))
        log_warn "Vault not available, attempt $retries/$VAULT_RETRY_MAX"
        sleep $VAULT_RETRY_INTERVAL
    done

    log_error "Vault not available after $VAULT_RETRY_MAX attempts"
    return 1
}

# Check if Vault is sealed and try to unseal
ensure_vault_unsealed() {
    local seal_status
    seal_status=$(curl -sk "$VAULT_ADDR/v1/sys/seal-status" | jq -r '.sealed // true' 2>/dev/null || echo "true")

    if [ "$seal_status" = "true" ]; then
        log_warn "Vault is sealed, attempting to unseal..."

        # Try to find unseal keys
        local unseal_keys_file="/opt/my-secure-ha-stack/vault-unseal-keys.env"
        if [ -f "$unseal_keys_file" ]; then
            source "$unseal_keys_file"

            # Try to unseal with available keys
            for i in {1..3}; do
                local key_var="UNSEAL_KEY_$i"
                if [ -n "${!key_var:-}" ]; then
                    curl -sk -X PUT -d "{\"key\":\"${!key_var}\"}" "$VAULT_ADDR/v1/sys/unseal" > /dev/null
                    log_info "Applied unseal key $i"
                fi
            done

            # Check if unsealed
            seal_status=$(curl -sk "$VAULT_ADDR/v1/sys/seal-status" | jq -r '.sealed // true' 2>/dev/null || echo "true")
            if [ "$seal_status" = "false" ]; then
                log_info "Successfully unsealed Vault"
            else
                log_warn "Vault still sealed after unseal attempts"
            fi
        else
            log_warn "No unseal keys found at $unseal_keys_file"
        fi
    else
        log_info "Vault is already unsealed"
    fi
}

# Authenticate with Vault using available token
authenticate_vault() {
    # Try multiple token sources
    local token=""

    # Source 1: Environment variable
    if [ -n "${VAULT_TOKEN:-}" ]; then
        token="$VAULT_TOKEN"
        log_info "Using VAULT_TOKEN from environment"

    # Source 2: Token file
    elif [ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]; then
        token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
        log_info "Using token from /opt/my-secure-ha-stack/secrets/vault_token"

    # Source 3: Root token file
    elif [ -f "/opt/my-secure-ha-stack/vault-init-output.txt" ]; then
        token=$(grep "Initial Root Token:" /opt/my-secure-ha-stack/vault-init-output.txt | awk '{print $NF}' || echo "")
        if [ -n "$token" ]; then
            log_info "Using root token from vault-init-output.txt"
        fi
    fi

    if [ -z "$token" ]; then
        log_error "No Vault token available"
        return 1
    fi

    export VAULT_TOKEN="$token"

    # Verify token works
    if curl -sk -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/auth/token/lookup-self" | jq -e '.data' > /dev/null 2>&1; then
        log_info "Vault authentication successful"
        return 0
    else
        log_error "Vault token authentication failed"
        return 1
    fi
}

# Setup Keycloak database secrets in Vault
setup_keycloak_secrets() {
    log_info "Setting up Keycloak secrets in Vault"

    # Enable KV secrets engine if not already enabled
    curl -sk -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
        -d '{"type":"kv-v2"}' \
        "$VAULT_ADDR/v1/sys/mounts/secret" > /dev/null 2>&1 || true

    # Create database secrets for Keycloak
    local keycloak_db_secrets='{
        "data": {
            "username": "keycloak",
            "password": "keycloak_secure_password_'$(date +%s)'",
            "database": "keycloak",
            "host": "purebliss-postgres",
            "port": "5432"
        }
    }'

    curl -sk -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
        -d "$keycloak_db_secrets" \
        "$VAULT_ADDR/v1/secret/data/keycloak/database" > /dev/null

    # Create admin secrets for Keycloak
    local keycloak_admin_secrets='{
        "data": {
            "username": "admin",
            "password": "admin_secure_password_'$(date +%s)'",
            "realm": "master"
        }
    }'

    curl -sk -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
        -d "$keycloak_admin_secrets" \
        "$VAULT_ADDR/v1/secret/data/keycloak/admin" > /dev/null

    log_info "Keycloak secrets configured in Vault"
}

# Retrieve secrets from Vault
get_vault_secret() {
    local secret_path="$1"
    local secret_key="$2"

    local secret_data
    secret_data=$(curl -sk -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/data/$secret_path" | jq -r ".data.data.$secret_key // empty" 2>/dev/null)

    if [ -n "$secret_data" ] && [ "$secret_data" != "null" ]; then
        echo "$secret_data"
        return 0
    else
        log_warn "Failed to retrieve secret: $secret_path/$secret_key"
        return 1
    fi
}

# Configure Keycloak environment from Vault
configure_keycloak_from_vault() {
    log_info "Configuring Keycloak environment from Vault secrets"

    # Get database credentials
    if DB_USERNAME=$(get_vault_secret "keycloak/database" "username") && [ -n "$DB_USERNAME" ]; then
        export KC_DB_USERNAME="$DB_USERNAME"
        log_info "Retrieved database username from Vault"
    else
        export KC_DB_USERNAME="${KC_DB_USERNAME:-keycloak}"
        log_warn "Using fallback database username: $KC_DB_USERNAME"
    fi

    if DB_PASSWORD=$(get_vault_secret "keycloak/database" "password") && [ -n "$DB_PASSWORD" ]; then
        export KC_DB_PASSWORD="$DB_PASSWORD"
        log_info "Retrieved database password from Vault"
    else
        export KC_DB_PASSWORD="${KC_DB_PASSWORD:-keycloak_password_changeme}"
        log_warn "Using fallback database password"
    fi

    if DB_NAME=$(get_vault_secret "keycloak/database" "database") && [ -n "$DB_NAME" ]; then
        export KC_DB_NAME="$DB_NAME"
        log_info "Retrieved database name from Vault"
    else
        export KC_DB_NAME="${KC_DB_NAME:-keycloak}"
        log_warn "Using fallback database name: $KC_DB_NAME"
    fi

    if DB_HOST=$(get_vault_secret "keycloak/database" "host") && [ -n "$DB_HOST" ]; then
        export KC_DB_HOST="$DB_HOST"
        log_info "Retrieved database host from Vault"
    else
        export KC_DB_HOST="${KC_DB_HOST:-purebliss-postgres}"
        log_warn "Using fallback database host: $KC_DB_HOST"
    fi

    if DB_PORT=$(get_vault_secret "keycloak/database" "port") && [ -n "$DB_PORT" ]; then
        export KC_DB_PORT="$DB_PORT"
        log_info "Retrieved database port from Vault"
    else
        export KC_DB_PORT="${KC_DB_PORT:-5432}"
        log_warn "Using fallback database port: $KC_DB_PORT"
    fi

    # Get Redis configuration for caching and sessions
    log_info "Configuring Redis for Keycloak caching..."

    if REDIS_HOST_VAULT=$(get_vault_secret "keycloak/redis" "host") && [ -n "$REDIS_HOST_VAULT" ]; then
        export REDIS_HOST="$REDIS_HOST_VAULT"
        log_info "Retrieved Redis host from Vault"
    else
        export REDIS_HOST="${REDIS_HOST:-purebliss-redis}"
        log_warn "Using fallback Redis host: $REDIS_HOST"
    fi

    if REDIS_PORT_VAULT=$(get_vault_secret "keycloak/redis" "port") && [ -n "$REDIS_PORT_VAULT" ]; then
        export REDIS_PORT="$REDIS_PORT_VAULT"
        log_info "Retrieved Redis port from Vault"
    else
        export REDIS_PORT="${REDIS_PORT:-6379}"
        log_warn "Using fallback Redis port: $REDIS_PORT"
    fi

    if REDIS_PASSWORD_VAULT=$(get_vault_secret "keycloak/redis" "password") && [ -n "$REDIS_PASSWORD_VAULT" ]; then
        export REDIS_PASSWORD="$REDIS_PASSWORD_VAULT"
        log_info "Retrieved Redis password from Vault"
    else
        export REDIS_PASSWORD="${REDIS_PASSWORD}"
        log_warn "Using fallback Redis password (if any)"
    fi

    if REDIS_DATABASE_VAULT=$(get_vault_secret "keycloak/redis" "database") && [ -n "$REDIS_DATABASE_VAULT" ]; then
        export REDIS_DATABASE="$REDIS_DATABASE_VAULT"
        log_info "Retrieved Redis database from Vault"
    else
        export REDIS_DATABASE="${REDIS_DATABASE:-1}"
        log_warn "Using fallback Redis database: $REDIS_DATABASE"
    fi

    # Get admin credentials
    if ADMIN_USER=$(get_vault_secret "keycloak/admin" "username") && [ -n "$ADMIN_USER" ]; then
        export KEYCLOAK_ADMIN="$ADMIN_USER"
        log_info "Retrieved admin username from Vault"
    else
        export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
        log_warn "Using fallback admin username: $KEYCLOAK_ADMIN"
    fi

    if ADMIN_PASSWORD=$(get_vault_secret "keycloak/admin" "password") && [ -n "$ADMIN_PASSWORD" ]; then
        export KEYCLOAK_ADMIN_PASSWORD="$ADMIN_PASSWORD"
        log_info "Retrieved admin password from Vault"
    else
        export KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin123}"
        log_warn "Using fallback admin password"
    fi

    # Construct database URL
    export KC_DB_URL="jdbc:postgresql://${KC_DB_HOST}:${KC_DB_PORT}/${KC_DB_NAME}"
    export KC_DB="postgres"

    log_info "Keycloak configuration complete:"
    log_info "  Database URL: $KC_DB_URL"
    log_info "  Database User: $KC_DB_USERNAME"
    log_info "  Admin User: $KEYCLOAK_ADMIN"
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    log_info "Waiting for PostgreSQL to be ready..."

    local retries=0
    local max_retries=30

    while [ $retries -lt $max_retries ]; do
        if PGPASSWORD="$KC_DB_PASSWORD" psql -h "$KC_DB_HOST" -p "$KC_DB_PORT" -U "$KC_DB_USERNAME" -d "$KC_DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
            log_info "PostgreSQL is ready"
            return 0
        fi

        retries=$((retries + 1))
        log_info "PostgreSQL not ready, attempt $retries/$max_retries"
        sleep 5
    done

    log_error "PostgreSQL not ready after $max_retries attempts"
    return 1
}

# Setup Keycloak database if needed
setup_keycloak_database() {
    log_info "Setting up Keycloak database"

    # Check if database exists
    if ! PGPASSWORD="$KC_DB_PASSWORD" psql -h "$KC_DB_HOST" -p "$KC_DB_PORT" -U "$KC_DB_USERNAME" -d "$KC_DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        log_info "Database connection failed, it might need to be created"

        # Try to create database using postgres user (fallback)
        local postgres_password="${POSTGRES_PASSWORD:-postgres}"
        if PGPASSWORD="$postgres_password" createdb -h "$KC_DB_HOST" -p "$KC_DB_PORT" -U postgres "$KC_DB_NAME" > /dev/null 2>&1; then
            log_info "Created database $KC_DB_NAME"

            # Create user if needed
            PGPASSWORD="$postgres_password" psql -h "$KC_DB_HOST" -p "$KC_DB_PORT" -U postgres -c "
                CREATE USER $KC_DB_USERNAME WITH PASSWORD '$KC_DB_PASSWORD';
                GRANT ALL PRIVILEGES ON DATABASE $KC_DB_NAME TO $KC_DB_USERNAME;
            " > /dev/null 2>&1 || log_warn "User creation failed (might already exist)"

        else
            log_warn "Could not create database, assuming it exists"
        fi
    else
        log_info "Database connection successful"
    fi
}

# Main execution flow
main() {
    log_info "Starting enhanced Keycloak with Vault and PostgreSQL integration"

    # Install required tools if not available
    if ! command -v curl > /dev/null; then
        log_info "Installing curl..."
        microdnf install -y curl || apk add --no-cache curl || apt-get update && apt-get install -y curl || true
    fi

    if ! command -v jq > /dev/null; then
        log_info "Installing jq..."
        microdnf install -y jq || apk add --no-cache jq || apt-get install -y jq || true
    fi

    if ! command -v psql > /dev/null; then
        log_info "Installing PostgreSQL client..."
        microdnf install -y postgresql || apk add --no-cache postgresql-client || apt-get install -y postgresql-client || true
    fi

    # Vault integration
    detect_vault_address

    if wait_for_vault; then
        ensure_vault_unsealed

        if authenticate_vault; then
            setup_keycloak_secrets
            configure_keycloak_from_vault
        else
            log_warn "Vault authentication failed, using environment defaults"
            export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
            export KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin123}"
            export KC_DB_USERNAME="${KC_DB_USERNAME:-keycloak}"
            export KC_DB_PASSWORD="${KC_DB_PASSWORD:-keycloak_password}"
            export KC_DB_HOST="${KC_DB_HOST:-purebliss-postgres}"
            export KC_DB_PORT="${KC_DB_PORT:-5432}"
            export KC_DB_NAME="${KC_DB_NAME:-keycloak}"
            export KC_DB_URL="jdbc:postgresql://${KC_DB_HOST}:${KC_DB_PORT}/${KC_DB_NAME}"
            export KC_DB="postgres"
        fi
    else
        log_warn "Vault not available, using environment defaults"
        export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
        export KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin123}"
        export KC_DB_USERNAME="${KC_DB_USERNAME:-keycloak}"
        export KC_DB_PASSWORD="${KC_DB_PASSWORD:-keycloak_password}"
        export KC_DB_HOST="${KC_DB_HOST:-purebliss-postgres}"
        export KC_DB_PORT="${KC_DB_PORT:-5432}"
        export KC_DB_NAME="${KC_DB_NAME:-keycloak}"
        export KC_DB_URL="jdbc:postgresql://${KC_DB_HOST}:${KC_DB_PORT}/${KC_DB_NAME}"
        export KC_DB="postgres"
    fi

    # PostgreSQL integration
    wait_for_postgres
    setup_keycloak_database

    # Set additional Keycloak configurations
    export KC_HOSTNAME="${KC_HOSTNAME:-dev.purebliss.app}"
    export KC_PROXY="${KC_PROXY:-edge}"
    export KC_HTTP_RELATIVE_PATH="${KC_HTTP_RELATIVE_PATH:-/auth}"
    export KC_HTTP_ENABLED="${KC_HTTP_ENABLED:-true}"
    export KC_HOSTNAME_STRICT="${KC_HOSTNAME_STRICT:-false}"
    export KC_HOSTNAME_STRICT_HTTPS="${KC_HOSTNAME_STRICT_HTTPS:-false}"

    # Build Keycloak with PostgreSQL
    log_info "Building Keycloak with PostgreSQL configuration..."
    /opt/keycloak/bin/kc.sh build --db=postgres

    # Configure Redis for Keycloak caching and sessions
    log_info "Configuring Redis integration for Keycloak..."

    # Test Redis connectivity before starting Keycloak
    log_info "Testing Redis connectivity..."
    if command -v redis-cli >/dev/null 2>&1; then
        if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ping >/dev/null 2>&1; then
            log_info "Redis connectivity test successful"
            export KC_CACHE_CONFIG_FILE="/opt/keycloak/conf/cache-ispn-redis.xml"
        else
            log_warn "Redis connectivity test failed, using default cache configuration"
        fi
    else
        log_info "redis-cli not available, using default cache configuration"
    fi

    # Start Keycloak
    log_info "Starting Keycloak with configuration:"
    log_info "  Admin: $KEYCLOAK_ADMIN"
    log_info "  Database: $KC_DB_URL"
    log_info "  Redis: $REDIS_HOST:$REDIS_PORT (database: $REDIS_DATABASE)"
    log_info "  Hostname: $KC_HOSTNAME"
    log_info "  Proxy: $KC_PROXY"
    log_info "  Path: $KC_HTTP_RELATIVE_PATH"

    # Determine start mode
    local start_mode="${KC_START_MODE:-start-dev}"

    # Set up Redis-related Java system properties
    local redis_props=""
    if [ -n "$REDIS_HOST" ]; then
        redis_props="-Dkeycloak.redis.host=$REDIS_HOST"
        redis_props="$redis_props -Dkeycloak.redis.port=$REDIS_PORT"
        redis_props="$redis_props -Dkeycloak.redis.database=$REDIS_DATABASE"
        if [ -n "$REDIS_PASSWORD" ]; then
            redis_props="$redis_props -Dkeycloak.redis.password=$REDIS_PASSWORD"
        fi
        log_info "Redis properties configured: $redis_props"
    fi

    if [ "$start_mode" = "start-dev" ]; then
        log_info "Starting in development mode with Redis integration"
        exec /opt/keycloak/bin/kc.sh start-dev \
            --db=postgres \
            --db-url="$KC_DB_URL" \
            --db-username="$KC_DB_USERNAME" \
            --db-password="$KC_DB_PASSWORD" \
            --hostname="$KC_HOSTNAME" \
            --proxy="$KC_PROXY" \
            --http-relative-path="$KC_HTTP_RELATIVE_PATH" \
            --http-enabled=true \
            --hostname-strict=false \
            --hostname-strict-https=false \
            --cache=ispn \
            --cache-stack=tcp
    else
        log_info "Starting in production mode with Redis integration"
        exec /opt/keycloak/bin/kc.sh start \
            --db=postgres \
            --db-url="$KC_DB_URL" \
            --db-username="$KC_DB_USERNAME" \
            --db-password="$KC_DB_PASSWORD" \
            --hostname="$KC_HOSTNAME" \
            --proxy="$KC_PROXY" \
            --http-relative-path="$KC_HTTP_RELATIVE_PATH" \
            --cache=ispn \
            --cache-stack=tcp
    fi
}

# Execute main function
main "$@"
