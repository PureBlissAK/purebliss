#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_DATABASE_ENTRYPOINT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-database-entrypoint.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced validation script for redis operations"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="validation"
SCRIPT_TAGS="enhancement,automation,redis,validation"
SCRIPT_SERVICES="redis"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Enhanced validation script for redis with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi
if [[ -f "$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "$SCRIPT_DIR/utilities/retry-utils.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
vault_database_entrypoint_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_database_entrypoint_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_database_entrypoint_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

set -euo pipefail

# Vault Database Dynamic Credentials Entrypoint
# Generates dynamic database credentials and configures database connection

VAULT_ADDR="${VAULT_ADDR:-https://purebliss-vault:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
SERVICE_NAME="${SERVICE_NAME:-redis}"
DB_ROLE="${DB_ROLE:-redis-role}"

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
