#!/bin/bash
# Legacy wrapper for start-postgres-vault.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: start-postgres-vault.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "start-postgres-vault.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "start-postgres-vault.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "start-postgres-vault.sh" == *validate* || "start-postgres-vault.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for start-postgres-vault.sh"
    exit 1
fi
