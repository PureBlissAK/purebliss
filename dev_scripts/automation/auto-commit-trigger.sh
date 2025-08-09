#!/bin/bash
set -euo pipefail

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
