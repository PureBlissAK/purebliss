#!/bin/bash

# Redis Container Setup Script
# Container 3 of 10 - Scaffolding Approach

set -e

echo "🔧 Setting up Redis Container (Container 3/10)"
echo "=================================================="

# Ensure network exists
docker network ls | grep -q purebliss-scaffolding || {
    echo "❌ Network 'purebliss-scaffolding' not found"
    echo "Please ensure Vault and PostgreSQL containers are running first"
    exit 1
}

# Stop and remove any existing Redis container
echo "🧹 Cleaning up existing Redis container..."
docker-compose -f docker-compose.redis.yml down -v 2>/dev/null || true

# Start Redis container
echo "🚀 Starting Redis container..."
docker-compose -f docker-compose.redis.yml up -d

# Wait for container to be ready
echo "⏳ Waiting for Redis to initialize..."
sleep 5

# Wait for health check to pass
echo "🔍 Waiting for Redis health check..."
timeout=120
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f docker-compose.redis.yml ps | grep -q "(healthy)"; then
        echo "✅ Redis health check passed"
        break
    fi
    echo "⏳ Still waiting for Redis... ($elapsed/${timeout}s)"
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Redis health check timeout"
    echo "📋 Container logs:"
    docker logs purebliss-redis-scaffolding --tail 20
    exit 1
fi

# Run health validation using our universal script
echo "🔍 Running comprehensive health validation..."
/opt/dev-purebliss/scaffolding/scripts/health-check.sh purebliss-redis-scaffolding 6379 redis

# Test basic Redis connectivity
echo "🔍 Testing Redis connectivity..."
docker exec purebliss-redis-scaffolding redis-cli ping | grep -q PONG || {
    echo "❌ Redis connectivity test failed"
    exit 1
}

echo ""
echo "🎯 Redis Container Setup Complete!"
echo "==================================="
echo "✅ Container: purebliss-redis-scaffolding"
echo "✅ Port: 6379"
echo "✅ Health: Validated"
echo "✅ Ready for: Restart testing"
echo ""
echo "📋 Next Steps:"
echo "1. Run restart test: ./test-redis-restart.sh"
echo "2. Generate documentation: ./document-redis.sh"
echo "3. Move to Container 4 (Nginx)"
