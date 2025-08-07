#!/bin/sh
# Redis health check script

# Test basic connectivity
if ! redis-cli ping >/dev/null 2>&1; then
    echo "ERROR: Redis ping failed"
    exit 1
fi

# Test memory usage
MEMORY_USAGE=$(redis-cli info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
if [ -z "$MEMORY_USAGE" ]; then
    echo "ERROR: Could not get Redis memory usage"
    exit 1
fi

# Test persistence
if ! redis-cli lastsave >/dev/null 2>&1; then
    echo "WARNING: Redis persistence check failed"
fi

echo "OK: Redis is healthy (Memory: $MEMORY_USAGE)"
exit 0
