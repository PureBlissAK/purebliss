#!/bin/bash
# Legacy wrapper for update-vault-script-references.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: update-vault-script-references.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "update-vault-script-references.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "update-vault-script-references.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "update-vault-script-references.sh" == *validate* || "update-vault-script-references.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for update-vault-script-references.sh"
    exit 1
fi
