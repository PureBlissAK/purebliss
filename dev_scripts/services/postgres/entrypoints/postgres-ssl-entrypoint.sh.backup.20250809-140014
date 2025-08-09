#!/bin/bash
# PostgreSQL SSL Certificate Setup Script
# This runs during database initialization

set -e

echo "Setting up SSL certificates for PostgreSQL..."

# Wait for certificate files to be available
until [ -f /raid-storage/letsencrypt/live/dev.purebliss.app/cert.pem ]; do
  echo "Waiting for SSL certificates..."
  sleep 2
done

# Copy certificates to PostgreSQL data directory
if [ -f /raid-storage/letsencrypt/live/dev.purebliss.app/cert.pem ]; then
    cp /raid-storage/letsencrypt/live/dev.purebliss.app/cert.pem "$PGDATA/server.crt"
    cp /raid-storage/letsencrypt/live/dev.purebliss.app/privkey.pem "$PGDATA/server.key"

    # Set proper permissions for PostgreSQL
    chown postgres:postgres "$PGDATA/server.crt" "$PGDATA/server.key"
    chmod 600 "$PGDATA/server.key"
    chmod 644 "$PGDATA/server.crt"

    echo "SSL certificates configured successfully for PostgreSQL"
else
    echo "Warning: SSL certificates not found, PostgreSQL will start without SSL"
fi
