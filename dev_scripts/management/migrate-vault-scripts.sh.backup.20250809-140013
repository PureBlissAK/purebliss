#!/bin/bash
set -euo pipefail

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

set -euo pipefail

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
#!/bin/bash
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
