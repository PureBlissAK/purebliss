#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# MIGRATE_VAULT_SCRIPTS_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="migrate-vault-scripts.sh"
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
migrate_vault_scripts_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
migrate_vault_scripts_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
migrate_vault_scripts_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
migrate_vault_scripts_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    migrate_vault_scripts_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        migrate_vault_scripts_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            migrate_vault_scripts_log_success "Validation passed - proceeding with auto-commit"
        else
            migrate_vault_scripts_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        migrate_vault_scripts_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        migrate_vault_scripts_log_info "Auto-commit system not available - manual commit required"
        migrate_vault_scripts_log_info "Recommended commit message: $commit_message"
        migrate_vault_scripts_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
migrate_vault_scripts_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    migrate_vault_scripts_log_success "$final_message"
    
    # Execute auto-commit wrapper
    migrate_vault_scripts_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    migrate_vault_scripts_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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

# Vault Script Migration to Centralized Location
# Pure Bliss Elite Framework - Safe Additive Migration


# Centralized paths
CENTRAL_VAULT_DIR="/opt/dev-purebliss/dev_scripts/services/vault"
SOURCE_VAULT_DIR="/opt/dev-purebliss/services/vault"
BACKUP_DIR="/opt/dev-purebliss/services/vault/backup"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_SCRIPT_MIGRATION: $1" | tee -a "$LOG_FILE"
}

# Pre-migration health check
log_action "Starting Vault script migration with health validation"

# Create centralized directory structure
mkdir -p "$CENTRAL_VAULT_DIR"/{automation,deployment,health-checks,configuration,legacy}
mkdir -p "$BACKUP_DIR"

log_action "Created centralized directory structure for Vault scripts"

# Define script categories and migration mapping
declare -A SCRIPT_CATEGORIES=(
    ["vault-init-automation.sh"]="automation"
    ["vault-auto-unseal.sh"]="automation"
    ["vault-simple-unseal.sh"]="automation"
    ["vault-dev-init.sh"]="automation"
    ["vault-break-fix.sh"]="automation"
    ["vault-manual-permissions-fix.sh"]="automation"
    ["vault-setup-tls.sh"]="automation"
    ["test-vault-init.sh"]="health-checks"
    ["entrypoint.sh"]="deployment"
    ["vault-dockerfile"]="deployment"
    ["vault-docker-compose.yml"]="deployment"
    ["vault.hcl"]="configuration"
    ["config.hcl"]="configuration"
    ["myconfig.hcl"]="configuration"
    ["vault-dev.hcl"]="configuration"
    ["dev-policy.hcl"]="configuration"
    [".env"]="configuration"
)

# Migration function
migrate_script() {
    local script_name="$1"
    local category="$2"
    local source_path="$SOURCE_VAULT_DIR/$script_name"
    local target_path="$CENTRAL_VAULT_DIR/$category/$script_name"

    if [[ -f "$source_path" ]]; then
        # Copy to centralized location (safe additive migration)
        cp "$source_path" "$target_path"
        chmod +x "$target_path" 2>/dev/null || true
        log_action "✅ Migrated $script_name to centralized location: $category/$script_name"

        # Move original to backup (preserve originals)
        mv "$source_path" "$BACKUP_DIR/"
        log_action "📦 Backed up original $script_name to backup directory"
    else
        log_action "⚠️  Script not found: $script_name"
    fi
}

# Execute migration for categorized scripts
log_action "Starting systematic script migration..."

for script in "${!SCRIPT_CATEGORIES[@]}"; do
    migrate_script "$script" "${SCRIPT_CATEGORIES[$script]}"
done

# Handle directories specially
if [[ -d "$SOURCE_VAULT_DIR/vault-agent" ]]; then
    cp -r "$SOURCE_VAULT_DIR/vault-agent" "$CENTRAL_VAULT_DIR/deployment/"
    mv "$SOURCE_VAULT_DIR/vault-agent" "$BACKUP_DIR/"
    log_action "✅ Migrated vault-agent directory to deployment"
fi

if [[ -d "$SOURCE_VAULT_DIR/vault-agent-config" ]]; then
    cp -r "$SOURCE_VAULT_DIR/vault-agent-config" "$CENTRAL_VAULT_DIR/configuration/"
    mv "$SOURCE_VAULT_DIR/vault-agent-config" "$BACKUP_DIR/"
    log_action "✅ Migrated vault-agent-config directory to configuration"
fi

if [[ -d "$SOURCE_VAULT_DIR/certs" ]]; then
    cp -r "$SOURCE_VAULT_DIR/certs" "$CENTRAL_VAULT_DIR/configuration/"
    mv "$SOURCE_VAULT_DIR/certs" "$BACKUP_DIR/"
    log_action "✅ Migrated certs directory to configuration"
fi

# Migrate documentation
if [[ -f "$SOURCE_VAULT_DIR/VAULT_AUTOMATION_GUIDE.md" ]]; then
    cp "$SOURCE_VAULT_DIR/VAULT_AUTOMATION_GUIDE.md" "$CENTRAL_VAULT_DIR/"
    mv "$SOURCE_VAULT_DIR/VAULT_AUTOMATION_GUIDE.md" "$BACKUP_DIR/"
    log_action "✅ Migrated VAULT_AUTOMATION_GUIDE.md"
