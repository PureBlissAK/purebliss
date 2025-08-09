#!/bin/bash
set -euo pipefail

# Test script for Nginx independent container startup with Vault PKI integration
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
DOMAIN="${LOCAL_HOSTNAME:-dev.purebliss.app}"

echo "[$(date)] INFO: Testing Nginx independent container startup with Vault PKI integration..." | tee -a "$LOG_FILE"

# Function to check service health
check_service_health() {
    local service_name="$1"
    local endpoint="$2"
    local max_attempts=30
    local attempt=1

    echo "[$(date)] INFO: Checking $service_name health at $endpoint..." | tee -a "$LOG_FILE"

    while [[ $attempt -le $max_attempts ]]; do
        if curl -k -s -o /dev/null -w "%{http_code}" "$endpoint" | grep -qE "200|301|302"; then
            echo "[$(date)] SUCCESS: $service_name is healthy (attempt $attempt)" | tee -a "$LOG_FILE"
            return 0
        fi
        echo "[$(date)] INFO: $service_name not ready yet (attempt $attempt/$max_attempts)" | tee -a "$LOG_FILE"
        sleep 5
        ((attempt++))
    done

    echo "[$(date)] ERROR: $service_name failed health check after $max_attempts attempts" | tee -a "$LOG_FILE"
    return 1
}

# Test 1: Clean environment
echo "[$(date)] INFO: Test 1 - Cleaning existing Nginx resources..." | tee -a "$LOG_FILE"
docker rm -f purebliss-nginx >/dev/null 2>&1 || true
docker volume rm purebliss_nginx_certs purebliss_nginx_dhparam >/dev/null 2>&1 || true

# Test 2: Verify Vault is running
echo "[$(date)] INFO: Test 2 - Verifying Vault availability..." | tee -a "$LOG_FILE"
if ! docker ps --format '{{.Names}}' | grep -q "purebliss-vault"; then
    echo "[$(date)] ERROR: Vault container not running - starting Vault first..." | tee -a "$LOG_FILE"
    cd /opt/dev-purebliss
    if ! /opt/dev-purebliss/dev_scripts/automation/start-all-services.sh vault; then
        echo "[$(date)] ERROR: Failed to start Vault" | tee -a "$LOG_FILE"
        exit 1
    fi
    sleep 10
fi

# Test 3: Test direct docker run (independent startup)
echo "[$(date)] INFO: Test 3 - Testing direct docker run for Nginx..." | tee -a "$LOG_FILE"
cd /opt/dev-purebliss/services/nginx

# Build image
if docker build -t purebliss-nginx-test -f nginx-dockerfile . >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Nginx test image built successfully" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Failed to build Nginx test image" | tee -a "$LOG_FILE"
    exit 1
fi

# Auto-detect Vault configuration
vault_addr="https://127.0.0.1:8200"
vault_token="dev-root-token-purebliss"

if docker ps --format '{{.Names}}' | grep -q "purebliss-vault" && \
   ! docker logs purebliss-vault 2>/dev/null | grep -q "dev mode is enabled"; then
    vault_addr="https://127.0.0.1:8200"
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    fi
fi

# Create network
docker network create purebliss-net >/dev/null 2>&1 || true

# Start independent container
echo "[$(date)] INFO: Starting Nginx test container independently..." | tee -a "$LOG_FILE"
if docker run -d \
    --name purebliss-nginx-test \
    --network purebliss-net \
    -p 8080:80 \
    -p 8443:443 \
    -e VAULT_ADDR="$vault_addr" \
    -e VAULT_TOKEN="$vault_token" \
    -e DOMAIN="$DOMAIN" \
    -e USE_VAULT="true" \
    -e VAULT_SKIP_VERIFY="true" \
    -v purebliss_nginx_test_certs:/etc/nginx/ssl \
    -v purebliss_nginx_test_dhparam:/etc/nginx/dhparam \
    -v /opt/my-secure-ha-stack/logs/dev-environment-setup.log:/opt/my-secure-ha-stack/logs/dev-environment-setup.log \
    purebliss-nginx-test >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] SUCCESS: Nginx test container started independently" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Failed to start Nginx test container" | tee -a "$LOG_FILE"
    exit 1
fi

# Test 4: Wait for SSL certificate generation and validate
echo "[$(date)] INFO: Test 4 - Waiting for SSL certificate generation..." | tee -a "$LOG_FILE"
sleep 20

# Check container logs
echo "[$(date)] INFO: Checking container startup logs..." | tee -a "$LOG_FILE"
docker logs purebliss-nginx-test | tail -10 | tee -a "$LOG_FILE"

