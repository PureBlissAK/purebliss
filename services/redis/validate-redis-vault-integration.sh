#!/bin/bash
set -euo pipefail

# redis Vault Integration Validation Script
# Validates all aspects of redis Vault integration
# Integration Type: database_dynamic

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE_NAME="redis"
INTEGRATION_TYPE="database_dynamic"

function log_check() {
    echo "🔍 $1"
    echo "[$(date)] REDIS_VALIDATION: $1" >> "$LOG_FILE"
}

function log_success() {
    echo "✅ $1"
    echo "[$(date)] REDIS_VALIDATION: ✅ SUCCESS: $1" >> "$LOG_FILE"
}

function log_error() {
    echo "❌ $1"
    echo "[$(date)] REDIS_VALIDATION: ❌ ERROR: $1" >> "$LOG_FILE"
}

function validate_container_health() {
    log_check "Validating $SERVICE_NAME container health..."

    if docker ps | grep -q purebliss-$SERVICE_NAME; then
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-$SERVICE_NAME 2>/dev/null || echo "no_healthcheck")
        
        case "$health_status" in
            "healthy")
                log_success "$SERVICE_NAME container is healthy"
                return 0
                ;;
            "unhealthy")
                log_error "$SERVICE_NAME container is unhealthy"
                return 1
                ;;
            "starting")
                log_check "$SERVICE_NAME container is starting..."
                return 1
                ;;
            "no_healthcheck")
                if docker inspect --format='{{.State.Status}}' purebliss-$SERVICE_NAME | grep -q running; then
                    log_success "$SERVICE_NAME container is running (no health check)"
                    return 0
                else
                    log_error "$SERVICE_NAME container is not running"
                    return 1
                fi
                ;;
        esac
    else
        log_error "$SERVICE_NAME container is not running"
        return 1
    fi
}

function validate_vault_integration() {
    log_check "Validating $SERVICE_NAME Vault integration..."

    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
        
        case "$INTEGRATION_TYPE" in
            "kv_secrets")
                validate_kv_secrets_integration
                ;;
            "database_dynamic")
                validate_database_integration
                ;;
            "pki_certificates")
                validate_pki_integration
                ;;
            "monitoring_config")
                validate_monitoring_integration
                ;;
        esac
    else
        log_error "Vault token not found"
        return 1
    fi
}

function validate_kv_secrets_integration() {
    log_check "Validating KV secrets integration..."

    if vault kv get secret/$SERVICE_NAME >/dev/null 2>&1; then
        log_success "KV secrets accessible for $SERVICE_NAME"
        
        # Test secret retrieval
        local admin_password
        admin_password=$(vault kv get -field=admin_password secret/$SERVICE_NAME 2>/dev/null || echo "")
        if [[ -n "$admin_password" ]]; then
            log_success "Admin password retrieved from Vault"
        else
            log_error "Admin password not found in Vault"
            return 1
        fi
    else
        log_error "KV secrets not accessible for $SERVICE_NAME"
        return 1
    fi
}

function validate_database_integration() {
    log_check "Validating database dynamic credentials integration..."

    # Test database role
    if vault read database/roles/$SERVICE_NAME-role >/dev/null 2>&1; then
        log_success "Database role configured for $SERVICE_NAME"
        
        # Test credential generation
        if vault read database/creds/$SERVICE_NAME-role >/dev/null 2>&1; then
            log_success "Dynamic credentials can be generated for $SERVICE_NAME"
        else
            log_error "Dynamic credential generation failed for $SERVICE_NAME"
            return 1
        fi
    else
        log_error "Database role not configured for $SERVICE_NAME"
        return 1
    fi
}

function validate_pki_integration() {
    log_check "Validating PKI certificate integration..."

    # Test PKI engine
    if vault read pki-$SERVICE_NAME/cert/ca >/dev/null 2>&1; then
        log_success "PKI CA certificate available for $SERVICE_NAME"
        
        # Test certificate generation
        if vault write pki-$SERVICE_NAME/issue/$SERVICE_NAME-role common_name="test.dev.purebliss.app" ttl="1h" >/dev/null 2>&1; then
            log_success "PKI certificate can be generated for $SERVICE_NAME"
        else
            log_error "PKI certificate generation failed for $SERVICE_NAME"
            return 1
        fi
    else
        log_error "PKI CA certificate not available for $SERVICE_NAME"
        return 1
    fi
}

function validate_monitoring_integration() {
    log_check "Validating monitoring configuration integration..."

    if vault kv get $SERVICE_NAME-config/main >/dev/null 2>&1; then
        log_success "Monitoring configuration accessible for $SERVICE_NAME"
        
        # Test configuration retrieval
        local scrape_interval
        scrape_interval=$(vault kv get -field=scrape_interval $SERVICE_NAME-config/main 2>/dev/null || echo "")
        if [[ -n "$scrape_interval" ]]; then
            log_success "Configuration parameters retrieved from Vault"
        else
            log_error "Configuration parameters not found in Vault"
            return 1
        fi
    else
        log_error "Monitoring configuration not accessible for $SERVICE_NAME"
        return 1
    fi
}

function validate_service_functionality() {
    log_check "Validating $SERVICE_NAME service functionality..."

    # Service-specific functionality tests
    case "$SERVICE_NAME" in
        "redis")
            validate_redis_functionality
            ;;
        "keycloak")
            validate_keycloak_functionality
            ;;
        "nginx")
            validate_nginx_functionality
            ;;
        "prometheus")
            validate_prometheus_functionality
            ;;
        *)
            log_check "Generic service functionality validation for $SERVICE_NAME"
            # Generic HTTP health check
            local service_port=$(docker port purebliss-$SERVICE_NAME | head -1 | cut -d: -f2)
            if [[ -n "$service_port" ]] && curl -sf "http://localhost:$service_port/health" >/dev/null 2>&1; then
                log_success "$SERVICE_NAME service endpoint responding"
            else
                log_check "$SERVICE_NAME service endpoint not responding (may be expected)"
            fi
            ;;
    esac
}

function validate_redis_functionality() {
    if docker exec purebliss-redis redis-cli ping | grep -q PONG; then
        log_success "Redis ping successful"
    else
        log_error "Redis ping failed"
        return 1
    fi
}

function validate_keycloak_functionality() {
    if curl -s "http://localhost:8080/" | grep -qE "(Keycloak|Resource not found)"; then
        log_success "Keycloak endpoint responding"
    else
        log_error "Keycloak endpoint not responding"
        return 1
    fi
}

function validate_nginx_functionality() {
    if curl -sk "https://dev.purebliss.app" -o /dev/null -w "%{http_code}" | grep -q 200; then
        log_success "Nginx HTTPS endpoint responding"
    else
        log_error "Nginx HTTPS endpoint not responding"
        return 1
    fi
}

function validate_prometheus_functionality() {
    if curl -s "http://localhost:9090/-/healthy" | grep -q "Prometheus is Healthy"; then
        log_success "Prometheus health endpoint responding"
    else
        log_error "Prometheus health endpoint not responding"
        return 1
    fi
}

# Main execution
function main() {
    log_check "Starting $SERVICE_NAME Vault integration validation..."

    local validation_status=0

    validate_container_health || validation_status=1
    validate_vault_integration || validation_status=1
    validate_service_functionality || validation_status=1

    if [[ $validation_status -eq 0 ]]; then
        log_success "$SERVICE_NAME Vault integration validation completed successfully!"
    else
        log_error "$SERVICE_NAME Vault integration validation failed"
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
