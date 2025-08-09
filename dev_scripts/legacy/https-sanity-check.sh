#!/bin/bash
# Legacy wrapper for https-sanity-check.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: https-sanity-check.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "https-sanity-check.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "https-sanity-check.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "https-sanity-check.sh" == *validate* || "https-sanity-check.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for https-sanity-check.sh"
    exit 1
fi
