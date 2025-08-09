#!/bin/bash

# Simple Keycloak Database Authentication Fix
# Updates password and tests connection
# Date: 2025-08-06

set -euo pipefail

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - DB_AUTH_SIMPLE [$1]: $2" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

log_action "INFO" "Starting simple database authentication fix for Keycloak"

# Set the password we'll use
KEYCLOAK_PASSWORD="keycloak_secure_2025"

# Update keycloak user password
update_keycloak_password() {
    log_action "INFO" "Updating Keycloak user password"

    docker exec purebliss-postgres psql -U postgres -c "ALTER ROLE keycloak PASSWORD '$KEYCLOAK_PASSWORD';" || {
        log_action "ERROR" "Failed to update keycloak password"
        return 1
    }

    log_action "SUCCESS" "Keycloak password updated"
}

# Test database connection
test_connection() {
    log_action "INFO" "Testing Keycloak database connection"

    # Test connection with new password
    export PGPASSWORD="$KEYCLOAK_PASSWORD"
    if docker exec -e PGPASSWORD="$KEYCLOAK_PASSWORD" purebliss-postgres psql -U keycloak -d keycloak -c "SELECT current_user, current_database(), version();" 2>/dev/null; then
        log_action "SUCCESS" "Database connection test passed"
        return 0
    else
        log_action "ERROR" "Database connection test failed"
        return 1
    fi
}

# Create simple Keycloak docker-compose
create_simple_keycloak_compose() {
    log_action "INFO" "Creating simple Keycloak docker-compose"

    cat > /opt/dev-purebliss/services/keycloak/docker-compose.simple.yml << EOF
version: '3.8'

services:
  purebliss-keycloak:
    image: quay.io/keycloak/keycloak:24.0.5
    container_name: purebliss-keycloak
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin_secure_2025
      KC_DB: postgres
      KC_DB_URL_HOST: purebliss-postgres
      KC_DB_URL_PORT: 5432
      KC_DB_URL_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: $KEYCLOAK_PASSWORD
      KC_HOSTNAME: dev.purebliss.app
      KC_HOSTNAME_STRICT: false
      KC_PROXY: edge
      KC_HTTP_ENABLED: true
    command: |
      bash -c '
        echo "[$(date)] Waiting for PostgreSQL..."
        until nc -z purebliss-postgres 5432; do
          echo "[$(date)] PostgreSQL not ready, waiting..."
          sleep 5
        done

        echo "[$(date)] Testing database connection..."
        export PGPASSWORD=$KEYCLOAK_PASSWORD
        until docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT 1;" > /dev/null 2>&1; do
          echo "[$(date)] Database connection failed, waiting..."
          sleep 10
        done

        echo "[$(date)] Database connection successful, starting Keycloak..."
        exec /opt/keycloak/bin/kc.sh start-dev
      '
    depends_on:
      - purebliss-postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    networks:
      - purebliss-net

networks:
  purebliss-net:
    external: true
EOF

    log_action "SUCCESS" "Simple Keycloak docker-compose created"
}

# Grant database permissions
grant_permissions() {
    log_action "INFO" "Granting database permissions to keycloak user"

    docker exec purebliss-postgres psql -U postgres -c "
        GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
        ALTER DATABASE keycloak OWNER TO keycloak;
    " || {
        log_action "WARNING" "Failed to grant some permissions (may already exist)"
    }

    log_action "SUCCESS" "Database permissions updated"
}

# Main execution
main() {
    log_action "INFO" "Starting simple database authentication fix"

    # Update password
    if update_keycloak_password; then
        log_action "SUCCESS" "Password update completed"
    else
        log_action "ERROR" "Password update failed"
        exit 1
    fi

    # Grant permissions
    grant_permissions

    # Test connection
    if test_connection; then
        log_action "SUCCESS" "Connection test passed"
    else
        log_action "ERROR" "Connection test failed"
        exit 1
    fi

    # Create compose file
    create_simple_keycloak_compose

    log_action "SUCCESS" "Database authentication fix completed successfully"
    log_action "INFO" "Next steps:"
    log_action "INFO" "1. Stop current Keycloak: docker stop purebliss-keycloak && docker rm purebliss-keycloak"
    log_action "INFO" "2. Start with new config: docker-compose -f /opt/dev-purebliss/services/keycloak/docker-compose.simple.yml up -d"
    log_action "INFO" "3. Check logs: docker logs purebliss-keycloak -f"
}

main "$@"
