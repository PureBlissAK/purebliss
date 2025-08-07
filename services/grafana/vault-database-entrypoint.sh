#!/bin/bash
set -euo pipefail

# Vault Database Dynamic Credentials Entrypoint
# Generates dynamic database credentials and configures database connection

VAULT_ADDR="${VAULT_ADDR:-https://purebliss-vault:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
SERVICE_NAME="${SERVICE_NAME:-grafana}"
DB_ROLE="${DB_ROLE:-grafana-role}"

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
for i in {1..30}; do
    if curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
        echo "Vault is ready"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo "ERROR: Vault not ready after 30 attempts"
        exit 1
    fi
    sleep 2
done

# Generate dynamic database credentials
echo "Generating dynamic database credentials..."
if [[ -f "/vault-token" ]]; then
    VAULT_TOKEN=$(cat /vault-token)
    export VAULT_TOKEN

    # Generate dynamic credentials
    DB_CREDS=$(vault read -format=json "database/creds/$DB_ROLE")

    if [[ "$DB_CREDS" != "null" ]]; then
        # Extract credentials
        DB_USERNAME=$(echo "$DB_CREDS" | jq -r '.data.username')
        DB_PASSWORD=$(echo "$DB_CREDS" | jq -r '.data.password')

        # Export database environment variables
        export DATABASE_USER="$DB_USERNAME"
        export DATABASE_PASSWORD="$DB_PASSWORD"
        export DATABASE_URL="postgresql://$DB_USERNAME:$DB_PASSWORD@${DATABASE_HOST:-purebliss-postgres}:${DATABASE_PORT:-5432}/${DATABASE_NAME:-$SERVICE_NAME}"

        echo "Dynamic database credentials generated successfully"
        echo "Database user: $DB_USERNAME"
    else
        echo "ERROR: Failed to generate dynamic database credentials"
        exit 1
    fi
else
    echo "ERROR: Vault token not found at /vault-token"
    exit 1
fi

echo "Vault database credentials initialization completed"
