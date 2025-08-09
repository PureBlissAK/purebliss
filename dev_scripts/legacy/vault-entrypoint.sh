#!/bin/bash
# Legacy wrapper for vault-entrypoint.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: vault-entrypoint.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "vault-entrypoint.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "vault-entrypoint.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "vault-entrypoint.sh" == *validate* || "vault-entrypoint.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for vault-entrypoint.sh"
    exit 1
fi
