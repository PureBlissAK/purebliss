#!/bin/bash
set -euo pipefail

# Simple Vault initialization and unseal for development
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting simple Vault initialization"

# Wait for Vault to be ready
sleep 5

# Check if vault-keys.txt exists on the host (mounted volume)
if [[ -f "/opt/my-secure-ha-stack/vault-keys.txt" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Found existing vault-keys.txt, attempting unseal"

    # Extract unseal key from vault-keys.txt (first line is unseal key)
    UNSEAL_KEY=$(head -n 1 /opt/my-secure-ha-stack/vault-keys.txt)

    # Check if vault is sealed
    if curl -sk -f https://localhost:8200/v1/sys/health | grep -q '"sealed":true'; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Vault is sealed, unsealing with existing key"

        # Use wget instead of curl for unsealing
        wget --quiet \
             --method=POST \
             --header="Content-Type: application/json" \
             --body-data="{\"key\": \"$UNSEAL_KEY\"}" \
             --output-document=- \
             https://localhost:8200/v1/sys/unseal || {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to unseal vault"
            exit 1
        }

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Vault unsealed successfully"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Vault is already unsealed"
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: No existing vault-keys.txt found, vault needs manual initialization"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Vault initialization script completed"
