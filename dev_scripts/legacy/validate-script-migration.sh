#!/bin/bash
# Legacy wrapper for validate-script-migration.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: validate-script-migration.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "validate-script-migration.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "validate-script-migration.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "validate-script-migration.sh" == *validate* || "validate-script-migration.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for validate-script-migration.sh"
    exit 1
fi
