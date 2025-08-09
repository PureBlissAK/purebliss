#!/bin/bash

# Redis Container Restart Test Script
# Container 3 of 10 - Scaffolding Approach

set -e

echo "🔄 Testing Redis Container Restart (Container 3/10)"
echo "====================================================="

# Check container is running first
if ! docker ps | grep -q purebliss-redis-scaffolding; then
    echo "❌ Redis container not running"
    echo "Please run ./setup-redis.sh first"
    exit 1
fi

# Record current state
echo "📊 Recording pre-restart state..."
echo "Current uptime:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep purebliss-redis-scaffolding

# Test Redis connectivity before restart
echo "🔍 Testing Redis before restart..."
docker exec purebliss-redis-scaffolding redis-cli ping | grep -q PONG || {
    echo "❌ Pre-restart Redis test failed"
    exit 1
}

# Restart the container
echo "🔄 Restarting Redis container..."
docker restart purebliss-redis-scaffolding

# Wait for container to come back up
echo "⏳ Waiting for container to restart..."
sleep 5

# Wait for health check to pass again
echo "🔍 Waiting for Redis health check after restart..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker ps | grep purebliss-redis-scaffolding | grep -q "(healthy)"; then
        echo "✅ Redis health check passed after restart"
        break
    fi
    echo "⏳ Still waiting for Redis health check... ($elapsed/${timeout}s)"
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Redis health check timeout after restart"
    echo "📋 Container logs:"
    docker logs purebliss-redis-scaffolding --tail 20
    exit 1
fi

# Record post-restart state
echo "📊 Recording post-restart state..."
echo "New uptime:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep purebliss-redis-scaffolding

# Run full health validation
echo "🔍 Running comprehensive health validation..."
/opt/dev-purebliss/scaffolding/scripts/health-check.sh purebliss-redis-scaffolding 6379 redis

# Test Redis connectivity after restart
echo "🔍 Testing Redis after restart..."
docker exec purebliss-redis-scaffolding redis-cli ping | grep -q PONG || {
    echo "❌ Post-restart Redis test failed"
    exit 1
}

echo ""
echo "🎯 Redis Restart Test Complete!"
echo "================================"
echo "✅ Container: Successfully restarted"
echo "✅ Health: All checks passed"
echo "✅ Connectivity: Confirmed"
echo "✅ Ready for: Documentation generation"
echo ""
echo "📋 Next Steps:"
echo "Run documentation step with: ./document-redis.sh"
