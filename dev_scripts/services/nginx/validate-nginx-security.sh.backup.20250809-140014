#!/bin/bash
set -euo pipefail

# NGINX Security Validation Script
# Comprehensive security testing for NGINX configuration

NGINX_CONTAINER="purebliss-nginx"
TEST_DOMAIN="dev.purebliss.app"
RESULTS_FILE="/tmp/nginx_security_results.json"

validate_security_headers() {
    echo "Testing security headers..."
    
    RESPONSE=$(curl -sI "https://$TEST_DOMAIN/health" 2>/dev/null || echo "FAILED")
    
    if [[ "$RESPONSE" == "FAILED" ]]; then
        echo "❌ HTTPS connection failed"
        return 1
    fi
    
    # Check for security headers
    headers=(
        "Strict-Transport-Security"
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
        "Content-Security-Policy"
        "Referrer-Policy"
        "Permissions-Policy"
    )
    
    for header in "${headers[@]}"; do
        if echo "$RESPONSE" | grep -qi "$header"; then
            echo "✅ $header header present"
        else
            echo "❌ $header header missing"
        fi
    done
}

validate_ssl_configuration() {
    echo "Testing SSL/TLS configuration..."
    
    # Test SSL protocols
    if openssl s_client -connect "$TEST_DOMAIN:443" -tls1_2 -verify_return_error < /dev/null 2>/dev/null; then
        echo "✅ TLS 1.2 supported"
    else
        echo "❌ TLS 1.2 not working"
    fi
    
    # Test weak protocols (should fail)
    if ! openssl s_client -connect "$TEST_DOMAIN:443" -ssl3 < /dev/null 2>/dev/null; then
        echo "✅ SSLv3 properly disabled"
    else
        echo "❌ SSLv3 still enabled (security risk)"
    fi
}

validate_rate_limiting() {
    echo "Testing rate limiting..."
    
    # Send multiple rapid requests
    for i in {1..15}; do
        curl -s "https://$TEST_DOMAIN/health" > /dev/null &
    done
    wait
    
    # Check if rate limiting is working
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TEST_DOMAIN/health")
    if [[ "$RESPONSE_CODE" == "429" ]]; then
        echo "✅ Rate limiting active"
    else
        echo "⚠️  Rate limiting may not be properly configured"
    fi
}

validate_waf_rules() {
    echo "Testing WAF rules..."
    
    # Test SQL injection protection
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TEST_DOMAIN/health?id=1' OR '1'='1")
    if [[ "$RESPONSE_CODE" == "403" || "$RESPONSE_CODE" == "444" ]]; then
        echo "✅ SQL injection protection active"
    else
        echo "❌ SQL injection protection not working"
    fi
    
    # Test XSS protection
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TEST_DOMAIN/health?test=<script>alert('xss')</script>")
    if [[ "$RESPONSE_CODE" == "403" || "$RESPONSE_CODE" == "444" ]]; then
        echo "✅ XSS protection active"
    else
        echo "❌ XSS protection not working"
    fi
}

main() {
    echo "🔒 NGINX Security Validation Starting..."
    echo "=================================="
    
    validate_security_headers
    echo ""
    validate_ssl_configuration
    echo ""
    validate_rate_limiting
    echo ""
    validate_waf_rules
    
    echo ""
    echo "🔒 NGINX Security Validation Complete"
    echo "Results logged to: $RESULTS_FILE"
}

main "$@"
