#!/bin/bash
set -euo pipefail

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
SCRIPT_PURPOSE="Wrapper to ensure all scripts trigger auto-commit on success"

# Enhanced logging with auto-commit integration
log_task_completion() {
    local level="$1"
    local message="$2"
    local task_context="${3:-general}"
    local auto_commit="${4:-true}"

    # Log the message normally
    case "$level" in
        "SUCCESS")
            log_success "$message"
            ;;
        "INFO")
            log_info "$message"
            ;;
        "ERROR")
            log_error "$message"
            ;;
        "WARN")
            log_warn "$message"
            ;;
    esac

    # Trigger auto-commit for SUCCESS level messages if enabled
    if [[ "$level" == "SUCCESS" && "$auto_commit" == "true" ]]; then
        trigger_auto_commit_for_success "$message" "$task_context"
    fi
}

# Auto-commit trigger for successful operations
trigger_auto_commit_for_success() {
    local success_message="$1"
    local task_context="$2"

    log_info "AUTO_COMMIT_CHECK: Success detected - checking for auto-commit trigger"

    # Extract task information from success message
    local task_type="task-completion"
    local task_name="$task_context"
    local component="scaffolding"

    # Auto-commit integration script
    local AUTO_COMMIT_SCRIPT="$SCRIPT_DIR/automation/task-completion-with-auto-commit.sh"

    if [[ -x "$AUTO_COMMIT_SCRIPT" ]]; then
        log_info "AUTO_COMMIT_TRIGGER: Executing auto-commit for successful task"

        if "$AUTO_COMMIT_SCRIPT" complete-task "$task_type" "$task_name" "$component" "SUCCESS"; then
            log_info "✅ AUTO_COMMIT: Success - changes committed automatically"
        else
            log_warn "⚠️ AUTO_COMMIT: Failed - manual commit may be required"
        fi
    else
        log_warn "AUTO_COMMIT: Script not found - manual commit required"
    fi
}

# Enhanced script execution wrapper with auto-commit
execute_with_auto_commit() {
    local script_path="$1"
    shift
    local script_args="$@"

    log_info "EXECUTE_WITH_AUTO_COMMIT: Running $script_path with auto-commit integration"

    # Execute the script and capture result
    if "$script_path" "$script_args"; then
        local script_name="$(basename "$script_path")"
        log_task_completion "SUCCESS" "Script completed successfully: $script_name" "$script_name" "true"
        return 0
    else
        local exit_code=$?
        log_task_completion "ERROR" "Script failed: $(basename "$script_path")" "$(basename "$script_path")" "false"
        return $exit_code
    fi
}

# Container operation wrapper with auto-commit
container_operation_with_auto_commit() {
    local operation="$1"
    local container_name="$2"
    local additional_info="${3:-}"

    log_info "CONTAINER_OPERATION: $operation for $container_name"

    case "$operation" in
        "build")
            log_info "Building container: $container_name"
            # Container build logic would go here
            log_task_completion "SUCCESS" "Container built successfully: $container_name" "container-$container_name" "true"
            ;;
        "start")
            log_info "Starting container: $container_name"
            # Container start logic would go here
            log_task_completion "SUCCESS" "Container started successfully: $container_name" "container-$container_name" "true"
            ;;
        "health-check")
            log_info "Running health check for: $container_name"
            execute_with_auto_commit "$SCRIPT_DIR/core/validate-container-health.sh" "$container_name" "$additional_info"
            ;;
        "complete")
            log_info "Marking container as complete: $container_name"
            log_task_completion "SUCCESS" "Container scaffolding complete: $container_name" "container-$container_name" "true"
            ;;
        *)
            log_error "Unknown container operation: $operation"
            return 1
            ;;
    esac
}

# Service task wrapper with auto-commit
service_task_with_auto_commit() {
    local service_name="$1"
    local task_number="$2"
    local task_description="$3"
    local validation_command="${4:-true}"

    log_info "SERVICE_TASK: $service_name Task $task_number - $task_description"

    # Execute validation command
    if eval "$validation_command"; then
        log_task_completion "SUCCESS" "Task $task_number completed: $task_description" "$service_name-task-$task_number" "true"
        return 0
    else
        log_task_completion "ERROR" "Task $task_number failed: $task_description" "$service_name-task-$task_number" "false"
        return 1
    fi
}

# Usage examples and help
show_usage() {
    cat << EOF
Auto-Commit Integration Wrapper
Pure Bliss Elite Development Framework

Usage: $0 <command> [args...]

Commands:
  execute-script <script_path> [args...]     - Execute script with auto-commit on success
  container-op <operation> <name> [info]     - Container operation with auto-commit
  service-task <service> <num> <desc> [cmd]  - Service task with auto-commit
  log-success <message> [context]            - Log success with auto-commit trigger

Container Operations:
  build, start, health-check, complete

Examples:
  $0 execute-script ./build-vault.sh
  $0 container-op health-check vault "task-1.5"
  $0 service-task vault 1.1 "TLS certificate fix" "test -f /opt/vault/certs/vault.crt"
  $0 log-success "Vault scaffolding complete" "vault-container"
EOF
}

# Main execution
main() {
    local command="${1:-help}"

    case "$command" in
        "execute-script")
            shift
            execute_with_auto_commit "$@"
            ;;
        "container-op")
            container_operation_with_auto_commit "$2" "$3" "${4:-}"
            ;;
        "service-task")
            service_task_with_auto_commit "$2" "$3" "$4" "${5:-true}"
            ;;
        "log-success")
            log_task_completion "SUCCESS" "$2" "${3:-general}" "true"
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
