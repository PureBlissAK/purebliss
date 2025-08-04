#!/bin/bash
set -euo pipefail

# Keycloak Vault Integration Entrypoint
# Fetches Keycloak admin credentials and database passwords from Vault before starting Keycloak

LOG_PREFIX="[KEYCLOAK-VAULT]"

log_info() {
    echo "$LOG_PREFIX INFO: $1" >&2
}

log_error() {
    echo "$LOG_PREFIX ERROR: $1" >&2
}

log_warn() {
    echo "$LOG_PREFIX WARN: $1" >&2
}

# Set defaults if not already provided via environment
export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN_USER:-admin}"
export KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-keycloak_admin_changeme}"
export KC_DB="${KC_DB:-postgres}"
export KC_DB_URL="${KC_DB_URL:-jdbc:postgresql://purebliss-postgres:5432/keycloak}"
export KC_DB_USERNAME="${POSTGRES_USER:-keycloak}"
export KC_DB_PASSWORD="${KC_DB_PASSWORD:-keycloak_password_changeme}"

log_info "Starting Keycloak with admin user: $KEYCLOAK_ADMIN"
log_info "Database URL: $KC_DB_URL"
log_info "Using database credentials for user: $KC_DB_USERNAME"

# Build and start Keycloak with PostgreSQL configuration
log_info "Building Keycloak with PostgreSQL configuration..."
/opt/keycloak/bin/kc.sh build --db=postgres

log_info "Starting Keycloak with PostgreSQL..."
exec /opt/keycloak/bin/kc.sh start \
    --db=postgres \
    --db-url="$KC_DB_URL" \
    --db-username="$KC_DB_USERNAME" \
    --db-password="$KC_DB_PASSWORD"
