#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE_CONTAINER_MIGRATION_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="comprehensive-container-migration.sh"
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
comprehensive_container_migration_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
comprehensive_container_migration_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
comprehensive_container_migration_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
comprehensive_container_migration_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    comprehensive_container_migration_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        comprehensive_container_migration_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            comprehensive_container_migration_log_success "Validation passed - proceeding with auto-commit"
        else
            comprehensive_container_migration_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        comprehensive_container_migration_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        comprehensive_container_migration_log_info "Auto-commit system not available - manual commit required"
        comprehensive_container_migration_log_info "Recommended commit message: $commit_message"
        comprehensive_container_migration_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
comprehensive_container_migration_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    comprehensive_container_migration_log_success "$final_message"
    
    # Execute auto-commit wrapper
    comprehensive_container_migration_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    comprehensive_container_migration_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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
SCRIPT_PURPOSE="Comprehensive Container Script Migration with Health Validation"

# Comprehensive Container Script Migration with Health Validation
# Systematically migrates ALL container scripts with health validation between each step
# CRITICAL: Tests infrastructure health after each migration to ensure 100% functionality


CENTRAL_REPO="/opt/dev-purebliss/dev_scripts"
MIGRATION_LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
HEALTH_VALIDATOR="/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh"

# Log function with enhanced container focus
log_migration() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_MIGRATION: $1" >> "$MIGRATION_LOG"
    echo "🐳 CONTAINER_MIGRATION: $1"
}

# PROJECT_PLAN integration for issue tracking
add_issue_to_project_plan() {
    local issue_type="$1"     # "container-health", "migration-failure", "validation-error"
    local service="$2"        # affected service
    local description="$3"    # issue description
    local severity="$4"       # "HIGH", "MEDIUM", "LOW"

    local project_plan="/opt/dev-purebliss/PROJECT_PLAN_ENHANCED.md"
    local issue_id=$(get_next_issue_id)
    local priority_table=""

    # Determine priority table based on severity
    case "$severity" in
        "HIGH"|"CRITICAL")
            priority_table="🔥 HIGH PRIORITY ISSUES"
            ;;
        "MEDIUM")
            priority_table="⚠️ MEDIUM PRIORITY ISSUES"
            ;;
        *)
            priority_table="⚠️ MEDIUM PRIORITY ISSUES"
            severity="MEDIUM"
            ;;
    esac

    log_migration "AUTO_ISSUE: Creating $issue_id in PROJECT_PLAN - $severity priority"

    # Add issue to appropriate priority table
    local temp_file="/tmp/project_plan_issue_update.tmp"

    # Find the priority table and add the new issue
    if grep -q "#### $priority_table" "$project_plan"; then
        # Add after the header row of the table
        sed "/#### $priority_table/,/^#### / {
            /^| Issue ID | Service | Description | Status | Resolution | Date Found |/ a\\
| $issue_id | $service | $issue_type: $description | 🔄 Investigating | Container migration issue | $(date +%Y-%m-%d) |
        }" "$project_plan" > "$temp_file"
        mv "$temp_file" "$project_plan"

        log_migration "AUTO_ISSUE: Added $issue_id to $priority_table table"
    else
        log_migration "ERROR: Could not find $priority_table table in PROJECT_PLAN"
    fi
}

