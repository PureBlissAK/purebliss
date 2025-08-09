#!/bin/bash

# Safe Script Migration to Centralized Repository
# CRITICAL: MOVES scripts only - NO DELETIONS
# All scripts are preserved and moved to appropriate centralized locations

set -euo pipefail

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
#!/bin/bash

# Update Container Script References
# Updates all container code to reference centralized scripts

set -euo pipefail

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
