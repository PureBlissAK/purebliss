#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

echo "[$(date)] POSTGRES_FRESH_START: Starting PostgreSQL with fresh database and Vault integration..." | tee -a "$LOG_FILE"

# Start PostgreSQL with fresh configuration
echo "[$(date)] POSTGRES_FRESH_START: Starting PostgreSQL with fresh database..." | tee -a "$LOG_FILE"
cd /opt/dev-purebliss/services/postgres
docker-compose -f postgres-docker-compose-fresh.yml up -d

# Wait for PostgreSQL to be ready
echo "[$(date)] POSTGRES_FRESH_START: Waiting for PostgreSQL to be ready..." | tee -a "$LOG_FILE"
for i in {1..30}; do
    if docker exec purebliss-postgres pg_isready -U postgres -d postgres >/dev/null 2>&1; then
        echo "[$(date)] POSTGRES_FRESH_START: PostgreSQL is ready for connections." | tee -a "$LOG_FILE"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "[$(date)] POSTGRES_FRESH_START: ERROR: PostgreSQL failed to start within timeout" | tee -a "$LOG_FILE"
        exit 1
    fi
    sleep 2
done

# Verify the fresh setup
echo "[$(date)] POSTGRES_FRESH_START: Verifying fresh PostgreSQL setup..." | tee -a "$LOG_FILE"
docker exec purebliss-postgres psql -U postgres -d postgres -c "\l" | tee -a "$LOG_FILE"
docker exec purebliss-postgres psql -U postgres -d postgres -c "\du" | tee -a "$LOG_FILE"

# Configure Vault database connection with the correct credentials
echo "[$(date)] POSTGRES_FRESH_START: Configuring Vault database connection..." | tee -a "$LOG_FILE"

# Ensure we have a Vault token
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
    echo "[$(date)] POSTGRES_FRESH_START: ERROR: Vault token not found. Please ensure Vault is initialized and unsealed." | tee -a "$LOG_FILE"
    exit 1
fi

export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1

# Configure the database secrets engine with correct credentials
vault write database/config/postgres-app \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@purebliss-postgres:5432/postgres?sslmode=disable" \
    allowed_roles="postgres-role" \
    username="vault_admin" \
    password="vault_admin_password_123" \
    disable_escaping=true || {
    echo "[$(date)] POSTGRES_FRESH_START: ERROR: Failed to configure Vault database connection" | tee -a "$LOG_FILE"
    exit 1
}

echo "[$(date)] POSTGRES_FRESH_START: Database connection configuration completed successfully." | tee -a "$LOG_FILE"

# Test Vault database credential generation
echo "[$(date)] POSTGRES_FRESH_START: Testing Vault database credential generation..." | tee -a "$LOG_FILE"
VAULT_CREDS=$(vault read -format=json database/creds/postgres-role 2>/dev/null) || {
    echo "[$(date)] POSTGRES_FRESH_START: ERROR: Failed to generate database credentials from Vault." | tee -a "$LOG_FILE"
    exit 1
}

# Extract credentials and test connection
VAULT_DB_USER=$(echo "$VAULT_CREDS" | jq -r '.data.username')
VAULT_DB_PASS=$(echo "$VAULT_CREDS" | jq -r '.data.password')

echo "[$(date)] POSTGRES_FRESH_START: Generated Vault credentials - User: $VAULT_DB_USER" | tee -a "$LOG_FILE"

# Test the generated credentials
docker exec purebliss-postgres psql -U "$VAULT_DB_USER" -d postgres -c "SELECT 1 as vault_connection_test;" || {
    echo "[$(date)] POSTGRES_FRESH_START: ERROR: Failed to connect with Vault-generated credentials" | tee -a "$LOG_FILE"
    exit 1
}

echo "[$(date)] POSTGRES_FRESH_START: ✅ SUCCESS: PostgreSQL started fresh with Vault integration!" | tee -a "$LOG_FILE"
echo "[$(date)] POSTGRES_FRESH_START: Bootstrap credentials - postgres:bootstrap_admin_password_12345" | tee -a "$LOG_FILE"
echo "[$(date)] POSTGRES_FRESH_START: Vault admin credentials - vault_admin:vault_admin_password_123" | tee -a "$LOG_FILE"
echo "[$(date)] POSTGRES_FRESH_START: Vault dynamic credentials working: $VAULT_DB_USER" | tee -a "$LOG_FILE"

# Log to troubleshooting log
echo "[$(date)] POSTGRES_FRESH_START: Fresh PostgreSQL setup completed successfully with Vault integration" >> "$LOG_FILE"
