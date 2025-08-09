#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# MIGRATE_SINGLE_SCRIPT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="migrate-single-script.sh"
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
migrate_single_script_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
migrate_single_script_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
migrate_single_script_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
migrate_single_script_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    migrate_single_script_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        migrate_single_script_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            migrate_single_script_log_success "Validation passed - proceeding with auto-commit"
        else
            migrate_single_script_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        migrate_single_script_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        migrate_single_script_log_info "Auto-commit system not available - manual commit required"
        migrate_single_script_log_info "Recommended commit message: $commit_message"
        migrate_single_script_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
migrate_single_script_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    migrate_single_script_log_success "$final_message"
    
    # Execute auto-commit wrapper
    migrate_single_script_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    migrate_single_script_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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


# Safe Single Script Migration with Infrastructure Testing
# Migrates ONE script at a time with immediate container testing
# CRITICAL: Tests infrastructure after each migration to ensure 100% functionality


CENTRAL_REPO="/opt/dev-purebliss/dev_scripts"
MIGRATION_LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Log function
log_migration() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SINGLE_SCRIPT_MIGRATION: $1" >> "$MIGRATION_LOG"
    echo "$1"
}

# Create backup before migration
create_script_backup() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    local backup_path="/opt/dev-purebliss/backup-${script_name}-$(date +%Y%m%d-%H%M%S)"

    if [[ -f "$script_path" ]]; then
        cp "$script_path" "$backup_path"
        log_migration "Created backup: $backup_path"
        echo "$backup_path"  # Return backup path
    else
        log_migration "ERROR: Script not found: $script_path"
        return 1
    fi
}

# Safe script migration with immediate testing
migrate_single_script() {
    local source_script="$1"
    local target_path="$2"
    local affected_services="$3"  # Space-separated list of services to test

    local script_name=$(basename "$source_script")
    log_migration "Starting migration: $script_name"
    log_migration "Source: $source_script"
    log_migration "Target: $target_path"
    log_migration "Affected services: $affected_services"

    # Step 1: Create backup
    local backup_path
    backup_path=$(create_script_backup "$source_script")

    # Step 2: Ensure target directory exists
    mkdir -p "$(dirname "$target_path")"

    # Step 3: Copy script to new location (don't delete original yet)
    cp "$source_script" "$target_path"
    chmod +x "$target_path"
    log_migration "Copied script to: $target_path"

    # Step 4: Update references in affected containers
    update_script_references "$script_name" "$source_script" "$target_path" "$affected_services"

    # Step 5: Test affected services
    if test_affected_services "$affected_services"; then
        # Step 6: Only remove original if tests pass
        rm "$source_script"
        log_migration "SUCCESS: Migration complete, original removed"
        log_migration "Backup available at: $backup_path"
        return 0
    else
        # Step 7: Rollback on failure
        rollback_migration "$script_name" "$source_script" "$target_path" "$backup_path" "$affected_services"
        return 1
    fi
}

# Update script references in container files
update_script_references() {
    local script_name="$1"
    local old_path="$2"
    local new_path="$3"
    local affected_services="$4"

    log_migration "Updating references for $script_name"

    # Find all files referencing the script
    while IFS= read -r file; do
        if [[ -f "$file" && "$file" != "$old_path" && "$file" != "$new_path" ]]; then
            log_migration "Updating references in: $file"
            # Use sed to replace the path
            sed -i.bak "s|$old_path|$new_path|g" "$file"
            sed -i.bak "s|/opt/dev-purebliss/$script_name|$new_path|g" "$file"
            sed -i.bak "s|\\./$script_name|$new_path|g" "$file"
        fi
    done < <(grep -r "$script_name" /opt/dev-purebliss/ --include="*.sh" -l 2>/dev/null || true)
}

