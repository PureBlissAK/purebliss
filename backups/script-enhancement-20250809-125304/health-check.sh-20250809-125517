#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Keycloak container health check"

log_info "Starting Keycloak health check..."

# Basic health endpoint check (to be enhanced)
if curl -sfk https://dev.purebliss.app/keycloak/realms/master; then
  log_success "Keycloak health endpoint responded."
  exit 0
else
  log_error "Keycloak health endpoint failed."
  exit 1
fi
