#!/bin/bash
# Legacy wrapper for deploy-purebliss-complete.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: deploy-purebliss-complete.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "deploy-purebliss-complete.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "deploy-purebliss-complete.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "deploy-purebliss-complete.sh" == *validate* || "deploy-purebliss-complete.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for deploy-purebliss-complete.sh"
    exit 1
fi
