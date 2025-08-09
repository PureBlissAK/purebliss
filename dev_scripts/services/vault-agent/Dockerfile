# PURE BLISS CONTAINER METADATA
# Container: purebliss-vault-agent
# Purpose: Vault Agent for secret management and authentication proxy
# Scaffolding Phase: Phase 1 - Infrastructure Foundation
# Description: This container provides Vault Agent functionality for AppRole authentication, secret retrieval, and template processing for all services on purebliss-net.
# Production-ready container for Vault integration.
# END METADATA

FROM hashicorp/vault:1.17.3

# Add a simple healthcheck that verifies the agent process is running and port is listening
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD netstat -tuln | grep -q ':8201.*LISTEN' && pgrep vault >/dev/null || exit 1
