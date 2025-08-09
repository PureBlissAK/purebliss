#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Individual Keycloak AppRole scaffolding for Vault integration"

# Vault connection parameters
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=myroot
export VAULT_SKIP_VERIFY=true

SERVICE_NAME="keycloak"
LOG_PREFIX="SCAFFOLD_KEYCLOAK_VAULT"

log_info "Starting individual $SERVICE_NAME Vault AppRole scaffolding"

# Validate Vault is accessible
validate_vault_connection() {
    log_info "Validating Vault connection for $SERVICE_NAME"

    if ! vault status >/dev/null 2>&1; then
        log_error "Vault is not accessible. Cannot proceed with $SERVICE_NAME AppRole setup"
        return 1
    fi

    log_success "Vault connection validated for $SERVICE_NAME"
}

# Create service-specific policy
create_keycloak_policy() {
    log_info "Creating $SERVICE_NAME-specific Vault policy"

    vault policy write keycloak-policy - << 'EOL'
path "secret/data/keycloak/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/keycloak/*" {
  capabilities = ["read", "list"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOL

    if [[ $? -eq 0 ]]; then
        log_success "Keycloak policy created successfully"
    else
        log_error "Failed to create keycloak policy"
        return 1
    fi
}

# Create AppRole for Keycloak
create_keycloak_approle() {
    log_info "Creating AppRole for $SERVICE_NAME"

    vault write auth/approle/role/keycloak \
        token_policies="keycloak-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true \
        secret_id_ttl=1h

    if [[ $? -eq 0 ]]; then
        log_success "Keycloak AppRole created successfully"
    else
        log_error "Failed to create keycloak AppRole"
        return 1
    fi
}

# Generate and store credentials
generate_keycloak_credentials() {
    log_info "Generating $SERVICE_NAME AppRole credentials"

    # Get role-id
    ROLE_ID=$(vault read -field=role_id auth/approle/role/keycloak/role-id)
    if [[ -z "$ROLE_ID" ]]; then
        log_error "Failed to retrieve role_id for keycloak"
        return 1
    fi

    # Generate secret-id
    SECRET_ID=$(vault write -force -field=secret_id auth/approle/role/keycloak/secret-id)
    if [[ -z "$SECRET_ID" ]]; then
        log_error "Failed to generate secret_id for keycloak"
        return 1
    fi

    log_info "Keycloak AppRole credentials generated"
    log_info "Role ID: $ROLE_ID"
    log_info "Secret ID: [REDACTED - stored in Vault]"

    # Store credentials in Vault KV store
    vault kv put secret/keycloak/approle \
        role_id="$ROLE_ID" \
        secret_id="$SECRET_ID" \
        service="keycloak" \
        created_date="$(date -Iseconds)"

    if [[ $? -eq 0 ]]; then
        log_success "Keycloak credentials stored in Vault KV store"
    else
        log_error "Failed to store keycloak credentials"
        return 1
    fi
}

# Test AppRole authentication
test_keycloak_auth() {
    log_info "Testing $SERVICE_NAME AppRole authentication"

    # Retrieve stored credentials
    STORED_ROLE_ID=$(vault kv get -field=role_id secret/keycloak/approle)
    STORED_SECRET_ID=$(vault kv get -field=secret_id secret/keycloak/approle)

    # Test authentication
    TEST_TOKEN=$(vault write -field=token auth/approle/login \
        role_id="$STORED_ROLE_ID" \
        secret_id="$STORED_SECRET_ID")

    if [[ -n "$TEST_TOKEN" ]]; then
        log_success "Keycloak AppRole authentication test successful"

        # Test token capabilities
        VAULT_TOKEN="$TEST_TOKEN" vault token lookup-self >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            log_success "Keycloak token validation successful"
        else
            log_error "Keycloak token validation failed"
            return 1
        fi
    else
        log_error "Keycloak AppRole authentication test failed"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting $SERVICE_NAME Vault integration scaffolding"

    # Phase 1: Validation
    validate_vault_connection || return 1

    # Phase 2: Policy Creation
    create_keycloak_policy || return 1

    # Phase 3: AppRole Creation
    create_keycloak_approle || return 1

    # Phase 4: Credential Generation
    generate_keycloak_credentials || return 1

    # Phase 5: Authentication Testing
    test_keycloak_auth || return 1

    log_success "✅ $SERVICE_NAME Vault AppRole scaffolding complete"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $LOG_PREFIX: Individual scaffolding complete - ready for container integration" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

    return 0
}

# Execute main function
main "$@"
