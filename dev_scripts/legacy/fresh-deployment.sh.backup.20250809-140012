#!/bin/bash
# Legacy wrapper for fresh-deployment.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: fresh-deployment.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "fresh-deployment.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "fresh-deployment.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "fresh-deployment.sh" == *validate* || "fresh-deployment.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for fresh-deployment.sh"
    exit 1
fi
