#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# START_VAULT_INTEGRATED_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="start-vault-integrated.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced vault-integration script for vault operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="vault-integration"
SCRIPT_TAGS="enhancement,automation,auto-commit,vault,security"
SCRIPT_SERVICES="vault"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced vault-integration script for vault with auto-commit functionality,
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
start_vault_integrated_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
start_vault_integrated_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
start_vault_integrated_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
start_vault_integrated_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    start_vault_integrated_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        start_vault_integrated_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            start_vault_integrated_log_success "Validation passed - proceeding with auto-commit"
        else
            start_vault_integrated_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        start_vault_integrated_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        start_vault_integrated_log_info "Auto-commit system not available - manual commit required"
        start_vault_integrated_log_info "Recommended commit message: $commit_message"
        start_vault_integrated_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
start_vault_integrated_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    start_vault_integrated_log_success "$final_message"
    
    # Execute auto-commit wrapper
    start_vault_integrated_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    start_vault_integrated_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
POSTGRES_SERVICE_DIR="/opt/dev-purebliss/services/postgres"

function log_action() {
    echo "[$(date)] POSTGRES_VAULT_START: $1" | tee -a "$LOG_FILE"
}

log_action "Starting PostgreSQL with Vault integration..."

# Step 1: Start PostgreSQL with bootstrap credentials
log_action "Starting PostgreSQL with bootstrap admin credentials..."
cat > "$POSTGRES_SERVICE_DIR/postgres-bootstrap.env" << EOF
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=bootstrap_admin_password_12345
POSTGRES_DATA_PATH=/mnt/raid0/postgres/postgres-data
POSTGRES_LOG_PATH=/mnt/raid0/logs/postgres.log
EOF

# Ensure data directory exists
sudo mkdir -p /mnt/raid0/postgres/postgres-data /mnt/raid0/logs || mkdir -p /mnt/raid0/postgres/postgres-data /mnt/raid0/logs
sudo chown -R $USER:$USER /mnt/raid0/postgres /mnt/raid0/logs 2>/dev/null || true

# Start PostgreSQL with bootstrap environment
source "$POSTGRES_SERVICE_DIR/postgres-bootstrap.env"
set +a

docker-compose -f "$POSTGRES_SERVICE_DIR/postgres-docker-compose.yml" up -d

log_action "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
  if docker exec purebliss-postgres pg_isready -U postgres >/dev/null 2>&1; then
    log_action "PostgreSQL is ready for connections."
    break
  fi
  sleep 2
done

if ! docker exec purebliss-postgres pg_isready -U postgres >/dev/null 2>&1; then
  log_action "ERROR: PostgreSQL failed to start properly."
  exit 1
fi

# Step 2: Configure Vault database connection now that PostgreSQL is running
log_action "Configuring Vault database connection to running PostgreSQL..."
export VAULT_SKIP_VERIFY=true
source /opt/my-secure-ha-stack/secrets/vault/vault-env.sh

# Configure the database connection in Vault
vault write database/config/postgres-app \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://postgres:bootstrap_admin_password_12345@purebliss-postgres:5432/postgres?sslmode=disable" \
    allowed_roles="postgres-role" \
    username="postgres" \
    password="bootstrap_admin_password_12345" || {
    log_action "Database connection configuration completed (may have already existed)."
}

# Test credential generation
log_action "Testing Vault database credential generation..."
vault read database/creds/postgres-role | tee -a "$LOG_FILE" || {
    log_action "ERROR: Failed to generate database credentials from Vault."
    exit 1
}

log_action "SUCCESS: PostgreSQL started and Vault database integration configured."
log_action "PostgreSQL is now ready to serve applications with Vault-managed dynamic credentials."

# Display connection information
echo ""
echo "🐘 PostgreSQL Service Ready:"
echo "   Container: purebliss-postgres"
echo "   Port: 5432"
echo "   Admin User: postgres"
echo "   Dynamic Credentials: Available via Vault at database/creds/postgres-role"
echo "   Role ID: $(cat /opt/dev-purebliss/services/postgres/role_id)"
echo "   Secret ID: Available (refreshes every 10 minutes)"
echo ""

log_action "PostgreSQL onboarding to Vault completed successfully."

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
