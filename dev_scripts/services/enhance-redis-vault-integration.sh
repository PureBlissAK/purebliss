#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# ENHANCE_REDIS_VAULT_INTEGRATION_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="enhance-redis-vault-integration.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced validation script for redis operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="validation"
SCRIPT_TAGS="enhancement,automation,auto-commit,vault,security"
SCRIPT_SERVICES="redis"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced validation script for redis with auto-commit functionality,
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
enhance_redis_vault_integration_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
enhance_redis_vault_integration_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
enhance_redis_vault_integration_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
enhance_redis_vault_integration_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    enhance_redis_vault_integration_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        enhance_redis_vault_integration_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            enhance_redis_vault_integration_log_success "Validation passed - proceeding with auto-commit"
        else
            enhance_redis_vault_integration_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        enhance_redis_vault_integration_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        enhance_redis_vault_integration_log_info "Auto-commit system not available - manual commit required"
        enhance_redis_vault_integration_log_info "Recommended commit message: $commit_message"
        enhance_redis_vault_integration_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
enhance_redis_vault_integration_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    enhance_redis_vault_integration_log_success "$final_message"
    
    # Execute auto-commit wrapper
    enhance_redis_vault_integration_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    enhance_redis_vault_integration_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utilities/retry-utils.sh" 2>/dev/null || true

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="[Enhanced with centralized structure]"


# Redis Vault Integration Enhancement Script
# Configures Redis with Vault database plugin for dynamic credential management
# Priority: Next after PostgreSQL completion
# Last Updated: August 5, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] REDIS_ENHANCE: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] REDIS_ENHANCE: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] REDIS_ENHANCE: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

function main() {
    log_action "Starting Redis Vault integration enhancement..."

    # Use universal enhancement script with Redis-specific configuration
    if [[ -x "/opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh" ]]; then
        /opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh redis database_dynamic
    else
        log_error "Universal enhancement script not found"
        exit 1
    fi

    # Redis-specific post-enhancement configuration
    log_action "Applying Redis-specific configurations..."

    # Create Redis-specific database plugin configuration
    create_redis_database_plugin_config

    # Create Redis monitoring configuration
    create_redis_monitoring_config

    log_success "Redis Vault integration enhancement completed!"
}

function create_redis_database_plugin_config() {
    log_action "Creating Redis database plugin configuration..."

    local redis_dir="/opt/dev-purebliss/services/redis"
    local config_file="$redis_dir/redis-vault-database-config.sh"

    cat > "$config_file" << 'EOF'
# Redis Database Plugin Configuration for Vault
# Configures Vault to manage Redis dynamic credentials

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1
export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

# Enable Redis database secrets engine
log_action "Enabling Redis database secrets engine..."
vault secrets enable -path=redis database

# Configure Redis connection
log_action "Configuring Redis database connection..."
vault write redis/config/redis \
    plugin_name=redis-database-plugin \
    connection_url="redis://purebliss-redis:6379" \
    allowed_roles="redis-role" \
    max_open_connections=5 \
    max_idle_connections=0 \
    max_connection_lifetime="1h"

# Create Redis role for dynamic credentials
log_action "Creating Redis role for dynamic credentials..."
vault write redis/roles/redis-role \
    db_name=redis \
    creation_statements='["~*", "&*", "+@all", "-@dangerous"]' \
    default_ttl="1h" \
    max_ttl="24h"

log_success "Redis database plugin configuration completed"
EOF

    chmod +x "$config_file"
    log_success "Redis database plugin configuration script created"
}

function create_redis_monitoring_config() {
    log_action "Creating Redis monitoring configuration..."

    local redis_dir="/opt/dev-purebliss/services/redis"
    local monitor_file="$redis_dir/redis-vault-monitoring.yml"

    cat > "$monitor_file" << 'EOF'
# Redis Monitoring Configuration for Vault Integration
# Prometheus metrics and health checks for Redis with Vault

redis_monitoring:
  metrics:
    enabled: true
    port: 6379
    auth: vault-managed
  health_checks:
    - name: redis_ping
      command: "redis-cli ping"
      expected: "PONG"
    - name: vault_connectivity
      command: "nc -z purebliss-vault 8200"
      expected: "success"
    - name: dynamic_credentials
      command: "vault read redis/creds/redis-role"
      expected: "credentials_generated"
  alerts:
    - name: redis_down
      condition: "redis_ping != PONG"
      severity: critical
    - name: vault_integration_failed
      condition: "dynamic_credentials == failed"
      severity: high
EOF

    log_success "Redis monitoring configuration created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

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
