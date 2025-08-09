#!/bin/bash
set -euo pipefail

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Vault container init - waiting for vault to start"

# Wait for vault to be available
sleep 10

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Checking vault status"

# Simple health check using wget (available in vault container)
if wget --quiet --tries=3 --timeout=10 --spider https://localhost:8200/v1/sys/health 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Vault is responding to health checks"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Vault health check failed"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Vault container initialization complete"
