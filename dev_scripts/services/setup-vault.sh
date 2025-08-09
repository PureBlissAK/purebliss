#!/bin/bash
set -euo pipefail

# Quick Vault Setup for Pure Bliss Development
# Handles initialization and automation setup

echo "🚀 Pure Bliss Vault Setup"
echo "========================="
echo ""
echo "This will initialize Vault with secure key management for full automation."
echo "You'll be prompted for a master password to encrypt the Vault keys."
echo ""

# Check if Vault is running
if ! curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
    echo "❌ Vault is not running. Please start Vault first:"
    echo "   cd /opt && ./dev-purebliss/start-all-services.sh vault"
    exit 1
fi

# Run the initialization
echo "Starting Vault initialization..."
echo ""

cd /opt/dev-purebliss/services/vault
./vault-init-automation.sh

echo ""
echo "🎉 Vault setup complete!"
echo ""
echo "Next steps:"
echo "1. Vault is now initialized and unsealed"
echo "2. Keys are encrypted and stored securely"
echo "3. Future startups will auto-unseal automatically"
echo ""
echo "You can now proceed with starting other services:"
echo "   cd /opt && ./dev-purebliss/start-all-services.sh"
echo ""
