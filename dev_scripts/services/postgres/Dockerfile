## PURE BLISS CONTAINER METADATA
# Container: purebliss-postgres
# Purpose: Production PostgreSQL instance for Pure Bliss stack
# Scaffolding Phase: Phase 2 - Database Service Integration
# Description: This container provides the PostgreSQL backend for all core services on the purebliss-net network. It must be discoverable as 'postgres' by all dependent containers.
# DO NOT use for scaffolding or development-only tasks.
## END METADATA
FROM postgres:16

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD pg_isready -U postgres || exit 1

FROM postgres:16

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD pg_isready -U postgres || exit 1
