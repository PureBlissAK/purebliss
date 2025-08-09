#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SEARCH_SCRIPTS_SIMPLE_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="search-scripts-simple.sh"
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
search_scripts_simple_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
search_scripts_simple_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
search_scripts_simple_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
search_scripts_simple_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    search_scripts_simple_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        search_scripts_simple_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            search_scripts_simple_log_success "Validation passed - proceeding with auto-commit"
        else
            search_scripts_simple_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        search_scripts_simple_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        search_scripts_simple_log_info "Auto-commit system not available - manual commit required"
        search_scripts_simple_log_info "Recommended commit message: $commit_message"
        search_scripts_simple_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
search_scripts_simple_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    search_scripts_simple_log_success "$final_message"
    
    # Execute auto-commit wrapper
    search_scripts_simple_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    search_scripts_simple_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Simple script search utility for Pure Bliss
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

# Function to search by service
search_by_service() {
    local service="$1"
    echo "🔍 Searching for $service scripts..."
    echo ""

    local found=0
    find /opt -name "*.sh" -type f 2>/dev/null | while read script_path; do
        if [[ -f "$script_path" && -s "$script_path" ]]; then
            if grep -qi "$service" "$script_path" 2>/dev/null; then
                script_name=$(basename "$script_path")
                purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' | head -c 80 || echo "No description")

                echo "📄 $script_name"
                echo "   Path: $script_path"
                echo "   Purpose: $purpose"
                echo ""
                found=$((found + 1))
            fi
        fi
    done

    echo "Found scripts containing '$service'"
}

# Function to search by functionality
search_by_functionality() {
    local func="$1"
    echo "🔍 Searching for '$func' functionality..."
    echo ""

    find /opt -name "*.sh" -type f 2>/dev/null | while read script_path; do
        if [[ -f "$script_path" && -s "$script_path" ]]; then
            script_name=$(basename "$script_path")
            if [[ "$script_name" =~ $func ]] || grep -qi "$func" "$script_path" 2>/dev/null; then
                purpose=$(grep -m1 "^#" "$script_path" 2>/dev/null | head -1 | sed 's/^# *//' || echo "No description")

                echo "📄 $script_name"
                echo "   Path: $script_path"
                echo "   Purpose: $purpose"
                echo ""
            fi
        fi
    done
}

# Function to list services with script counts
list_services() {
    echo "🏢 Services with scripts:"
    echo ""

    for service in vault postgres nginx keycloak grafana loki prometheus plane codeserver; do
        count=$(find /opt -name "*.sh" -type f -exec grep -l "$service" {} \; 2>/dev/null | wc -l)
        echo "  $service: $count scripts"
    done
    echo ""
}

# Function to show usage
show_usage() {
    echo "Pure Bliss Script Search Utility"
    echo ""
    echo "Usage: $0 [OPTION] [SEARCH_TERM]"
    echo ""
    echo "Options:"
    echo "  -s SERVICE    Search scripts for specific service"
    echo "  -f FUNCTION   Search scripts by functionality"
    echo "  -ls           List all services with script counts"
    echo "  -la           List all scripts"
    echo "  -h            Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 -s vault"
    echo "  $0 -f health"
    echo "  $0 -ls"
    echo ""
}

# Function to list all scripts
list_all_scripts() {
    echo "📚 All shell scripts in /opt:"
    echo ""

    find /opt -name "*.sh" -type f 2>/dev/null | sort | while read script_path; do
        if [[ -f "$script_path" && -s "$script_path" ]]; then
            script_name=$(basename "$script_path")
            purpose=$(grep -m1 "^#[^!]" "$script_path" 2>/dev/null | sed 's/^# *//' | head -c 60 || echo "No description")

            echo "📄 $script_name"
            echo "   $script_path"
            echo "   $purpose"
            echo ""
        fi
    done
}

# Main execution
case "${1:-}" in
    -s|--service)
        if [[ -n "${2:-}" ]]; then
            search_by_service "$2"
        else
            echo "Error: Service name required"
            show_usage
        fi
        ;;
    -f|--functionality)
        if [[ -n "${2:-}" ]]; then
            search_by_functionality "$2"
        else
            echo "Error: Functionality term required"
            show_usage
        fi
        ;;
    -ls|--list-services)
        list_services
        ;;
    -la|--list-all)
        list_all_scripts
        ;;
    -h|--help)
        show_usage
        ;;
    "")
        echo "Interactive mode:"
        echo "1) Search by service"
        echo "2) Search by functionality"
        echo "3) List services"
        echo "4) List all scripts"
        echo ""
        read -p "Enter choice (1-4): " choice

        case "$choice" in
            1)
                read -p "Enter service name: " service
                search_by_service "$service"
                ;;
            2)
                read -p "Enter functionality: " func
                search_by_functionality "$func"
                ;;
            3)
                list_services
                ;;
            4)
                list_all_scripts
                ;;
            *)
                echo "Invalid choice"
                ;;
        esac
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
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
