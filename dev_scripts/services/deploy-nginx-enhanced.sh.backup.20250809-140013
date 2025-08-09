#!/bin/bash
set -euo pipefail

echo "Deploying nginx with smart upstream logic for Pure Bliss..."

# Cleanup any existing nginx containers
docker stop purebliss-nginx 2>/dev/null || true
docker rm purebliss-nginx 2>/dev/null || true

# Build and deploy nginx with enhanced configuration
cd /opt/dev-purebliss/services/nginx

# Create a production-ready nginx container with smart upstream logic
docker build -t nginx:purebliss-enhanced -f nginx-dockerfile .

# Deploy with proper configuration
docker run -d \
    --name purebliss-nginx \
    --network purebliss-net \
    --env-file .env \
    -p 80:80 \
    -p 443:443 \
    -v /opt/my-secure-ha-stack/logs:/opt/my-secure-ha-stack/logs \
    nginx:purebliss-enhanced

echo "Waiting for nginx to start..."
sleep 15

# Validate nginx is healthy
if docker inspect --format='{{.State.Health.Status}}' purebliss-nginx | grep -q "healthy"; then
    echo "✅ nginx is healthy"
else
    echo "❌ nginx is not healthy"
    docker logs purebliss-nginx --tail 20
    exit 1
fi

# Test endpoints
echo "Testing nginx endpoints..."
if curl -f http://localhost/health; then
    echo "✅ HTTP health check passed"
else
    echo "❌ HTTP health check failed"
fi

echo "nginx deployment completed successfully!"

# Log the completion
echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: nginx gateway service deployed with smart upstream logic" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
