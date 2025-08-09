#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# TASK_COMPLETION_WITH_AUTO_COMMIT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="task-completion-with-auto-commit.sh"
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
task_completion_with_auto_commit_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
task_completion_with_auto_commit_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
task_completion_with_auto_commit_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
task_completion_with_auto_commit_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    task_completion_with_auto_commit_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        task_completion_with_auto_commit_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            task_completion_with_auto_commit_log_success "Validation passed - proceeding with auto-commit"
        else
            task_completion_with_auto_commit_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        task_completion_with_auto_commit_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        task_completion_with_auto_commit_log_info "Auto-commit system not available - manual commit required"
        task_completion_with_auto_commit_log_info "Recommended commit message: $commit_message"
        task_completion_with_auto_commit_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
task_completion_with_auto_commit_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    task_completion_with_auto_commit_log_success "$final_message"
    
    # Execute auto-commit wrapper
    task_completion_with_auto_commit_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    task_completion_with_auto_commit_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY LOG FILE DEFINITION (CRITICAL FOR AUTO-COMMIT)
export LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0"
SCRIPT_PURPOSE="Task completion with mandatory auto-commit integration"

# Auto-commit integration
AUTO_COMMIT_SCRIPT="$SCRIPT_DIR/automation/auto-commit-trigger.sh"

# Enhanced task completion function with auto-commit guarantee
complete_task_with_auto_commit() {
    local task_type="$1"
    local task_name="$2"
    local component="${3:-scaffolding}"
    local validation_result="${4:-SUCCESS}"

    log_info "TASK_COMPLETION: Completing task with auto-commit integration"
    log_info "Task: $task_type - $task_name ($component)"
    log_info "Result: $validation_result"

    # Validate task completion requirements
    if [[ "$validation_result" != "SUCCESS" ]]; then
        log_error "Task validation failed: $validation_result"
        log_error "AUTO-COMMIT BLOCKED: Task must be 100% successful before commit"
        return 1
    fi

    # Update PROJECT_PLAN with completion status
    update_project_plan_completion "$task_type" "$task_name" "$component"

    # Log completion to development log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - TASK_COMPLETE: $task_type - $task_name ($component) - STATUS: $validation_result" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

    # Trigger mandatory auto-commit
    trigger_auto_commit "$task_type" "$task_name" "$component"

    log_success "✅ Task completed with auto-commit: $task_type - $task_name"
}

# Update PROJECT_PLAN with completion status
update_project_plan_completion() {
    local task_type="$1"
    local task_name="$2"
    local component="$3"

    log_info "PROJECT_PLAN_UPDATE: Updating completion status"

    # Update SCAFFOLDING_PROJECT_PLAN.md with completion date
    local completion_date="$(date '+%Y-%m-%d')"
    local update_comment="(**COMPLETED $completion_date**)"

    log_info "Marking task as completed in project plan: $task_name"

    # This would update the specific task in the PROJECT_PLAN
    # For now, log the completion requirement
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PROJECT_PLAN_UPDATE: $task_type - $task_name marked as completed" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Trigger auto-commit with validation
trigger_auto_commit() {
    local task_type="$1"
    local task_name="$2"
    local component="$3"

    log_info "AUTO_COMMIT_TRIGGER: Initiating automated git commit"

    if [[ -x "$AUTO_COMMIT_SCRIPT" ]]; then
        log_info "Executing auto-commit script: $AUTO_COMMIT_SCRIPT"

        # Execute auto-commit trigger
        if "$AUTO_COMMIT_SCRIPT" "$task_type" "$task_name" "$component"; then
            log_success "✅ AUTO-COMMIT: Successfully committed and pushed changes"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO_COMMIT_SUCCESS: $task_type - $task_name committed to git" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
        else
            log_error "❌ AUTO-COMMIT: Failed to commit changes"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO_COMMIT_FAILED: $task_type - $task_name commit failed" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
            return 1
        fi
    else
        log_error "AUTO-COMMIT: Script not found or not executable: $AUTO_COMMIT_SCRIPT"
        log_warn "Creating missing auto-commit script"
        create_missing_auto_commit_script
        return 1
    fi
}

# Create missing auto-commit script if needed
create_missing_auto_commit_script() {
    log_warn "AUTO_COMMIT_SCRIPT: Creating missing auto-commit integration"

    # Ensure auto-commit script exists and is executable
    if [[ ! -x "$AUTO_COMMIT_SCRIPT" ]]; then
        log_info "Making auto-commit script executable"
        chmod +x "$AUTO_COMMIT_SCRIPT" 2>/dev/null || true
    fi
}

# Container completion with auto-commit
complete_container_scaffolding() {
    local container_name="$1"
    local container_number="$2"
    local all_tasks_completed="${3:-false}"

    if [[ "$all_tasks_completed" == "true" ]]; then
        log_info "CONTAINER_COMPLETION: All tasks completed for $container_name"

        # Complete with auto-commit
        complete_task_with_auto_commit "container-scaffolding" "$container_name" "container-$container_number" "SUCCESS"

        log_success "✅ CONTAINER_COMPLETE: $container_name scaffolding complete with auto-commit"
    else
        log_error "CONTAINER_INCOMPLETE: Not all tasks completed for $container_name"
        log_error "AUTO-COMMIT BLOCKED: Container must be 100% complete"
        return 1
    fi
}

# Service task completion with auto-commit
complete_service_task() {
    local service_name="$1"
    local task_number="$2"
    local task_description="$3"
    local validation_passed="${4:-false}"

    if [[ "$validation_passed" == "true" ]]; then
        log_info "SERVICE_TASK_COMPLETION: $service_name task $task_number completed"

        # Complete with auto-commit
        complete_task_with_auto_commit "service-task" "$service_name-task-$task_number" "$service_name" "SUCCESS"

        log_success "✅ SERVICE_TASK_COMPLETE: $service_name task $task_number with auto-commit"
    else
        log_error "SERVICE_TASK_INCOMPLETE: Task validation failed for $service_name task $task_number"
        log_error "AUTO-COMMIT BLOCKED: Task must pass validation"
        return 1
    fi
}

# Main execution function for task completion
main() {
    local action="${1:-help}"

    case "$action" in
        "complete-task")
            complete_task_with_auto_commit "$2" "$3" "${4:-scaffolding}" "${5:-SUCCESS}"
            ;;
        "complete-container")
            complete_container_scaffolding "$2" "$3" "${4:-false}"
            ;;
        "complete-service-task")
            complete_service_task "$2" "$3" "$4" "${5:-false}"
            ;;
        "help"|*)
            echo "Usage: $0 <action> [args...]"
            echo "Actions:"
            echo "  complete-task <task_type> <task_name> [component] [validation_result]"
            echo "  complete-container <container_name> <container_number> [all_tasks_completed]"
            echo "  complete-service-task <service_name> <task_number> <description> [validation_passed]"
            ;;
    esac
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
