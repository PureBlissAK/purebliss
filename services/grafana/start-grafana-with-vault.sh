#!/bin/bash
set -euo pipefail

# grafana Vault Integration Startup Script
# Configures Vault integration and starts grafana with dynamic secrets
# Integration Type: database_dynamic

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE_NAME="grafana"
INTEGRATION_TYPE="database_dynamic"

function log_action() {
    echo "[$(date)] GRAFANA_VAULT_START: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] GRAFANA_VAULT_START: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] GRAFANA_VAULT_START: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

# Configure Vault integration based on type
function configure_vault_integration() {
    log_action "Configuring Vault $INTEGRATION_TYPE integration for $SERVICE_NAME..."

    export VAULT_ADDR="http://127.0.0.1:8200"
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

    case "$INTEGRATION_TYPE" in
        "kv_secrets")
            configure_kv_secrets_integration
            ;;
        "database_dynamic")
            configure_database_integration
            ;;
        "pki_certificates")
            configure_pki_integration
            ;;
        "monitoring_config")
            configure_monitoring_integration
            ;;
    esac
}

function configure_kv_secrets_integration() {
    log_action "Configuring KV v2 secrets for $SERVICE_NAME..."

    # Enable KV v2 secrets engine if not already enabled
    vault secrets enable -version=2 kv 2>/dev/null || true

    # Create default secrets for service
    if ! vault kv get secret/$SERVICE_NAME >/dev/null 2>&1; then
        log_action "Creating default secrets for $SERVICE_NAME..."
        vault kv put secret/$SERVICE_NAME \
            admin_password="$(openssl rand -base64 32)" \
            api_key="$(openssl rand -hex 32)" \
            secret_key="$(openssl rand -base64 32)"
        log_success "Default secrets created for $SERVICE_NAME"
    else
        log_success "Secrets already exist for $SERVICE_NAME"
    fi
}

function configure_database_integration() {
    log_action "Configuring database dynamic credentials for $SERVICE_NAME..."

    # Configure database role if not exists
    if ! vault read database/roles/$SERVICE_NAME-role >/dev/null 2>&1; then
        log_action "Creating database role for $SERVICE_NAME..."
        vault write database/roles/$SERVICE_NAME-role \
            db_name=postgres-grafana \
            creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT CONNECT ON DATABASE $SERVICE_NAME TO \"{{name}}\"; GRANT USAGE ON SCHEMA public TO \"{{name}}\"; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"{{name}}\";" \
            default_ttl="1h" \
            max_ttl="24h"
        log_success "Database role created for $SERVICE_NAME"
    else
        log_success "Database role already exists for $SERVICE_NAME"
    fi
}

function configure_pki_integration() {
    log_action "Configuring PKI certificates for $SERVICE_NAME..."

    # Enable PKI secrets engine if not exists
    vault secrets enable -path=pki-$SERVICE_NAME pki 2>/dev/null || true
    vault secrets tune -max-lease-ttl=8760h pki-$SERVICE_NAME

    # Configure PKI root CA if not exists
    if ! vault read pki-$SERVICE_NAME/cert/ca >/dev/null 2>&1; then
        log_action "Creating PKI root CA for $SERVICE_NAME..."
        vault write pki-$SERVICE_NAME/root/generate/internal \
            common_name="Pure Bliss $SERVICE_NAME CA" \
            ttl=8760h
        log_success "PKI root CA created for $SERVICE_NAME"
    fi

    # Configure PKI role if not exists
    if ! vault read pki-$SERVICE_NAME/roles/$SERVICE_NAME-role >/dev/null 2>&1; then
        log_action "Creating PKI role for $SERVICE_NAME..."
        vault write pki-$SERVICE_NAME/roles/$SERVICE_NAME-role \
            allowed_domains="dev.purebliss.app" \
            allow_subdomains=true \
            max_ttl="720h"
        log_success "PKI role created for $SERVICE_NAME"
    fi
}

function configure_monitoring_integration() {
    log_action "Configuring monitoring configuration for $SERVICE_NAME..."

    # Create monitoring configuration in Vault
    if ! vault kv get $SERVICE_NAME-config/main >/dev/null 2>&1; then
        log_action "Creating monitoring configuration for $SERVICE_NAME..."
        vault kv put $SERVICE_NAME-config/main \
            scrape_interval="15s" \
            evaluation_interval="15s" \
            retention_time="200h" \
            admin_password="$(openssl rand -base64 32)"
        log_success "Monitoring configuration created for $SERVICE_NAME"
    fi
}

function start_service() {
    log_action "Starting $SERVICE_NAME with Vault integration..."

    cd "$(dirname "$0")"
    docker-compose -f ${SERVICE_NAME}-docker-compose-vault-enhanced.yml up -d

    # Wait for service to be healthy
    for i in {1..30}; do
        if docker inspect --format='{{.State.Health.Status}}' purebliss-$SERVICE_NAME 2>/dev/null | grep -q healthy; then
            log_success "$SERVICE_NAME is healthy and ready"
            break
        fi
        if [[ $i -eq 30 ]]; then
            log_error "$SERVICE_NAME failed to start within timeout"
            return 1
        fi
        sleep 2
    done
}

function validate_integration() {
    log_action "Validating $SERVICE_NAME Vault integration..."

    if [[ -x "./validate-${SERVICE_NAME}-vault-integration.sh" ]]; then
        ./validate-${SERVICE_NAME}-vault-integration.sh
    else
        log_action "No validation script found, running basic checks..."

        # Basic health check
        if docker ps | grep -q purebliss-$SERVICE_NAME; then
            log_success "$SERVICE_NAME container is running"
        else
            log_error "$SERVICE_NAME container is not running"
            return 1
        fi
    fi
}

# Main execution
function main() {
    log_action "Starting $SERVICE_NAME with Vault $INTEGRATION_TYPE integration..."

    configure_vault_integration
    start_service
    validate_integration

    log_success "$SERVICE_NAME successfully started with Vault integration!"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
