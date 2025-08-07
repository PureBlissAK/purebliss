#!/bin/sh
# Nginx health check script

# Test basic connectivity
if ! curl -f -s -o /dev/null http://localhost/health; then
    echo "ERROR: Nginx health endpoint failed"
    exit 1
fi

# Test configuration
if ! nginx -t 2>/dev/null; then
    echo "ERROR: Nginx configuration test failed"
    exit 1
fi

# Test process
if ! pgrep nginx >/dev/null; then
    echo "ERROR: Nginx process not running"
    exit 1
fi

echo "OK: Nginx is healthy"
exit 0
