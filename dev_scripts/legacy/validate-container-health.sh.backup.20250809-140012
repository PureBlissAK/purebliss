#!/bin/bash
# Legacy wrapper for validate-container-health.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: validate-container-health.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "validate-container-health.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "validate-container-health.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "validate-container-health.sh" == *validate* || "validate-container-health.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for validate-container-health.sh"
    exit 1
fi
