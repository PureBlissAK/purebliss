#!/bin/bash
# Legacy wrapper for vault-manual-permissions-fix.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: vault-manual-permissions-fix.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "vault-manual-permissions-fix.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "vault-manual-permissions-fix.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "vault-manual-permissions-fix.sh" == *validate* || "vault-manual-permissions-fix.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for vault-manual-permissions-fix.sh"
    exit 1
fi
