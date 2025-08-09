#!/bin/bash
set -euo pipefail

# Enhanced Grafana Vault Troubleshooting Script
# Based on vault-break-fix.sh patterns and VAULT_AUTOMATION_GUIDE.md
# Stops looping by focusing on root cause analysis and definitive fixes

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE_NAME="grafana"

function log_action() {
    echo "[$(date)] GRAFANA_TROUBLESHOOT: $1" | tee -a "$LOG_FILE"
}

function log_success() {
    echo "[$(date)] GRAFANA_TROUBLESHOOT: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
}

function log_error() {
    echo "[$(date)] GRAFANA_TROUBLESHOOT: ❌ ERROR: $1" | tee -a "$LOG_FILE"
}

function log_warning() {
    echo "[$(date)] GRAFANA_TROUBLESHOOT: ⚠️ WARNING: $1" | tee -a "$LOG_FILE"
}

# Phase 1: Immediate Issue Assessment
function assess_current_state() {
    log_action "=== PHASE 1: Current State Assessment ==="

    # Check container status
    local container_status=$(docker inspect --format='{{.State.Status}}' purebliss-grafana 2>/dev/null || echo "not_found")
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-grafana 2>/dev/null || echo "no_health_check")

    log_action "Container Status: $container_status"
    log_action "Health Status: $health_status"

    # Check if Grafana is actually responding internally
    local grafana_api_response=$(docker exec purebliss-grafana curl -sk -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null || echo "connection_failed")
    log_action "Grafana API Response: $grafana_api_response"

    # Check if healthcheck endpoint is wrong
    local health_endpoint_check=$(docker exec purebliss-grafana curl -sk -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null || echo "health_endpoint_failed")
    log_action "Health Endpoint Check: $health_endpoint_check"

    # Return assessment
    if [[ "$grafana_api_response" == "200" ]]; then
        log_action "✅ Root Issue: Grafana is running but healthcheck configuration is incorrect"
        return 0
    else
        log_action "❌ Root Issue: Grafana service is not responding properly"
        return 1
    fi
}

# Phase 2: Database Connection Analysis
function analyze_database_connection() {
    log_action "=== PHASE 2: Database Connection Analysis ==="

    # Check if Grafana is trying to connect to database
    log_action "Checking Grafana database configuration..."

    # Get database connection environment variables
    local db_host=$(docker exec purebliss-grafana printenv DATABASE_HOST 2>/dev/null || echo "not_set")
    local db_name=$(docker exec purebliss-grafana printenv DATABASE_NAME 2>/dev/null || echo "not_set")
    local db_user=$(docker exec purebliss-grafana printenv DATABASE_USER 2>/dev/null || echo "not_set")

    log_action "DB_HOST: $db_host, DB_NAME: $db_name, DB_USER: $db_user"

    # Check for Grafana-specific environment variables
    local gf_db_type=$(docker exec purebliss-grafana printenv GF_DATABASE_TYPE 2>/dev/null || echo "not_set")
    local gf_db_host=$(docker exec purebliss-grafana printenv GF_DATABASE_HOST 2>/dev/null || echo "not_set")
    local gf_db_user=$(docker exec purebliss-grafana printenv GF_DATABASE_USER 2>/dev/null || echo "not_set")

    log_action "GF_DATABASE_TYPE: $gf_db_type, GF_DATABASE_HOST: $gf_db_host, GF_DATABASE_USER: $gf_db_user"

    # Test database connectivity from Grafana container
    log_action "Testing database connectivity from Grafana container..."
    if docker exec purebliss-grafana nc -z purebliss-postgres 5432 2>/dev/null; then
        log_success "✅ Database is reachable from Grafana container"
    else
        log_error "❌ Database is NOT reachable from Grafana container"
        return 1
    fi

    return 0
}

# Phase 3: Vault Dynamic Secrets Analysis
function analyze_vault_integration() {
    log_action "=== PHASE 3: Vault Integration Analysis ==="

    # Test Vault connectivity from Grafana container
    log_action "Testing Vault connectivity from Grafana container..."
    if docker exec purebliss-grafana nc -z purebliss-vault 8200 2>/dev/null; then
        log_success "✅ Vault is reachable from Grafana container"
    else
        log_error "❌ Vault is NOT reachable from Grafana container"
        return 1
    fi

    # Test dynamic credential generation from host
    log_action "Testing Vault dynamic credential generation..."
    local vault_addr="https://127.0.0.1:8200"
    local vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

    VAULT_ADDR="$vault_addr" VAULT_TOKEN="$vault_token" \
    vault read database/creds/grafana-role > /tmp/grafana_vault_test.out 2>&1

    if [[ $? -eq 0 ]]; then
        log_success "✅ Vault dynamic credentials are working"
        local dynamic_user=$(grep "username" /tmp/grafana_vault_test.out | awk '{print $2}')
        log_action "Dynamic User: $dynamic_user"
        rm -f /tmp/grafana_vault_test.out
    else
        log_error "❌ Vault dynamic credentials failed"
        cat /tmp/grafana_vault_test.out >> "$LOG_FILE"
        rm -f /tmp/grafana_vault_test.out
        return 1
    fi

    return 0
}

