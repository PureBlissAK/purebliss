#!/bin/bash
# Legacy wrapper for auto-health-check-all.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: auto-health-check-all.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "auto-health-check-all.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "auto-health-check-all.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "auto-health-check-all.sh" == *validate* || "auto-health-check-all.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for auto-health-check-all.sh"
    exit 1
fi
