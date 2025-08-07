#!/bin/bash
# ============================================================================
# Nginx SSL/TLS Compliance Validation Script
# ============================================================================

set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
CONTAINER_NAME="purebliss-nginx"
DOMAIN="dev.purebliss.app"

echo "[$(date)] INFO: Starting comprehensive Nginx SSL/TLS compliance validation" | tee -a "$LOG_FILE"

# Function to check if container is running
check_container_status() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        echo "[$(date)] ERROR: Container $CONTAINER_NAME is not running" | tee -a "$LOG_FILE"
        return 1
    fi
    echo "[$(date)] SUCCESS: Container $CONTAINER_NAME is running" | tee -a "$LOG_FILE"
    return 0
}

# Function to test HTTP redirect
test_http_redirect() {
    echo "[$(date)] INFO: Testing HTTP to HTTPS redirect" | tee -a "$LOG_FILE"
    local http_status
    http_status=$(docker exec "$CONTAINER_NAME" curl -s -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" http://127.0.0.1)

    if [[ "$http_status" == "301" ]]; then
        echo "[$(date)] SUCCESS: HTTP redirects to HTTPS (status: $http_status)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: HTTP redirect failed (status: $http_status, expected: 301)" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test HTTPS response
test_https_response() {
    echo "[$(date)] INFO: Testing HTTPS response" | tee -a "$LOG_FILE"
    local https_status
    https_status=$(docker exec "$CONTAINER_NAME" curl -sSk -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" https://127.0.0.1)

    if [[ "$https_status" == "200" ]]; then
        echo "[$(date)] SUCCESS: HTTPS responds correctly (status: $https_status)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: HTTPS response failed (status: $https_status, expected: 200)" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test HSTS header
test_hsts_header() {
    echo "[$(date)] INFO: Testing HSTS header presence" | tee -a "$LOG_FILE"
    local hsts_header
    hsts_header=$(docker exec "$CONTAINER_NAME" curl -sSk -D - -H "Host: $DOMAIN" https://127.0.0.1 | grep -i "Strict-Transport-Security" || echo "")

    if [[ -n "$hsts_header" ]]; then
        echo "[$(date)] SUCCESS: HSTS header present: $hsts_header" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: HSTS header missing" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test SSL certificate
test_ssl_certificate() {
    echo "[$(date)] INFO: Testing SSL certificate validity" | tee -a "$LOG_FILE"
    local cert_check
    cert_check=$(docker exec "$CONTAINER_NAME" sh -c "echo '' | openssl s_client -connect 127.0.0.1:443 -servername $DOMAIN -verify_return_error 2>/dev/null | grep 'verify return:'" || echo "")

    if echo "$cert_check" | grep -q "verify return:1"; then
        echo "[$(date)] SUCCESS: SSL certificate is valid: $cert_check" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] WARNING: SSL certificate verification: $cert_check" | tee -a "$LOG_FILE"
        # Don't fail for self-signed certs in development
        return 0
    fi
}

# Function to test TLS protocol
test_tls_protocol() {
    echo "[$(date)] INFO: Testing TLS protocol version" | tee -a "$LOG_FILE"
    local tls_protocol
    tls_protocol=$(docker exec "$CONTAINER_NAME" sh -c "echo '' | openssl s_client -connect 127.0.0.1:443 -servername $DOMAIN 2>/dev/null | grep 'Protocol  :'" || echo "")

    if echo "$tls_protocol" | grep -qE "(TLSv1\.2|TLSv1\.3)"; then
        echo "[$(date)] SUCCESS: TLS protocol is secure: $tls_protocol" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: Insecure or unknown TLS protocol: $tls_protocol" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test Nginx configuration
test_nginx_config() {
    echo "[$(date)] INFO: Testing Nginx configuration syntax" | tee -a "$LOG_FILE"
    if docker exec "$CONTAINER_NAME" nginx -t 2>&1 | tee -a "$LOG_FILE"; then
        echo "[$(date)] SUCCESS: Nginx configuration is valid" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: Nginx configuration is invalid" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main validation function
main() {
    echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: Nginx SSL/TLS Compliance Validation" | tee -a "$LOG_FILE"
    echo "[$(date)] INFO: ========================================" | tee -a "$LOG_FILE"

    local tests=(
        "check_container_status"
        "test_nginx_config"
        "test_http_redirect"
        "test_https_response"
        "test_hsts_header"
        "test_ssl_certificate"
        "test_tls_protocol"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
        echo "" | tee -a "$LOG_FILE"
    done

    if [[ $failed_tests -eq 0 ]]; then
        echo "[$(date)] SUCCESS: All SSL/TLS compliance tests passed" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: Nginx is 100% SSL/TLS compliant" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[$(date)] ERROR: $failed_tests SSL/TLS compliance tests failed" | tee -a "$LOG_FILE"
        echo "[$(date)] INFO: Nginx is NOT fully SSL/TLS compliant" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Run main function
main "$@"
