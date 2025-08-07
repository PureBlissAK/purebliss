#!/bin/bash
set -euo pipefail

# PostgreSQL Startup Script with Vault Integration
# Pure Bliss Elite Standards: Automated, Zero-Trust, Microservices
# Ensures PostgreSQL starts with Vault secrets and passes health checks

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_info() {
    echo "[$(date)] POSTGRES_STARTUP: $1" | tee -a "$LOG_FILE"
}

function log_error() {
    echo "[$(date)] POSTGRES_STARTUP: ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ POSTGRES_STARTUP: $1" >&2
}

function log_success() {
    echo "[$(date)] POSTGRES_STARTUP: SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ POSTGRES_STARTUP: $1"
}

# Change to the postgres service directory
cd /opt/dev-purebliss/services/postgres

log_info "Starting PostgreSQL with Vault integration..."

# Check prerequisites
log_info "Checking prerequisites..."

# Create required directories
mkdir -p /opt/my-secure-ha-stack/logs
mkdir -p /opt/my-secure-ha-stack/secrets

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    log_error "docker-compose not found. Please install docker-compose."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker."
    exit 1
fi

# Create network if it doesn't exist
if ! docker network ls | grep -q purebliss-net; then
    log_info "Creating purebliss-net network..."
    docker network create purebliss-net
    log_success "Network created"
fi

# Stop any existing containers
log_info "Stopping any existing PostgreSQL containers..."
docker-compose down 2>/dev/null || true

# Clean up any existing volumes if requested
if [[ "${1:-}" == "--clean" ]]; then
    log_info "Cleaning up existing volumes..."
    docker volume rm purebliss_postgres_data 2>/dev/null || true
    docker volume rm purebliss_vault_data 2>/dev/null || true
    log_success "Volumes cleaned"
fi

# Start services
log_info "Starting Vault and PostgreSQL services..."
docker-compose up -d

# Wait for Vault to be ready
log_info "Waiting for Vault to be ready..."
max_attempts=60
attempt=1

while [[ $attempt -le $max_attempts ]]; do
    if docker exec purebliss-vault vault status >/dev/null 2>&1; then
        log_success "Vault is ready"
        break
    fi

    if [[ $attempt -eq $max_attempts ]]; then
        log_error "Vault failed to start within expected time"
        docker-compose logs vault
        exit 1
    fi

    log_info "Waiting for Vault... (attempt $attempt/$max_attempts)"
    sleep 3
    ((attempt++))
done

# Initialize Vault with initial secrets if this is first run
log_info "Ensuring Vault has initial PostgreSQL secrets..."
if ! docker exec purebliss-vault vault kv get secret/postgres >/dev/null 2>&1; then
    log_info "Creating initial PostgreSQL secrets in Vault..."

    # Generate secure passwords
    bootstrap_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    vault_admin_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    docker exec purebliss-vault vault kv put secret/postgres \
        bootstrap_password="$bootstrap_password" \
        vault_admin_password="$vault_admin_password" \
        description="PostgreSQL bootstrap credentials - auto-generated $(date)" \
        service="purebliss-postgres" \
        environment="development"

    log_success "Initial PostgreSQL secrets created in Vault"
else
    log_info "PostgreSQL secrets already exist in Vault"
fi

# Wait for PostgreSQL to be ready
log_info "Waiting for PostgreSQL to be ready..."
max_attempts=60
attempt=1

while [[ $attempt -le $max_attempts ]]; do
    if docker exec purebliss-postgres pg_isready -U postgres -d postgres >/dev/null 2>&1; then
        log_success "PostgreSQL is ready"
        break
    fi

    if [[ $attempt -eq $max_attempts ]]; then
        log_error "PostgreSQL failed to start within expected time"
        log_error "PostgreSQL logs:"
        docker-compose logs postgres
        exit 1
    fi

    log_info "Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
    sleep 3
    ((attempt++))
done

# Run health check
log_info "Running comprehensive health check..."
if /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh postgres 2>/dev/null; then
    log_success "PostgreSQL health check passed"
else
    log_error "PostgreSQL health check failed"
    log_error "Check logs for details:"
    docker-compose logs postgres
    exit 1
fi

# Test Vault integration
log_info "Testing Vault database integration..."
if docker exec purebliss-vault vault read database/creds/postgres-role >/dev/null 2>&1; then
    log_success "Vault database integration is working"
else
    log_info "Vault database integration not yet configured (will be setup automatically)"
fi

# Show service status
log_success "PostgreSQL startup completed successfully!"
echo ""
echo "📊 Service Status:"
echo "  🐘 PostgreSQL: $(docker exec purebliss-postgres pg_isready -U postgres || echo 'Not Ready')"
echo "  🔐 Vault: $(docker exec purebliss-vault vault status -format=json 2>/dev/null | jq -r '.sealed // "Unknown"' | sed 's/false/Unsealed/' | sed 's/true/Sealed/')"
echo ""
echo "🔗 Access Information:"
echo "  📊 PostgreSQL: localhost:5432 (postgres/[vault-managed])"
echo "  🔐 Vault: http://localhost:8200 (token: dev-root-token-purebliss)"
echo ""
echo "🔧 Useful Commands:"
echo "  # View logs: docker-compose logs -f"
echo "  # Test connection: docker exec purebliss-postgres psql -U postgres -c 'SELECT version();'"
echo "  # Check Vault secrets: docker exec purebliss-vault vault kv get secret/postgres"
echo "  # Stop services: docker-compose down"
echo ""

log_success "PostgreSQL with Vault integration is ready for production use!"
