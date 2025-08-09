#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

SCRIPT_NAME="setup-letsencrypt.sh"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Scaffold and start the LetsEncrypt container for Pure Bliss development."

log_info "[letsencrypt] Starting LetsEncrypt container scaffolding setup."

# Build and run LetsEncrypt container using Docker Compose
if [ ! -f docker-compose.letsencrypt.yml ]; then
    log_error "docker-compose.letsencrypt.yml not found in $(pwd)"
    exit 1
fi

docker compose -f docker-compose.letsencrypt.yml up -d
log_info "[letsencrypt] LetsEncrypt container started via Docker Compose."

# Health validation (initial)
$SCRIPT_DIR/core/validate-container-health.sh letsencrypt initial-setup

log_success "[letsencrypt] Initial LetsEncrypt container setup and health validation complete."
