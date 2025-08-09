#!/bin/bash
# Legacy wrapper for validate-project-plan-enhancements-simple.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: validate-project-plan-enhancements-simple.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "validate-project-plan-enhancements-simple.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "validate-project-plan-enhancements-simple.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "validate-project-plan-enhancements-simple.sh" == *validate* || "validate-project-plan-enhancements-simple.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for validate-project-plan-enhancements-simple.sh"
    exit 1
fi
