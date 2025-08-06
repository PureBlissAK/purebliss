#!/bin/bash

# Quick test script for Keycloak Vault integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/opt/my-secure-ha-stack/logs/keycloak-vault-test.log"

echo "======================================"
echo "Keycloak Vault Integration Test"
echo "======================================"
echo "$(date): Starting Keycloak Vault integration test..." | tee -a "$LOG_FILE"

# Test 1: Check if Keycloak container is running
echo ""
echo "Test 1: Checking Keycloak container status..."
if docker ps | grep -q purebliss-keycloak; then
    echo "✓ Keycloak container is running"
else
    echo "✗ Keycloak container is not running"
    exit 1
fi

# Test 2: Check if Vault is accessible
echo ""
echo "Test 2: Checking Vault accessibility..."
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1

if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    if vault status >/dev/null 2>&1; then
        echo "✓ Vault is accessible and unsealed"
    else
        echo "✗ Vault is not accessible or sealed"
        exit 1
    fi
else
    echo "✗ Vault token file not found"
    exit 1
fi

# Test 3: Check Keycloak AppRole credentials
echo ""
echo "Test 3: Checking Keycloak AppRole credentials..."
if [[ -f "$SCRIPT_DIR/vault-role-id" && -f "$SCRIPT_DIR/vault-secret-id" ]]; then
    echo "✓ AppRole credentials files exist"

    # Test AppRole authentication
    ROLE_ID=$(cat "$SCRIPT_DIR/vault-role-id")
    SECRET_ID=$(cat "$SCRIPT_DIR/vault-secret-id")

    if [[ -n "$ROLE_ID" && -n "$SECRET_ID" ]]; then
        echo "✓ AppRole credentials are populated"

        # Test authentication
        if vault write auth/keycloak/login role_id="$ROLE_ID" secret_id="$SECRET_ID" >/dev/null 2>&1; then
            echo "✓ AppRole authentication successful"
        else
            echo "✗ AppRole authentication failed"
        fi
    else
        echo "✗ AppRole credentials are empty"
    fi
else
    echo "✗ AppRole credentials files missing"
fi

# Test 4: Check Keycloak database access in Vault
echo ""
echo "Test 4: Testing Keycloak database access in Vault..."
if vault read keycloak/creds/keycloak-role >/dev/null 2>&1; then
    echo "✓ Keycloak database credentials can be generated"
else
    echo "✗ Failed to generate Keycloak database credentials"
fi

# Test 5: Check Keycloak health endpoint
echo ""
echo "Test 5: Testing Keycloak health endpoint..."
if curl -sf "http://localhost:8080/health" >/dev/null 2>&1; then
    echo "✓ Keycloak health endpoint accessible"
elif curl -sf "http://localhost:8080/" >/dev/null 2>&1; then
    echo "✓ Keycloak basic endpoint accessible"
else
    echo "✗ Keycloak endpoints not accessible"
fi

# Test 6: Check PostgreSQL Keycloak database
echo ""
echo "Test 6: Testing PostgreSQL Keycloak database..."
if docker exec purebliss-postgres psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname='keycloak';" | grep -q "1" 2>/dev/null; then
    echo "✓ Keycloak database exists in PostgreSQL"
else
    echo "✗ Keycloak database not found in PostgreSQL"
fi

# Test 7: Check Redis connectivity
echo ""
echo "Test 7: Testing Redis connectivity for Keycloak caching..."
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli -h "${REDIS_HOST:-purebliss-redis}" -p "${REDIS_PORT:-6379}" ping >/dev/null 2>&1; then
        echo "✓ Redis connectivity successful"

        # Test Redis database access
        if redis-cli -h "${REDIS_HOST:-purebliss-redis}" -p "${REDIS_PORT:-6379}" -n "${REDIS_DATABASE:-1}" ping >/dev/null 2>&1; then
            echo "✓ Redis database ${REDIS_DATABASE:-1} accessible"
        else
            echo "✗ Redis database ${REDIS_DATABASE:-1} not accessible"
        fi
    else
        echo "✗ Redis connectivity failed"
    fi
elif docker exec purebliss-redis redis-cli ping >/dev/null 2>&1; then
    echo "✓ Redis connectivity successful (via Docker)"
else
    echo "✗ Redis not accessible"
fi

# Test 8: Check Keycloak configuration
echo ""
echo "Test 8: Checking Keycloak configuration..."
# Test 8: Check Keycloak configuration
echo ""
echo "Test 8: Checking Keycloak configuration..."
if docker exec purebliss-keycloak env | grep -q "VAULT_ADDR\|DB_VENDOR\|REDIS_HOST"; then
    echo "✓ Keycloak environment variables configured"
else
    echo "? Keycloak environment variables check inconclusive"
fi

# Test 9: Validate setup script exists
echo ""
echo "Test 9: Checking setup script..."
if [[ -x "$SCRIPT_DIR/setup-keycloak-vault.sh" ]]; then
    echo "✓ Setup script exists and is executable"
else
    echo "✗ Setup script missing or not executable"
fi

# Test 10: Validate validation script exists
echo ""
echo "Test 10: Checking validation script..."
if [[ -x "$SCRIPT_DIR/validate-keycloak-vault.sh" ]]; then
    echo "✓ Validation script exists and is executable"
else
    echo "✗ Validation script missing or not executable"
fi

# Test 11: Check Docker Compose configuration
echo ""
echo "Test 11: Checking Docker Compose configuration..."
if [[ -f "$SCRIPT_DIR/keycloak-vault-docker-compose.yml" ]]; then
    echo "✓ Keycloak Vault Docker Compose file exists"

    # Validate compose file syntax
    if docker-compose -f "$SCRIPT_DIR/keycloak-vault-docker-compose.yml" config >/dev/null 2>&1; then
        echo "✓ Docker Compose file syntax is valid"
    else
        echo "✗ Docker Compose file has syntax errors"
    fi
else
    echo "✗ Keycloak Vault Docker Compose file missing"
fi

echo ""
echo "======================================"
echo "Keycloak Vault Integration Test Complete"
echo "======================================"
echo "$(date): Test completed. Check results above." | tee -a "$LOG_FILE"

# Summary
echo ""
echo "For detailed validation, run:"
echo "  cd $SCRIPT_DIR && ./validate-keycloak-vault.sh"
echo ""
echo "To restart Keycloak with Vault integration:"
echo "  cd $SCRIPT_DIR && ./setup-keycloak-vault.sh"
