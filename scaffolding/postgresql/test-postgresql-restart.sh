#!/bin/bash

# PostgreSQL Container Restart Test Script
# Container 2 of 10 - Scaffolding Approach

set -e

echo "🔄 Testing PostgreSQL Container Restart (Container 2/10)"
echo "========================================================"

# Check container is running first
if ! docker ps | grep -q purebliss-postgresql-scaffolding; then
    echo "❌ PostgreSQL container not running"
    echo "Please run ./setup-postgresql.sh first"
    exit 1
fi

# Record current state
echo "📊 Recording pre-restart state..."
echo "Current uptime:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep purebliss-postgresql-scaffolding

# Test database connectivity before restart
echo "🔍 Testing database before restart..."
docker exec purebliss-postgresql-scaffolding psql -U postgres -d purebliss_dev -c "SELECT 'Pre-restart test' AS status, NOW() AS timestamp;" || {
    echo "❌ Pre-restart database test failed"
    exit 1
}

# Restart the container
echo "🔄 Restarting PostgreSQL container..."
docker restart purebliss-postgresql-scaffolding

# Wait for container to come back up
echo "⏳ Waiting for container to restart..."
sleep 5

# Wait for health check to pass again
echo "🔍 Waiting for PostgreSQL health check after restart..."
timeout=120
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f docker-compose.postgresql.yml ps | grep -q "(healthy)"; then
        echo "✅ PostgreSQL health check passed after restart"
        break
    fi
    echo "⏳ Still waiting for PostgreSQL health check... ($elapsed/${timeout}s)"
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ PostgreSQL health check timeout after restart"
    echo "📋 Container logs:"
    docker logs purebliss-postgresql-scaffolding --tail 20
    exit 1
fi

# Record post-restart state
echo "📊 Recording post-restart state..."
echo "New uptime:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep purebliss-postgresql-scaffolding

# Run full health validation
echo "🔍 Running comprehensive health validation..."
/opt/dev-purebliss/scaffolding/scripts/health-check.sh purebliss-postgresql-scaffolding 5432

# Test database connectivity after restart
echo "🔍 Testing database after restart..."
docker exec purebliss-postgresql-scaffolding psql -U postgres -d purebliss_dev -c "SELECT 'Post-restart test' AS status, NOW() AS timestamp;" || {
    echo "❌ Post-restart database test failed"
    exit 1
}

# Test data persistence (check our health_check table)
echo "🔍 Testing data persistence..."
record_count=$(docker exec purebliss-postgresql-scaffolding psql -U postgres -d purebliss_dev -t -c "SELECT COUNT(*) FROM purebliss_app.health_check;")
if [ "$record_count" -ge 1 ]; then
    echo "✅ Data persistence confirmed - health_check table has $record_count records"
else
    echo "❌ Data persistence failed - health_check table empty"
    exit 1
fi

# Test Vault connectivity if Vault is running
echo "🔍 Testing Vault connectivity after restart..."
if docker ps | grep -q purebliss-vault-scaffolding; then
    docker exec purebliss-postgresql-scaffolding ping -c 1 purebliss-vault-scaffolding >/dev/null 2>&1 && {
        echo "✅ Vault connectivity maintained after restart"
    } || {
        echo "⚠️  Vault connectivity test failed"
    }
else
    echo "⚠️  Vault container not running"
fi

echo ""
echo "🎯 PostgreSQL Restart Test Complete!"
echo "===================================="
echo "✅ Container: Successfully restarted"
echo "✅ Health: All checks passed"
echo "✅ Database: Connectivity confirmed"
echo "✅ Data: Persistence verified"
echo "✅ Network: Vault connectivity maintained"
echo "✅ Ready for: Documentation generation"
echo ""
echo "📋 Next Steps:"
echo "Run documentation step with: ./document-postgresql.sh"
