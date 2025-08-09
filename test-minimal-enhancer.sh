#!/bin/bash
set -euo pipefail

# Minimal script enhancer test
echo "Starting minimal test..."

# Source common functions
source "/opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh"

# Test discovery
echo "Testing discovery..."
script_count=0
while IFS= read -r script_file; do
    echo "Found: $script_file"
    ((script_count++))
    if [[ $script_count -ge 5 ]]; then
        echo "Stopping at 5 scripts for test"
        break
    fi
done < <(find /opt/dev-purebliss -name "*.sh" -type f 2>/dev/null)

echo "Discovery test complete: $script_count scripts found"

# Test safety validation on one script
test_script="/opt/dev-purebliss/test_safe_script.sh"
if [[ -f "$test_script" ]]; then
    echo "Testing safety validation on: $test_script"

    # Basic syntax check
    if bash -n "$test_script"; then
        echo "✅ Syntax check passed"
    else
        echo "❌ Syntax check failed"
    fi

    # Check for basic patterns
    if grep -q "while true" "$test_script"; then
        echo "⚠️  Found potential infinite loop"
    else
        echo "✅ No obvious infinite loops"
    fi
else
    echo "Test script not found: $test_script"
fi

echo "Minimal test complete!"
