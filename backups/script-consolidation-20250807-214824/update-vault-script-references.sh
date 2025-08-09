#!/bin/bash
# Update all references to vault scripts to use centralized paths

CENTRAL_BASE="/opt/dev-purebliss/dev_scripts/services/vault"

# Update common script references in other files
find /opt/dev-purebliss -name "*.sh" -type f -exec sed -i "s|/opt/dev-purebliss/services/vault/vault-init-automation.sh|${CENTRAL_BASE}/automation/vault-init-automation.sh|g" {} \;
find /opt/dev-purebliss -name "*.sh" -type f -exec sed -i "s|/opt/dev-purebliss/services/vault/vault-auto-unseal.sh|${CENTRAL_BASE}/automation/vault-auto-unseal.sh|g" {} \;
find /opt/dev-purebliss -name "*.sh" -type f -exec sed -i "s|/opt/dev-purebliss/services/vault/test-vault-init.sh|${CENTRAL_BASE}/health-checks/test-vault-init.sh|g" {} \;

echo "Updated vault script references to centralized locations"