# Generate next available issue ID
# Get next available issue ID
get_next_issue_id() {
    local project_plan="/opt/dev-purebliss/PROJECT_PLAN_ENHANCED.md"

    if [[ ! -f "$project_plan" ]]; then
        echo "ISS-001"
        return
    fi

    # Find highest ISS number, avoiding octal issues by forcing base 10
    local highest=$(grep -o "ISS-[0-9]\+" "$project_plan" | grep -o "[0-9]\+" | sort -n | tail -n 1)

    if [[ -z "$highest" ]]; then
        echo "ISS-001"
    else
        # Force base 10 arithmetic and increment
        local next_num=$((10#$highest + 1))
        printf "ISS-%03d" "$next_num"
    fi
}

# Enhanced container health validation with issue tracking
validate_container_health() {
    local phase="$1"
    log_migration "=== CONTAINER HEALTH VALIDATION: $phase ==="

    # Get all running containers
    local containers=$(docker ps --format "{{.Names}}" 2>/dev/null || echo "")
    local healthy_count=0
    local total_count=0
    local critical_failures=0
    local health_issues=()

    if [[ -z "$containers" ]]; then
        log_migration "⚠️  WARNING: No running containers found"
        add_issue_to_project_plan "No running containers" "infrastructure" "No Docker containers running during migration phase: $phase" "HIGH"
        return 1
    fi

    for container in $containers; do
        total_count=$((total_count + 1))
        log_migration "Checking container: $container"

        # Check container status
        local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
        local restart_count=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null || echo "0")

        log_migration "  Status: $status, Health: $health, Restarts: $restart_count"

        # Detect issues and add to PROJECT_PLAN
        if [[ "$status" != "running" ]]; then
            critical_failures=$((critical_failures + 1))
            health_issues+=("$container: Not running ($status)")
            add_issue_to_project_plan "Container not running" "$container" "Container $container status: $status during $phase" "HIGH"
        elif [[ "$health" == "unhealthy" ]]; then
            critical_failures=$((critical_failures + 1))
            health_issues+=("$container: Unhealthy")
            add_issue_to_project_plan "Container unhealthy" "$container" "Container $container health check failing during $phase" "HIGH"
        elif [[ "$restart_count" -gt 5 ]]; then
            health_issues+=("$container: High restart count ($restart_count)")
            add_issue_to_project_plan "High restart count" "$container" "Container $container has $restart_count restarts" "MEDIUM"
        elif [[ "$health" == "no-healthcheck" ]]; then
            health_issues+=("$container: No health check defined")
            add_issue_to_project_plan "Missing health check" "$container" "Container $container lacks Docker health check" "MEDIUM"
        fi

        # Use comprehensive health validator if available
        if [[ -x "$HEALTH_VALIDATOR" ]]; then
            if "$HEALTH_VALIDATOR" "$container" "container-migration-$phase" 2>/dev/null; then
                log_migration "  ✅ $container: Health validation passed"
                healthy_count=$((healthy_count + 1))
            else
                log_migration "  ❌ $container: Health validation failed"
                critical_failures=$((critical_failures + 1))
                health_issues+=("$container: Failed comprehensive health validation")
                add_issue_to_project_plan "Health validation failed" "$container" "Comprehensive health validation failed during $phase" "HIGH"
            fi
        else
            # Basic health check
            if [[ "$status" == "running" && "$health" != "unhealthy" ]]; then
                log_migration "  ✅ $container: Running"
                healthy_count=$((healthy_count + 1))
            else
                log_migration "  ❌ $container: Issues detected"
                critical_failures=$((critical_failures + 1))
            fi
        fi
    done

    log_migration "Health Summary: $healthy_count/$total_count containers healthy"

    # Log all detected issues
    if [[ ${#health_issues[@]} -gt 0 ]]; then
        log_migration "Detected Issues:"
        for issue in "${health_issues[@]}"; do
            log_migration "  - $issue"
        done
    fi

    if [[ $critical_failures -gt 0 ]]; then
        log_migration "🚨 CRITICAL: $critical_failures containers failed health validation"
        add_issue_to_project_plan "Critical health failures" "infrastructure" "$critical_failures containers failed health validation during $phase" "HIGH"
        return 1
    fi

    if [[ $healthy_count -eq $total_count ]]; then
        log_migration "✅ ALL CONTAINERS HEALTHY - Safe to proceed"
        return 0
    else
        log_migration "⚠️  Some containers unhealthy but no critical failures"
        return 2  # Warning but not critical
    fi
}

# Container restart and validation
restart_and_validate_containers() {
    local affected_services="$1"
    log_migration "=== CONTAINER RESTART AND VALIDATION ==="

    if [[ "$affected_services" == "none" || -z "$affected_services" ]]; then
        log_migration "No specific services to restart"
        return 0
    fi

    for service in $affected_services; do
        log_migration "Restarting container: $service"

        # Check if container exists
        if docker ps -a --format "{{.Names}}" | grep -q "^${service}$\|purebliss-${service}$"; then
            local container_name=""
            if docker ps -a --format "{{.Names}}" | grep -q "^purebliss-${service}$"; then
                container_name="purebliss-${service}"
            else
                container_name="$service"
            fi

            log_migration "Found container: $container_name"

            # Restart container
            if docker restart "$container_name" >/dev/null 2>&1; then
                log_migration "✅ Container $container_name restarted successfully"

                # Wait for startup
                sleep 5

                # Validate health
                if validate_container_health "post-restart-$service"; then
                    log_migration "✅ Container $container_name passed post-restart validation"
                else
                    log_migration "❌ Container $container_name failed post-restart validation"
                    return 1
                fi
            else
                log_migration "❌ Failed to restart container $container_name"
                return 1
            fi
        else
            log_migration "⚠️  Container $service not found, skipping restart"
        fi
    done

    return 0
}

# Enhanced script migration with container awareness and issue tracking
migrate_container_script() {
    local script_name="$1"
    local source_path="$2"
    local target_category="$3"
    local affected_containers="$4"

    log_migration "=== MIGRATING CONTAINER SCRIPT: $script_name ==="
    log_migration "Source: $source_path"
    log_migration "Category: $target_category"
    log_migration "Affected containers: $affected_containers"

    # Pre-migration container health check
    if ! validate_container_health "pre-migration-$script_name"; then
        log_migration "❌ Pre-migration health check failed - aborting migration"
        add_issue_to_project_plan "Pre-migration health check failed" "$affected_containers" "Health check failed before migrating $script_name" "HIGH"
        return 1
    fi

    # Use the enhanced migration tool
    local migration_tool="/opt/dev-purebliss/dev_scripts/utilities/migrate-single-script.sh"

    if [[ -x "$migration_tool" ]]; then
        log_migration "Using enhanced migration tool"
        if "$migration_tool" "$script_name" "$target_category" "$affected_containers"; then
            log_migration "✅ Migration tool completed successfully"
        else
            log_migration "❌ Migration tool failed - checking container health"
            add_issue_to_project_plan "Migration tool failed" "$affected_containers" "Failed to migrate script $script_name to $target_category" "HIGH"
            validate_container_health "post-failed-migration-$script_name"
            return 1
        fi
    else
        log_migration "❌ Migration tool not found: $migration_tool"
        add_issue_to_project_plan "Migration tool missing" "infrastructure" "Migration tool not found: $migration_tool" "HIGH"
        return 1
    fi

    # Post-migration container health check
    if ! validate_container_health "post-migration-$script_name"; then
        log_migration "❌ Post-migration health check failed"
        add_issue_to_project_plan "Post-migration health check failed" "$affected_containers" "Health check failed after migrating $script_name" "HIGH"
        return 1
    fi

    # Restart and validate affected containers
    if [[ "$affected_containers" != "none" ]]; then
        if restart_and_validate_containers "$affected_containers"; then
            log_migration "✅ Container restart and validation successful"
        else
            log_migration "❌ Container restart and validation failed"
            add_issue_to_project_plan "Container restart failed" "$affected_containers" "Failed to restart containers after migrating $script_name" "HIGH"
            return 1
        fi
    fi

    log_migration "✅ Container script migration completed successfully: $script_name"
    return 0
}

# Systematic container script discovery and migration
discover_and_migrate_container_scripts() {
    log_migration "=== DISCOVERING CONTAINER SCRIPTS ==="

    # Priority order for container script migration
    local script_priorities=(
        # High Priority - Infrastructure Critical
        "validate-container-health.sh:core:all"
        "container-scaffold.sh:core:all"
        "upstream-validation.sh:utilities:nginx"

        # Medium Priority - Health and Validation
        "comprehensive-health-check.sh:health-checks:none"
        "https-sanity-check.sh:health-checks:none"
        "verify-https.sh:health-checks:nginx"
        "reboot-sanity.sh:utilities:none"

        # Service-Specific Scripts
        "enhance-nginx-vault-integration.sh:services/nginx:nginx"
        "enhance-container-with-vault.sh:automation:all"
        "independent-service-testing.sh:utilities:all"

        # Deployment Scripts
        "scaffold-build.sh:deployment:none"
        "test-nginx-independent-startup.sh:services/nginx:nginx"

        # Utility Scripts
        "health-validation-integration-example.sh:utilities:none"
        "fix-keycloak-database-auth.sh:services/keycloak:keycloak"
    )

    local total_scripts=${#script_priorities[@]}
    local completed_scripts=0
    local failed_scripts=0

    for script_entry in "${script_priorities[@]}"; do
        IFS=':' read -r script_name category containers <<< "$script_entry"

        log_migration "Processing script $((completed_scripts + 1))/$total_scripts: $script_name"

        # Find the script
        local script_path=$(find /opt/dev-purebliss -maxdepth 1 -name "$script_name" -type f 2>/dev/null | head -1)

        if [[ -z "$script_path" ]]; then
            log_migration "⚠️  Script not found: $script_name"
            continue
        fi

        # Check if already migrated
        if [[ -f "$CENTRAL_REPO/$category/$script_name" ]]; then
            log_migration "✅ Script already migrated: $script_name"
            completed_scripts=$((completed_scripts + 1))
            continue
        fi

        # Migrate with container validation
        if migrate_container_script "$script_name" "$script_path" "$category" "$containers"; then
            completed_scripts=$((completed_scripts + 1))
            log_migration "✅ Successfully migrated: $script_name ($completed_scripts/$total_scripts)"
        else
            failed_scripts=$((failed_scripts + 1))
            log_migration "❌ Failed to migrate: $script_name"

            # Critical decision point
            read -p "Continue with remaining migrations despite failure? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_migration "Migration halted at user request"
                return 1
            fi
        fi

        # Brief pause between migrations
        sleep 2
    done

    log_migration "=== MIGRATION SUMMARY ==="
    log_migration "Total scripts processed: $total_scripts"
    log_migration "Successfully migrated: $completed_scripts"
    log_migration "Failed migrations: $failed_scripts"

    if [[ $failed_scripts -eq 0 ]]; then
        log_migration "✅ ALL CONTAINER SCRIPTS MIGRATED SUCCESSFULLY"
        return 0
    else
        log_migration "⚠️  Some migrations failed - review required"
        return 1
    fi
}

# Final container health validation
final_container_validation() {
    log_migration "=== FINAL CONTAINER HEALTH VALIDATION ==="

    # Wait for containers to stabilize
    log_migration "Waiting 30 seconds for containers to stabilize..."
    sleep 30

    # Comprehensive health check
    if validate_container_health "final-validation"; then
        log_migration "✅ FINAL VALIDATION PASSED - All containers healthy"

        # Additional checks
        log_migration "Running additional health checks..."

        # Check for any restarting containers
        local restarting=$(docker ps --filter "status=restarting" --format "{{.Names}}" | wc -l)
        local exited=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | wc -l)

        log_migration "Restarting containers: $restarting"
        log_migration "Exited containers: $exited"

        if [[ $restarting -gt 0 ]]; then
            log_migration "⚠️  Warning: $restarting containers are restarting"
            docker ps --filter "status=restarting" --format "table {{.Names}}\t{{.Status}}"
        fi

        return 0
    else
        log_migration "❌ FINAL VALIDATION FAILED"
        return 1
    fi
}

# Main execution function
main() {
    log_migration "=== COMPREHENSIVE CONTAINER SCRIPT MIGRATION STARTED ==="
    log_migration "Target: Migrate ALL container scripts to centralized location with health validation"

    # Initial container health assessment
    log_migration "=== INITIAL CONTAINER HEALTH ASSESSMENT ==="
    validate_container_health "initial-assessment" || {
        log_migration "⚠️  Some containers unhealthy at start - proceeding with caution"
    }

    # Discover and migrate all container scripts
    if discover_and_migrate_container_scripts; then
        log_migration "✅ Container script migration completed"
    else
        log_migration "❌ Container script migration had failures"
        return 1
    fi

    # Final validation
    if final_container_validation; then
        log_migration "🎉 COMPREHENSIVE CONTAINER MIGRATION SUCCESS"
        log_migration "All container scripts centralized with healthy infrastructure"
        return 0
    else
        log_migration "❌ Final validation failed - infrastructure issues detected"
        return 1
    fi
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
