#!/bin/bash
set -euo pipefail

# Use the fresh PostgreSQL startup with Vault integration
exec /opt/dev-purebliss/services/postgres/start-fresh.sh
