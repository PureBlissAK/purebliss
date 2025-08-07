#!/bin/bash
set -euo pipefail

echo "Deploying basic working nginx for immediate gateway functionality..."

# Cleanup any existing nginx containers
docker stop purebliss-nginx 2>/dev/null || true
docker rm purebliss-nginx 2>/dev/null || true

# Deploy basic nginx using Phase 1 image (known working)
cd /opt/dev-purebliss/services/nginx

docker run -d \
    --name purebliss-nginx \
    --network purebliss-net \
    --env-file .env \
    -p 80:80 \
    nginx:phase1

echo "Waiting for nginx to start..."
sleep 10

# Validate nginx is healthy
if docker inspect --format='{{.State.Health.Status}}' purebliss-nginx | grep -q "healthy"; then
    echo "✅ nginx is healthy"

    # Test endpoints
    if curl -f http://localhost/health; then
        echo "✅ HTTP health check passed"
    else
        echo "❌ HTTP health check failed"
    fi

    echo "✅ nginx gateway service deployed successfully!"

    # Log the completion
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: nginx gateway service deployed (Phase 1 - basic functionality)" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

else
    echo "❌ nginx is not healthy"
    docker logs purebliss-nginx --tail 20
    exit 1
fi
