#!/bin/bash
set -euo pipefail

# Start PostgreSQL with Vault integration using Docker Compose
cd /opt/dev-purebliss/services/postgres

echo "Starting PostgreSQL with Vault integration..."

# Use the postgres-vault-docker-compose.yml for SSL/TLS compliance
docker compose -f postgres-vault-docker-compose.yml up -d

echo "PostgreSQL containers started. Checking health..."

# Wait for containers to be healthy
sleep 10

# Check container status
docker ps --filter "name=purebliss-postgres" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

echo "PostgreSQL startup complete. Check logs with: docker logs purebliss-postgres"
