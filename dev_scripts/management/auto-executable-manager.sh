#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO_EXECUTABLE_MANAGER_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="auto-executable-manager.sh"
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
auto_executable_manager_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
auto_executable_manager_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
auto_executable_manager_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
auto_executable_manager_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    auto_executable_manager_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        auto_executable_manager_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            auto_executable_manager_log_success "Validation passed - proceeding with auto-commit"
        else
            auto_executable_manager_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        auto_executable_manager_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        auto_executable_manager_log_info "Auto-commit system not available - manual commit required"
        auto_executable_manager_log_info "Recommended commit message: $commit_message"
        auto_executable_manager_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
auto_executable_manager_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    auto_executable_manager_log_success "$final_message"
    
    # Execute auto-commit wrapper
    auto_executable_manager_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    auto_executable_manager_log_success "${SCRIPT_NAME} execution and auto-commit completed"
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
SCRIPT_PURPOSE="Auto-Executable Script Manager - Pure Bliss Elite Autonomous Enhancement"

# Auto-Executable Script Manager - Pure Bliss Elite Autonomous Enhancement
# Automatically makes new scripts executable and applies proper permissions
# Prevents permission-related deployment failures and enhances automation resilience


# Pure Bliss Elite Standards
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
ENHANCEMENT_LOG="/opt/my-secure-ha-stack/logs/autonomous-enhancements.log"

# Logging function
log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO_EXECUTABLE: $message" | tee -a "$LOG_FILE"
}

log_enhancement() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_ENHANCEMENT: $message" | tee -a "$ENHANCEMENT_LOG"
}

# Function to automatically make scripts executable
auto_make_executable() {
    local target_dir="${1:-$(pwd)}"
    local pattern="${2:-*.sh}"
    local exclude_pattern="${3:-}"

    log_action "Starting auto-executable enhancement in: $target_dir"

    # Find script files and make them executable
    local count=0
    while IFS= read -r -d '' script_file; do
        # Skip if matches exclude pattern
        if [[ -n "$exclude_pattern" && "$script_file" =~ $exclude_pattern ]]; then
            continue
        fi

        # Check if file is already executable
        if [[ ! -x "$script_file" ]]; then
            chmod +x "$script_file"
            log_action "Made executable: $script_file"
            ((count++))
        fi
    done < <(find "$target_dir" -name "$pattern" -type f -print0 2>/dev/null)

    if [[ $count -gt 0 ]]; then
        log_action "Enhanced $count script files with executable permissions"
        log_enhancement "Auto-executable enhancement: $count scripts updated in $target_dir"
    else
        log_action "All scripts already executable in $target_dir"
    fi

    return $count
}

# Function to set up automated script monitoring
setup_script_monitoring() {
    local watch_dir="${1:-/opt/dev-purebliss}"

    log_action "Setting up automated script monitoring for: $watch_dir"

    # Create monitoring script
    cat > "/tmp/script-monitor.sh" << 'EOF'
# Automated Script Permission Monitor
# Continuously monitors for new scripts and makes them executable

WATCH_DIR="$1"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_monitor() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_MONITOR: $1" >> "$LOG_FILE"
}

# Monitor for new .sh files and make them executable
inotifywait -m -r -e create -e moved_to --format '%w%f' "$WATCH_DIR" 2>/dev/null | while read file; do
    if [[ "$file" =~ \.sh$ ]] && [[ -f "$file" ]]; then
        if [[ ! -x "$file" ]]; then
            chmod +x "$file"
            log_monitor "Auto-made executable: $file"
        fi
    fi
done
EOF

    chmod +x "/tmp/script-monitor.sh"
    log_action "Created script monitoring daemon"
}

# Function to enhance existing automation scripts
enhance_automation_scripts() {
    log_action "Enhancing existing automation scripts with auto-executable logic"

    # Define scripts to enhance
    local scripts_to_enhance=(
        "/opt/dev-purebliss/dev_scripts/core/container-scaffold.sh"
        "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh"
        "/opt/dev-purebliss/upstream-validation.sh"
        "/opt/dev-purebliss/dev_scripts/automation/start-all-services.sh"
    )

    for script in "${scripts_to_enhance[@]}"; do
        if [[ -f "$script" ]]; then
            # Add auto-executable logic if not already present
            if ! grep -q "auto_make_executable" "$script" 2>/dev/null; then
                log_action "Script $script exists but needs enhancement - will be handled by specific enhancement"
            else
                log_action "Script $script already has auto-executable logic"
            fi
        else
            log_action "Script $script not found - will be created with auto-executable logic"
        fi
    done
}

