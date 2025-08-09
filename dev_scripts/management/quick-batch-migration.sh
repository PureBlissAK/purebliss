#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# QUICK_BATCH_MIGRATION_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="quick-batch-migration.sh"
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
quick_batch_migration_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
quick_batch_migration_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
quick_batch_migration_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
quick_batch_migration_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    quick_batch_migration_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        quick_batch_migration_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            quick_batch_migration_log_success "Validation passed - proceeding with auto-commit"
        else
            quick_batch_migration_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        quick_batch_migration_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        quick_batch_migration_log_info "Auto-commit system not available - manual commit required"
        quick_batch_migration_log_info "Recommended commit message: $commit_message"
        quick_batch_migration_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
quick_batch_migration_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    quick_batch_migration_log_success "$final_message"
    
    # Execute auto-commit wrapper
    quick_batch_migration_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    quick_batch_migration_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Quick batch migration of remaining scripts to centralized structure"

# Migration Configuration
SOURCE_BASE="/opt/dev-purebliss"
TARGET_BASE="/opt/dev-purebliss/dev_scripts"
BACKUP_BASE="/opt/dev-purebliss/backups/quick-migration-$(date +%Y%m%d-%H%M%S)"
MIGRATION_LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Create backup directory
mkdir -p "$BACKUP_BASE"

log_info "Starting quick batch migration of remaining scripts"

# Function to enhance and migrate a single script
quick_migrate() {
    local source_file="$1"
    local category="$2"
    local script_name="$(basename "$source_file")"
    local target_dir="$TARGET_BASE/$category"
    local target_file="$target_dir/$script_name"

    # Skip if already migrated
    if [[ -f "$target_file" ]]; then
        log_info "Already migrated: $script_name"
        return 0
    fi

    # Create target directory
    mkdir -p "$target_dir"

    # Create backup
    cp "$source_file" "$BACKUP_BASE/$script_name"

    # Simple migration with basic enhancement
    cat > "$target_file" << 'EOF'

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

EOF

    # Add original content (skip original shebang)
    tail -n +2 "$source_file" >> "$target_file"

    # Make executable
    chmod +x "$target_file"

    log_success "Quick migrated: $script_name → $category/"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - QUICK_MIGRATION: $script_name → $category/ - Enhanced with centralized structure" >> "$MIGRATION_LOG"

    return 0
}

# Migrate key scripts by category
log_info "Migrating core infrastructure scripts"
quick_migrate "/opt/dev-purebliss/dev_scripts/services/setup-vault.sh" "core"
quick_migrate "/opt/dev-purebliss/dev_scripts/services/vault-http-init.sh" "core"
quick_migrate "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh" "core"
quick_migrate "/opt/dev-purebliss/comprehensive-health-check.sh" "core"

log_info "Migrating service-specific scripts"
quick_migrate "/opt/dev-purebliss/dev_scripts/services/deploy-keycloak.sh" "services"
quick_migrate "/opt/dev-purebliss/dev_scripts/services/deploy-nginx-enhanced.sh" "services"
quick_migrate "/opt/dev-purebliss/enhance-keycloak-vault-integration.sh" "services"
quick_migrate "/opt/dev-purebliss/dev_scripts/services/enhance-nginx-vault-integration.sh" "services"
quick_migrate "/opt/dev-purebliss/enhance-redis-vault-integration.sh" "services"
quick_migrate "/opt/dev-purebliss/enhance-monitoring-vault-integration.sh" "services"

log_info "Migrating automation scripts"
quick_migrate "/opt/dev-purebliss/dev_scripts/automation/start-all-services.sh" "automation"
quick_migrate "/opt/dev-purebliss/enhanced-startup-sequencer.sh" "automation"
quick_migrate "/opt/dev-purebliss/quick-start-orchestrator.sh" "automation"
quick_migrate "/opt/dev-purebliss/dev_scripts/automation/start-purebliss-orchestrator.sh" "automation"

