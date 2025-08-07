#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
echo "[$(date)] INFO: Starting PostgreSQL container setup" | tee -a "$LOG_FILE"

# This script will be executed by the official postgres container
# before it starts the postgres server. The postgres server will
# be started as the user that owns the data directory.

# Function to create a database if it doesn't exist
create_database() {
    local db_name=$1
    echo "[$(date)] INFO: Checking for database '$db_name'" | tee -a "$LOG_FILE"
    if psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo "[$(date)] INFO: Database '$db_name' already exists." | tee -a "$LOG_FILE"
    else
        echo "[$(date)] INFO: Database '$db_name' does not exist. Creating..." | tee -a "$LOG_FILE"
        psql -U "$POSTGRES_USER" -c "CREATE DATABASE $db_name"
        echo "[$(date)] SUCCESS: Database '$db_name' created." | tee -a "$LOG_FILE"
    fi
}

# The official postgres entrypoint will start the server and then
# run any .sh or .sql scripts in /docker-entrypoint-initdb.d/
# We need to wait for the server to be ready before creating databases.

# A simple loop to wait for postgres to be ready
wait_for_postgres() {
    echo "[$(date)] INFO: Waiting for PostgreSQL to be ready..." | tee -a "$LOG_FILE"
    until pg_isready -U "$POSTGRES_USER" -h localhost -p 5432; do
        echo "[$(date)] INFO: PostgreSQL is unavailable - sleeping" | tee -a "$LOG_FILE"
        sleep 2
    done
    echo "[$(date)] SUCCESS: PostgreSQL is ready." | tee -a "$LOG_FILE"
}

# Run the database creation logic after a brief wait for the server to initialize
(
    wait_for_postgres
    create_database "keycloak"
    create_database "plane"
    create_database "vikunja"
) &

echo "[$(date)] INFO: PostgreSQL setup script finished. Handing over to official entrypoint." | tee -a "$LOG_FILE"

# Now, call the original entrypoint script to start postgres
exec docker-entrypoint.sh "$@"
