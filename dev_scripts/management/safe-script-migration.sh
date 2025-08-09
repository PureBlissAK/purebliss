#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SAFE_SCRIPT_MIGRATION_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="safe-script-migration.sh"
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
safe_script_migration_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
safe_script_migration_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
safe_script_migration_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
safe_script_migration_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    safe_script_migration_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        safe_script_migration_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            safe_script_migration_log_success "Validation passed - proceeding with auto-commit"
        else
            safe_script_migration_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        safe_script_migration_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        safe_script_migration_log_info "Auto-commit system not available - manual commit required"
        safe_script_migration_log_info "Recommended commit message: $commit_message"
        safe_script_migration_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
safe_script_migration_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    safe_script_migration_log_success "$final_message"
    
    # Execute auto-commit wrapper
    safe_script_migration_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    safe_script_migration_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Safe Script Migration to Centralized Repository
# CRITICAL: MOVES scripts only - NO DELETIONS
# All scripts are preserved and moved to appropriate centralized locations


# Centralized script repository
CENTRAL_REPO="/opt/dev-purebliss/dev_scripts"
MIGRATION_LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
MIGRATION_BACKUP="/opt/dev-purebliss/script-migration-backup-$(date +%Y%m%d-%H%M%S)"

# Create timestamped log entry
log_migration() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_MIGRATION: $1" >> "$MIGRATION_LOG"
}

# Create backup directory for safety
create_migration_backup() {
    log_migration "Creating migration backup directory: $MIGRATION_BACKUP"
    mkdir -p "$MIGRATION_BACKUP"

    # Copy all scripts to backup before migration
    find /opt/dev-purebliss -maxdepth 1 -name "*.sh" -type f -exec cp {} "$MIGRATION_BACKUP"/ \;
    log_migration "Backup created with $(ls "$MIGRATION_BACKUP" | wc -l) scripts"
}

# Ensure centralized directory structure exists
ensure_central_structure() {
    log_migration "Ensuring centralized directory structure exists"

    local directories=(
        "$CENTRAL_REPO/core"
        "$CENTRAL_REPO/services/vault"
        "$CENTRAL_REPO/services/postgres"
        "$CENTRAL_REPO/services/redis"
        "$CENTRAL_REPO/services/nginx"
        "$CENTRAL_REPO/services/keycloak"
        "$CENTRAL_REPO/services/grafana"
        "$CENTRAL_REPO/services/prometheus"
        "$CENTRAL_REPO/services/loki"
        "$CENTRAL_REPO/services/plane"
        "$CENTRAL_REPO/services/codeserver"
        "$CENTRAL_REPO/services/letsencrypt"
        "$CENTRAL_REPO/automation"
        "$CENTRAL_REPO/deployment"
        "$CENTRAL_REPO/health-checks"
        "$CENTRAL_REPO/utilities"
        "$CENTRAL_REPO/legacy"
    )

    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        log_migration "Created directory: $dir"
    done
}

# Safe move function with validation
safe_move() {
    local source="$1"
    local destination="$2"
    local script_name=$(basename "$source")

    if [[ ! -f "$source" ]]; then
        log_migration "WARNING: Source script not found: $source"
        return 1
    fi

    if [[ -f "$destination" ]]; then
        log_migration "WARNING: Destination exists, creating versioned copy: $destination"
        destination="${destination}.$(date +%Y%m%d-%H%M%S)"
    fi

    # Move script (preserve original until validation)
    cp "$source" "$destination"
    chmod +x "$destination"

    # Validate moved script
    if [[ -f "$destination" && -x "$destination" ]]; then
        log_migration "SUCCESS: Moved $script_name -> $destination"
        rm "$source"  # Only remove source after successful move and validation
        return 0
    else
        log_migration "ERROR: Failed to move $script_name"
        return 1
    fi
}

