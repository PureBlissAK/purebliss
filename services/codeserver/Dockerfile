# PURE BLISS CONTAINER METADATA
# Container: purebliss-codeserver
# Purpose: Development environment and IDE for Pure Bliss stack
# Scaffolding Phase: Phase5 - Development Environment Integration
# Description: This container provides VS Code Server for development work. Depends on vault for authentication and workspace access.
# Production Status: production-ready
# Dependencies: vault
# Network: purebliss-net
# Vault Integration: yes
# Last Enhanced: 2025-08-08
# Enhancement Notes: Added complete metadata fields for validation compliance
# END METADATA

FROM codercom/code-server:4.20.0

USER root

# Install necessary packages for development
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Vault CLI for secret management
RUN wget -O- https://releases.hashicorp.com/vault/1.17.3/vault_1.17.3_linux_amd64.zip | \
    unzip - && \
    mv vault /usr/local/bin/ && \
    chmod +x /usr/local/bin/vault

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch back to coder user
USER coder

# Healthcheck for VS Code Server
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080 || exit 1

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
