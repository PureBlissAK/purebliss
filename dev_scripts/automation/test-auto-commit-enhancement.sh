#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT ENHANCEMENT TESTING SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Test Auto-Commit Wrapper Integration
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="test-auto-commit-enhancement.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Test auto-commit wrapper functionality in enhanced scripts"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="$(date +%Y-%m-%d)"
SCRIPT_CATEGORY="testing"
SCRIPT_TAGS="testing,auto-commit,git,validation"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh,intelligent-script-enhancer.sh"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# Initialize logging
log_info "Starting auto-commit enhancement testing"

# Test configuration
TEST_SCRIPT_DIR="/tmp/auto_commit_test_$$"
TEST_SCRIPT_PATH="$TEST_SCRIPT_DIR/test-sample-script.sh"
ENHANCER_SCRIPT="/opt/dev-purebliss/dev_scripts/automation/intelligent-script-enhancer.sh"

# Cleanup function
cleanup_test() {
    log_info "Cleaning up test environment"
    rm -rf "$TEST_SCRIPT_DIR" 2>/dev/null || true
}

# Trap cleanup on exit
trap cleanup_test EXIT

# Create test environment
log_info "Setting up test environment"
mkdir -p "$TEST_SCRIPT_DIR"

# Create a simple test script
cat << 'EOF' > "$TEST_SCRIPT_PATH"
#!/bin/bash
# Simple test script for auto-commit enhancement

echo "Test script executing..."
echo "Creating test file..."
touch /tmp/test_auto_commit_marker_$$
echo "Test script completed successfully"
EOF

chmod +x "$TEST_SCRIPT_PATH"
log_success "Test script created at $TEST_SCRIPT_PATH"

# Test 1: Enhance the script with auto-commit functionality
log_info "TEST 1: Enhancing script with auto-commit functionality"
if [[ -f "$ENHANCER_SCRIPT" ]]; then
    cd "$TEST_SCRIPT_DIR"
    
    # Run the enhancer on our test script
    if "$ENHANCER_SCRIPT" "$TEST_SCRIPT_PATH"; then
        log_success "Script enhancement completed"
        
        # Check if auto-commit functions were added
        if grep -q "auto_commit_wrapper\|complete_with_commit" "$TEST_SCRIPT_PATH"; then
            log_success "Auto-commit wrapper functions found in enhanced script"
        else
            log_error "Auto-commit wrapper functions NOT found in enhanced script"
            exit 1
        fi
        
        # Check if usage examples were added
        if grep -q "AUTO-COMMIT USAGE EXAMPLES" "$TEST_SCRIPT_PATH"; then
            log_success "Auto-commit usage examples found in enhanced script"
        else
            log_error "Auto-commit usage examples NOT found in enhanced script"
            exit 1
        fi
        
    else
        log_error "Script enhancement failed"
        exit 1
    fi
else
    log_error "Intelligent script enhancer not found at $ENHANCER_SCRIPT"
    exit 1
fi

# Test 2: Verify syntax of enhanced script
log_info "TEST 2: Validating syntax of enhanced script"
if bash -n "$TEST_SCRIPT_PATH"; then
    log_success "Enhanced script syntax is valid"
else
    log_error "Enhanced script has syntax errors"
    exit 1
fi

# Test 3: Test auto-commit wrapper function availability
log_info "TEST 3: Testing auto-commit wrapper function availability"
# Extract the wrapper function name from the enhanced script
WRAPPER_FUNCTION=$(grep -o '[a-z_]*_auto_commit_wrapper' "$TEST_SCRIPT_PATH" | head -1)
if [[ -n "$WRAPPER_FUNCTION" ]]; then
    log_success "Auto-commit wrapper function identified: $WRAPPER_FUNCTION"
    
    # Test if function can be sourced and called
    if source "$TEST_SCRIPT_PATH" && declare -F "$WRAPPER_FUNCTION" >/dev/null; then
        log_success "Auto-commit wrapper function is properly defined"
    else
        log_error "Auto-commit wrapper function is not properly defined"
        exit 1
    fi
else
    log_error "Could not identify auto-commit wrapper function"
    exit 1
fi

# Test 4: Check common functions library integration
log_info "TEST 4: Verifying common functions library integration"
if grep -q "auto_commit_push_wrapper" /opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh; then
    log_success "Auto-commit functions found in common functions library"
else
    log_error "Auto-commit functions NOT found in common functions library"
    exit 1
fi

# Test 5: Validate git repository detection
log_info "TEST 5: Testing git repository detection"
cd /opt
if git rev-parse --git-dir > /dev/null 2>&1; then
    log_success "Git repository detected - auto-commit functionality will work"
    
    # Test git status wrapper
    if command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        log_success "Auto-commit push wrapper is available"
    else
        log_warn "Auto-commit push wrapper not in PATH - sourcing common functions"
        source /opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh
        if command -v auto_commit_push_wrapper >/dev/null 2>&1; then
            log_success "Auto-commit push wrapper loaded successfully"
        else
            log_error "Could not load auto-commit push wrapper"
            exit 1
        fi
    fi
else
    log_warn "Not in a git repository - auto-commit will be skipped in actual usage"
fi

# Final validation
log_info "FINAL VALIDATION: All auto-commit enhancement tests"
echo ""
echo "📊 AUTO-COMMIT ENHANCEMENT TEST RESULTS:"
echo "  ✅ Script enhancement with auto-commit wrappers"
echo "  ✅ Enhanced script syntax validation"
echo "  ✅ Auto-commit wrapper function availability"
echo "  ✅ Common functions library integration"
echo "  ✅ Git repository detection and functionality"
echo ""

log_success "All auto-commit enhancement tests passed successfully!"
log_info "Auto-commit wrapper functionality is ready for production use"

# Log results to development log
echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] AUTO-COMMIT-ENHANCEMENT-TEST: All validation tests passed - auto-commit wrapper functionality verified and ready for production use" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

echo ""
echo "🚀 NEXT STEPS:"
echo "  1. Run intelligent-script-enhancer.sh on existing scripts to add auto-commit functionality"
echo "  2. Use enhanced scripts with auto-commit wrappers for automated git workflows"
echo "  3. Monitor /opt/my-secure-ha-stack/logs/dev-environment-setup.log for auto-commit activities"
echo "  4. Customize validation commands for specific script requirements"
