#!/bin/bash
# Legacy wrapper for automate-vault-integration.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: automate-vault-integration.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "automate-vault-integration.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "automate-vault-integration.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "automate-vault-integration.sh" == *validate* || "automate-vault-integration.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for automate-vault-integration.sh"
    exit 1
fi
