#!/bin/bash
# Legacy wrapper for deploy-nginx-enhanced.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: deploy-nginx-enhanced.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "deploy-nginx-enhanced.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "deploy-nginx-enhanced.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "deploy-nginx-enhanced.sh" == *validate* || "deploy-nginx-enhanced.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for deploy-nginx-enhanced.sh"
    exit 1
fi
