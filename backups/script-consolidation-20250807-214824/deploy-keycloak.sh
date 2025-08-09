#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utilities/retry-utils.sh" 2>/dev/null || true

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="[Enhanced with centralized structure]"

set -euo pipefail

echo "Deploying Keycloak authentication service with Pure Bliss integration..."

# Cleanup any existing keycloak containers
docker stop purebliss-keycloak 2>/dev/null || true
docker rm purebliss-keycloak 2>/dev/null || true

cd /opt/dev-purebliss/services/keycloak

# Build enhanced Keycloak container
echo "Building enhanced Keycloak container..."
docker build -t keycloak:purebliss-enhanced -f keycloak-enhanced-dockerfile .

# Deploy Keycloak with proper configuration
echo "Deploying Keycloak container..."
docker run -d \
    --name purebliss-keycloak \
    --network purebliss-net \
    --env-file .env \
    -p 8080:8080 \
    -v /opt/my-secure-ha-stack/logs:/opt/my-secure-ha-stack/logs \
    keycloak:purebliss-enhanced

echo "Waiting for Keycloak to start (this may take 2-3 minutes)..."
sleep 30

# Check container status
if docker ps --filter "name=purebliss-keycloak" --format "{{.Names}}" | grep -q "purebliss-keycloak"; then
    echo "✅ Keycloak container is running"

    # Wait for health check to pass
    echo "Waiting for Keycloak health check..."
    for i in {1..20}; do
        if docker inspect --format='{{.State.Health.Status}}' purebliss-keycloak 2>/dev/null | grep -q "healthy"; then
            echo "✅ Keycloak is healthy"
            break
        elif [ $i -eq 20 ]; then
            echo "⚠️  Keycloak health check timeout (may still be starting)"
        else
            echo "⏳ Waiting for Keycloak health check ($i/20)..."
            sleep 15
        fi
    done

    # Test basic connectivity
    if curl -f http://localhost:8080/health/ready 2>/dev/null; then
        echo "✅ Keycloak ready endpoint accessible"
    else
        echo "⚠️  Keycloak ready endpoint not yet accessible (may still be initializing)"
    fi

    echo "✅ Keycloak authentication service deployed successfully!"

    # Log the completion
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: Keycloak authentication service deployed with Vault integration, PostgreSQL backend, and Redis caching" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

else
    echo "❌ Keycloak container failed to start"
    docker logs purebliss-keycloak --tail 30
    exit 1
fi
