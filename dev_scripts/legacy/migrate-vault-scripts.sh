#!/bin/bash
# Legacy wrapper for migrate-vault-scripts.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: migrate-vault-scripts.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "migrate-vault-scripts.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "migrate-vault-scripts.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "migrate-vault-scripts.sh" == *validate* || "migrate-vault-scripts.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for migrate-vault-scripts.sh"
    exit 1
fi
