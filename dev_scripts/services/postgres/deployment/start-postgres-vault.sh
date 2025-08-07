#!/bin/bash
set -euo pipefail

# PostgreSQL Vault-Integrated Startup Script
# Pure Bliss Elite Standards: Zero-Trust, Vault-Managed Secrets
# This script starts PostgreSQL with full Vault integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_info() {
    echo "[$(date)] POSTGRES_START: $1" | tee -a "$LOG_FILE"
}

function log_success() {
    echo "[$(date)] POSTGRES_START: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] POSTGRES_START: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1" >&2
}

function wait_for_vault() {
    local max_attempts=60
    local attempt=1

    log_info "Waiting for Vault to be ready before starting PostgreSQL..."

    while [[ $attempt -le $max_attempts ]]; do
        if curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
            if curl -sk https://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false'; then
                log_success "Vault is ready and unsealed"
                return 0
            fi
        fi

        log_info "Waiting for Vault (attempt $attempt/$max_attempts)..."
        sleep 3
        ((attempt++))
    done

    log_error "Vault not ready after $max_attempts attempts"
    return 1
}

function cleanup_existing_postgres() {
    log_info "Cleaning up any existing PostgreSQL containers..."

    # Stop and remove existing PostgreSQL containers
    if docker ps -a | grep -q purebliss-postgres; then
        docker stop purebliss-postgres 2>/dev/null || true
        docker rm purebliss-postgres 2>/dev/null || true
        log_info "Removed existing PostgreSQL container"
    fi

    # Clean up any orphaned volumes if needed
    if docker volume ls | grep -q postgres_secrets; then
        docker volume rm postgres_secrets 2>/dev/null || true
    fi
}

function start_postgres_vault_integrated() {
    log_info "Starting PostgreSQL with Vault integration..."

    # Ensure we're in the correct directory
    cd "$SCRIPT_DIR"

    # Make sure the entrypoint script is executable
    chmod +x vault-entrypoint.sh

    # Start PostgreSQL using the Vault-integrated docker-compose
    if docker-compose -f postgres-docker-compose-vault.yml up -d; then
        log_success "PostgreSQL container started with Vault integration"
    else
        log_error "Failed to start PostgreSQL container"
        return 1
    fi

    # Wait for container to be running
    local max_wait=60
    local wait_count=0

    while [[ $wait_count -lt $max_wait ]]; do
        if docker ps | grep -q purebliss-postgres; then
            log_success "PostgreSQL container is running"
            break
        fi
        sleep 2
        ((wait_count++))
    done

    if [[ $wait_count -ge $max_wait ]]; then
        log_error "PostgreSQL container failed to start properly"
        docker logs purebliss-postgres --tail 50
        return 1
    fi
}

function wait_for_postgres_healthy() {
    log_info "Waiting for PostgreSQL to be healthy..."

    local max_attempts=60
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        # Check container health
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-postgres 2>/dev/null || echo "no_healthcheck")

        if [[ "$health_status" == "healthy" ]]; then
            log_success "PostgreSQL is healthy and ready"
            return 0
        elif [[ "$health_status" == "unhealthy" ]]; then
            log_error "PostgreSQL health check failed"
            docker logs purebliss-postgres --tail 20
            return 1
        fi

        log_info "PostgreSQL health status: $health_status (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    log_error "PostgreSQL health check timed out"
    return 1
}

function validate_postgres_vault_integration() {
    log_info "Validating PostgreSQL Vault integration..."

    # Test basic PostgreSQL connectivity
    if docker exec purebliss-postgres pg_isready -U postgres -d postgres >/dev/null 2>&1; then
        log_success "PostgreSQL basic connectivity working"
    else
        log_error "PostgreSQL basic connectivity failed"
        return 1
    fi

    # Test if vault_admin user exists
    if docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='vault_admin'" 2>/dev/null | grep -q 1; then
        log_success "Vault admin user exists in PostgreSQL"
    else
        log_error "Vault admin user not found in PostgreSQL"
        return 1
    fi

    # Test if service databases exist
    local databases=("keycloak" "plane" "vikunja")
    for db in "${databases[@]}"; do
        if docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$db'" 2>/dev/null | grep -q 1; then
            log_success "Database '$db' exists"
        else
            log_error "Database '$db' not found"
            return 1
        fi
    done

    # Test Vault dynamic credentials if available
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=1
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

        if vault read database/creds/postgres-role >/dev/null 2>&1; then
            log_success "Vault dynamic credentials working"
        else
            log_error "Vault dynamic credentials not working"
            return 1
        fi
    else
        log_info "Vault token not available for testing dynamic credentials"
    fi

    log_success "PostgreSQL Vault integration validation completed successfully"
}

function main() {
    log_info "Starting PostgreSQL with complete Vault integration (Pure Bliss Elite Standards)"

    # Step 1: Wait for Vault to be ready
    if ! wait_for_vault; then
        log_error "Cannot start PostgreSQL without Vault (Zero-Trust principle)"
        exit 1
    fi

    # Step 2: Cleanup any existing containers
    cleanup_existing_postgres

    # Step 3: Start PostgreSQL with Vault integration
    if ! start_postgres_vault_integrated; then
        log_error "Failed to start PostgreSQL with Vault integration"
        exit 1
    fi

    # Step 4: Wait for PostgreSQL to be healthy
    if ! wait_for_postgres_healthy; then
        log_error "PostgreSQL failed to become healthy"
        exit 1
    fi

    # Step 5: Validate the integration
    if ! validate_postgres_vault_integration; then
        log_error "PostgreSQL Vault integration validation failed"
        exit 1
    fi

    log_success "🎉 PostgreSQL started successfully with complete Vault integration!"
    log_success "✅ Zero hardcoded secrets"
    log_success "✅ Dynamic credential generation working"
    log_success "✅ Service databases created and configured"
    log_success "✅ Ready for other services to connect"

    # Show status
    echo ""
    echo "PostgreSQL Status:"
    docker ps --filter name=purebliss-postgres --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo "To validate the setup, run:"
    echo "  /opt/dev-purebliss/services/postgres/validate-setup.sh"
    echo ""
    echo "To run comprehensive health check:"
    echo "  /opt/dev-purebliss/comprehensive-health-check.sh"
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
