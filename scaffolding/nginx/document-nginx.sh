#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

SCRIPT_NAME="document-nginx.sh"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Generate Nginx container documentation and run final health validation."

log_info "[nginx] Generating Nginx container documentation."

cat > "$DOC_DIR/nginx-container-documentation.md" <<EOF
# Nginx Container - Pure Bliss Scaffolding

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Purpose:** Gateway for all Pure Bliss services, SSL/TLS enforced
**Consolidation Type:** automation
**Services Covered:** nginx

## Overview
Nginx serves as the secure gateway for all Pure Bliss services, enforcing HTTPS and smart upstream logic. This scaffolding phase validates container health, restart survival, and SSL configuration.

## Health Validation
- Docker health: \\`docker ps | grep purebliss-nginx\\`
- Service health: \\`curl -k -s -o /dev/null -w "%{http_code}" https://localhost/\\` (expect 200)
- Restart test: \\`docker restart purebliss-nginx && sleep 10 && curl -k -s -o /dev/null -w "%{http_code}" https://localhost/\\`
- Log validation: \\`docker logs purebliss-nginx --since=5m | grep -i "error|critical|fatal" || echo "No critical errors found"\\`

## Configuration
- Docker Compose: [scaffolding/nginx/docker-compose.nginx.yml]
- Nginx config: [scaffolding/nginx/nginx.conf]
- SSL certs: /opt/my-secure-ha-stack/nginx/certs

## Integration Points
- Vault: SSL certs managed via Vault PKI
- Upstream: Smart upstream logic to be added in later phases

## Validation Results
- All health checks must pass before integration with other services.

EOF

log_info "[nginx] Documentation generated. Running final health validation."

$SCRIPT_DIR/core/validate-container-health.sh nginx documentation

log_success "[nginx] Nginx documentation and final health validation complete."
