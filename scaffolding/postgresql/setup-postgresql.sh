#!/bin/bash

# PostgreSQL Container Setup Script
# Container 2 of 10 - Scaffolding Approach

set -e

echo "🔧 Setting up PostgreSQL Container (Container 2/10)"
echo "=================================================="

# Ensure network exists (created by Vault)
docker network ls | grep -q purebliss-scaffolding || {
    echo "❌ Network 'purebliss-scaffolding' not found"
    echo "Please ensure Vault container is running first"
    exit 1
}

# Stop and remove any existing PostgreSQL container
echo "🧹 Cleaning up existing PostgreSQL container..."
docker-compose -f docker-compose.postgresql.yml down -v 2>/dev/null || true

# Start PostgreSQL container
echo "🚀 Starting PostgreSQL container..."
docker-compose -f docker-compose.postgresql.yml up -d

# Wait for container to be ready
echo "⏳ Waiting for PostgreSQL to initialize..."
sleep 10

# Wait for health check to pass
echo "🔍 Waiting for PostgreSQL health check..."
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f docker-compose.postgresql.yml ps | grep -q "(healthy)"; then
        echo "✅ PostgreSQL health check passed"
        break
    fi
    echo "⏳ Still waiting for PostgreSQL... ($elapsed/${timeout}s)"
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ PostgreSQL health check timeout"
    echo "📋 Container logs:"
    docker logs purebliss-postgresql-scaffolding --tail 20
    exit 1
fi

# Run health validation using our universal script
echo "🔍 Running comprehensive health validation..."
/opt/dev-purebliss/scaffolding/scripts/health-check.sh purebliss-postgresql-scaffolding 5432

# Test basic PostgreSQL connectivity
echo "🔍 Testing PostgreSQL connectivity..."
docker exec purebliss-postgresql-scaffolding psql -U postgres -d purebliss_dev -c "SELECT 'PostgreSQL is ready' AS status;" || {
    echo "❌ PostgreSQL connectivity test failed"
    exit 1
}

# Test our initialization worked
echo "🔍 Testing database initialization..."
docker exec purebliss-postgresql-scaffolding psql -U postgres -d purebliss_dev -c "SELECT COUNT(*) as records FROM purebliss_app.health_check;" || {
    echo "❌ Database initialization test failed"
    exit 1
}

# Test Vault integration (basic connectivity)
echo "🔍 Testing Vault integration possibility..."
if docker ps | grep -q purebliss-vault-scaffolding; then
    echo "✅ Vault container is running - integration ready"

    # Test network connectivity between containers
    docker exec purebliss-postgresql-scaffolding ping -c 1 purebliss-vault-scaffolding >/dev/null 2>&1 && {
        echo "✅ Network connectivity between PostgreSQL and Vault confirmed"
    } || {
        echo "⚠️  Network connectivity test failed - containers may not be on same network"
    }
else
    echo "⚠️  Vault container not running - start Vault first for full integration"
fi

echo ""
echo "🎯 PostgreSQL Container Setup Complete!"
echo "======================================="
echo "✅ Container: purebliss-postgresql-scaffolding"
echo "✅ Database: purebliss_dev"
echo "✅ Port: 5432"
echo "✅ Health: Validated"
echo "✅ Ready for: Restart testing"
echo ""
echo "📋 Next Steps:"
echo "1. Run restart test: ./test-postgresql-restart.sh"
echo "2. Generate documentation: ./document-postgresql.sh"
echo "3. Move to Container 3 (Redis)"
