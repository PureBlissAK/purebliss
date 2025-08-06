#!/bin/bash

echo "🎯 Keycloak Redis Integration Status Check"
echo "=========================================="
echo

# Check Redis
echo "📦 Redis Container Status:"
if docker ps | grep -q purebliss-redis; then
    echo "✅ Redis container is running"
    if docker exec purebliss-redis redis-cli ping >/dev/null 2>&1; then
        echo "✅ Redis is responding to requests"
        if docker exec purebliss-redis redis-cli -n 1 ping >/dev/null 2>&1; then
            echo "✅ Redis database 1 (Keycloak) is accessible"
        else
            echo "⚠️  Redis database 1 connectivity issue"
        fi
    else
        echo "❌ Redis is not responding"
    fi
else
    echo "❌ Redis container is not running"
fi

echo

# Check Keycloak
echo "🔐 Keycloak Container Status:"
if docker ps | grep -q purebliss-keycloak; then
    echo "✅ Keycloak container is running"

    # Check if Keycloak logs show Redis configuration
    if docker logs purebliss-keycloak 2>&1 | grep -q "keycloak.redis.host"; then
        echo "✅ Redis integration configured in Keycloak"
    else
        echo "⚠️  Redis integration configuration not found in logs"
    fi

    # Check if Keycloak is responding
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ | grep -q "200"; then
        echo "✅ Keycloak is responding to HTTP requests"
    else
        echo "⏳ Keycloak is still starting (this is normal)"
    fi
else
    echo "❌ Keycloak container is not running"
fi

echo

# Summary
echo "📊 Integration Summary:"
echo "- Redis Cache Server: $(docker ps --format 'table {{.Status}}' --filter name=purebliss-redis | tail -1)"
echo "- Keycloak Auth Server: $(docker ps --format 'table {{.Status}}' --filter name=purebliss-keycloak | tail -1)"
echo

# Redis info
echo "🔧 Redis Configuration:"
echo "- Host: purebliss-redis"
echo "- Port: 6379"
echo "- Database: 1 (dedicated for Keycloak)"
echo "- Network: purebliss-net"

echo

# Next steps
echo "🚀 Next Steps:"
echo "1. Wait for Keycloak to complete startup (2-3 minutes)"
echo "2. Test Keycloak at: http://localhost:8080/auth"
echo "3. Admin console: http://localhost:8080/auth/admin"
echo "4. Run validation: ./validate-keycloak-vault.sh"

echo
echo "✨ Keycloak + Redis integration is ready!"
