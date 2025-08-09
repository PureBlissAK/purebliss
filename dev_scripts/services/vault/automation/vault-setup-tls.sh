#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_SETUP_TLS_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-setup-tls.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced vault-integration script for vault operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="vault-integration"
SCRIPT_TAGS="enhancement,automation,auto-commit,vault,security"
SCRIPT_SERVICES="vault"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced vault-integration script for vault with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
vault_setup_tls_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_setup_tls_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_setup_tls_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
vault_setup_tls_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    vault_setup_tls_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        vault_setup_tls_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            vault_setup_tls_log_success "Validation passed - proceeding with auto-commit"
        else
            vault_setup_tls_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        vault_setup_tls_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        vault_setup_tls_log_info "Auto-commit system not available - manual commit required"
        vault_setup_tls_log_info "Recommended commit message: $commit_message"
        vault_setup_tls_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
vault_setup_tls_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    vault_setup_tls_log_success "$final_message"
    
    # Execute auto-commit wrapper
    vault_setup_tls_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    vault_setup_tls_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Vault AppRole Setup for Services with TLS Support
# Creates database secrets engine and AppRole for secure service authentication

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="https://127.0.0.1:8200"
VAULT_ROOT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault/vault-root-token"
VAULT_ENV_FILE="/opt/my-secure-ha-stack/secrets/vault/vault-env.sh"

# Enable TLS skip verify for development with self-signed certificates
export VAULT_SKIP_VERIFY=true

echo "[$(date)] VAULT_SETUP: Starting Vault AppRole and secrets engine setup with TLS..." | tee -a "$LOG_FILE"

# Function to check if Vault is ready
check_vault_status() {
    echo "[$(date)] VAULT_SETUP: Checking Vault status..." | tee -a "$LOG_FILE"

    local status_response
    status_response=$(curl -sk "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo '{"sealed":true}')

    if echo "$status_response" | grep -q '"sealed":false'; then
        echo "[$(date)] VAULT_SETUP: Vault is unsealed and ready" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Vault is sealed or not accessible" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to get Vault token
get_vault_token() {
    if [[ -f "$VAULT_ENV_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$VAULT_ENV_FILE"
        echo "[$(date)] VAULT_SETUP: Using Vault token from $VAULT_ENV_FILE" | tee -a "$LOG_FILE"
        return 0
    elif [[ -f "$VAULT_ROOT_TOKEN_FILE" ]]; then
        export VAULT_TOKEN=$(cat "$VAULT_ROOT_TOKEN_FILE")
        echo "[$(date)] VAULT_SETUP: Using Vault token from $VAULT_ROOT_TOKEN_FILE" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] VAULT_SETUP: ERROR: No Vault token found" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to enable database secrets engine
enable_database_engine() {
    echo "[$(date)] VAULT_SETUP: Enabling database secrets engine..." | tee -a "$LOG_FILE"

    vault secrets enable -path=database database 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: Database secrets engine already enabled or error occurred" | tee -a "$LOG_FILE"
    }
}

# Function to configure PostgreSQL connection
configure_postgres_connection() {
    echo "[$(date)] VAULT_SETUP: Configuring PostgreSQL database connection..." | tee -a "$LOG_FILE"

    vault write database/config/postgres-app \
        plugin_name=postgresql-database-plugin \
        connection_url="postgresql://{{username}}:{{password}}@postgres:5432/postgres?sslmode=disable" \
        allowed_roles="postgres-role" \
        username="postgres" \
        password="postgres_password" 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: PostgreSQL connection configuration failed or already exists" | tee -a "$LOG_FILE"
    }
}

# Function to create database role
create_database_role() {
    echo "[$(date)] VAULT_SETUP: Creating PostgreSQL database role..." | tee -a "$LOG_FILE"

    vault write database/roles/postgres-role \
        db_name=postgres-app \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h" 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: Database role creation failed or already exists" | tee -a "$LOG_FILE"
    }
}

# Function to enable AppRole authentication
enable_approle_auth() {
    echo "[$(date)] VAULT_SETUP: Enabling AppRole authentication..." | tee -a "$LOG_FILE"

    vault auth enable approle 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: AppRole auth already enabled or error occurred" | tee -a "$LOG_FILE"
    }
}

# Function to create AppRole policy
create_approle_policy() {
    echo "[$(date)] VAULT_SETUP: Creating AppRole policy for database access..." | tee -a "$LOG_FILE"

    cat > /tmp/postgres-policy.hcl << EOF
# Allow reading database credentials
path "database/creds/postgres-role" {
  capabilities = ["read"]
}

# Allow reading static secrets (if needed)
path "secret/data/postgres/*" {
  capabilities = ["read"]
}
EOF

    vault policy write postgres-policy /tmp/postgres-policy.hcl 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: Policy creation failed or already exists" | tee -a "$LOG_FILE"
    }

    rm -f /tmp/postgres-policy.hcl
}

# Function to create AppRole
create_approle() {
    echo "[$(date)] VAULT_SETUP: Creating AppRole for PostgreSQL service..." | tee -a "$LOG_FILE"

    vault write auth/approle/role/postgres-app \
        token_policies="postgres-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true \
        secret_id_ttl=10m \
        secret_id_num_uses=0 2>/dev/null || {
        echo "[$(date)] VAULT_SETUP: AppRole creation failed or already exists" | tee -a "$LOG_FILE"
    }
}