# Phase 4: Definitive Fix Implementation
function implement_definitive_fix() {
    log_action "=== PHASE 4: Implementing Definitive Fix ==="

    # The core issue: Grafana needs GF_DATABASE_* environment variables, not generic DATABASE_* variables
    log_action "Configuring Grafana with proper environment variables..."

    # Get fresh dynamic credentials
    local vault_addr="https://127.0.0.1:8200"
    local vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

    VAULT_ADDR="$vault_addr" VAULT_TOKEN="$vault_token" \
    vault read database/creds/grafana-role > /tmp/grafana_creds.out 2>&1

    if [[ $? -ne 0 ]]; then
        log_error "❌ Failed to get fresh dynamic credentials"
        return 1
    fi

    local dynamic_user=$(grep "username" /tmp/grafana_creds.out | awk '{print $2}')
    local dynamic_pass=$(grep "password" /tmp/grafana_creds.out | awk '{print $2}')
    rm -f /tmp/grafana_creds.out

    log_action "Got dynamic credentials - User: $dynamic_user"

    # Update environment and restart container
    log_action "Stopping current Grafana container..."
    docker stop purebliss-grafana 2>/dev/null || true
    docker rm purebliss-grafana 2>/dev/null || true

    # Start with proper GF_ environment variables
    log_action "Starting Grafana with proper GF_ database configuration..."
    docker run -d \
        --name purebliss-grafana \
        --network purebliss-net \
        --restart unless-stopped \
        -e GF_DATABASE_TYPE=postgres \
        -e GF_DATABASE_HOST=purebliss-postgres:5432 \
        -e GF_DATABASE_NAME=grafana \
        -e GF_DATABASE_USER="$dynamic_user" \
        -e GF_DATABASE_PASSWORD="$dynamic_pass" \
        -e GF_DATABASE_SSL_MODE=disable \
        -e GF_SERVER_HTTP_PORT=3000 \
        -e GF_SERVER_DOMAIN=dev.purebliss.app \
        -e GF_SECURITY_ADMIN_USER=admin \
        -e GF_SECURITY_ADMIN_PASSWORD=admin \
        --health-cmd="curl -fk http://localhost:3000/api/health || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        --health-start-period=60s \
        -v grafana_grafana_data:/var/lib/grafana \
        grafana/grafana:latest

    # Wait for startup and validate
    log_action "Waiting for Grafana to start with proper configuration..."
    sleep 15

    # Test health
    for i in {1..8}; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-grafana 2>/dev/null || echo "not_found")
        log_action "Health check attempt $i: $health_status"

        if [[ "$health_status" == "healthy" ]]; then
            log_success "✅ Grafana is now healthy with proper GF_ environment variables!"
            return 0
        elif [[ "$health_status" == "unhealthy" ]] && [[ $i -ge 6 ]]; then
            log_error "❌ Grafana still unhealthy after fix attempt"
            docker logs --tail 20 purebliss-grafana | tee -a "$LOG_FILE"
            return 1
        fi

        sleep 10
    done

    return 1
}

# Main execution
function main() {
    log_action "🔧 Starting Enhanced Grafana Vault Integration Troubleshooting..."

    assess_current_state
    analyze_database_connection
    analyze_vault_integration

    log_action "Implementing definitive fix based on root cause analysis..."
    if implement_definitive_fix; then
        log_success "🎉 Grafana Vault integration successfully fixed!"

        # Validate the fix
        log_action "Final validation..."
        sleep 5
        local final_health=$(docker inspect --format='{{.State.Health.Status}}' purebliss-grafana)
        local api_response=$(docker exec purebliss-grafana curl -sk -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null || echo "failed")

        log_success "Final Status - Health: $final_health, API: $api_response"

        # Log enhancement for future prevention
        log_action "SCRIPT_ENHANCEMENT: Fixed Grafana Vault integration by using proper GF_DATABASE_* environment variables instead of generic DATABASE_* variables. Root cause: Grafana requires GF_ prefixed environment variables for database configuration. Prevention: All future Grafana deployments must use GF_ environment variable format. Validation: Container health check passes with exit code 0."

        return 0
    else
        log_error "❌ Definitive fix failed - manual intervention required"
        return 1
    fi
}

# Run the troubleshooting
main "$@"
