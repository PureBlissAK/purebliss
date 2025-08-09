#!/bin/bash

# Database Authentication Fix for Keycloak
# Addresses the specific "password authentication failed for user 'keycloak'" issue found in logs
# Date: 2025-08-06

set -euo pipefail

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - DB_AUTH_FIX [$1]: $2" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

log_action "INFO" "Starting database authentication fix for Keycloak"

# Check current PostgreSQL users and databases
check_postgres_config() {
    log_action "INFO" "Checking current PostgreSQL configuration"

    echo "Current PostgreSQL users:"
    docker exec purebliss-postgres psql -U postgres -c "\du" || true

    echo -e "\nCurrent databases:"
    docker exec purebliss-postgres psql -U postgres -c "\l" || true

    echo -e "\nChecking if keycloak user exists:"
    local user_exists=$(docker exec purebliss-postgres psql -U postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='keycloak';" | xargs)
    if [ "$user_exists" = "1" ]; then
        log_action "INFO" "Keycloak user exists in PostgreSQL"
    else
        log_action "WARNING" "Keycloak user does not exist in PostgreSQL"
    fi

    echo -e "\nChecking if keycloak database exists:"
    local db_exists=$(docker exec purebliss-postgres psql -U postgres -t -c "SELECT 1 FROM pg_database WHERE datname='keycloak';" | xargs)
    if [ "$db_exists" = "1" ]; then
        log_action "INFO" "Keycloak database exists in PostgreSQL"
    else
        log_action "WARNING" "Keycloak database does not exist in PostgreSQL"
    fi
}

# Create Keycloak user and database
create_keycloak_db_user() {
    log_action "INFO" "Creating Keycloak database user and database"

    # Set a secure password for keycloak user
    local keycloak_password="${KEYCLOAK_DB_PASSWORD:-keycloak_secure_2025}"

    # Create keycloak user if it doesn't exist
    docker exec purebliss-postgres psql -U postgres -c "
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'keycloak') THEN
                CREATE ROLE keycloak LOGIN PASSWORD '$keycloak_password';
                GRANT CONNECT ON DATABASE postgres TO keycloak;
                ALTER ROLE keycloak CREATEDB;
                RAISE NOTICE 'Created keycloak user';
            ELSE
                ALTER ROLE keycloak PASSWORD '$keycloak_password';
                RAISE NOTICE 'Updated keycloak user password';
            END IF;
        END
        \$\$;
    " || {
        log_action "ERROR" "Failed to create/update keycloak user"
        return 1
    }

    # Create keycloak database if it doesn't exist
    docker exec purebliss-postgres psql -U postgres -c "
        SELECT 'CREATE DATABASE keycloak OWNER keycloak'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keycloak')\gexec
    " || {
        log_action "ERROR" "Failed to create keycloak database"
        return 1
    }

    # Grant necessary permissions
    docker exec purebliss-postgres psql -U postgres -c "
        GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
        ALTER DATABASE keycloak OWNER TO keycloak;
    " || {
        log_action "ERROR" "Failed to grant permissions to keycloak user"
        return 1
    }

    log_action "SUCCESS" "Keycloak database user and database created/updated"
}

# Update Keycloak environment configuration
update_keycloak_env() {
    log_action "INFO" "Updating Keycloak environment configuration"

    # Create/update environment file for Keycloak
    cat > /opt/dev-purebliss/services/keycloak/keycloak.env << 'EOF'
# Enhanced Keycloak Environment Configuration
# Addresses database authentication issues

# Keycloak Admin Configuration
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin_secure_2025

# Database Configuration
KC_DB=postgres
KC_DB_URL_HOST=purebliss-postgres
KC_DB_URL_PORT=5432
KC_DB_URL_DATABASE=keycloak
KC_DB_USERNAME=keycloak
KC_DB_PASSWORD=keycloak_secure_2025

# Hostname Configuration
KC_HOSTNAME=dev.purebliss.app
KC_HOSTNAME_STRICT=false
KC_PROXY=edge

# HTTP Configuration
KC_HTTP_ENABLED=true
KC_HTTPS_CERTIFICATE_FILE=/opt/keycloak/conf/server.crt
KC_HTTPS_CERTIFICATE_KEY_FILE=/opt/keycloak/conf/server.key

# Development Mode Settings
KC_DEV_FEATURES=dev-ui
KEYCLOAK_LOGLEVEL=INFO
ROOT_LOGLEVEL=INFO

# Performance Settings
KC_DB_POOL_INITIAL_SIZE=5
KC_DB_POOL_MIN_SIZE=5
KC_DB_POOL_MAX_SIZE=20

# Cache Settings
KC_CACHE=ispn
KC_CACHE_STACK=tcp
EOF

    log_action "SUCCESS" "Keycloak environment configuration updated"
}

