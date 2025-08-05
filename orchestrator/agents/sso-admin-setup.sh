#!/bin/bash
set -euo pipefail
# Production-Ready SSO Integration - Phase 1: Admin Setup
# Ensures Keycloak has a working admin user before proceeding with SSO integration

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
KEYCLOAK_CONTAINER="purebliss-keycloak"
CONFIG_ENV="/opt/my-secure-ha-stack/config.env"

log() {
    echo "[$(date)] SSO-ADMIN-SETUP: $1" | tee -a "$LOG_FILE"
}

log "Starting Keycloak admin user setup for production SSO integration..."

# Source environment configuration
if [[ -f "$CONFIG_ENV" ]]; then
    source "$CONFIG_ENV"
    log "Loaded environment configuration from: $CONFIG_ENV"
else
    log "ERROR: Configuration file not found: $CONFIG_ENV"
    exit 1
fi

ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
ADMIN_PASS="${KEYCLOAK_ADMIN_PASSWORD:-admin123}"
KC_ADMIN="/opt/keycloak/bin/kcadm.sh"

log "Setting up admin user: $ADMIN_USER"

# Determine the correct Keycloak URL
KEYCLOAK_BASE_URL="http://localhost:8080"
if docker exec $KEYCLOAK_CONTAINER env | grep -q "KC_HTTP_RELATIVE_PATH=/auth"; then
    KEYCLOAK_BASE_URL="http://localhost:8080/auth"
    log "Using Keycloak URL with /auth path: $KEYCLOAK_BASE_URL"
else
    log "Using direct Keycloak URL: $KEYCLOAK_BASE_URL"
fi

# Test if admin user already exists and works
log "Testing existing admin credentials..."
if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
    log "SUCCESS: Admin user is already configured and working"
    exit 0
fi

log "Admin authentication failed. Attempting to create or fix admin user..."

# For Keycloak 24.0.5, we need to ensure the admin user is created properly
# First, try to create an initial admin user using Keycloak's bootstrap method
log "Attempting to bootstrap admin user in Keycloak..."

# Stop the container to set proper environment variables
log "Stopping Keycloak container to configure admin user..."
docker stop $KEYCLOAK_CONTAINER

# Create a temporary environment file for admin setup
cat > /tmp/keycloak-admin.env << EOF
KEYCLOAK_ADMIN=$ADMIN_USER
KEYCLOAK_ADMIN_PASSWORD=$ADMIN_PASS
KC_DB=postgres
KC_DB_URL_HOST=purebliss-postgres
KC_DB_URL_PORT=5432
KC_DB_URL_DATABASE=keycloak
KC_DB_USERNAME=vault_admin
KC_DB_PASSWORD=vault_password
KC_HOSTNAME=dev.purebliss.app
KC_PROXY=edge
KC_HTTP_RELATIVE_PATH=/auth
EOF

log "Starting Keycloak with admin environment variables..."
docker run --rm --name temp-keycloak-admin \
    --network purebliss-net \
    --env-file /tmp/keycloak-admin.env \
    -d quay.io/keycloak/keycloak:24.0.5 start-dev

# Wait for temporary container to initialize admin user
log "Waiting for admin user initialization..."
sleep 30

# Stop temporary container
docker stop temp-keycloak-admin 2>/dev/null || true

# Clean up
rm -f /tmp/keycloak-admin.env

# Start the original container
log "Starting original Keycloak container..."
docker start $KEYCLOAK_CONTAINER

# Wait for startup
log "Waiting for Keycloak to be ready..."
sleep 30

# Test authentication again
log "Testing admin authentication after setup..."
RETRY_COUNT=0
while [[ $RETRY_COUNT -lt 5 ]]; do
    if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
        log "SUCCESS: Admin user is now configured and working"

        # Verify by getting master realm info
        if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN get realms/master --fields id,realm --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
            log "SUCCESS: Admin user has proper permissions"
            exit 0
        fi
    fi

    ((RETRY_COUNT++))
    log "Authentication attempt $RETRY_COUNT failed, retrying..."
    sleep 10
done

log "ERROR: Failed to configure admin user after all attempts"
log "Manual intervention may be required"
exit 1