# Migration mapping based on script analysis
migrate_core_scripts() {
    log_migration "Migrating core infrastructure scripts"

    # Core infrastructure scripts
    safe_move "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh" "$CENTRAL_REPO/core/validate-container-health.sh"
    safe_move "/opt/dev-purebliss/upstream-validation.sh" "$CENTRAL_REPO/core/upstream-validation.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/core/container-scaffold.sh" "$CENTRAL_REPO/core/container-scaffold.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/automation/start-all-services.sh" "$CENTRAL_REPO/core/start-all-services.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/automation/start-all.sh" "$CENTRAL_REPO/core/start-all.sh"
    safe_move "/opt/dev-purebliss/enhanced-startup-sequencer.sh" "$CENTRAL_REPO/core/enhanced-startup-sequencer.sh"
    safe_move "/opt/dev-purebliss/quick-start-orchestrator.sh" "$CENTRAL_REPO/core/quick-start-orchestrator.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/automation/start-purebliss-orchestrator.sh" "$CENTRAL_REPO/core/start-purebliss-orchestrator.sh"
}

migrate_automation_scripts() {
    log_migration "Migrating automation and enhancement scripts"

    # Automation scripts
    safe_move "/opt/dev-purebliss/dev_scripts/utilities/container-cleanup.sh" "$CENTRAL_REPO/automation/container-cleanup.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh" "$CENTRAL_REPO/automation/enhance-container-with-vault.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/management/auto-executable-manager.sh" "$CENTRAL_REPO/automation/auto-executable-manager.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/utilities/container-config-generator.sh" "$CENTRAL_REPO/automation/container-config-generator.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/services/script-enhancements-keycloak-containers.sh" "$CENTRAL_REPO/automation/script-enhancements-keycloak-containers.sh"
}

migrate_service_scripts() {
    log_migration "Migrating service-specific scripts"

    # Vault scripts
    safe_move "/opt/dev-purebliss/dev_scripts/services/setup-vault.sh" "$CENTRAL_REPO/services/vault/setup-vault.sh"
    safe_move "/opt/dev-purebliss/show-vault-integrations.sh" "$CENTRAL_REPO/services/vault/show-vault-integrations.sh"

    # Nginx scripts
    safe_move "/opt/dev-purebliss/deploy-nginx-basic.sh" "$CENTRAL_REPO/services/nginx/deploy-nginx-basic.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/services/deploy-nginx-enhanced.sh" "$CENTRAL_REPO/services/nginx/deploy-nginx-enhanced.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/services/enhance-nginx-vault-integration.sh" "$CENTRAL_REPO/services/nginx/enhance-nginx-vault-integration.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/services/test-nginx-independent-startup.sh" "$CENTRAL_REPO/services/nginx/test-nginx-independent-startup.sh"

    # Keycloak scripts
    safe_move "/opt/dev-purebliss/dev_scripts/services/deploy-keycloak.sh" "$CENTRAL_REPO/services/keycloak/deploy-keycloak.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/services/fix-keycloak-database-auth.sh" "$CENTRAL_REPO/services/keycloak/fix-keycloak-database-auth.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/services/simple-keycloak-auth-fix.sh" "$CENTRAL_REPO/services/keycloak/simple-keycloak-auth-fix.sh"
    safe_move "/opt/dev-purebliss/enhance-keycloak-vault-integration.sh" "$CENTRAL_REPO/services/keycloak/enhance-keycloak-vault-integration.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/independent-keycloak-dependency-test.sh" "$CENTRAL_REPO/services/keycloak/independent-keycloak-dependency-test.sh"

    # Redis scripts
    safe_move "/opt/dev-purebliss/enhance-redis-vault-integration.sh" "$CENTRAL_REPO/services/redis/enhance-redis-vault-integration.sh"

    # Monitoring scripts
    safe_move "/opt/dev-purebliss/enhance-monitoring-vault-integration.sh" "$CENTRAL_REPO/services/grafana/enhance-monitoring-vault-integration.sh"
}

