#!/bin/bash
# PostgreSQL SSL Certificate Setup Script
# Copies certificates from Let's Encrypt and sets proper permissions

echo "Setting up SSL certificates for PostgreSQL..."

# Wait for certificate files to be available
until [ -f /raid-storage/letsencrypt/live/dev.purebliss.app/cert.pem ]; do
  echo "Waiting for SSL certificates..."
  sleep 5
done

# Copy certificates to PostgreSQL data directory
cp /raid-storage/letsencrypt/live/dev.purebliss.app/cert.pem /var/lib/postgresql/data/server.crt
cp /raid-storage/letsencrypt/live/dev.purebliss.app/privkey.pem /var/lib/postgresql/data/server.key

# Set proper permissions for PostgreSQL
chown postgres:postgres /var/lib/postgresql/data/server.crt
chown postgres:postgres /var/lib/postgresql/data/server.key
chmod 600 /var/lib/postgresql/data/server.key
chmod 644 /var/lib/postgresql/data/server.crt

echo "SSL certificates configured successfully for PostgreSQL"