# Test affected services
test_affected_services() {
    local services="$1"

    log_migration "Testing affected services: $services"

    if [[ -z "$services" || "$services" == "none" ]]; then
        log_migration "No services to test"
        return 0
    fi

    for service in $services; do
        log_migration "Testing service: $service"

        # Check if container exists and is running
        if docker ps -q -f name="$service" >/dev/null 2>&1; then
            log_migration "Container $service is running"

            # Test basic health
            if docker exec "$service" echo "health check" >/dev/null 2>&1; then
                log_migration "✓ $service: Basic connectivity test passed"
            else
                log_migration "✗ $service: Basic connectivity test failed"
                return 1
            fi

            # Test service-specific health if script exists
            if [[ -x "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh" ]]; then
                if /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$service" "script-migration-test" >/dev/null 2>&1; then
                    log_migration "✓ $service: Health validation passed"
                else
                    log_migration "✗ $service: Health validation failed"
                    return 1
                fi
            fi
        else
            log_migration "Service $service not running - skipping test"
        fi
    done

    log_migration "All service tests passed"
    return 0
}

# Rollback migration on failure
rollback_migration() {
    local script_name="$1"
    local original_path="$2"
    local new_path="$3"
    local backup_path="$4"
    local affected_services="$5"

    log_migration "ROLLBACK: Migration failed, restoring original state"

    # Restore original script
    cp "$backup_path" "$original_path"
    chmod +x "$original_path"

    # Remove failed new location
    rm -f "$new_path"

    # Restore original references
    while IFS= read -r file; do
        if [[ -f "$file.bak" ]]; then
            mv "$file.bak" "$file"
            log_migration "Restored references in: $file"
        fi
    done < <(find /opt/dev-purebliss -name "*.bak" 2>/dev/null || true)

    log_migration "ROLLBACK COMPLETE: Original state restored"
}

# Reboot and validate system
reboot_and_validate() {
    local services="$1"

    log_migration "Performing system validation reboot"

    # Restart docker containers for affected services
    for service in $services; do
        if docker ps -q -f name="$service" >/dev/null 2>&1; then
            log_migration "Restarting container: $service"
            docker restart "$service"
            sleep 5

            # Wait for service to be healthy
            local retries=0
            while [[ $retries -lt 12 ]]; do
                if docker ps -q -f name="$service" -f health=healthy >/dev/null 2>&1; then
                    log_migration "✓ $service: Healthy after restart"
                    break
                fi
                sleep 5
                ((retries++))
            done

            if [[ $retries -ge 12 ]]; then
                log_migration "✗ $service: Not healthy after restart - CRITICAL"
                return 1
            fi
        fi
    done

    log_migration "All services healthy after reboot"
    return 0
}

# Main execution function for single script migration
main() {
    local script_to_migrate="$1"
    local target_category="$2"
    local affected_services="${3:-none}"

    case "$script_to_migrate" in
        "retry-utils.sh")
            migrate_single_script "/opt/dev-purebliss/retry-utils.sh" \
                                "$CENTRAL_REPO/utilities/retry-utils.sh" \
                                "keycloak"
            ;;
        "service-entrypoint-template.sh")
            migrate_single_script "/opt/dev-purebliss/service-entrypoint-template.sh" \
                                "$CENTRAL_REPO/utilities/service-entrypoint-template.sh" \
                                "none"
            ;;
        "verify-https.sh")
            migrate_single_script "/opt/dev-purebliss/verify-https.sh" \
                                "$CENTRAL_REPO/health-checks/verify-https.sh" \
                                "nginx"
            ;;
        *)
            log_migration "ERROR: Unknown script: $script_to_migrate"
            echo "Usage: $0 <script_name> <category> [affected_services]"
            echo "Example: $0 retry-utils.sh utilities keycloak"
            return 1
            ;;
    esac

    # Reboot and validate after successful migration
    if [[ "$affected_services" != "none" ]]; then
        reboot_and_validate "$affected_services"
    fi

    log_migration "=== SINGLE SCRIPT MIGRATION COMPLETE ==="
}

# Execute if called directly
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
