#!/bin/bash
# Legacy wrapper for validate-deployment-readiness.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: validate-deployment-readiness.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "validate-deployment-readiness.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "validate-deployment-readiness.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "validate-deployment-readiness.sh" == *validate* || "validate-deployment-readiness.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for validate-deployment-readiness.sh"
    exit 1
fi
