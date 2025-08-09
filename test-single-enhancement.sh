#!/bin/bash
set -euo pipefail

# Quick test of enhancement on a single script
echo "=== TESTING SINGLE SCRIPT ENHANCEMENT ==="

# Source common functions
source "/opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh"

# Test script path
TEST_SCRIPT="/opt/dev-purebliss/simple-test-script.sh"

echo "Testing enhancement on: $TEST_SCRIPT"

# Create backup
BACKUP_DIR="/opt/dev-purebliss/backups/single-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$TEST_SCRIPT" "$BACKUP_DIR/"

echo "✅ Backup created"

# Check if script needs enhancement (basic check)
if ! grep -q "SCRIPT_NAME\|SCRIPT_VERSION" "$TEST_SCRIPT"; then
    echo "✅ Script needs enhancement - adding metadata"

    # Create enhanced version
    TEMP_ENHANCED="/tmp/enhanced_test.sh"

    # Add header
    cat << 'EOF' > "$TEMP_ENHANCED"
#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SIMPLE_TEST_SCRIPT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="simple-test-script.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced script for general with standardized metadata and wrapper functions"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,testing"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Enhanced script for general with standardized metadata and wrapper functions with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
simple_test_script_log_info() {
    local message="$1"
    log_info "${SCRIPT_NAME}: $message"
}

# Wrapper for standardized error logging with script context
simple_test_script_log_error() {
    local message="$1"
    log_error "${SCRIPT_NAME}: $message"
}

# Wrapper for standardized success logging with script context
simple_test_script_log_success() {
    local message="$1"
    log_success "${SCRIPT_NAME}: $message"
}

EOF

    # Add original content (skip first line - shebang)
    tail -n +2 "$TEST_SCRIPT" >> "$TEMP_ENHANCED"

    # Validate syntax
    if bash -n "$TEMP_ENHANCED"; then
        echo "✅ Enhanced script syntax is valid"

        # Replace original
        mv "$TEMP_ENHANCED" "$TEST_SCRIPT"
        chmod +x "$TEST_SCRIPT"

        echo "✅ Script enhanced successfully!"
        echo ""
        echo "=== ENHANCED SCRIPT PREVIEW ==="
        head -20 "$TEST_SCRIPT"
        echo ""
        echo "✅ Enhancement complete!"
    else
        echo "❌ Enhanced script has syntax errors"
        rm -f "$TEMP_ENHANCED"
    fi
else
    echo "ℹ️  Script already has metadata"
fi

echo ""
echo "=== TEST COMPLETE ==="
