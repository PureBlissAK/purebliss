#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

SCRIPT_NAME="test-nginx-restart.sh"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Test Nginx container restart and validate health."

log_info "[nginx] Restarting Nginx container for reboot validation."

docker restart purebliss-nginx
sleep 10

$SCRIPT_DIR/core/validate-container-health.sh nginx restart-test

log_success "[nginx] Nginx container restart and health validation complete."