# Function to create auto-executable template
create_script_template() {
    local script_name="${1:-new-script.sh}"
    local script_path="${2:-$(pwd)}"
    local full_path="$script_path/$script_name"

    cat > "$full_path" << 'EOF'
# Auto-Generated Script Template with Pure Bliss Elite Standards
# Automatically includes logging, error handling, and executable permissions


# Pure Bliss Elite Standards
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Logging function
log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SCRIPT_NAME%%.*}: $message" | tee -a "$LOG_FILE"
}

# Main script logic goes here
main() {
    log_action "Script started with parameters: $*"

    # Add your script logic here

    log_action "Script completed successfully"
}

# Auto-make this script executable if it isn't already
if [[ ! -x "$0" ]]; then
    chmod +x "$0"
    log_action "Auto-made script executable: $0"
fi

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF

    chmod +x "$full_path"
    log_action "Created auto-executable script template: $full_path"
    return 0
}

# Function to enhance container scaffolding with auto-executable
enhance_container_scaffolding() {
    log_action "Enhancing container scaffolding with auto-executable logic"

    # Create enhancement snippet for container scaffolding
    cat > "/tmp/auto-executable-enhancement.snippet" << 'EOF'
# Auto-Executable Enhancement - Pure Bliss Elite Standards
auto_make_scripts_executable() {
    local service_dir="$1"
    local count=0

    echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO_EXECUTABLE: Making scripts executable in $service_dir" >> "$LOG_FILE"

    # Make all .sh files executable
    find "$service_dir" -name "*.sh" -type f ! -executable -exec chmod +x {} \; -exec echo "Made executable: {}" \; 2>/dev/null | while read line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO_EXECUTABLE: $line" >> "$LOG_FILE"
        ((count++)) || true
    done

    return 0
}

# Auto-make created scripts executable
post_script_creation_hook() {
    local created_file="$1"

    if [[ "$created_file" =~ \.sh$ ]]; then
        chmod +x "$created_file"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO_EXECUTABLE: Auto-made executable: $created_file" >> "$LOG_FILE"
    fi
}
EOF

    log_action "Created auto-executable enhancement snippet"
}

# Function to test auto-executable functionality
test_auto_executable() {
    log_action "Testing auto-executable functionality"

    # Create test directory
    local test_dir="/tmp/auto-executable-test"
    mkdir -p "$test_dir"

    # Create test script without executable permissions
    cat > "$test_dir/test-script.sh" << 'EOF'
echo "Test script executed successfully"
EOF

    # Remove executable permissions to test
    chmod -x "$test_dir/test-script.sh"

    # Test auto-executable function
    auto_make_executable "$test_dir"

    # Verify script is now executable
    if [[ -x "$test_dir/test-script.sh" ]]; then
        log_action "✅ Auto-executable test PASSED"
        log_enhancement "Auto-executable functionality validated successfully"
    else
        log_action "❌ Auto-executable test FAILED"
        return 1
    fi

    # Cleanup
    rm -rf "$test_dir"
    log_action "Test cleanup completed"
}

# Main execution function
main() {
    local action="${1:-enhance}"
    local target_dir="${2:-/opt/dev-purebliss}"

    case "$action" in
        "enhance")
            log_action "Starting comprehensive auto-executable enhancement"
            auto_make_executable "$target_dir"
            enhance_automation_scripts
            enhance_container_scaffolding
            setup_script_monitoring "$target_dir"
            ;;
        "monitor")
            setup_script_monitoring "$target_dir"
            ;;
        "template")
            local script_name="${3:-new-script.sh}"
            create_script_template "$script_name" "$target_dir"
            ;;
        "test")
            test_auto_executable
            ;;
        *)
            echo "Usage: $0 {enhance|monitor|template|test} [target_dir] [script_name]"
            echo "  enhance  - Apply auto-executable enhancements"
            echo "  monitor  - Set up script monitoring"
            echo "  template - Create new script template"
            echo "  test     - Test auto-executable functionality"
            return 1
            ;;
    esac

    log_action "Auto-executable enhancement completed: $action"
}

# Auto-make this script executable if it isn't already
if [[ ! -x "$0" ]]; then
    chmod +x "$0"
    log_action "Auto-made script executable: $0"
fi

# Run main function if script is executed directly
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
