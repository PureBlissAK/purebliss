#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# QUICK_SCAN_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="quick-scan.sh"
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
quick_scan_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
quick_scan_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
quick_scan_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
quick_scan_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    quick_scan_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        quick_scan_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            quick_scan_log_success "Validation passed - proceeding with auto-commit"
        else
            quick_scan_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        quick_scan_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        quick_scan_log_info "Auto-commit system not available - manual commit required"
        quick_scan_log_info "Recommended commit message: $commit_message"
        quick_scan_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
quick_scan_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    quick_scan_log_success "$final_message"
    
    # Execute auto-commit wrapper
    quick_scan_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    quick_scan_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Simple script counter and basic indexing
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

mkdir -p "$INDEX_DIR"

echo "🔍 Pure Bliss Script Discovery"
echo "=============================="

# Count all scripts
total_scripts=$(find /opt -name "*.sh" -type f 2>/dev/null | wc -l)
echo "📊 Total .sh scripts found: $total_scripts"

# Create basic index
results_file="$INDEX_DIR/basic_script_index.txt"
echo "=== Pure Bliss Script Index ===" > "$results_file"
echo "Generated: $(date)" >> "$results_file"
echo "Total Scripts: $total_scripts" >> "$results_file"
echo "" >> "$results_file"

echo "📝 Creating basic index..."

# List scripts by location
echo "=== Scripts by Location ===" >> "$results_file"
find /opt -name "*.sh" -type f 2>/dev/null | while read script; do
    echo "$script" >> "$results_file"
done

echo "" >> "$results_file"
echo "=== Scripts by Category (Estimated) ===" >> "$results_file"

# Count by probable categories
health_scripts=$(find /opt -name "*health*" -o -name "*check*" -o -name "*validate*" | grep "\.sh$" | wc -l)
deploy_scripts=$(find /opt -name "*deploy*" -o -name "*start*" -o -name "*setup*" | grep "\.sh$" | wc -l)
backup_scripts=$(find /opt -name "*backup*" -o -name "*restore*" | grep "\.sh$" | wc -l)

echo "Health/Validation Scripts: $health_scripts" >> "$results_file"
echo "Deployment Scripts: $deploy_scripts" >> "$results_file"
echo "Backup Scripts: $backup_scripts" >> "$results_file"

echo "" >> "$results_file"
echo "=== Top Directories with Scripts ===" >> "$results_file"
find /opt -name "*.sh" -type f 2>/dev/null | xargs dirname | sort | uniq -c | sort -nr | head -20 >> "$results_file"

# Update main index library with discovered count
if [[ -f "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md" ]]; then
    sed -i "s/\*\*Total Scripts\*\*:.*/\*\*Total Scripts\*\*: $total_scripts | \*\*Last Scan\*\*: $(date -Iseconds)/" "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
    sed -i "s/Index Status.*/Index Status**: 🟢 ACTIVE - $total_scripts scripts discovered/" "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
fi

echo "$total_scripts" > "$INDEX_DIR/script_count.txt"

echo ""
echo "✅ Basic indexing complete!"
echo "📄 Results saved to: $results_file"
echo "📊 Found $total_scripts scripts across /opt"
echo ""
echo "Quick Statistics:"
echo "  Health/Check scripts: $health_scripts"
echo "  Deployment scripts: $deploy_scripts"
echo "  Backup scripts: $backup_scripts"
echo ""
echo "🔧 Next steps:"
echo "  1. Use search utility: $INDEX_DIR/search-scripts.sh"
echo "  2. Add metadata to scripts: $INDEX_DIR/update-script-metadata.sh"
echo "  3. View main index: $INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"

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