migrate_utility_scripts() {
    log_migration "Migrating utility and testing scripts"

    # Health check scripts
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh" "$CENTRAL_REPO/health-checks/comprehensive-health-check.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/health-validation-integration-example.sh" "$CENTRAL_REPO/health-checks/health-validation-integration-example.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/https-sanity-check.sh" "$CENTRAL_REPO/health-checks/https-sanity-check.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/verify-https.sh" "$CENTRAL_REPO/health-checks/verify-https.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/reboot-sanity.sh" "$CENTRAL_REPO/health-checks/reboot-sanity.sh"

    # Utility scripts
    safe_move "/opt/dev-purebliss/dev_scripts/utilities/retry-utils.sh" "$CENTRAL_REPO/utilities/retry-utils.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/utilities/service-entrypoint-template.sh" "$CENTRAL_REPO/utilities/service-entrypoint-template.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/validate-service-dependencies.sh" "$CENTRAL_REPO/utilities/validate-service-dependencies.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/health-checks/independent-service-testing.sh" "$CENTRAL_REPO/utilities/independent-service-testing.sh"
    safe_move "/opt/dev-purebliss/dev_scripts/core/scaffold-build.sh" "$CENTRAL_REPO/utilities/scaffold-build.sh"
}

# Create reference update script
create_reference_updater() {
    log_migration "Creating reference update script for container code"

    cat > "$CENTRAL_REPO/utilities/update-script-references.sh" << 'EOF'

# Update Container Script References
# Updates all container code to reference centralized scripts


CENTRAL_REPO="/opt/dev-purebliss/dev_scripts"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_update() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - REFERENCE_UPDATE: $1" >> "$LOG_FILE"
}

# Update Dockerfile references
update_dockerfile_references() {
    log_update "Updating Dockerfile script references"

    # Find all Dockerfiles and update script paths
    find /opt/my-secure-ha-stack -name "*dockerfile*" -type f | while read dockerfile; do
        if grep -q "/opt/dev-purebliss/.*\.sh" "$dockerfile"; then
            log_update "Updating references in: $dockerfile"
            # This will be implemented per-service as we migrate
        fi
    done
}

# Update docker-compose references
update_compose_references() {
    log_update "Updating docker-compose script references"

    if [[ -f "/opt/my-secure-ha-stack/docker-compose.yml" ]]; then
        # Update any script references in docker-compose
        log_update "Checking docker-compose.yml for script references"
    fi
}

log_update "Reference updater script created - ready for per-service implementation"
EOF

    chmod +x "$CENTRAL_REPO/utilities/update-script-references.sh"
    log_migration "Reference updater script created and executable"
}

# Main migration execution
main() {
    log_migration "=== STARTING SAFE SCRIPT MIGRATION ==="
    log_migration "Policy: MOVE ONLY - NO DELETIONS"

    echo "Starting safe script migration..."
    echo "Policy: MOVE scripts to centralized locations - NO DELETIONS"

    # Create backup first
    create_migration_backup

    # Ensure directory structure
    ensure_central_structure

    # Execute migrations in phases
    migrate_core_scripts
    migrate_automation_scripts
    migrate_service_scripts
    migrate_utility_scripts

    # Create reference updater
    create_reference_updater

    # Final validation
    local remaining_scripts=$(find /opt/dev-purebliss -maxdepth 1 -name "*.sh" -type f | wc -l)
    local centralized_scripts=$(find "$CENTRAL_REPO" -name "*.sh" -type f | wc -l)

    log_migration "Migration complete:"
    log_migration "  - Remaining in root: $remaining_scripts scripts"
    log_migration "  - Centralized scripts: $centralized_scripts scripts"
    log_migration "  - Backup location: $MIGRATION_BACKUP"
    log_migration "=== SAFE SCRIPT MIGRATION COMPLETE ==="

    echo "Migration complete!"
    echo "Remaining scripts in root: $remaining_scripts"
    echo "Centralized scripts: $centralized_scripts"
    echo "Backup saved to: $MIGRATION_BACKUP"
}

# Execute migration
main "$@"

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
