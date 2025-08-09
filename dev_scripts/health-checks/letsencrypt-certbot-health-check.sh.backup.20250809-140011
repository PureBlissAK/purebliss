#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="LetsEncrypt certbot job health validation (one-shot)"

CERTBOT_CONTAINER="purebliss-letsencrypt"
CERTBOT_CMD="certbot certonly --standalone --dry-run -d example.com"

log_info "Starting LetsEncrypt certbot health validation job..."
docker run --rm \
  --name "$CERTBOT_CONTAINER" \
  -v "$(pwd)/certs:/etc/letsencrypt" \
  -v "$(pwd)/logs:/var/log/letsencrypt" \
  certbot/certbot:latest $CERTBOT_CMD > certbot-job.log 2>&1 || {
    log_error "Certbot job failed. See certbot-job.log for details."
    exit 1
}

if grep -q "Congratulations" certbot-job.log || grep -q "The dry run was successful" certbot-job.log; then
  log_success "Certbot job completed successfully."
else
  log_error "Certbot job did not complete successfully. See certbot-job.log."
  exit 1
fi

log_info "Validating certbot logs for errors..."
grep -i "error\|critical\|fatal" certbot-job.log && {
  log_error "Errors found in certbot job log."
  exit 1
} || log_success "No critical errors found in certbot job log."

log_success "LetsEncrypt certbot health validation passed."