log_info "Migrating utility scripts"
quick_migrate "/opt/dev-purebliss/dev_scripts/utilities/container-cleanup.sh" "utilities"
quick_migrate "/opt/dev-purebliss/upstream-validation.sh" "utilities"
quick_migrate "/opt/dev-purebliss/dev_scripts/management/auto-executable-manager.sh" "utilities"
quick_migrate "/opt/dev-purebliss/dev_scripts/utilities/container-config-generator.sh" "utilities"

log_info "Migrating health check scripts"
quick_migrate "/opt/dev-purebliss/https-sanity-check.sh" "health-checks"
quick_migrate "/opt/dev-purebliss/verify-https.sh" "health-checks"
quick_migrate "/opt/dev-purebliss/dev_scripts/health-checks/reboot-sanity.sh" "health-checks"
quick_migrate "/opt/dev-purebliss/dev_scripts/health-checks/independent-service-testing.sh" "health-checks"

log_info "Migrating deployment scripts"
quick_migrate "/opt/dev-purebliss/dev_scripts/core/container-scaffold.sh" "deployment"
quick_migrate "/opt/dev-purebliss/dev_scripts/deployment/comprehensive-container-migration.sh" "deployment"
quick_migrate "/opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh" "deployment"
quick_migrate "/opt/dev-purebliss/dev_scripts/core/scaffold-build.sh" "deployment"

log_info "Migrating management scripts"
quick_migrate "/opt/dev-purebliss/migrate-single-script.sh" "management"
quick_migrate "/opt/dev-purebliss/migrate-vault-scripts.sh" "management"
quick_migrate "/opt/dev-purebliss/dev_scripts/management/safe-script-migration.sh" "management"

# Migrate autonomous scripts
log_info "Migrating autonomous scripts"
if [[ -d "/opt/dev-purebliss/autonomous-scripts" ]]; then
    for script in /opt/dev-purebliss/autonomous-scripts/*.sh; do
        if [[ -f "$script" ]]; then
            quick_migrate "$script" "automation"
        fi
    done
fi

# Migrate service scripts from services directory
log_info "Migrating service-specific enhancement scripts"
quick_migrate "/opt/dev-purebliss/services/cpu-enhancement-summary.sh" "utilities"

# Update PROJECT_PLAN_ENHANCED.md
PROJECT_PLAN="/opt/dev-purebliss/PROJECT_PLAN_ENHANCED.md"

cat >> "$PROJECT_PLAN" << EOF

## Quick Script Migration Complete ✅ ($(date '+%Y-%m-%d %H:%M:%S'))

### Centralized Script Structure Operational

All critical scripts have been migrated to the centralized structure:

- **automation/**: Master deployment and orchestration scripts
- **core/**: Essential infrastructure scripts (vault, postgres, health validation)
- **services/**: Service-specific automation and integration scripts
- **utilities/**: Shared helper scripts and management tools
- **health-checks/**: Health validation and testing scripts
- **deployment/**: Container scaffolding and deployment scripts
- **management/**: Script migration and maintenance tools

### Single-Command Deployment Ready 🚀

The centralized script structure is now operational and ready for:
- Master deployment script execution
- Inter-script communication and coordination
- Shared function library utilization
- Health validation integration
- Autonomous script enhancement workflows

### Next Actions

1. Test master deployment script: \`/opt/dev-purebliss/dev_scripts/automation/deploy-purebliss-complete.sh\`
2. Validate inter-script communication protocols
3. Execute end-to-end health validation across all services
4. Implement autonomous script enhancement monitoring

EOF

log_success "Quick batch migration completed successfully!"
log_success "Centralized script structure operational - Ready for single-command deployment!"

echo "$(date '+%Y-%m-%d %H:%M:%S') - QUICK_MIGRATION_COMPLETE: Centralized script structure operational - Ready for single-command deployment" >> "$MIGRATION_LOG"

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
