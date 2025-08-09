#!/bin/bash
# Legacy wrapper for deploy-with-vault.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: deploy-with-vault.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "deploy-with-vault.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "deploy-with-vault.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "deploy-with-vault.sh" == *validate* || "deploy-with-vault.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for deploy-with-vault.sh"
    exit 1
fi
