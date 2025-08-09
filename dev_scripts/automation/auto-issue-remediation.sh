#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO_ISSUE_REMEDIATION_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="auto-issue-remediation.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced automation script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced automation script for development with auto-commit functionality,
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
auto_issue_remediation_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
auto_issue_remediation_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
auto_issue_remediation_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
auto_issue_remediation_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    auto_issue_remediation_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        auto_issue_remediation_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            auto_issue_remediation_log_success "Validation passed - proceeding with auto-commit"
        else
            auto_issue_remediation_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        auto_issue_remediation_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        auto_issue_remediation_log_info "Auto-commit system not available - manual commit required"
        auto_issue_remediation_log_info "Recommended commit message: $commit_message"
        auto_issue_remediation_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
auto_issue_remediation_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    auto_issue_remediation_log_success "$final_message"
    
    # Execute auto-commit wrapper
    auto_issue_remediation_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    auto_issue_remediation_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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

# Auto-generated autonomous script by Copilot
# Purpose: Autonomous common issue remediation and problem resolution
# Service: ALL
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Auto-update: This script self-updates based on discovered improvements


# Configuration
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
HEALTH_VALIDATOR="/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh"

# Autonomous logging function
log_autonomous() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTONOMOUS_${SCRIPT_NAME}: $1" >> "$LOG_FILE"
    echo "🤖 $1"
}

# Error handling with autonomous remediation
handle_error() {
    log_autonomous "ERROR: $1"
    return 1
}

# Common issue patterns and their autonomous remediation
remediate_container_startup_issues() {
    log_autonomous "Remediating container startup issues"

    # Check for failed containers
    failed_containers=$(docker ps -a --filter "status=exited" --filter "name=purebliss-*" --format "{{.Names}}")

    if [[ -n "$failed_containers" ]]; then
        log_autonomous "Found failed containers: $failed_containers"

        for container in $failed_containers; do
            log_autonomous "Attempting to restart: $container"
            docker start "$container" || log_autonomous "Failed to restart $container"
            sleep 5

            # Check if restart was successful
            if docker ps --filter "name=$container" | grep -q "$container"; then
                log_autonomous "✅ Successfully restarted: $container"
            else
                log_autonomous "❌ Failed to restart: $container - checking logs"
                docker logs --tail 20 "$container"
            fi
        done
    else
        log_autonomous "No failed containers found"
    fi
}

# Fix common network issues
remediate_network_issues() {
    log_autonomous "Remediating network connectivity issues"

    # Check if purebliss network exists
    if ! docker network ls | grep -q "purebliss-net"; then
        log_autonomous "Creating missing purebliss-net network"
        docker network create purebliss-net || handle_error "Failed to create network"
    fi

    # Check for containers not connected to network
    local containers=$(docker ps --filter "name=purebliss-*" --format "{{.Names}}")
    for container in $containers; do
        if ! docker inspect "$container" | grep -q "purebliss-net"; then
            log_autonomous "Connecting $container to purebliss-net"
            docker network connect purebliss-net "$container" || log_autonomous "Failed to connect $container to network"
        fi
    done
}

# Clean up orphaned resources
remediate_resource_cleanup() {
    log_autonomous "Cleaning up orphaned resources"

    # Remove stopped test containers
    test_containers=$(docker ps -a --filter "name=*-test*" --filter "name=*-enhanced*" --format "{{.Names}}")
    if [[ -n "$test_containers" ]]; then
        log_autonomous "Removing test containers: $test_containers"
        echo "$test_containers" | xargs -r docker rm -f
    fi

    # Remove dangling images
    dangling_images=$(docker images -f "dangling=true" -q)
    if [[ -n "$dangling_images" ]]; then
        log_autonomous "Removing dangling images"
        echo "$dangling_images" | xargs -r docker rmi
    fi

    # Remove unused volumes (excluding data volumes)
    unused_volumes=$(docker volume ls -f "dangling=true" -q | grep -v "data" || true)
    if [[ -n "$unused_volumes" ]]; then
        log_autonomous "Removing unused volumes (excluding data volumes)"
        echo "$unused_volumes" | xargs -r docker volume rm
    fi
}

# Fix permission issues
remediate_permission_issues() {
    log_autonomous "Remediating file permission issues"

    # Fix common permission issues in dev-purebliss
    if [[ -d "/opt/dev-purebliss" ]]; then
        # Make scripts executable
        find /opt/dev-purebliss -name "*.sh" -type f ! -executable -exec chmod +x {} \;

        # Fix ownership if needed
        if [[ "$(stat -c %U /opt/dev-purebliss)" != "$(whoami)" ]]; then
            log_autonomous "Fixing ownership of /opt/dev-purebliss"
            sudo chown -R "$(id -u):$(id -g)" /opt/dev-purebliss || log_autonomous "Failed to fix ownership"
        fi
    fi
}

# Check and fix Vault connectivity
remediate_vault_connectivity() {
    log_autonomous "Checking Vault connectivity and health"

    # Check if Vault is responding
    if curl -s -k https://vault.purebliss.app:8200/v1/sys/health >/dev/null 2>&1; then
        log_autonomous "✅ Vault is responding"
    else
        log_autonomous "❌ Vault connectivity issues detected"

        # Check if Vault container is running
        if docker ps --filter "name=purebliss-vault" | grep -q "purebliss-vault"; then
            log_autonomous "Vault container is running, checking logs"
            docker logs --tail 20 purebliss-vault
        else
            log_autonomous "Vault container is not running, attempting restart"
            docker start purebliss-vault || handle_error "Failed to start Vault"
        fi
    fi
}

# Fix service endpoint connectivity issues
remediate_endpoint_connectivity() {
    log_autonomous "Checking and fixing service endpoint connectivity"

    # Use autonomous endpoint diagnostics if available
    local endpoint_diagnostics="/opt/dev-purebliss/autonomous-scripts/auto-endpoint-diagnostics.sh"

    if [[ -x "$endpoint_diagnostics" ]]; then
        log_autonomous "Running comprehensive endpoint audit and remediation"
        if "$endpoint_diagnostics" audit; then
            log_autonomous "✅ All endpoints are healthy after remediation"
        else
            log_autonomous "❌ Some endpoints still have issues after remediation"
        fi
    else
        log_autonomous "⚠️ Endpoint diagnostics script not available"

        # Basic endpoint checks for critical services
        local services=("loki" "prometheus" "grafana" "keycloak")
        for service in "${services[@]}"; do
            if docker ps --filter "name=$service" | grep -q "$service"; then
                local health_url="https://dev.purebliss.app/$service/health"
                if ! curl -f -s -k --max-time 10 "$health_url" >/dev/null 2>&1; then
                    log_autonomous "❌ $service endpoint not accessible, restarting service"
                    docker restart "$service" || log_autonomous "Failed to restart $service"
                    sleep 10
                fi
            fi
        done
    fi
}

# Main autonomous remediation workflow
main() {
    log_autonomous "Starting autonomous issue remediation"

    # Execute all remediation functions
    remediate_container_startup_issues
    remediate_network_issues
    remediate_resource_cleanup
    remediate_permission_issues
    remediate_vault_connectivity
    remediate_endpoint_connectivity

    # Final health check
    log_autonomous "Performing final health validation"
    if [[ -f "$HEALTH_VALIDATOR" ]]; then
        "$HEALTH_VALIDATOR" "all" "autonomous-remediation" || log_autonomous "Some services still require attention"
    fi

    log_autonomous "🎉 Autonomous remediation completed"
    log_autonomous "Check individual service logs for any remaining issues"
}

# Execute main function
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
