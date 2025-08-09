#!/bin/bash
# Legacy wrapper for enhance-container-with-vault.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: enhance-container-with-vault.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "enhance-container-with-vault.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "enhance-container-with-vault.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "enhance-container-with-vault.sh" == *validate* || "enhance-container-with-vault.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for enhance-container-with-vault.sh"
    exit 1
fi
