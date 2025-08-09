#!/bin/bash
# Legacy wrapper for vault-http-init.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: vault-http-init.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "vault-http-init.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "vault-http-init.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "vault-http-init.sh" == *validate* || "vault-http-init.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for vault-http-init.sh"
    exit 1
fi
