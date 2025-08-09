#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE DEV SCRIPTS ENHANCER WITH AUTO-COMMIT
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhance All Scripts in /opt/dev-purebliss/dev_scripts
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="comprehensive-dev-scripts-enhancer.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Comprehensive enhancement of all scripts in dev_scripts with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="$(date +%Y-%m-%d)"
SCRIPT_MODIFIED="$(date +%Y-%m-%d)"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit,comprehensive,metadata"
SCRIPT_SERVICES="all"
SCRIPT_DEPENDENCIES="common-functions-library.sh,batch-script-auto-commit-enhancer.sh"
SCRIPT_DESCRIPTION="Comprehensive script enhancement system that processes all scripts in
/opt/dev-purebliss/dev_scripts with auto-commit functionality, metadata addition, and
Script Index Library updates"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
else
    echo "ERROR: Common functions library not found!"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
comprehensive_dev_scripts_enhancer_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
comprehensive_dev_scripts_enhancer_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
comprehensive_dev_scripts_enhancer_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
comprehensive_dev_scripts_enhancer_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    comprehensive_dev_scripts_enhancer_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        comprehensive_dev_scripts_enhancer_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            comprehensive_dev_scripts_enhancer_log_success "Validation passed - proceeding with auto-commit"
        else
            comprehensive_dev_scripts_enhancer_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        comprehensive_dev_scripts_enhancer_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
            "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        comprehensive_dev_scripts_enhancer_log_info "Auto-commit system not available - manual commit required"
        comprehensive_dev_scripts_enhancer_log_info "Recommended commit message: $commit_message"
        comprehensive_dev_scripts_enhancer_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
comprehensive_dev_scripts_enhancer_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    comprehensive_dev_scripts_enhancer_log_success "$final_message"
    
    # Execute auto-commit wrapper
    comprehensive_dev_scripts_enhancer_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    comprehensive_dev_scripts_enhancer_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE SCRIPT ENHANCEMENT SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════════

# Configuration
ENHANCER_SCRIPT="/opt/dev-purebliss/dev_scripts/automation/batch-script-auto-commit-enhancer.sh"
TARGET_DIR="/opt/dev-purebliss/dev_scripts"
BACKUP_DIR="/opt/dev-purebliss/backups/comprehensive-enhancement-$(date +%Y%m%d-%H%M%S)"
INDEX_LIBRARY="/opt/dev-purebliss/dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md"

# Counters
TOTAL_SCRIPTS=0
ENHANCED_SCRIPTS=0
SKIPPED_SCRIPTS=0
ERROR_SCRIPTS=0

# Initialize
comprehensive_dev_scripts_enhancer_log_info "Starting comprehensive dev_scripts enhancement"
comprehensive_dev_scripts_enhancer_log_info "Target directory: $TARGET_DIR"
comprehensive_dev_scripts_enhancer_log_info "Using enhancer: $ENHANCER_SCRIPT"

# Verify enhancer exists
if [[ ! -f "$ENHANCER_SCRIPT" ]]; then
    comprehensive_dev_scripts_enhancer_log_error "Single script auto-commit enhancer not found: $ENHANCER_SCRIPT"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"
comprehensive_dev_scripts_enhancer_log_success "Backup directory created: $BACKUP_DIR"

