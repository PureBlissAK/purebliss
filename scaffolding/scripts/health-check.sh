#!/bin/bash
set -euo pipefail

# Simple Container Health Check for Scaffolding Approach
# Usage: ./health-check.sh <container_name> <port> [service_type]

CONTAINER_NAME="${1:-}"
SERVICE_PORT="${2:-}"
SERVICE_TYPE="${3:-auto}"

if [[ -z "$CONTAINER_NAME" ]]; then
    echo "❌ Error: Container name required"
    echo "Usage: $0 <container_name> <port> [service_type]"
    echo "Service types: vault, postgresql, redis, nginx, auto"
    exit 1
fi

echo "🔍 Checking health for container: $CONTAINER_NAME"
echo "========================================"

# Auto-detect service type if not specified
if [[ "$SERVICE_TYPE" == "auto" ]]; then
    if [[ "$CONTAINER_NAME" == *"vault"* ]]; then
        SERVICE_TYPE="vault"
    elif [[ "$CONTAINER_NAME" == *"postgres"* ]]; then
        SERVICE_TYPE="postgresql"
    elif [[ "$CONTAINER_NAME" == *"redis"* ]]; then
        SERVICE_TYPE="redis"
    elif [[ "$CONTAINER_NAME" == *"nginx"* ]]; then
        SERVICE_TYPE="nginx"
    else
        SERVICE_TYPE="generic"
    fi
fi

# 1. Docker Container Status
echo "1. Docker Container Status:"
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$CONTAINER_NAME"; then
    echo "   ✅ Container is running"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$CONTAINER_NAME"
else
    echo "   ❌ Container is not running"
    exit 1
fi

# 2. Service-Specific Health Check
if [[ -n "$SERVICE_PORT" ]]; then
    echo "2. Service Health Check ($SERVICE_TYPE):"

    case "$SERVICE_TYPE" in
        "vault")
            if curl -s -f "http://localhost:$SERVICE_PORT/v1/sys/health" > /dev/null; then
                echo "   ✅ Vault health endpoint responding"
                curl -s "http://localhost:$SERVICE_PORT/v1/sys/health"
            else
                echo "   ❌ Vault health endpoint not responding"
                exit 1
            fi
            ;;
        "postgresql")
            if docker exec "$CONTAINER_NAME" pg_isready -q; then
                echo "   ✅ PostgreSQL is ready"
                docker exec "$CONTAINER_NAME" psql -U postgres -d purebliss_dev -c "SELECT 'PostgreSQL Health Check' AS status, NOW() AS timestamp;" 2>/dev/null || echo "   ⚠️  Database query test failed"
            else
                echo "   ❌ PostgreSQL is not ready"
                exit 1
            fi
            ;;
        "redis")
            if docker exec "$CONTAINER_NAME" redis-cli ping | grep -q "PONG"; then
                echo "   ✅ Redis is responding"
                docker exec "$CONTAINER_NAME" redis-cli info server | grep "redis_version" || echo "   ⚠️  Redis info query failed"
            else
                echo "   ❌ Redis is not responding"
                exit 1
            fi
            ;;
        "nginx")
            if curl -s -f "http://localhost:$SERVICE_PORT/" > /dev/null; then
                echo "   ✅ Nginx is responding"
                curl -s -I "http://localhost:$SERVICE_PORT/" | head -1
            else
                echo "   ❌ Nginx is not responding"
                exit 1
            fi
            ;;
        *)
            echo "   ⚠️  Generic health check - checking port $SERVICE_PORT"
            if nc -z localhost "$SERVICE_PORT" 2>/dev/null; then
                echo "   ✅ Port $SERVICE_PORT is open"
            else
                echo "   ❌ Port $SERVICE_PORT is not accessible"
                exit 1
            fi
            ;;
    esac
fi

# 3. Container Logs Check
echo "3. Container Logs Check (last 10 lines):"
echo "   Recent logs:"
docker logs "$CONTAINER_NAME" --tail=10 | sed 's/^/     /'

# 4. Error Detection (simplified for scaffolding)
echo "4. Error Detection:"
if docker logs "$CONTAINER_NAME" --since=5m | grep -qE "\[ERROR\]|\[FATAL\]|\[CRITICAL\]|ERROR:|FATAL:|CRITICAL:"; then
    echo "   ⚠️  Found critical errors in logs"
    docker logs "$CONTAINER_NAME" --since=5m | grep -E "\[ERROR\]|\[FATAL\]|\[CRITICAL\]|ERROR:|FATAL:|CRITICAL:" | head -3 | sed 's/^/     /'
    exit 1
else
    echo "   ✅ No critical errors found"
fi

echo ""
echo "🎯 Container Health Summary: $CONTAINER_NAME"
echo "   Status: ✅ HEALTHY"
echo "   Ready for next scaffolding step"
exit 0