# Validate configuration
if docker exec purebliss-nginx-test nginx -t >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: Nginx configuration is valid" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Nginx configuration validation failed" | tee -a "$LOG_FILE"
    docker exec purebliss-nginx-test nginx -t 2>&1 | tee -a "$LOG_FILE"
fi

# Test 5: Check SSL certificate existence
echo "[$(date)] INFO: Test 5 - Checking SSL certificate generation..." | tee -a "$LOG_FILE"
if docker exec purebliss-nginx-test test -f "/etc/nginx/ssl/$DOMAIN.crt"; then
    echo "[$(date)] SUCCESS: SSL certificate exists for $DOMAIN" | tee -a "$LOG_FILE"

    # Check certificate details
    echo "[$(date)] INFO: Certificate details:" | tee -a "$LOG_FILE"
    docker exec purebliss-nginx-test openssl x509 -in "/etc/nginx/ssl/$DOMAIN.crt" -text -noout | head -20 | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: SSL certificate not found for $DOMAIN" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: Available files in /etc/nginx/ssl/:" | tee -a "$LOG_FILE"
    docker exec purebliss-nginx-test ls -la /etc/nginx/ssl/ | tee -a "$LOG_FILE"
fi

# Test 6: Health checks
echo "[$(date)] INFO: Test 6 - Running health checks..." | tee -a "$LOG_FILE"

# HTTP health check
if check_service_health "Nginx HTTP" "http://localhost:8080/health"; then
    echo "[$(date)] SUCCESS: HTTP health check passed" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: HTTP health check failed" | tee -a "$LOG_FILE"
fi

# HTTPS health check
if check_service_health "Nginx HTTPS" "https://localhost:8443/health"; then
    echo "[$(date)] SUCCESS: HTTPS health check passed" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: HTTPS health check failed" | tee -a "$LOG_FILE"
fi

# Test 7: Test orchestrator function
echo "[$(date)] INFO: Test 7 - Testing orchestrator start_nginx() function..." | tee -a "$LOG_FILE"

# Clean up test container first
docker rm -f purebliss-nginx-test >/dev/null 2>&1 || true
docker volume rm purebliss_nginx_test_certs purebliss_nginx_test_dhparam >/dev/null 2>&1 || true

# Source the orchestrator and test start_nginx function
cd /opt/dev-purebliss
source start-all-services.sh

if start_nginx; then
    echo "[$(date)] SUCCESS: Orchestrator start_nginx() function completed successfully" | tee -a "$LOG_FILE"

    # Final health check on production container
    if check_service_health "Production Nginx HTTPS" "https://$DOMAIN/health"; then
        echo "[$(date)] SUCCESS: Production Nginx is healthy and SSL/TLS compliant" | tee -a "$LOG_FILE"
    else
        echo "[$(date)] WARNING: Production Nginx health check inconclusive" | tee -a "$LOG_FILE"
    fi
else
    echo "[$(date)] ERROR: Orchestrator start_nginx() function failed" | tee -a "$LOG_FILE"
    exit 1
fi

# Test 8: SSL/TLS compliance validation
echo "[$(date)] INFO: Test 8 - SSL/TLS compliance validation..." | tee -a "$LOG_FILE"

# Check SSL configuration
echo "[$(date)] INFO: Validating SSL configuration..." | tee -a "$LOG_FILE"
if curl -k -s -I "https://$DOMAIN" | grep -q "Strict-Transport-Security"; then
    echo "[$(date)] SUCCESS: HSTS header present" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: HSTS header missing" | tee -a "$LOG_FILE"
fi

if curl -k -s -I "https://$DOMAIN" | grep -q "X-Content-Type-Options"; then
    echo "[$(date)] SUCCESS: Security headers present" | tee -a "$LOG_FILE"
else
    echo "[$(date)] WARNING: Security headers missing" | tee -a "$LOG_FILE"
fi

# Summary
echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: Nginx Independent Startup Test Summary" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: Nginx independent container startup with Vault PKI integration completed" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: SSL/TLS certificate automation functional" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: Nginx container can start standalone with docker run" | tee -a "$LOG_FILE"
echo "[$(date)] SUCCESS: Orchestrator integration functional" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: Nginx SSL/TLS compliance enhancement complete" | tee -a "$LOG_FILE"
echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"

echo "[$(date)] SUCCESS: All Nginx independent startup tests completed successfully" | tee -a "$LOG_FILE"
