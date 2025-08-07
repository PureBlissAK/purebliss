#!/bin/bash
set -euo pipefail

# PostgreSQL Independent Entrypoint for PureBliss Development Environment
# Handles database creation and service independence
# Compatible with Vault integration but doesn't require it

# Logging function
log_info() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [PostgreSQL] INFO: $1"
}

log_error() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [PostgreSQL] ERROR: $1" >&2
}

log_success() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [PostgreSQL] SUCCESS: $1"
}

# Append to dev log
append_to_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] POSTGRES: $1" >> /opt/logs/postgres.log 2>/dev/null || true
}

log_info "PostgreSQL container entrypoint started."
append_to_log "PostgreSQL entrypoint started"

# Create logs directory if it doesn't exist
mkdir -p /opt/logs

# Ensure required environment variables are set with defaults
export POSTGRES_DB="${POSTGRES_DB:-postgres}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"

# If no password is provided and no password file exists, generate one
if [[ -z "${POSTGRES_PASSWORD:-}" ]] && [[ ! -f "${POSTGRES_PASSWORD_FILE:-}" ]]; then
    log_info "No password provided, checking for Vault integration..."

    # Check if Vault is available (optional dependency)
    if command -v curl >/dev/null 2>&1 && curl -s http://purebliss-vault:8200/v1/sys/health >/dev/null 2>&1; then
        log_info "Vault detected, will try to use Vault integration"
        # For now, use a development password - Vault integration can be added later
        export POSTGRES_PASSWORD="purebliss_dev_postgres_2025"
        append_to_log "Using development password (Vault integration available for future enhancement)"
    else
        log_info "Vault not available, using development password"
        export POSTGRES_PASSWORD="purebliss_dev_postgres_2025"
        append_to_log "Using development password (no Vault integration)"
    fi
fi

# Create init script for database creation
log_info "Preparing database initialization script..."

cat > /docker-entrypoint-initdb.d/99-create-databases.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "[$(date)] PostgreSQL: Creating application databases..."

# Function to create database if it doesn't exist
create_database_if_not_exists() {
    local db_name=$1
    echo "[$(date)] PostgreSQL: Checking database '$db_name'"

    if psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo "[$(date)] PostgreSQL: Database '$db_name' already exists"
    else
        echo "[$(date)] PostgreSQL: Creating database '$db_name'"
        psql -U "$POSTGRES_USER" -c "CREATE DATABASE $db_name;"
        echo "[$(date)] PostgreSQL: Database '$db_name' created successfully"
    fi
}

# Create application databases
create_database_if_not_exists "keycloak"
create_database_if_not_exists "plane"
create_database_if_not_exists "vikunja"

echo "[$(date)] PostgreSQL: All application databases created/verified"

# Create application users with default passwords (can be updated by Vault later)
echo "[$(date)] PostgreSQL: Creating application users..."

psql -U "$POSTGRES_USER" -d postgres << 'SQL'
-- Create keycloak user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'keycloak') THEN
        CREATE ROLE keycloak WITH LOGIN PASSWORD 'keycloak_dev_2025';
        GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
        RAISE NOTICE 'Created keycloak user with development password';
    ELSE
        RAISE NOTICE 'User keycloak already exists';
    END IF;
END
$$;

-- Create plane user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'plane') THEN
        CREATE ROLE plane WITH LOGIN PASSWORD 'plane_dev_2025';
        GRANT ALL PRIVILEGES ON DATABASE plane TO plane;
        RAISE NOTICE 'Created plane user with development password';
    ELSE
        RAISE NOTICE 'User plane already exists';
    END IF;
END
$$;

-- Create vikunja user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vikunja') THEN
        CREATE ROLE vikunja WITH LOGIN PASSWORD 'vikunja_dev_2025';
        GRANT ALL PRIVILEGES ON DATABASE vikunja TO vikunja;
        RAISE NOTICE 'Created vikunja user with development password';
    ELSE
        RAISE NOTICE 'User vikunja already exists';
    END IF;
END
$$;
SQL

echo "[$(date)] PostgreSQL: Application users created/verified"
echo "[$(date)] PostgreSQL: Database initialization complete"
EOF

chmod +x /docker-entrypoint-initdb.d/99-create-databases.sh

log_success "Database initialization script prepared"
append_to_log "Database initialization script created"

# Create a background process to log when PostgreSQL is ready
(
    # Wait for PostgreSQL to be ready
    sleep 10
    max_attempts=30
    attempt=1

    while [ $attempt -le $max_attempts ]; do
        if pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h localhost -p 5432 >/dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] POSTGRES: PostgreSQL is ready and accepting connections" >> /opt/logs/postgres.log 2>/dev/null || true
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] POSTGRES: All application databases created and users configured" >> /opt/logs/postgres.log 2>/dev/null || true
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
) &

log_info "Starting PostgreSQL with independent configuration..."
append_to_log "Starting PostgreSQL server"

# Start PostgreSQL using the official entrypoint
exec docker-entrypoint.sh "$@"