fi

if [[ -f "$SOURCE_VAULT_DIR/BEST_PRACTICES.md" ]]; then
    cp "$SOURCE_VAULT_DIR/BEST_PRACTICES.md" "$CENTRAL_VAULT_DIR/"
    mv "$SOURCE_VAULT_DIR/BEST_PRACTICES.md" "$BACKUP_DIR/"
    log_action "✅ Migrated BEST_PRACTICES.md"
fi

if [[ -f "$SOURCE_VAULT_DIR/vault-break-fix-report.md" ]]; then
    cp "$SOURCE_VAULT_DIR/vault-break-fix-report.md" "$CENTRAL_VAULT_DIR/"
    mv "$SOURCE_VAULT_DIR/vault-break-fix-report.md" "$BACKUP_DIR/"
    log_action "✅ Migrated vault-break-fix-report.md"
fi

# Move remaining files to legacy
for item in "$SOURCE_VAULT_DIR"/*; do
    if [[ -e "$item" ]] && [[ "$(basename "$item")" != "backup" ]]; then
        cp -r "$item" "$CENTRAL_VAULT_DIR/legacy/"
        mv "$item" "$BACKUP_DIR/"
        log_action "📦 Moved $(basename "$item") to legacy and backup"
    fi
done

# Create reference update script
cat > "$CENTRAL_VAULT_DIR/update-vault-script-references.sh" << 'SCRIPT_EOF'
# Update all references to vault scripts to use centralized paths

CENTRAL_BASE="/opt/dev-purebliss/dev_scripts/services/vault"

# Update common script references in other files
find /opt/dev-purebliss -name "*.sh" -type f -exec sed -i "s|/opt/dev-purebliss/services/vault/vault-init-automation.sh|${CENTRAL_BASE}/automation/vault-init-automation.sh|g" {} \;
find /opt/dev-purebliss -name "*.sh" -type f -exec sed -i "s|/opt/dev-purebliss/services/vault/vault-auto-unseal.sh|${CENTRAL_BASE}/automation/vault-auto-unseal.sh|g" {} \;
find /opt/dev-purebliss -name "*.sh" -type f -exec sed -i "s|/opt/dev-purebliss/services/vault/test-vault-init.sh|${CENTRAL_BASE}/health-checks/test-vault-init.sh|g" {} \;

echo "Updated vault script references to centralized locations"
SCRIPT_EOF

chmod +x "$CENTRAL_VAULT_DIR/update-vault-script-references.sh"

log_action "✅ Created reference update script"

# Generate migration summary
cat > "$CENTRAL_VAULT_DIR/MIGRATION_SUMMARY.md" << 'DOC_EOF'
# Vault Script Migration Summary

## Migration Date
$(date '+%Y-%m-%d %H:%M:%S')

## Migration Strategy
- Safe Additive Migration (no destruction)
- Original files preserved in backup directory
- Centralized organization by functionality

## Directory Structure
```
/opt/dev-purebliss/dev_scripts/services/vault/
├── automation/          # Automated deployment and management scripts
├── deployment/          # Container and service deployment
├── health-checks/       # Validation and testing scripts
├── configuration/       # Configuration files and templates
├── legacy/              # Legacy files and deprecated scripts
├── VAULT_AUTOMATION_GUIDE.md
├── BEST_PRACTICES.md
├── vault-break-fix-report.md
└── update-vault-script-references.sh
```

## Scripts by Category

### Automation Scripts
- vault-init-automation.sh
- vault-auto-unseal.sh
- vault-simple-unseal.sh
- vault-dev-init.sh
- vault-break-fix.sh
- vault-manual-permissions-fix.sh
- vault-setup-tls.sh

### Health Check Scripts
- test-vault-init.sh

### Deployment Scripts
- entrypoint.sh
- vault-dockerfile
- vault-docker-compose.yml
- vault-agent/ (directory)

### Configuration Files
- vault.hcl
- config.hcl
- myconfig.hcl
- vault-dev.hcl
- dev-policy.hcl
- .env
- vault-agent-config/ (directory)
- certs/ (directory)

## Usage
To use centralized scripts, reference them by their new paths:
```bash
# Example: Initialize Vault
/opt/dev-purebliss/dev_scripts/services/vault/automation/vault-init-automation.sh

# Example: Health check
/opt/dev-purebliss/dev_scripts/services/vault/health-checks/test-vault-init.sh
```

## Rollback
All original files are preserved in:
/opt/dev-purebliss/services/vault/backup/

To rollback, copy files back from backup directory.
DOC_EOF

log_action "✅ Generated migration summary documentation"

# Final validation
log_action "Migration completed successfully. Running validation..."

# Count migrated files
MIGRATED_COUNT=$(find "$CENTRAL_VAULT_DIR" -type f | wc -l)
BACKUP_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)

log_action "📊 Migration Summary: $MIGRATED_COUNT files in centralized location, $BACKUP_COUNT files backed up"

echo "✅ Vault script migration completed successfully!"
echo "📍 Centralized location: $CENTRAL_VAULT_DIR"
echo "📦 Backup location: $BACKUP_DIR"
echo "📋 See migration summary: $CENTRAL_VAULT_DIR/MIGRATION_SUMMARY.md"

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
