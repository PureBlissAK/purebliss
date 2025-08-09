#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO_COMMIT_TRIGGER_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="auto-commit-trigger.sh"
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
auto_commit_trigger_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
auto_commit_trigger_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
auto_commit_trigger_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
auto_commit_trigger_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    auto_commit_trigger_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        auto_commit_trigger_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            auto_commit_trigger_log_success "Validation passed - proceeding with auto-commit"
        else
            auto_commit_trigger_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        auto_commit_trigger_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        auto_commit_trigger_log_info "Auto-commit system not available - manual commit required"
        auto_commit_trigger_log_info "Recommended commit message: $commit_message"
        auto_commit_trigger_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
auto_commit_trigger_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    auto_commit_trigger_log_success "$final_message"
    
    # Execute auto-commit wrapper
    auto_commit_trigger_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    auto_commit_trigger_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
else
    # Fallback logging functions if common library not available
    log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] $(basename "$0"): $1" | tee -a "$LOG_FILE"; }
    log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] $(basename "$0"): $1" | tee -a "$LOG_FILE"; }
    log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] $(basename "$0"): $1" | tee -a "$LOG_FILE"; }
fi

if [[ -f "$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "$SCRIPT_DIR/utilities/retry-utils.sh"
fi

if [[ -f "$SCRIPT_DIR/utilities/script-communication-bridge.sh" ]]; then
    source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"
fi

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0"
SCRIPT_PURPOSE="Auto-commit integration helper for successful task completion"

# Configuration
AUTO_COMMIT_SCRIPT="/opt/dev-purebliss/dev_scripts/automation/auto-commit-push.sh"

# Logging function
log_task_success() {
    local task_type="$1"
    local task_name="$2"
    local component="${3:-system}"

    # Log task completion with auto-commit trigger using centralized logging
    log_success "AUTO_COMMIT_TRIGGER: Task completed - $task_type:$task_name ($component)"
    log_info "AUTO_COMMIT_TRIGGER: Triggering automated git commit and push"
}

# Trigger auto-commit immediately
trigger_commit() {
    local task_type="$1"
    local task_name="$2"
    local component="${3:-system}"

    # Log the completion
    log_task_success "$task_type" "$task_name" "$component"

    # Execute auto-commit
    if [[ -x "$AUTO_COMMIT_SCRIPT" ]]; then
        "$AUTO_COMMIT_SCRIPT" manual "$task_type" "$task_name" "$component"
    else
        log_error "Auto-commit script not found or not executable: $AUTO_COMMIT_SCRIPT"
        return 1
    fi
}

# Usage examples and help
show_usage() {
    cat << EOF
Auto-Commit Integration Helper
Pure Bliss Elite Development Framework

Usage: $0 <task_type> <task_name> [component]

Examples:
  $0 migration "Script migration complete" "retry-utils"
  $0 health-validation "All containers healthy" "infrastructure"
  $0 container-enhancement "Loki container enhanced" "loki"
  $0 automation "Deployment script created" "automation"
  $0 troubleshooting "Database issue resolved" "postgres"

Task Types:
  migration, health-validation, container-enhancement, automation,
  troubleshooting, deployment, integration, security, performance

This script will:
1. Log the task completion with SUCCESS marker
2. Trigger automated git commit with elite message format
3. Push changes to remote repository
4. All without requiring user intervention

EOF
}

# Main execution
if [[ $# -lt 2 ]]; then
    show_usage
    exit 1
fi

trigger_commit "$1" "$2" "${3:-system}"

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
