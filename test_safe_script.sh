#!/bin/bash
set -euo pipefail

# Test script for validation - this should pass safety checks
echo "Test script starting"

# Simple function that doesn't cause issues
test_function() {
    local message="$1"
    echo "Test: $message"
    return 0
}

# Call the function
test_function "Hello World"

echo "Test script completed successfully"
