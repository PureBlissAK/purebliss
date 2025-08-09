#!/bin/bash

# Keycloak Database Initialization Script
# Ensures proper database setup before Keycloak startup

set -euo pipefail

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_INIT INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_INIT ERROR: $1" >&2
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    log_info "Waiting for PostgreSQL to be ready..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec purebliss-postgres pg_isready -U postgres > /dev/null 2>&1; then
            log_info "PostgreSQL is ready"
            return 0
        fi

        log_info "PostgreSQL not ready, attempt $attempt/$max_attempts..."
        sleep 5
        ((attempt++))
    done

    log_error "PostgreSQL failed to become ready after $max_attempts attempts"
    return 1
}

# Initialize Keycloak database and user
initialize_keycloak_db() {
    log_info "Initializing Keycloak database and user..."

    local keycloak_password="${KEYCLOAK_DB_PASSWORD:-keycloak_secure_2025}"

    # Create user and database
    docker exec purebliss-postgres psql -U postgres << SQL
        -- Create keycloak user if not exists
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'keycloak') THEN
                CREATE ROLE keycloak LOGIN PASSWORD '$keycloak_password';
                ALTER ROLE keycloak CREATEDB;
                RAISE NOTICE 'Created keycloak user';
            ELSE
                ALTER ROLE keycloak PASSWORD '$keycloak_password';
                RAISE NOTICE 'Updated keycloak user password';
            END IF;
        END
        \$\$;

        -- Create keycloak database if not exists
        SELECT 'CREATE DATABASE keycloak OWNER keycloak'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keycloak')\gexec

        -- Grant permissions
        GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
        ALTER DATABASE keycloak OWNER TO keycloak;
SQL

    # Test connection
    export PGPASSWORD="$keycloak_password"
    if docker exec -e PGPASSWORD="$keycloak_password" purebliss-postgres psql -U keycloak -d keycloak -c "SELECT current_user, current_database();"; then
        log_info "Database initialization successful"
        return 0
    else
        log_error "Database initialization failed"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting Keycloak database initialization..."

    if wait_for_postgres; then
        if initialize_keycloak_db; then
            log_info "Keycloak database initialization completed successfully"
            exit 0
        else
            log_error "Keycloak database initialization failed"
            exit 1
        fi
    else
        log_error "PostgreSQL not available"
        exit 1
    fi
}

main "$@"
