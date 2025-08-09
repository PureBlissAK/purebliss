#!/bin/bash
# Legacy wrapper for enhance-keycloak-vault-integration.sh
# This script has been consolidated - calling enhanced consolidated version

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
source "$SCRIPT_DIR/utilities/common-functions-library.sh"

log_info "DEPRECATED: enhance-keycloak-vault-integration.sh - Using consolidated functionality"

# Determine which consolidated script to call based on original script purpose
if [[ "enhance-keycloak-vault-integration.sh" == *vault* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh" "$@"
elif [[ "enhance-keycloak-vault-integration.sh" == *deploy* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-deployment.sh" "$@"
elif [[ "enhance-keycloak-vault-integration.sh" == *validate* || "enhance-keycloak-vault-integration.sh" == *check* ]]; then
    exec "$SCRIPT_DIR/utilities/consolidated-validation.sh" "$@"
else
    log_error "No consolidated replacement found for enhance-keycloak-vault-integration.sh"
    exit 1
fi
