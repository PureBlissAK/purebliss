#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

SCRIPT_NAME="document-letsencrypt.sh"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Generate LetsEncrypt container documentation and run final health validation."

log_info "[letsencrypt] Generating LetsEncrypt container documentation."

cat > "$DOC_DIR/letsencrypt-container-documentation.md" <<EOF
# LetsEncrypt Container - Pure Bliss Scaffolding

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Purpose:** Automated SSL certificate provisioning for Nginx and other services
**Consolidation Type:** automation
**Services Covered:** letsencrypt

## Overview
LetsEncrypt provides automated SSL certificate issuance and renewal for Pure Bliss services. This scaffolding phase validates container health, restart survival, and integration with Vault PKI.

## Health Validation
- Docker health: `docker ps | grep purebliss-letsencrypt`
- Restart test: `docker restart purebliss-letsencrypt && sleep 10 && docker ps | grep purebliss-letsencrypt`
- Log validation: `docker logs purebliss-letsencrypt --since=5m | grep -i "error|critical|fatal" || echo "No critical errors found"`

## Configuration
- Docker Compose: [scaffolding/letsencrypt/docker-compose.letsencrypt.yml]
- Cert storage: /opt/my-secure-ha-stack/nginx/certs

## Integration Points
- Vault: PKI integration for secure certificate management
- Nginx: Consumes issued certificates for HTTPS

## Validation Results
- All health checks must pass before integration with Nginx.

EOF

log_info "[letsencrypt] Documentation generated. Running final health validation."

$SCRIPT_DIR/core/validate-container-health.sh letsencrypt documentation

log_success "[letsencrypt] LetsEncrypt documentation and final health validation complete."
