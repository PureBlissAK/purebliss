#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

SCRIPT_NAME="test-letsencrypt-restart.sh"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Test LetsEncrypt container restart and validate health."

log_info "[letsencrypt] Restarting LetsEncrypt container for reboot validation."

docker restart purebliss-letsencrypt
sleep 10

$SCRIPT_DIR/core/validate-container-health.sh letsencrypt restart-test

log_success "[letsencrypt] LetsEncrypt container restart and health validation complete."
