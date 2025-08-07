#!/bin/bash

# Enhanced Keycloak Entrypoint
# Addresses startup issues and dependency validation failures found in logs

set -euo pipefail

# Source retry utilities
source /opt/dev-purebliss/retry-utils.sh

# Logging function
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] KEYCLOAK_ENTRYPOINT INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] KEYCLOAK_ENTRYPOINT ERROR: $1" >&2
}

# Pre-startup validation
validate_environment() {
    log_info "Validating environment variables..."
    
    local required_vars=(
        "KEYCLOAK_ADMIN"
        "KEYCLOAK_ADMIN_PASSWORD"
        "KC_DB_URL_HOST"
        "KC_DB_USERNAME"
        "KC_DB_PASSWORD"
        "KC_DB_URL_DATABASE"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    log_info "Environment variables validated"
}

# Database dependency validation
validate_database_dependency() {
    log_info "Validating database dependency..."
    
    local db_host="${KC_DB_URL_HOST:-purebliss-postgres}"
    local db_port="${KC_DB_URL_PORT:-5432}"
    
    # Wait for PostgreSQL port
    if ! wait_for_port "$db_host" "$db_port" 120; then
        log_error "PostgreSQL not available at $db_host:$db_port"
        exit 1
    fi
    
    # Wait for PostgreSQL readiness
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Testing PostgreSQL readiness (attempt $attempt/$max_attempts)..."
        
        if docker exec purebliss-postgres pg_isready -U "${KC_DB_USERNAME}" -d "${KC_DB_URL_DATABASE}" > /dev/null 2>&1; then
            log_info "PostgreSQL is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "PostgreSQL not ready after $max_attempts attempts"
            exit 1
        fi
        
        sleep 5
        ((attempt++))
    done
    
    log_info "Database dependency validated"
}

# Keycloak configuration preparation
prepare_keycloak_config() {
    log_info "Preparing Keycloak configuration..."
    
    # Create necessary directories
    mkdir -p /opt/keycloak/data/import
    
    # Set proper permissions
    chown -R keycloak:keycloak /opt/keycloak/data
    
    log_info "Keycloak configuration prepared"
}

# Keycloak startup with enhanced monitoring
start_keycloak() {
    log_info "Starting Keycloak with enhanced monitoring..."
    
    # Start Keycloak in background
    /opt/keycloak/bin/kc.sh start-dev \
        --db=postgres \
        --db-url="jdbc:postgresql://${KC_DB_URL_HOST}:${KC_DB_URL_PORT:-5432}/${KC_DB_URL_DATABASE}" \
        --db-username="${KC_DB_USERNAME}" \
        --db-password="${KC_DB_PASSWORD}" \
        --hostname="${KC_HOSTNAME:-localhost}" \
        --proxy=edge \
        --http-enabled=true \
        --hostname-strict=false &
    
    local keycloak_pid=$!
    
    # Monitor startup
    log_info "Monitoring Keycloak startup (PID: $keycloak_pid)..."
    
    # Wait for HTTP endpoint to be available
    if wait_for_http_endpoint "http://localhost:8080" 300; then
        log_info "Keycloak HTTP endpoint is available"
    else
        log_error "Keycloak HTTP endpoint failed to start"
        kill $keycloak_pid 2>/dev/null || true
        exit 1
    fi
    
    # Wait for admin console
    if wait_for_http_endpoint "http://localhost:8080/admin" 60; then
        log_info "Keycloak admin console is available"
    else
        log_error "Keycloak admin console not available"
        kill $keycloak_pid 2>/dev/null || true
        exit 1
    fi
    
    log_info "Keycloak started successfully"
    
    # Keep the process running
    wait $keycloak_pid
}

# Signal handlers for graceful shutdown
cleanup() {
    log_info "Received shutdown signal, stopping Keycloak..."
    pkill -f "kc.sh" || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main execution
main() {
    log_info "Enhanced Keycloak entrypoint starting..."
    
    validate_environment
    validate_database_dependency
    prepare_keycloak_config
    start_keycloak
}

main "$@"
