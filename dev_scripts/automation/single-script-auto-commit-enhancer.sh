#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SINGLE SCRIPT AUTO-COMMIT ENHANCER
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhance Single Script with Auto-Commit Functionality

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

TARGET_SCRIPT="$1"

if [[ -z "$TARGET_SCRIPT" ]]; then
    echo "Usage: $0 <script-path>"
    exit 1
fi

if [[ ! -f "$TARGET_SCRIPT" ]]; then
    echo "Error: Script not found: $TARGET_SCRIPT"
    exit 1
fi

log_info "Enhancing single script with auto-commit functionality: $TARGET_SCRIPT"

# Create backup
BACKUP_FILE="${TARGET_SCRIPT}.backup.$(date +%Y%m%d-%H%M%S)"
cp "$TARGET_SCRIPT" "$BACKUP_FILE"
log_success "Backup created: $BACKUP_FILE"

# Extract script name for wrapper functions
SCRIPT_NAME=$(basename "$TARGET_SCRIPT")
WRAPPER_PREFIX=$(echo "${SCRIPT_NAME%.*}" | tr '-' '_' | tr '.' '_')

# Check if already enhanced
if grep -q "auto_commit_wrapper\|SCRIPT_METADATA" "$TARGET_SCRIPT"; then
    log_warn "Script already appears to be enhanced"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Create enhanced version
TEMP_ENHANCED="/tmp/enhanced_${SCRIPT_NAME}_$$"

# Determine script category
CATEGORY="utilities"
SERVICES="general"
case "$TARGET_SCRIPT" in
    *cleanup*) CATEGORY="maintenance"; SERVICES="system" ;;
    *health*) CATEGORY="health-validation"; SERVICES="monitoring" ;;
    *status*) CATEGORY="monitoring"; SERVICES="system" ;;
    *redis*) CATEGORY="validation"; SERVICES="redis" ;;
    *vault*) CATEGORY="vault-integration"; SERVICES="vault" ;;
    *test*) CATEGORY="testing"; SERVICES="development" ;;
esac

# Generate tags
TAGS="enhancement,automation,auto-commit"
echo "$TARGET_SCRIPT" | grep -q "health\|status" && TAGS+=",monitoring" || true
echo "$TARGET_SCRIPT" | grep -q "cleanup\|maintenance" && TAGS+=",maintenance" || true
echo "$TARGET_SCRIPT" | grep -q "vault" && TAGS+=",vault,security" || true
echo "$TARGET_SCRIPT" | grep -q "test" && TAGS+=",testing,validation" || true

# Create enhanced header
cat << EOF > "$TEMP_ENHANCED"
#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# $(echo "$SCRIPT_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_' | tr '.' '_')
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="$SCRIPT_NAME"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced $CATEGORY script for $SERVICES operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="$(date +%Y-%m-%d)"
SCRIPT_MODIFIED="$(date +%Y-%m-%d)"
SCRIPT_CATEGORY="$CATEGORY"
SCRIPT_TAGS="$TAGS"
SCRIPT_SERVICES="$SERVICES"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced $CATEGORY script for $SERVICES with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "\$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "\$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
${WRAPPER_PREFIX}_log_info() {
    local message="\$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "\${SCRIPT_NAME}: \$message"
    else
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - [INFO] \${SCRIPT_NAME}: \$message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
${WRAPPER_PREFIX}_log_error() {
    local message="\$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "\${SCRIPT_NAME}: \$message"
    else
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] \${SCRIPT_NAME}: \$message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
${WRAPPER_PREFIX}_log_success() {
    local message="\$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "\${SCRIPT_NAME}: \$message"
    else
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] \${SCRIPT_NAME}: \$message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
${WRAPPER_PREFIX}_auto_commit_wrapper() {
    local commit_message="\${1:-"Auto-commit: \${SCRIPT_NAME} executed successfully"}"
    local validation_command="\${2:-}"
    
    ${WRAPPER_PREFIX}_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "\$validation_command" ]]; then
        ${WRAPPER_PREFIX}_log_info "Running validation: \$validation_command"
        if eval "\$validation_command"; then
            ${WRAPPER_PREFIX}_log_success "Validation passed - proceeding with auto-commit"
        else
            ${WRAPPER_PREFIX}_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        ${WRAPPER_PREFIX}_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
            "\${SCRIPT_CATEGORY}" "\$commit_message" "\${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "\${SCRIPT_NAME}" "\$commit_message"
    else
        ${WRAPPER_PREFIX}_log_info "Auto-commit system not available - manual commit required"
        ${WRAPPER_PREFIX}_log_info "Recommended commit message: \$commit_message"
        ${WRAPPER_PREFIX}_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
${WRAPPER_PREFIX}_complete_with_commit() {
    local final_message="\${1:-"\${SCRIPT_NAME} completed successfully"}"
    local validation_command="\${2:-}"
    
    # Log successful completion
    ${WRAPPER_PREFIX}_log_success "\$final_message"
    
    # Execute auto-commit wrapper
    ${WRAPPER_PREFIX}_auto_commit_wrapper "Auto-commit: \$final_message" "\$validation_command"
    
    # Final status
    ${WRAPPER_PREFIX}_log_success "\${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

EOF

# Add original content (skip shebang and set commands)
tail -n +1 "$TARGET_SCRIPT" | grep -v '^#!/bin/bash' | grep -v '^set -' >> "$TEMP_ENHANCED"

# Add auto-commit usage examples footer
cat << 'AUTO_COMMIT_FOOTER' >> "$TEMP_ENHANCED"

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
AUTO_COMMIT_FOOTER

# Validate enhanced script
if bash -n "$TEMP_ENHANCED"; then
    # Replace original with enhanced version
    mv "$TEMP_ENHANCED" "$TARGET_SCRIPT"
    chmod +x "$TARGET_SCRIPT"
    log_success "Script enhanced successfully with auto-commit functionality"
    
    # Show what was added
    echo ""
    echo "🚀 AUTO-COMMIT ENHANCEMENTS ADDED:"
    echo "  ✅ Script metadata and headers"
    echo "  ✅ Auto-commit wrapper functions:"
    echo "     - ${WRAPPER_PREFIX}_auto_commit_wrapper()"
    echo "     - ${WRAPPER_PREFIX}_complete_with_commit()"
    echo "     - ${WRAPPER_PREFIX}_log_info/error/success()"
    echo "  ✅ Usage examples and documentation"
    echo ""
    echo "📝 NEXT STEPS:"
    echo "  1. Add '${WRAPPER_PREFIX}_complete_with_commit \"Your success message\"' at the end of your script"
    echo "  2. Optionally add validation commands for automated testing"
    echo "  3. Run your enhanced script to test auto-commit functionality"
    echo ""
    
else
    log_error "Enhanced script has syntax errors - reverting"
    rm -f "$TEMP_ENHANCED"
    exit 1
fi
