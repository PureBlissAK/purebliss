#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# TASK_COMPLETION_MONITOR_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="task-completion-monitor.sh"
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
task_completion_monitor_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
task_completion_monitor_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
task_completion_monitor_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
task_completion_monitor_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    task_completion_monitor_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        task_completion_monitor_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            task_completion_monitor_log_success "Validation passed - proceeding with auto-commit"
        else
            task_completion_monitor_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        task_completion_monitor_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        task_completion_monitor_log_info "Auto-commit system not available - manual commit required"
        task_completion_monitor_log_info "Recommended commit message: $commit_message"
        task_completion_monitor_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
task_completion_monitor_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    task_completion_monitor_log_success "$final_message"
    
    # Execute auto-commit wrapper
    task_completion_monitor_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    task_completion_monitor_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Task Completion Detection and Auto-Commit Trigger
# Pure Bliss Elite Development Framework
#
# This script monitors for task completion patterns and automatically triggers
# git commit and push workflows without user intervention


# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
MONITOR_LOG_PREFIX="TASK_MONITOR"
AUTO_COMMIT_SCRIPT="/opt/dev-purebliss/dev_scripts/automation/auto-commit-push.sh"
LOCK_FILE="/tmp/auto-commit-monitor.lock"
MONITOR_INTERVAL=10  # seconds
MAX_MONITOR_TIME=3600  # 1 hour maximum monitoring

# Task completion patterns to monitor
declare -A TASK_PATTERNS=(
    ["migration"]="MIGRATION_SUCCESS|Script migration.*SUCCESS|✅.*migrated"
    ["health-validation"]="HEALTH_SUCCESS|Health validation.*PASSED|✅.*healthy"
    ["container-enhancement"]="CONTAINER_SUCCESS|Container.*enhanced|✅.*container"
    ["automation"]="AUTOMATION_SUCCESS|Automation.*complete|✅.*automated"
    ["troubleshooting"]="TROUBLESHOOTING_SUCCESS|Issue.*resolved|✅.*fixed"
    ["deployment"]="DEPLOYMENT_SUCCESS|Service.*deployed|✅.*deployed"
    ["integration"]="INTEGRATION_SUCCESS|Integration.*complete|✅.*integrated"
)

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$MONITOR_LOG_PREFIX] [$level] $message" | tee -a "$LOG_FILE"
}

# Check if monitoring is already running
check_lock_file() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_message "INFO" "Auto-commit monitoring already running (PID: $lock_pid)"
            return 1
        else
            log_message "INFO" "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    return 0
}

# Create lock file
create_lock_file() {
    echo $$ > "$LOCK_FILE"
    log_message "INFO" "Created lock file for monitoring process (PID: $$)"
}

# Remove lock file
remove_lock_file() {
    rm -f "$LOCK_FILE"
    log_message "INFO" "Removed lock file"
}

# Monitor log file for task completion patterns
monitor_task_completion() {
    local monitoring_duration=0
    local last_log_position=0

    log_message "INFO" "Starting task completion monitoring"
    log_message "INFO" "Monitoring patterns: ${!TASK_PATTERNS[*]}"

    # Get initial log file size
    if [[ -f "$LOG_FILE" ]]; then
        last_log_position=$(wc -l < "$LOG_FILE")
    fi

    while [[ $monitoring_duration -lt $MAX_MONITOR_TIME ]]; do
        # Check if log file exists and has new content
        if [[ -f "$LOG_FILE" ]]; then
            local current_position=$(wc -l < "$LOG_FILE")

            if [[ $current_position -gt $last_log_position ]]; then
                # Read new lines since last check
                local new_lines=$((current_position - last_log_position))
                log_message "DEBUG" "Analyzing $new_lines new log entries"

                # Extract new log entries
                local new_content
                new_content=$(tail -n "$new_lines" "$LOG_FILE")

                # Check each task pattern
                for task_type in "${!TASK_PATTERNS[@]}"; do
                    local pattern="${TASK_PATTERNS[$task_type]}"

                    if echo "$new_content" | grep -qE "$pattern"; then
                        log_message "SUCCESS" "Task completion detected: $task_type"

                        # Extract task details from log
                        local task_name
                        task_name=$(echo "$new_content" | grep -E "$pattern" | tail -1 | sed 's/.*- //' | cut -d: -f1)

                        # Trigger auto-commit
                        trigger_auto_commit "$task_type" "$task_name"

                        # Update last position to avoid re-processing
                        last_log_position=$current_position
                        break
                    fi
                done

                # Update position if no matches found
                last_log_position=$current_position
            fi
        fi

        # Wait before next check
        sleep "$MONITOR_INTERVAL"
        monitoring_duration=$((monitoring_duration + MONITOR_INTERVAL))
    done

    log_message "INFO" "Task completion monitoring stopped (timeout after ${MAX_MONITOR_TIME}s)"
}

