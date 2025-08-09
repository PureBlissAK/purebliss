#!/bin/bash
set -euo pipefail

# Grafana Vault Integration Troubleshooting Script
# Enhanced script to diagnose and fix Grafana + Vault database integration issues
# Based on Vault Automation Guide patterns

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SERVICE_NAME="grafana"

function log_action() {
    echo "[$(date)] GRAFANA_VAULT_TROUBLESHOOT: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] GRAFANA_VAULT_TROUBLESHOOT: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] GRAFANA_VAULT_TROUBLESHOOT: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

function check_vault_connectivity() {
    log_action "Checking Vault connectivity..."

    if docker exec purebliss-grafana curl -skk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
        log_success "Vault accessible from Grafana container"
        return 0
    else
        log_error "Vault not accessible from Grafana container"
        return 1
    fi
}

function check_vault_token() {
    log_action "Checking Vault token..."

    if docker exec purebliss-grafana test -f /vault-token; then
        log_success "Vault token file exists"
        # Test token validity
        if docker exec purebliss-grafana bash -c 'VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=$(cat /vault-token) vault status' >/dev/null 2>&1; then
            log_success "Vault token is valid"
            return 0
        else
            log_error "Vault token is invalid"
            return 1
        fi
    else
        log_error "Vault token file missing"
        return 1
    fi
}

function check_database_role() {
    log_action "Checking database role configuration..."

    if vault read database/roles/grafana-role >/dev/null 2>&1; then
        log_success "Database role 'grafana-role' exists"
        vault read database/roles/grafana-role
        return 0
    else
        log_error "Database role 'grafana-role' missing"
        return 1
    fi
}

function test_dynamic_credentials() {
    log_action "Testing dynamic credential generation..."

    CREDS=$(vault read -format=json database/creds/grafana-role 2>/dev/null)
    if [[ "$CREDS" != "null" ]] && [[ -n "$CREDS" ]]; then
        USERNAME=$(echo "$CREDS" | jq -r '.data.username')
        PASSWORD=$(echo "$CREDS" | jq -r '.data.password')

        log_success "Dynamic credentials generated: $USERNAME"

        # Test database connection
        if docker exec purebliss-postgres psql -U "$USERNAME" -d grafana -c "SELECT 1;" >/dev/null 2>&1; then
            log_success "Database connection successful with dynamic credentials"
            return 0
        else
            log_error "Database connection failed with dynamic credentials"
            return 1
        fi
    else
        log_error "Failed to generate dynamic credentials"
        return 1
    fi
}

function check_grafana_config() {
    log_action "Checking Grafana database configuration..."

    # Check if Grafana is using environment variables for database config
    log_action "Grafana environment variables:"
    docker exec purebliss-grafana env | grep -E "(DATABASE|GF_DATABASE)" || log_action "No database environment variables found"

    # Check Grafana configuration file
    if docker exec purebliss-grafana test -f /etc/grafana/grafana.ini; then
        log_action "Grafana configuration file exists"
        docker exec purebliss-grafana grep -A5 -B5 "\[database\]" /etc/grafana/grafana.ini || log_action "No database section in grafana.ini"
    else
        log_action "Grafana configuration file not found"
    fi
}

function fix_grafana_database_config() {
    log_action "Fixing Grafana database configuration..."

    # Generate fresh dynamic credentials
    log_action "Generating fresh dynamic credentials..."
    CREDS=$(vault read -format=json database/creds/grafana-role)

    if [[ "$CREDS" != "null" ]] && [[ -n "$CREDS" ]]; then
        USERNAME=$(echo "$CREDS" | jq -r '.data.username')
        PASSWORD=$(echo "$CREDS" | jq -r '.data.password')

        log_success "Generated credentials: $USERNAME"

        # Create Grafana environment file with dynamic credentials
        cat > /tmp/grafana-env << EOF
# Grafana Database Configuration with Vault Dynamic Credentials
GF_DATABASE_TYPE=postgres
GF_DATABASE_HOST=purebliss-postgres:5432
GF_DATABASE_NAME=grafana
GF_DATABASE_USER=${USERNAME}
GF_DATABASE_PASSWORD=${PASSWORD}
GF_DATABASE_SSL_MODE=disable
EOF

        # Apply the configuration by restarting container with new env
        log_action "Applying new database configuration..."

        # Stop current container
        docker stop purebliss-grafana

        # Start container with new environment
        docker run -d \
            --name purebliss-grafana \
            --network purebliss-net \
            --env-file /tmp/grafana-env \
            -e VAULT_ADDR=https://127.0.0.1:8200 \
            -e DATABASE_HOST=purebliss-postgres \
            -e DATABASE_PORT=5432 \
            -e DATABASE_NAME=grafana \
            --health-cmd="curl -fk http://localhost:3000/api/health || exit 1" \
            --health-interval=30s \
            --health-timeout=10s \
            --health-retries=3 \
            --health-start-period=60s \
            grafana:latest

        log_success "Grafana restarted with dynamic database credentials"

        # Clean up temporary file
        rm -f /tmp/grafana-env

        return 0
    else
        log_error "Failed to generate dynamic credentials for configuration"
        return 1
    fi
}

function validate_grafana_health() {
    log_action "Validating Grafana health..."

    # Wait for container to start
    sleep 10

    for i in {1..12}; do
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' purebliss-grafana 2>/dev/null || echo "unknown")

        case "$STATUS" in
            "healthy")
                log_success "Grafana container is healthy"
                return 0
                ;;
            "starting")
                log_action "Grafana still starting... (attempt $i/12)"
                ;;
            "unhealthy")
                log_error "Grafana container is unhealthy"
                docker logs --tail 20 purebliss-grafana
                return 1
                ;;
            *)
                log_error "Grafana container status unknown: $STATUS"
                return 1
                ;;
        esac

        sleep 5
    done

    log_error "Grafana failed to become healthy within timeout"
    return 1
}

