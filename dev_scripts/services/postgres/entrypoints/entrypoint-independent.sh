#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# ENTRYPOINT_INDEPENDENT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="entrypoint-independent.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with auto-commit functionality,
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
entrypoint_independent_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
entrypoint_independent_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
entrypoint_independent_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
entrypoint_independent_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    entrypoint_independent_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        entrypoint_independent_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            entrypoint_independent_log_success "Validation passed - proceeding with auto-commit"
        else
            entrypoint_independent_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        entrypoint_independent_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        entrypoint_independent_log_info "Auto-commit system not available - manual commit required"
        entrypoint_independent_log_info "Recommended commit message: $commit_message"
        entrypoint_independent_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
entrypoint_independent_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    entrypoint_independent_log_success "$final_message"
    
    # Execute auto-commit wrapper
    entrypoint_independent_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    entrypoint_independent_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# PostgreSQL Independent Entrypoint for PureBliss Development Environment
# Handles database creation and service independence
# Compatible with Vault integration but doesn't require it

# Logging function
log_info() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [PostgreSQL] INFO: $1"
}

log_error() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [PostgreSQL] ERROR: $1" >&2
}

log_success() {
    echo "[$(date -u '+%a %b %d %H:%M:%S UTC %Y')] [PostgreSQL] SUCCESS: $1"
}

# Append to dev log
append_to_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] POSTGRES: $1" >> /opt/logs/postgres.log 2>/dev/null || true
}

log_info "PostgreSQL container entrypoint started."
append_to_log "PostgreSQL entrypoint started"

# Create logs directory if it doesn't exist
mkdir -p /opt/logs

# Ensure required environment variables are set with defaults
export POSTGRES_DB="${POSTGRES_DB:-postgres}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"

# If no password is provided and no password file exists, generate one
if [[ -z "${POSTGRES_PASSWORD:-}" ]] && [[ ! -f "${POSTGRES_PASSWORD_FILE:-}" ]]; then
    log_info "No password provided, checking for Vault integration..."

    # Check if Vault is available (optional dependency)
    if command -v curl >/dev/null 2>&1 && curl -sk http://purebliss-vault:8200/v1/sys/health >/dev/null 2>&1; then
        log_info "Vault detected, will try to use Vault integration"
        # For now, use a development password - Vault integration can be added later
        export POSTGRES_PASSWORD="purebliss_dev_postgres_2025"
        append_to_log "Using development password (Vault integration available for future enhancement)"
    else
        log_info "Vault not available, using development password"
        export POSTGRES_PASSWORD="purebliss_dev_postgres_2025"
        append_to_log "Using development password (no Vault integration)"
    fi
fi

# Create init script for database creation
log_info "Preparing database initialization script..."

cat > /docker-entrypoint-initdb.d/99-create-databases.sh << 'EOF'

echo "[$(date)] PostgreSQL: Creating application databases..."

# Function to create database if it doesn't exist
create_database_if_not_exists() {
    local db_name=$1
    echo "[$(date)] PostgreSQL: Checking database '$db_name'"

    if psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo "[$(date)] PostgreSQL: Database '$db_name' already exists"
    else
        echo "[$(date)] PostgreSQL: Creating database '$db_name'"
        psql -U "$POSTGRES_USER" -c "CREATE DATABASE $db_name;"
        echo "[$(date)] PostgreSQL: Database '$db_name' created successfully"
    fi
}

# Create application databases
create_database_if_not_exists "keycloak"
create_database_if_not_exists "plane"
create_database_if_not_exists "vikunja"

echo "[$(date)] PostgreSQL: All application databases created/verified"

# Create application users with default passwords (can be updated by Vault later)
echo "[$(date)] PostgreSQL: Creating application users..."

psql -U "$POSTGRES_USER" -d postgres << 'SQL'
-- Create keycloak user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'keycloak') THEN
        CREATE ROLE keycloak WITH LOGIN PASSWORD 'keycloak_dev_2025';
        GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
        RAISE NOTICE 'Created keycloak user with development password';
    ELSE
        RAISE NOTICE 'User keycloak already exists';
    END IF;
END
$$;

-- Create plane user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'plane') THEN
        CREATE ROLE plane WITH LOGIN PASSWORD 'plane_dev_2025';
        GRANT ALL PRIVILEGES ON DATABASE plane TO plane;
        RAISE NOTICE 'Created plane user with development password';
    ELSE
        RAISE NOTICE 'User plane already exists';
    END IF;
END
$$;

-- Create vikunja user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vikunja') THEN
        CREATE ROLE vikunja WITH LOGIN PASSWORD 'vikunja_dev_2025';
        GRANT ALL PRIVILEGES ON DATABASE vikunja TO vikunja;
        RAISE NOTICE 'Created vikunja user with development password';
    ELSE
        RAISE NOTICE 'User vikunja already exists';
    END IF;
END
$$;
SQL

echo "[$(date)] PostgreSQL: Application users created/verified"
echo "[$(date)] PostgreSQL: Database initialization complete"
EOF

chmod +x /docker-entrypoint-initdb.d/99-create-databases.sh

log_success "Database initialization script prepared"
append_to_log "Database initialization script created"

# Create a background process to log when PostgreSQL is ready
(
    # Wait for PostgreSQL to be ready
    sleep 10
    max_attempts=30
    attempt=1

    while [ $attempt -le $max_attempts ]; do
        if pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h localhost -p 5432 >/dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] POSTGRES: PostgreSQL is ready and accepting connections" >> /opt/logs/postgres.log 2>/dev/null || true
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] POSTGRES: All application databases created and users configured" >> /opt/logs/postgres.log 2>/dev/null || true
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
) &

log_info "Starting PostgreSQL with independent configuration..."
append_to_log "Starting PostgreSQL server"

# Start PostgreSQL using the official entrypoint
exec docker-entrypoint.sh "$@"

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
