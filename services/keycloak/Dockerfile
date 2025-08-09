# PURE BLISS CONTAINER METADATA
# Container: purebliss-keycloak
# Purpose: Authentication and identity management service for Pure Bliss
# Scaffolding Phase: Phase3 - Core Service Integration
# Description: This container provides Keycloak OIDC/SAML authentication for all services. Depends on postgres, redis, and vault. Must be attached to purebliss-net.
# Production Status: production-ready
# Dependencies: postgres,redis,vault
# Network: purebliss-net
# Vault Integration: yes
# Last Enhanced: 2025-08-08
# Enhancement Notes: Added complete metadata fields for validation compliance
# END METADATA

# Stage 1: Builder stage to compile dependencies and get all shared libraries
FROM fedora:latest AS builder

# Install necessary tools and get all required shared libraries
RUN dnf install -y jq nmap-ncat curl postgresql && dnf clean all

# Get all shared libraries needed by curl and other tools
RUN mkdir -p /tmp/deps && \
    ldd /usr/bin/curl | grep -o '/[^[:space:]]*' | grep -E '\.(so|so\.[0-9]+)' | xargs -I {} cp {} /tmp/deps/ || true && \
    ldd /usr/bin/jq | grep -o '/[^[:space:]]*' | grep -E '\.(so|so\.[0-9]+)' | xargs -I {} cp {} /tmp/deps/ || true && \
    ldd /usr/bin/nc | grep -o '/[^[:space:]]*' | grep -E '\.(so|so\.[0-9]+)' | xargs -I {} cp {} /tmp/deps/ || true && \
    ldd /usr/bin/psql | grep -o '/[^[:space:]]*' | grep -E '\.(so|so\.[0-9]+)' | xargs -I {} cp {} /tmp/deps/ || true

# Stage 2: Final Keycloak image
FROM quay.io/keycloak/keycloak:24.0.5

USER root

# Copy the compiled tools and ALL their dependencies from the builder stage
COPY --from=builder /usr/bin/jq /usr/bin/jq
COPY --from=builder /usr/bin/nc /usr/bin/nc
COPY --from=builder /usr/bin/curl /usr/bin/curl
COPY --from=builder /usr/bin/psql /usr/bin/psql
COPY --from=builder /tmp/deps/* /usr/lib64/

# Copy the entrypoint script and make it executable
COPY entrypoint.sh /opt/keycloak/bin/
RUN chmod +x /opt/keycloak/bin/entrypoint.sh

# Switch back to the default Keycloak user
USER 1000

# Set the entrypoint
ENTRYPOINT ["/opt/keycloak/bin/entrypoint.sh"]

# --- Autonomous Enhancement: Override default healthcheck ---
# Root Cause: The base Keycloak 24.0.5 image has a default healthcheck pointing to a non-existent endpoint (/health/ready).
# Prevention: Override the HEALTHCHECK instruction to use the correct endpoint (/realms/master) for this version.
# This ensures the container's health status is accurately reported by Docker.
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=2 \
  CMD ["sh", "-c", "curl -f http://localhost:8080/realms/master || exit 1"]
