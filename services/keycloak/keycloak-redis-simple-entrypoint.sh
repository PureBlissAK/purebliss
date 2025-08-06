#!/bin/bash
set -euo pipefail

# Simple Keycloak Redis Integration Entrypoint
# Minimal script that works with Keycloak container limitations

echo "[KEYCLOAK-REDIS] Starting Keycloak with Redis caching integration..."

# Set up Redis environment variables
export REDIS_HOST="${REDIS_HOST:-purebliss-redis}"
export REDIS_PORT="${REDIS_PORT:-6379}"
export REDIS_DATABASE="${REDIS_DATABASE:-1}"

# Set up PostgreSQL environment variables
export KC_DB=postgres
export KC_DB_HOST="${POSTGRES_HOST:-purebliss-postgres}"
export KC_DB_PORT="${POSTGRES_PORT:-5432}"
export KC_DB_NAME="${KEYCLOAK_DB_NAME:-keycloak}"
export KC_DB_USERNAME="${KEYCLOAK_DB_USER:-keycloak}"
export KC_DB_PASSWORD="${KEYCLOAK_DB_PASSWORD:-keycloak_secure_password}"
export KC_DB_URL="jdbc:postgresql://$KC_DB_HOST:$KC_DB_PORT/$KC_DB_NAME"

# Set up Keycloak admin
export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
export KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin123}"

# Configure Keycloak server
export KC_HOSTNAME="${KC_HOSTNAME:-dev.purebliss.app}"
export KC_PROXY="${KC_PROXY:-edge}"
export KC_HTTP_RELATIVE_PATH="${KC_HTTP_RELATIVE_PATH:-/auth}"
export KC_HTTP_ENABLED="${KC_HTTP_ENABLED:-true}"
export KC_HOSTNAME_STRICT="${KC_HOSTNAME_STRICT:-false}"
export KC_HOSTNAME_STRICT_HTTPS="${KC_HOSTNAME_STRICT_HTTPS:-false}"

# Configure caching with Redis awareness
export KC_CACHE="${KC_CACHE:-ispn}"
export KC_CACHE_STACK="${KC_CACHE_STACK:-tcp}"

# Set Java system properties for Redis integration
export JAVA_OPTS_APPEND="${JAVA_OPTS_APPEND:-} -Dkeycloak.redis.host=$REDIS_HOST -Dkeycloak.redis.port=$REDIS_PORT -Dkeycloak.redis.database=$REDIS_DATABASE"

echo "[KEYCLOAK-REDIS] Configuration:"
echo "  Database: $KC_DB_URL"
echo "  Redis: $REDIS_HOST:$REDIS_PORT (database: $REDIS_DATABASE)"
echo "  Admin: $KEYCLOAK_ADMIN"
echo "  Hostname: $KC_HOSTNAME"

# Build Keycloak with PostgreSQL
echo "[KEYCLOAK-REDIS] Building Keycloak with PostgreSQL support..."
/opt/keycloak/bin/kc.sh build --db=postgres

# Start Keycloak in development mode
echo "[KEYCLOAK-REDIS] Starting Keycloak in development mode..."
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