# Get list of all shell scripts in dev_scripts
comprehensive_dev_scripts_enhancer_log_info "Discovering scripts in $TARGET_DIR"
mapfile -t ALL_SCRIPTS < <(find "$TARGET_DIR" -name "*.sh" -type f | sort)
TOTAL_SCRIPTS=${#ALL_SCRIPTS[@]}

comprehensive_dev_scripts_enhancer_log_info "Found $TOTAL_SCRIPTS shell scripts to process"

# Create enhancement report
REPORT_FILE="$BACKUP_DIR/enhancement-report.md"
cat << EOF > "$REPORT_FILE"
# Comprehensive Dev Scripts Enhancement Report
**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Total Scripts**: $TOTAL_SCRIPTS
**Target Directory**: $TARGET_DIR
**Backup Directory**: $BACKUP_DIR

## Enhancement Status

EOF

# Process each script
comprehensive_dev_scripts_enhancer_log_info "Starting script-by-script enhancement process"
echo ""

for script_path in "${ALL_SCRIPTS[@]}"; do
    script_name=$(basename "$script_path")
    relative_path=${script_path#$TARGET_DIR/}
    
    echo "🔧 Processing: $relative_path"
    
    # Skip if already this script to avoid recursion
    if [[ "$script_path" == "/opt/dev-purebliss/dev_scripts/automation/comprehensive-dev-scripts-enhancer.sh" ]]; then
        echo "  ⏭️  Skipping self (avoiding recursion)"
        ((SKIPPED_SCRIPTS++)) || true
        echo "| $script_name | Skipped | Self-reference (recursion prevention) |" >> "$REPORT_FILE"
        continue
    fi
    
    # Skip if it's the enhancer itself
    if [[ "$script_path" == "$ENHANCER_SCRIPT" ]]; then
        echo "  ⏭️  Skipping enhancer script"
        ((SKIPPED_SCRIPTS++)) || true
        echo "| $script_name | Skipped | Enhancer script (prevention) |" >> "$REPORT_FILE"
        continue
    fi
    
    # Check if already enhanced (improved detection)
    if grep -q "SCRIPT_METADATA\|AUTO-COMMIT WRAPPER FUNCTIONS\|auto_commit_wrapper\|Enhanced.*script.*with.*auto-commit" "$script_path" 2>/dev/null; then
        echo "  ℹ️  Already enhanced - skipping"
        ((SKIPPED_SCRIPTS++)) || true
        echo "| $script_name | Skipped | Already enhanced |" >> "$REPORT_FILE"
        continue
    fi
    
    # Run the enhancer
    if "$ENHANCER_SCRIPT" "$script_path" 2>/dev/null; then
        echo "  ✅ Enhanced successfully"
        ((ENHANCED_SCRIPTS++)) || true
        echo "| $script_name | ✅ Enhanced | Auto-commit wrappers added |" >> "$REPORT_FILE"
    else
        echo "  ❌ Enhancement failed"
        ((ERROR_SCRIPTS++)) || true
        echo "| $script_name | ❌ Failed | Enhancement error |" >> "$REPORT_FILE"
    fi
    
    echo ""
done

# Update enhancement report with final statistics
cat << EOF >> "$REPORT_FILE"

## Final Statistics

- **Total Scripts**: $TOTAL_SCRIPTS
- **Enhanced**: $ENHANCED_SCRIPTS
- **Skipped**: $SKIPPED_SCRIPTS  
- **Errors**: $ERROR_SCRIPTS
- **Success Rate**: $(( ENHANCED_SCRIPTS * 100 / TOTAL_SCRIPTS ))%

## Enhancement Features Added

For each enhanced script:
- ✅ Auto-commit wrapper functions
- ✅ Script-specific logging functions
- ✅ Pure Bliss Elite auto-commit integration
- ✅ Embedded usage documentation
- ✅ Validation command support

## Next Steps

1. Review enhanced scripts for auto-commit integration
2. Test enhanced scripts with auto-commit functionality
3. Update Script Index Library with new enhancements
4. Consider running health validation on enhanced scripts

**Enhancement Session Completed**: $(date '+%Y-%m-%d %H:%M:%S')
EOF

# Display final results
echo "🎉 COMPREHENSIVE ENHANCEMENT COMPLETE!"
echo "================================="
echo "📊 ENHANCEMENT STATISTICS:"
echo "  Total Scripts: $TOTAL_SCRIPTS"
echo "  Enhanced: $ENHANCED_SCRIPTS"
echo "  Skipped: $SKIPPED_SCRIPTS"
echo "  Errors: $ERROR_SCRIPTS"
echo "  Success Rate: $(( ENHANCED_SCRIPTS * 100 / TOTAL_SCRIPTS ))%"
echo ""
echo "📁 Enhancement Report: $REPORT_FILE"
echo "📁 Backup Directory: $BACKUP_DIR"
echo ""

# Update Script Index Library
if [[ $ENHANCED_SCRIPTS -gt 0 ]]; then
    comprehensive_dev_scripts_enhancer_log_info "Updating Script Index Library with enhancement results"
    
    # Add enhancement session to index library
    if [[ -f "$INDEX_LIBRARY" ]]; then
        cat << EOF >> "$INDEX_LIBRARY"

### 🎯 Comprehensive Enhancement Session - $(date '+%Y-%m-%d %H:%M:%S')

**MASS ENHANCEMENT COMPLETED**: Enhanced $ENHANCED_SCRIPTS out of $TOTAL_SCRIPTS scripts with auto-commit functionality

#### Enhancement Results:
- **Enhanced Scripts**: $ENHANCED_SCRIPTS
- **Skipped Scripts**: $SKIPPED_SCRIPTS (already enhanced or system scripts)
- **Error Scripts**: $ERROR_SCRIPTS
- **Success Rate**: $(( ENHANCED_SCRIPTS * 100 / TOTAL_SCRIPTS ))%

#### Features Added to Each Enhanced Script:
- Auto-commit wrapper functions (\`{script_name}_auto_commit_wrapper()\`)
- Script completion with commit (\`{script_name}_complete_with_commit()\`)
- Standardized logging functions
- Pure Bliss Elite auto-commit system integration
- Embedded usage documentation and examples

#### Enhancement Report: \`$REPORT_FILE\`

EOF
        comprehensive_dev_scripts_enhancer_log_success "Script Index Library updated with enhancement session results"
    else
        comprehensive_dev_scripts_enhancer_log_error "Script Index Library not found: $INDEX_LIBRARY"
    fi
fi

# Final completion with auto-commit
if [[ $ENHANCED_SCRIPTS -gt 0 ]]; then
    comprehensive_dev_scripts_enhancer_complete_with_commit \
        "Comprehensive dev_scripts enhancement completed - $ENHANCED_SCRIPTS scripts enhanced with auto-commit functionality"
else
    comprehensive_dev_scripts_enhancer_log_info "No scripts were enhanced - all were already enhanced or skipped"
fi

echo "🚀 Ready for production use with auto-commit functionality!"
