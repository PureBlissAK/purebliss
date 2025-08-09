#!/bin/bash
# Legacy wrapper for test-vault-init.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: test-vault-init.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "test-vault-init.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "test-vault-init.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "test-vault-init.sh" == *validate* || "test-vault-init.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for test-vault-init.sh"
    exit 1
fi
