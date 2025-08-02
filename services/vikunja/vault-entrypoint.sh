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
        export VIKUNJA_DATABASE_USER=$(echo "$DB_SECRETS" | jq -r '.data.data.username')
        export VIKUNJA_DATABASE_PASSWORD=$(echo "$DB_SECRETS" | jq -r '.data.data.password')
        export VIKUNJA_DATABASE_DATABASE=$(echo "$DB_SECRETS" | jq -r '.data.data.database')
        echo "Successfully retrieved database credentials from Vault for Vikunja"
    else
        echo "Failed to retrieve credentials from Vault, using defaults"
        export VIKUNJA_DATABASE_USER=${POSTGRES_USER:-vikunja}
        export VIKUNJA_DATABASE_PASSWORD=${POSTGRES_PASSWORD:-vikunjapassword}
        export VIKUNJA_DATABASE_DATABASE=${POSTGRES_DB:-vikunja}
    fi
else
    echo "VAULT_TOKEN not set, using default credentials"
    export VIKUNJA_DATABASE_USER=${POSTGRES_USER:-vikunja}
    export VIKUNJA_DATABASE_PASSWORD=${POSTGRES_PASSWORD:-vikunjapassword}
    export VIKUNJA_DATABASE_DATABASE=${POSTGRES_DB:-vikunja}
fi

# Execute the original vikunja entrypoint
exec /entrypoint.sh "$@"
