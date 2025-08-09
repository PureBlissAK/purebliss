#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="plane-docker-image-check.sh"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Check Plane Docker image availability and provide remediation guidance."

log_info "Checking Plane Docker image availability..."

if docker pull makeplane/plane:app-latest 2>&1 | grep -q 'pull access denied'; then
    log_error "Plane Docker image 'makeplane/plane:app-latest' is not public or does not exist."
    log_info "Refer to https://developers.plane.so/self-hosting/methods/docker-compose for official install instructions."
    log_info "Next step: Use Plane's official install script or build from source."
    exit 1
else
    log_success "Plane Docker image 'makeplane/plane:app-latest' is available."
    exit 0
fi