# Trigger auto-commit workflow
trigger_auto_commit() {
    local task_type="$1"
    local task_name="${2:-Automated enhancement}"

    log_message "INFO" "Triggering auto-commit for: $task_type - $task_name"

    # Extract component from task name or use default
    local component="system"
    if [[ "$task_name" =~ ([a-zA-Z-]+) ]]; then
        component="${BASH_REMATCH[1]}"
    fi

    # Wait a brief moment to ensure all log entries are written
    sleep 2

    # Execute auto-commit script
    if [[ -x "$AUTO_COMMIT_SCRIPT" ]]; then
        log_message "INFO" "Executing auto-commit script"

        if "$AUTO_COMMIT_SCRIPT" manual "$task_type" "$task_name" "$component"; then
            log_message "SUCCESS" "Auto-commit completed successfully"
            log_message "INFO" "Changes automatically committed and pushed"
        else
            log_message "ERROR" "Auto-commit failed"
        fi
    else
        log_message "ERROR" "Auto-commit script not found or not executable: $AUTO_COMMIT_SCRIPT"
    fi
}

# Start monitoring in background mode
start_background_monitoring() {
    if check_lock_file; then
        create_lock_file

        # Set up cleanup on exit
        trap remove_lock_file EXIT

        log_message "INFO" "Starting background task completion monitoring"
        monitor_task_completion &

        local monitor_pid=$!
        log_message "INFO" "Background monitoring started (PID: $monitor_pid)"

        # Wait for monitoring to complete
        wait $monitor_pid
    else
        log_message "WARNING" "Cannot start monitoring - already running"
    fi
}

# Check current monitoring status
check_monitoring_status() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_message "INFO" "Auto-commit monitoring is running (PID: $lock_pid)"
            return 0
        else
            log_message "INFO" "Auto-commit monitoring is not running (stale lock file)"
            rm -f "$LOCK_FILE"
            return 1
        fi
    else
        log_message "INFO" "Auto-commit monitoring is not running"
        return 1
    fi
}

# Stop monitoring
stop_monitoring() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_message "INFO" "Stopping auto-commit monitoring (PID: $lock_pid)"
            kill "$lock_pid" 2>/dev/null || true
            sleep 2
            if kill -0 "$lock_pid" 2>/dev/null; then
                log_message "WARNING" "Force killing monitoring process"
                kill -9 "$lock_pid" 2>/dev/null || true
            fi
        fi
        remove_lock_file
        log_message "INFO" "Auto-commit monitoring stopped"
    else
        log_message "INFO" "No monitoring process to stop"
    fi
}

# One-shot task detection and commit
oneshot_detection() {
    log_message "INFO" "Performing one-shot task completion detection"

    # Check last 50 lines for any completion patterns
    if [[ -f "$LOG_FILE" ]]; then
        local recent_content
        recent_content=$(tail -50 "$LOG_FILE")

        for task_type in "${!TASK_PATTERNS[@]}"; do
            local pattern="${TASK_PATTERNS[$task_type]}"

            if echo "$recent_content" | grep -qE "$pattern"; then
                log_message "SUCCESS" "Recent task completion detected: $task_type"

                # Extract task details
                local task_name
                task_name=$(echo "$recent_content" | grep -E "$pattern" | tail -1 | sed 's/.*- //' | cut -d: -f1)

                # Trigger auto-commit
                trigger_auto_commit "$task_type" "$task_name"
                return 0
            fi
        done

        log_message "INFO" "No recent task completions detected"
        return 1
    else
        log_message "ERROR" "Log file not found: $LOG_FILE"
        return 1
    fi
}

# Main command handling
case "${1:-help}" in
    "start")
        start_background_monitoring
        ;;
    "stop")
        stop_monitoring
        ;;
    "status")
        check_monitoring_status
        ;;
    "oneshot")
        oneshot_detection
        ;;
    "test")
        # Test mode - trigger immediate commit
        log_message "TEST" "Test mode - triggering immediate auto-commit"
        trigger_auto_commit "test" "Test auto-commit functionality"
        ;;
    "help"|*)
        echo "Task Completion Detection and Auto-Commit System"
        echo "Pure Bliss Elite Development Framework"
        echo ""
        echo "Usage: $0 {start|stop|status|oneshot|test}"
        echo ""
        echo "Commands:"
        echo "  start    - Start background task completion monitoring"
        echo "  stop     - Stop background monitoring"
        echo "  status   - Check monitoring status"
        echo "  oneshot  - Perform one-shot detection and commit"
        echo "  test     - Test auto-commit functionality"
        echo ""
        echo "Monitoring Patterns:"
        for task_type in "${!TASK_PATTERNS[@]}"; do
            echo "  $task_type: ${TASK_PATTERNS[$task_type]}"
        done
        echo ""
        echo "The monitoring system watches for task completion patterns in:"
        echo "  $LOG_FILE"
        echo ""
        echo "Auto-commits are triggered via:"
        echo "  $AUTO_COMMIT_SCRIPT"
        ;;
esac

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
