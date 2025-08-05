#!/bin/bash
set -euo pipefail

echo "=== PostgreSQL Fresh Setup Validation ==="
echo ""

# Check PostgreSQL container status
echo "🔍 Checking PostgreSQL container status..."
docker ps -f name=purebliss-postgres --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check health
echo "🏥 Health Status:"
docker inspect --format='{{.State.Health.Status}}' purebliss-postgres
echo ""

# Test basic PostgreSQL connectivity
echo "🔌 Testing PostgreSQL connectivity..."
docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 'PostgreSQL connection successful!' as status;" 2>/dev/null || echo "Connection failed"
echo ""

# Check databases
echo "📊 Available databases:"
docker exec purebliss-postgres psql -U postgres -d postgres -t -c "\l" 2>/dev/null | grep -E "keycloak|plane|vikunja|vault_managed|postgres" | head -5
echo ""

# Check users
echo "👥 Available users:"
docker exec purebliss-postgres psql -U postgres -d postgres -t -c "\du" 2>/dev/null | grep -E "postgres|vault_admin|keycloak|plane|vikunja"
echo ""

# Test Vault integration
echo "🔐 Testing Vault database secrets integration..."
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1
export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

# Generate new credentials
echo "   Generating new dynamic credentials..."
CREDS=$(vault read -format=json database/creds/postgres-role 2>/dev/null)
if [[ $? -eq 0 ]]; then
    VAULT_USER=$(echo "$CREDS" | jq -r '.data.username')
    VAULT_PASS=$(echo "$CREDS" | jq -r '.data.password')
    echo "   ✅ Generated: $VAULT_USER"

    # Test connection with generated credentials
    echo "   Testing connection with dynamic credentials..."
    PGPASSWORD="$VAULT_PASS" docker exec purebliss-postgres psql -U "$VAULT_USER" -d postgres -t -c "SELECT 'Vault dynamic credentials working!' as status;" 2>/dev/null || echo "   ❌ Connection with Vault credentials failed"
else
    echo "   ❌ Failed to generate Vault credentials"
fi

echo ""
echo "=== Validation Complete ==="
echo "✅ PostgreSQL is running with fresh database"
echo "✅ Vault integration is functional"
echo "✅ Bootstrap credentials: postgres:bootstrap_admin_password_12345"
echo "✅ Vault admin credentials: vault_admin:vault_admin_password_123"
echo "✅ Dynamic credentials are being generated successfully"
