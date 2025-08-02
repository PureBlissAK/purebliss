#!/bin/sh
set -e

# Vault configuration
VAULT_ADDR=${VAULT_ADDR:-"http://purebliss-vault:8200"}
VAULT_TOKEN=${VAULT_TOKEN}

# Fetch secrets from Vault
if [ -n "$VAULT_TOKEN" ]; then
    # Use vault CLI to fetch database credentials
    DB_SECRETS=$(vault kv get -format=json secret/postgres)
    if [ $? -eq 0 ]; then
        export POSTGRES_USER=$(echo "$DB_SECRETS" | jq -r '.data.data.username')
        export POSTGRES_PASSWORD=$(echo "$DB_SECRETS" | jq -r '.data.data.password')
        export POSTGRES_DB=$(echo "$DB_SECRETS" | jq -r '.data.data.database')
        echo "Successfully retrieved database credentials from Vault"
    else
        echo "Failed to retrieve credentials from Vault, using defaults"
        export POSTGRES_USER=${POSTGRES_USER:-vikunja}
        export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-vikunjapassword}
        export POSTGRES_DB=${POSTGRES_DB:-vikunja}
    fi
else
    echo "VAULT_TOKEN not set, using default credentials"
    export POSTGRES_USER=${POSTGRES_USER:-vikunja}
    export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-vikunjapassword}
    export POSTGRES_DB=${POSTGRES_DB:-vikunja}
fi

# Execute the original postgres entrypoint
exec docker-entrypoint.sh "$@"
