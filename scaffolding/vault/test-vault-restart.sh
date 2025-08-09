#!/bin/bash
set -euo pipefail

# Vault Restart Test Script
# Step 2 of Scaffolding: Test Vault Container Restart Robustness

echo "🔄 Starting Vault Restart Test"
echo "==============================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTH_SCRIPT="/opt/dev-purebliss/scaffolding/scripts/health-check.sh"

# Step 1: Verify Vault is currently running
echo "Step 1: Verifying Vault is currently running..."
if ! $HEALTH_SCRIPT "purebliss-vault-scaffolding" "8200" "/v1/sys/health"; then
    echo "❌ Vault is not running. Please run setup-vault.sh first."
    exit 1
fi

# Step 2: Test container restart
echo "Step 2: Testing container restart..."
echo "Restarting Vault container..."
docker restart purebliss-vault-scaffolding

# Wait for restart
echo "Waiting for Vault to restart..."
sleep 15

# Step 3: Verify health after restart
echo "Step 3: Verifying health after restart..."
if $HEALTH_SCRIPT "purebliss-vault-scaffolding" "8200" "/v1/sys/health"; then
    echo "✅ Vault restart test passed!"
else
    echo "❌ Vault restart test failed!"
    echo "Container logs after restart:"
    docker logs purebliss-vault-scaffolding --tail=20
    exit 1
fi

# Step 4: Test functionality after restart
echo "Step 4: Testing functionality after restart..."
export VAULT_ADDR='https://localhost:8200'
export VAULT_TOKEN='purebliss-root-token'

# Test vault status
if vault status; then
    echo "✅ Vault status check after restart passed!"
else
    echo "❌ Vault status check after restart failed!"
    exit 1
fi

# Test reading previously written secret (should fail in dev mode, which is expected)
echo "Testing secret persistence (expected to fail in dev mode)..."
if vault kv get secret/test 2>/dev/null; then
    echo "✅ Secret persisted (unexpected but good!)"
else
    echo "ℹ️  Secret not persisted (expected in dev mode)"
fi

# Write a new secret to verify functionality
echo "Testing new secret write after restart..."
if vault kv put secret/restart-test key=after-restart; then
    echo "✅ New secret write after restart successful!"
else
    echo "❌ New secret write after restart failed!"
    exit 1
fi

echo ""
echo "🎯 VAULT RESTART TEST COMPLETE!"
echo "==============================="
echo "✅ Vault container survives restart"
echo "✅ Vault functionality works after restart"
echo "✅ Ready for Step 3: Documentation"
echo ""
echo "Next: Run documentation step with:"
echo "./document-vault.sh"