# Create enhanced Keycloak docker-compose with fixed authentication
create_enhanced_keycloak_compose() {
    log_action "INFO" "Creating enhanced Keycloak docker-compose configuration"

    cat > /opt/dev-purebliss/services/keycloak/docker-compose.keycloak-enhanced.yml << 'EOF'
version: '3.8'

services:
  purebliss-keycloak:
    image: quay.io/keycloak/keycloak:24.0.5
    container_name: purebliss-keycloak
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "8443:8443"
    env_file:
      - ./keycloak.env
    command: |
      bash -c '
        # Enhanced startup sequence with database validation
        echo "[$(date)] Starting enhanced Keycloak startup sequence..."

        # Wait for PostgreSQL to be ready
        echo "[$(date)] Waiting for PostgreSQL..."
        until nc -z purebliss-postgres 5432; do
          echo "[$(date)] PostgreSQL not ready, waiting..."
          sleep 5
        done

        # Test database connection
        echo "[$(date)] Testing database connection..."
        export PGPASSWORD=keycloak_secure_2025
        until psql -h purebliss-postgres -U keycloak -d keycloak -c "SELECT 1;" > /dev/null 2>&1; do
          echo "[$(date)] Database connection failed, waiting..."
          sleep 10
        done

        echo "[$(date)] Database connection successful, starting Keycloak..."

        # Start Keycloak
        /opt/keycloak/bin/kc.sh start-dev \
          --db=postgres \
          --db-url="jdbc:postgresql://purebliss-postgres:5432/keycloak" \
          --db-username=keycloak \
          --db-password=keycloak_secure_2025 \
          --hostname=dev.purebliss.app \
          --hostname-strict=false \
          --proxy=edge \
          --http-enabled=true \
          --optimized
      '
    depends_on:
      purebliss-postgres:
        condition: service_healthy
    healthcheck:
      test: |
        bash -c '
          # Multi-stage health check
          if ! pgrep -f "keycloak" > /dev/null; then
            echo "Keycloak process not running"
            exit 1
          fi

          if ! nc -z localhost 8080; then
            echo "Port 8080 not accessible"
            exit 1
          fi

          if ! curl -f -s --connect-timeout 5 --max-time 10 "http://localhost:8080" > /dev/null; then
            echo "HTTP endpoint not responding"
            exit 1
          fi

          if ! curl -f -s --connect-timeout 5 --max-time 10 "http://localhost:8080/admin" > /dev/null; then
            echo "Admin console not accessible"
            exit 1
          fi

          echo "Keycloak is healthy"
          exit 0
        '
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 120s  # Allow 2 minutes for startup
    networks:
      - purebliss-net
    volumes:
      - keycloak_data:/opt/keycloak/data
      - ./conf:/opt/keycloak/conf:ro

volumes:
  keycloak_data:
    external: false

networks:
  purebliss-net:
    external: true
EOF

    log_action "SUCCESS" "Enhanced Keycloak docker-compose configuration created"
}

# Test database authentication
test_db_authentication() {
    log_action "INFO" "Testing database authentication"

    # Test connection as keycloak user
    if docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT current_user, current_database();" > /dev/null 2>&1; then
        log_action "SUCCESS" "Database authentication test passed"
        return 0
    else
        log_action "ERROR" "Database authentication test failed"
        return 1
    fi
}

# Create database initialization script
create_db_init_script() {
    log_action "INFO" "Creating database initialization script"

    cat > /opt/dev-purebliss/services/keycloak/init-keycloak-db.sh << 'EOF'
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
EOF

    chmod +x /opt/dev-purebliss/services/keycloak/init-keycloak-db.sh
    log_action "SUCCESS" "Database initialization script created"
}

# Main execution
main() {
    log_action "INFO" "Starting database authentication fix process"

    # Create necessary directories
    mkdir -p /opt/dev-purebliss/services/keycloak/conf

    # Check current state
    check_postgres_config

    # Create keycloak user and database
    if create_keycloak_db_user; then
        log_action "SUCCESS" "Database user and database creation completed"
    else
        log_action "ERROR" "Database user and database creation failed"
        exit 1
    fi

    # Update configurations
    update_keycloak_env
    create_enhanced_keycloak_compose
    create_db_init_script

    # Test authentication
    if test_db_authentication; then
        log_action "SUCCESS" "Database authentication test passed"
    else
        log_action "WARNING" "Database authentication test failed - may need manual review"
    fi

    # Verify setup
    check_postgres_config

    log_action "SUCCESS" "Database authentication fix completed"
    log_action "INFO" "Next steps:"
    log_action "INFO" "1. Stop current Keycloak container: docker stop purebliss-keycloak"
    log_action "INFO" "2. Use enhanced compose: docker-compose -f /opt/dev-purebliss/services/keycloak/docker-compose.keycloak-enhanced.yml up -d"
    log_action "INFO" "3. Run health validation: /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh keycloak db-auth-fix"
}

main "$@"