# Function to generate and save AppRole credentials
generate_approle_credentials() {
    echo "[$(date)] VAULT_SETUP: Generating AppRole credentials..." | tee -a "$LOG_FILE"

    # Get role ID
    local role_id
    role_id=$(vault read -field=role_id auth/approle/role/postgres-app/role-id 2>/dev/null || echo "")

    if [[ -n "$role_id" ]]; then
        echo "[$(date)] VAULT_SETUP: Role ID: $role_id" | tee -a "$LOG_FILE"
        echo "$role_id" > "/opt/my-secure-ha-stack/secrets/vault-agent-role-id/role_id"
        chmod 600 "/opt/my-secure-ha-stack/secrets/vault-agent-role-id/role_id"
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Failed to get role ID" | tee -a "$LOG_FILE"
        return 1
    fi

    # Generate secret ID
    local secret_id
    secret_id=$(vault write -force -field=secret_id auth/approle/role/postgres-app/secret-id 2>/dev/null || echo "")

    if [[ -n "$secret_id" ]]; then
        echo "[$(date)] VAULT_SETUP: Secret ID generated successfully" | tee -a "$LOG_FILE"
        echo "$secret_id" > "/opt/my-secure-ha-stack/secrets/vault-agent-secret-id/secret_id"
        chmod 600 "/opt/my-secure-ha-stack/secrets/vault-agent-secret-id/secret_id"
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Failed to generate secret ID" | tee -a "$LOG_FILE"
        return 1
    fi

    echo "[$(date)] VAULT_SETUP: AppRole credentials saved successfully" | tee -a "$LOG_FILE"
    return 0
}

# Function to test database credential generation
test_database_credentials() {
    echo "[$(date)] VAULT_SETUP: Testing database credential generation..." | tee -a "$LOG_FILE"

    local test_creds
    test_creds=$(vault read database/creds/postgres-role 2>/dev/null || echo "")

    if [[ -n "$test_creds" ]]; then
        echo "[$(date)] VAULT_SETUP: Database credential generation test successful" | tee -a "$LOG_FILE"
        echo "$test_creds" | grep -E "(username|password)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Database credential generation test failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main execution
main() {
    # Check Vault status
    if ! check_vault_status; then
        echo "[$(date)] VAULT_SETUP: ERROR: Vault is not ready" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Get Vault token
    if ! get_vault_token; then
        echo "[$(date)] VAULT_SETUP: ERROR: Cannot authenticate with Vault" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Set up database secrets engine
    enable_database_engine
    configure_postgres_connection
    create_database_role

    # Set up AppRole authentication
    enable_approle_auth
    create_approle_policy
    create_approle

    # Generate credentials
    if generate_approle_credentials; then
        echo "[$(date)] VAULT_SETUP: SUCCESS: AppRole setup completed" | tee -a "$LOG_FILE"
    else
        echo "[$(date)] VAULT_SETUP: ERROR: Failed to generate AppRole credentials" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Test the setup
    if test_database_credentials; then
        echo "[$(date)] VAULT_SETUP: SUCCESS: All tests passed" | tee -a "$LOG_FILE"
    else
        echo "[$(date)] VAULT_SETUP: WARNING: Database credential test failed" | tee -a "$LOG_FILE"
    fi

    echo "[$(date)] VAULT_SETUP: Vault AppRole and database secrets engine setup completed successfully" | tee -a "$LOG_FILE"
}

# Run main function
main "$@"

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT USAGE EXAMPLES - PURE BLISS ELITE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════════
#
# 📚 COMPLETE GUIDE: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md
#
# BASIC AUTO-COMMIT ON SUCCESS:
# Add this at the end of your main script logic:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed successfully"
#
# AUTO-COMMIT WITH VALIDATION:
# Add validation command to ensure script worked correctly:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed with validation" "docker ps | grep -q my-service"
#
# MANUAL AUTO-COMMIT TRIGGER:
# Use auto-commit wrapper directly with custom message:
#   ${WRAPPER_PREFIX}_auto_commit_wrapper "Custom commit: Feature implemented successfully"
#
# DIRECT PURE BLISS ELITE SYSTEM (Recommended):
# Use the official auto-commit trigger system:
#   /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
#       "${SCRIPT_CATEGORY}" "Description of accomplishment" "${SCRIPT_NAME}"
#
# CONDITIONAL AUTO-COMMIT:
# Only commit if certain conditions are met:
#   if [[ \$SUCCESS_FLAG == "true" ]]; then
#       ${WRAPPER_PREFIX}_auto_commit_wrapper "Conditional commit: Success flag set"
#   fi
#
# VALIDATION COMMAND EXAMPLES:
# - Container health check: "docker ps | grep -q healthy"
# - File existence: "test -f /path/to/expected/file"
# - Service response: "curl -s http://service/health | grep -q ok"
# - Custom function: "my_validation_function"
#
# ELITE COMMIT MESSAGE FORMAT:
# The Pure Bliss Elite system automatically generates comprehensive commit messages
# following the standard format with safety guarantees, validation results, and
# proper documentation references. See the AUTO_COMMIT_SYSTEM_GUIDE.md for details.
#
# ═══════════════════════════════════════════════════════════════════════════════════
