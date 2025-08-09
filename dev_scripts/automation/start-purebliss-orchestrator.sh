#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# START_PUREBLISS_ORCHESTRATOR_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="start-purebliss-orchestrator.sh"
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
start_purebliss_orchestrator_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
start_purebliss_orchestrator_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
start_purebliss_orchestrator_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
start_purebliss_orchestrator_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    start_purebliss_orchestrator_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        start_purebliss_orchestrator_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            start_purebliss_orchestrator_log_success "Validation passed - proceeding with auto-commit"
        else
            start_purebliss_orchestrator_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        start_purebliss_orchestrator_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        start_purebliss_orchestrator_log_info "Auto-commit system not available - manual commit required"
        start_purebliss_orchestrator_log_info "Recommended commit message: $commit_message"
        start_purebliss_orchestrator_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
start_purebliss_orchestrator_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    start_purebliss_orchestrator_log_success "$final_message"
    
    # Execute auto-commit wrapper
    start_purebliss_orchestrator_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    start_purebliss_orchestrator_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


SESSION="purebliss-orchestrator"
SPEC="/opt/dev-purebliss/project_spec.md"
PLAN="/opt/dev-purebliss/PROJECT_PLAN.md"
LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Create project spec if missing
if [ ! -f "$SPEC" ]; then
    cat > "$SPEC" << 'EOF'
PROJECT: Pure Bliss Service Independence & Vault Integration
GOAL: Refactor all services for container independence, Vault onboarding, and health-validated orchestration.
CONSTRAINTS:
- One service at a time, strict health validation
- Log all actions to /opt/my-secure-ha-stack/logs/dev-environment-setup.log
- Update /opt/dev-purebliss/PROJECT_PLAN.md in real time
- Use entrypoint.sh for all service startup logic
- Follow /opt/dev-purebliss/.github/copilot-instructions.md
DELIVERABLES:
1. Vault: entrypoint.sh, Dockerfile, Compose, health check, backup, docs
2. Repeat for postgres, redis, keycloak, nginx, etc.
3. Final orchestrator: pure orchestration, health checks, git workflow
SUCCESS CRITERIA:
- Each service starts independently and passes health checks
- All logs and docs updated per spec
- Git workflow and backup steps completed
EOF
    echo "[$(date)] [Orchestrator] Created project_spec.md" >> "$LOG"
fi

# Start tmux session and windows
tmux new-session -d -s "$SESSION" -n orchestrator
tmux new-window -t "$SESSION" -n project-manager
tmux new-window -t "$SESSION" -n engineer
tmux new-window -t "$SESSION" -n qa-logger

# Orchestrator agent prompt
tmux send-keys -t "$SESSION:0" "
You are the Orchestrator. Read $SPEC and $PLAN.
Set up a Project Manager agent in window 1 to manage the Vault refactor phase.
Schedule check-ins every 30 minutes. Log all actions to $LOG.
" C-m

# Project Manager agent prompt
tmux send-keys -t "$SESSION:1" "
You are the Project Manager for Pure Bliss Vault refactor.
Assign the Vault entrypoint.sh, Dockerfile, and Compose update tasks to an Engineer agent in window 2.
Update $PLAN after each step.
Schedule check-ins every 15 minutes.
" C-m

# Engineer agent prompt
tmux send-keys -t "$SESSION:2" "
You are the Engineer. Implement the Vault entrypoint.sh, update Dockerfile and Compose, and test container startup.
Log all actions and errors to $LOG.
Mark tasks complete in $PLAN.
Notify the Project Manager when Vault passes health checks.
" C-m

# QA/Logger agent prompt
tmux send-keys -t "$SESSION:3" "
You are the QA/Logger agent. Monitor $LOG for errors and health check results.
Validate Vault container health and backup steps.
Log all validation actions and update $PLAN.
" C-m

# Attach to orchestrator session
tmux attach-session -t "$SESSION"

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