function main() {
    log_action "Starting comprehensive Grafana Vault integration troubleshooting..."

    # Set Vault address for this script
    export VAULT_ADDR="https://127.0.0.1:8200"

    # Step 1: Check Vault connectivity
    if ! check_vault_connectivity; then
        log_error "Cannot proceed without Vault connectivity"
        exit 1
    fi

    # Step 2: Check Vault token
    if ! check_vault_token; then
        log_action "Copying Vault token to container..."
        if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
            docker cp /opt/my-secure-ha-stack/secrets/vault_token purebliss-grafana:/vault-token
            log_success "Vault token copied to container"
        else
            log_error "Vault token not found in host system"
            exit 1
        fi
    fi

    # Step 3: Check database role
    if ! check_database_role; then
        log_error "Database role missing - this should have been configured earlier"
        exit 1
    fi

    # Step 4: Test dynamic credentials
    if ! test_dynamic_credentials; then
        log_error "Dynamic credentials not working"
        exit 1
    fi

    # Step 5: Check current Grafana config
    check_grafana_config

    # Step 6: Fix Grafana database configuration
    if ! fix_grafana_database_config; then
        log_error "Failed to fix Grafana database configuration"
        exit 1
    fi

    # Step 7: Validate final health
    if validate_grafana_health; then
        log_success "Grafana Vault integration troubleshooting completed successfully!"

        # Final validation test
        log_action "Running final API test..."
        if docker exec purebliss-grafana curl -fk http://localhost:3000/api/health >/dev/null 2>&1; then
            log_success "Grafana API is responding correctly"
        else
            log_error "Grafana API not responding"
        fi
    else
        log_error "Grafana Vault integration troubleshooting failed"
        exit 1
    fi
}

# Show usage if called with --help
if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [--help]"
    echo ""
    echo "Enhanced Grafana Vault Integration Troubleshooting Script"
    echo "Diagnoses and fixes common issues with Grafana + Vault database integration"
    echo ""
    echo "This script will:"
    echo "  1. Check Vault connectivity from Grafana container"
    echo "  2. Validate Vault token and permissions"
    echo "  3. Test database role configuration"
    echo "  4. Generate and test dynamic credentials"
    echo "  5. Fix Grafana database configuration"
    echo "  6. Restart Grafana with proper environment"
    echo "  7. Validate final health and API response"
    echo ""
    echo "All actions are logged to: $LOG_FILE"
    exit 0
fi

# Run main function
main "$@"
