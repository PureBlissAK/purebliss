#!/bin/bash
# Redis Database Plugin Configuration for Vault
# Configures Vault to manage Redis dynamic credentials

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1
export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

# Enable Redis database secrets engine
log_action "Enabling Redis database secrets engine..."
vault secrets enable -path=redis database

# Configure Redis connection
log_action "Configuring Redis database connection..."
vault write redis/config/redis \
    plugin_name=redis-database-plugin \
    connection_url="redis://purebliss-redis:6379" \
    allowed_roles="redis-role" \
    max_open_connections=5 \
    max_idle_connections=0 \
    max_connection_lifetime="1h"

# Create Redis role for dynamic credentials
log_action "Creating Redis role for dynamic credentials..."
vault write redis/roles/redis-role \
    db_name=redis \
    creation_statements='["~*", "&*", "+@all", "-@dangerous"]' \
    default_ttl="1h" \
    max_ttl="24h"

log_success "Redis database plugin configuration completed"
