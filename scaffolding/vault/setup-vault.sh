#!/bin/bash
set -euo pipefail

# Vault Scaffolding Setup Script
# Step 1 of Scaffolding: Build and Test Vault Container

echo "🚀 Starting Vault Scaffolding Setup"
echo "===================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTH_SCRIPT="/opt/dev-purebliss/scaffolding/scripts/health-check.sh"

# Step 1: Start Vault Container
echo "Step 1: Starting Vault container..."
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.vault.yml up -d

# Step 2: Wait for container to be ready
echo "Step 2: Waiting for Vault to be ready..."
sleep 10

# Step 3: Health Check
echo "Step 3: Running health check..."
if $HEALTH_SCRIPT "purebliss-vault-scaffolding" "8200" "/v1/sys/health"; then
    echo "✅ Vault container health check passed!"
else
    echo "❌ Vault container health check failed!"
    echo "Checking container logs:"
    docker logs purebliss-vault-scaffolding
    exit 1
fi

# Step 4: Basic Vault Functionality Test
echo "Step 4: Testing basic Vault functionality..."
export VAULT_ADDR='https://localhost:8200'
export VAULT_TOKEN='purebliss-root-token'

# Test vault status
if vault status; then
    echo "✅ Vault status check passed!"
else
    echo "❌ Vault status check failed!"
    exit 1
fi

# Test writing and reading a secret
echo "Testing secret write/read..."
if vault kv put secret/test key=value; then
    echo "✅ Secret write successful!"
else
    echo "❌ Secret write failed!"
    exit 1
fi

if vault kv get secret/test; then
    echo "✅ Secret read successful!"
else
    echo "❌ Secret read failed!"
    exit 1
fi

echo ""
echo "🎯 VAULT SCAFFOLDING STEP 1 COMPLETE!"
echo "======================================"
echo "✅ Vault container is running and healthy"
echo "✅ Basic Vault functionality verified"
echo "✅ Ready for Step 2: Restart Testing"
echo ""
echo "Next: Run restart test with:"
echo "./test-vault-restart.sh"
