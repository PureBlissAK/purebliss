#!/bin/bash
# Legacy wrapper for comprehensive-health-check.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: comprehensive-health-check.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "comprehensive-health-check.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "comprehensive-health-check.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "comprehensive-health-check.sh" == *validate* || "comprehensive-health-check.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for comprehensive-health-check.sh"
    exit 1
fi
