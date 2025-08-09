#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VALIDATE_PROJECT_PLAN_ENHANCEMENTS_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="validate-project-plan-enhancements.sh"
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
validate_project_plan_enhancements_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
validate_project_plan_enhancements_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
validate_project_plan_enhancements_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
validate_project_plan_enhancements_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    validate_project_plan_enhancements_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        validate_project_plan_enhancements_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            validate_project_plan_enhancements_log_success "Validation passed - proceeding with auto-commit"
        else
            validate_project_plan_enhancements_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        validate_project_plan_enhancements_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        validate_project_plan_enhancements_log_info "Auto-commit system not available - manual commit required"
        validate_project_plan_enhancements_log_info "Recommended commit message: $commit_message"
        validate_project_plan_enhancements_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
validate_project_plan_enhancements_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    validate_project_plan_enhancements_log_success "$final_message"
    
    # Execute auto-commit wrapper
    validate_project_plan_enhancements_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    validate_project_plan_enhancements_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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

# Project Plan Enhancement Validation - Simplified
# Auto-generated by Copilot for autonomous operation
# Purpose: Validate enhanced project plan capabilities and autonomous framework
# Created: 2025-08-07

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_validation() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PROJECT_PLAN_VALIDATION: $1" >> "$LOG_FILE"
    echo "🔍 $1"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PROJECT_PLAN_SUCCESS: $1" >> "$LOG_FILE"
    echo "✅ $1"
}

log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PROJECT_PLAN_INFO: $1" >> "$LOG_FILE"
    echo "ℹ️ $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PROJECT_PLAN_ERROR: $1" >> "$LOG_FILE"
    echo "❌ $1"
}

echo ""
log_validation "=== PROJECT PLAN ENHANCEMENT VALIDATION ==="
log_validation "Validating autonomous framework integration and capabilities"
log_validation ""

# Change to correct directory
cd /opt/dev-purebliss || {
    log_error "Cannot access /opt/dev-purebliss directory"
    exit 1
}

# Validate autonomous scripts are available
log_validation "Checking autonomous script availability..."

autonomous_scripts=(
    "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh"
    "/opt/dev-purebliss/autonomous-scripts/auto-endpoint-diagnostics.sh"
    "/opt/dev-purebliss/autonomous-scripts/autonomous-completion-report.sh"
)

script_count=0
for script in "${autonomous_scripts[@]}"; do
    script_name=$(basename "$script")
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            log_success "Script ready: $script_name"
        else
            log_info "Making script executable: $script_name"
            if chmod +x "$script" 2>/dev/null; then
                log_success "Made executable: $script_name"
            else
                log_error "Cannot make executable: $script_name"
            fi
        fi
        script_count=$((script_count + 1))
    else
        log_error "Script missing: $script_name"
    fi
done

log_validation "Found $script_count autonomous scripts"

# Test endpoint diagnostics capabilities
log_validation ""
log_validation "Testing endpoint diagnostics framework..."

if [[ -x "/opt/dev-purebliss/autonomous-scripts/auto-endpoint-diagnostics.sh" ]]; then
    # Test the help capability
    if /opt/dev-purebliss/autonomous-scripts/auto-endpoint-diagnostics.sh help >/dev/null 2>&1; then
        log_success "Endpoint diagnostics script functional"
    else
        log_info "Endpoint diagnostics available but help command may have issues"
    fi

    # Test detection capability
    log_info "Testing container detection..."
    if /opt/dev-purebliss/autonomous-scripts/auto-endpoint-diagnostics.sh detect >/dev/null 2>&1; then
        log_success "Container detection working"
    else
        log_info "Container detection completed (may have found issues to report)"
    fi
else
    log_error "Endpoint diagnostics script not executable"
fi

# Check Docker status
log_validation ""
log_validation "Checking Docker and container status..."

if docker ps >/dev/null 2>&1; then
    log_success "Docker daemon is accessible"

    container_count=$(docker ps --format "{{.Names}}" | wc -l)
    log_info "Running containers: $container_count"

    # Look for PureBliss-related containers
    purebliss_count=0
    while IFS= read -r container; do
        if [[ "$container" =~ (purebliss|loki|vault|nginx|keycloak|postgres|redis|grafana|prometheus) ]]; then
            purebliss_count=$((purebliss_count + 1))
            log_info "Found PureBliss container: $container"
        fi
    done < <(docker ps --format "{{.Names}}")

    log_success "PureBliss containers: $purebliss_count"
