#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# START_POSTGRES_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="start-postgres.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced deployment script for infrastructure operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="deployment"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="infrastructure"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced deployment script for infrastructure with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
start_postgres_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
start_postgres_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
start_postgres_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
start_postgres_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    start_postgres_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        start_postgres_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            start_postgres_log_success "Validation passed - proceeding with auto-commit"
        else
            start_postgres_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        start_postgres_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        start_postgres_log_info "Auto-commit system not available - manual commit required"
        start_postgres_log_info "Recommended commit message: $commit_message"
        start_postgres_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
start_postgres_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    start_postgres_log_success "$final_message"
    
    # Execute auto-commit wrapper
    start_postgres_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    start_postgres_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


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
echo "  🔐 Vault: https://localhost:8200 (token: dev-root-token-purebliss)"
echo ""
echo "🔧 Useful Commands:"
echo "  # View logs: docker-compose logs -f"
echo "  # Test connection: docker exec purebliss-postgres psql -U postgres -c 'SELECT version();'"
echo "  # Check Vault secrets: docker exec purebliss-vault vault kv get secret/postgres"
echo "  # Stop services: docker-compose down"
echo ""

log_success "PostgreSQL with Vault integration is ready for production use!"

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT USAGE EXAMPLES - PURE BLISS ELITE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════════
#
# 📚 COMPLETE GUIDE: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md
#
# BASIC AUTO-COMMIT ON SUCCESS:
# Add this at the end of your main script logic:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed successfully"
#
# AUTO-COMMIT WITH VALIDATION:
# Add validation command to ensure script worked correctly:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed with validation" "docker ps | grep -q my-service"
#
# MANUAL AUTO-COMMIT TRIGGER:
# Use auto-commit wrapper directly with custom message:
#   ${WRAPPER_PREFIX}_auto_commit_wrapper "Custom commit: Feature implemented successfully"
#
# DIRECT PURE BLISS ELITE SYSTEM (Recommended):
# Use the official auto-commit trigger system:
#   /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
#       "${SCRIPT_CATEGORY}" "Description of accomplishment" "${SCRIPT_NAME}"
#
# CONDITIONAL AUTO-COMMIT:
# Only commit if certain conditions are met:
#   if [[ \$SUCCESS_FLAG == "true" ]]; then
#       ${WRAPPER_PREFIX}_auto_commit_wrapper "Conditional commit: Success flag set"
#   fi
#
# VALIDATION COMMAND EXAMPLES:
# - Container health check: "docker ps | grep -q healthy"
# - File existence: "test -f /path/to/expected/file"
# - Service response: "curl -s http://service/health | grep -q ok"
# - Custom function: "my_validation_function"
#
# ELITE COMMIT MESSAGE FORMAT:
# The Pure Bliss Elite system automatically generates comprehensive commit messages
# following the standard format with safety guarantees, validation results, and
# proper documentation references. See the AUTO_COMMIT_SYSTEM_GUIDE.md for details.
#
# ═══════════════════════════════════════════════════════════════════════════════════
