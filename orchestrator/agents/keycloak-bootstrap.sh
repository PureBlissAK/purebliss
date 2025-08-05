#!/bin/bash
set -euo pipefail
# Bootstrap Keycloak Admin User for SSO Integration

log() {
    echo "[$(date)] KEYCLOAK-BOOTSTRAP: $1"
}

log "Bootstrapping Keycloak admin user..."

# First, stop Keycloak to ensure clean state
docker stop purebliss-keycloak
docker rm purebliss-keycloak

log "Starting Keycloak with proper admin bootstrap..."

# Start Keycloak with admin user creation enabled
docker run -d \
  --name purebliss-keycloak \
  --network purebliss-net \
  -p 8080:8080 \
  -e KC_DB=postgres \
  -e KC_DB_URL_HOST=purebliss-postgres \
  -e KC_DB_URL_PORT=5432 \
  -e KC_DB_URL_DATABASE=keycloak \
  -e KC_DB_USERNAME=keycloak \
  -e KC_DB_PASSWORD=keycloak_password \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin123 \
  -e KC_HOSTNAME=dev.purebliss.app \
  -e KC_PROXY=edge \
  -e KC_HEALTH_ENABLED=true \
  -e KC_METRICS_ENABLED=true \
  --restart unless-stopped \
  quay.io/keycloak/keycloak:24.0.5 start-dev

log "Waiting for Keycloak to start up..."
sleep 45

# Test authentication
log "Testing admin authentication..."
if docker exec purebliss-keycloak /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin123 2>/dev/null; then
    log "SUCCESS: Admin user authenticated successfully"

    # Test getting master realm
    if docker exec purebliss-keycloak /opt/keycloak/bin/kcadm.sh get realms/master --fields id,realm 2>/dev/null; then
        log "SUCCESS: Admin user has proper permissions"
        log "Keycloak admin bootstrap completed successfully!"
        exit 0
    fi
else
    log "Authentication failed, checking logs..."
    docker logs purebliss-keycloak --tail 20
fi

log "Admin bootstrap may need manual intervention"
exit 1