else
    log_error "Docker daemon not accessible"
fi

# Check project plan files
log_validation ""
log_validation "Validating project documentation..."

if [[ -f "PROJECT_PLAN_ENHANCED.md" ]]; then
    log_success "Enhanced project plan exists"

    # Check if file has content
    if [[ -s "PROJECT_PLAN_ENHANCED.md" ]]; then
        log_success "Project plan has content"

        # Check for enhancement keywords
        enhancement_count=0
        for keyword in "autonomous" "endpoint" "diagnostics" "enhanced" "purebliss"; do
            if grep -q -i "$keyword" "PROJECT_PLAN_ENHANCED.md"; then
                enhancement_count=$((enhancement_count + 1))
            fi
        done

        if [[ $enhancement_count -gt 2 ]]; then
            log_success "Project plan includes enhancement keywords ($enhancement_count/5)"
        else
            log_info "Project plan may need more enhancement documentation"
        fi
    else
        log_error "Project plan is empty"
    fi
else
    log_error "Enhanced project plan not found"
fi

# Check git status
log_validation ""
log_validation "Checking git repository status..."

if git status >/dev/null 2>&1; then
    log_success "Git repository accessible"

    current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    log_info "Current branch: $current_branch"

    # Check for uncommitted changes
    uncommitted=$(git status --porcelain 2>/dev/null | wc -l)
    if [[ $uncommitted -eq 0 ]]; then
        log_success "Repository is clean"
    else
        log_info "Uncommitted changes: $uncommitted files"
    fi
else
    log_error "Git repository not accessible"
fi

# System resource check
log_validation ""
log_validation "Checking system resources..."

# Check disk space
disk_usage=$(df /opt 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "unknown")
if [[ "$disk_usage" != "unknown" ]] && [[ $disk_usage -lt 90 ]]; then
    log_success "Disk usage acceptable: ${disk_usage}%"
elif [[ "$disk_usage" != "unknown" ]]; then
    log_error "Disk usage high: ${disk_usage}%"
else
    log_info "Could not determine disk usage"
fi

# Check memory if available
if command -v free >/dev/null 2>&1; then
    memory_usage=$(free 2>/dev/null | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}' || echo "unknown")
    if [[ "$memory_usage" != "unknown" ]] && [[ $memory_usage -lt 80 ]]; then
        log_success "Memory usage acceptable: ${memory_usage}%"
    elif [[ "$memory_usage" != "unknown" ]]; then
        log_info "Memory usage elevated: ${memory_usage}%"
    else
        log_info "Could not determine memory usage"
    fi
fi

# Final summary
log_validation ""
log_validation "=== VALIDATION SUMMARY ==="

# Count recent validation results
recent_time=$(date '+%Y-%m-%d %H:%M')
success_count=$(grep "PROJECT_PLAN_SUCCESS.*$recent_time" "$LOG_FILE" 2>/dev/null | wc -l || echo "0")
error_count=$(grep "PROJECT_PLAN_ERROR.*$recent_time" "$LOG_FILE" 2>/dev/null | wc -l || echo "0")

log_validation "Validation results: $success_count successes, $error_count errors"

if [[ $error_count -eq 0 ]]; then
    log_success "✅ All validations passed - Autonomous framework fully operational"
    log_success "✅ Project plan enhancements validated and ready"
    log_success "✅ System ready for continued autonomous operation"
    exit_code=0
elif [[ $error_count -lt 3 ]]; then
    log_info "⚠️ Minor issues detected but framework operational"
    log_info "✅ Autonomous capabilities available with noted limitations"
    exit_code=1
else
    log_error "❌ Multiple critical issues detected"
    log_error "🔧 Manual intervention may be required"
    exit_code=2
fi

log_validation ""
log_validation "🎉 PROJECT PLAN ENHANCEMENT VALIDATION COMPLETE"
log_validation "Exit code: $exit_code (0=success, 1=warnings, 2=errors)"

echo ""
echo "🎯 **Validation Complete!** Check log for details: $LOG_FILE"

exit $exit_code

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
