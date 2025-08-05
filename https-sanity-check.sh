#!/bin/bash
set -euo pipefail

# HTTPS Service Sanity Check Script
# Tests all browser-based services via HTTPS with Let's Encrypt SSL

LOG_FILE="/tmp/https_sanity_check.log"
DOMAIN="dev.purebliss.app"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_service() {
    local name="$1"
    local url="$2"
    local expected_code="${3:-200}"

    log "Testing $name at $url"

    # Test with timeout and capture both status code and any redirects
    local result=$(timeout 10 curl -s -L -o /dev/null -w "%{http_code}|%{url_effective}" "$url" 2>/dev/null || echo "TIMEOUT|$url")
    local status_code=$(echo "$result" | cut -d'|' -f1)
    local final_url=$(echo "$result" | cut -d'|' -f2)

    if [[ "$status_code" == "TIMEOUT" ]]; then
        log "❌ $name: TIMEOUT"
        return 1
    elif [[ "$status_code" =~ ^[23] ]]; then
        log "✅ $name: HTTP $status_code (${final_url})"
        return 0
    else
        log "⚠️  $name: HTTP $status_code (${final_url})"
        return 1
    fi
}

# Clear previous log
> "$LOG_FILE"

log "=== HTTPS Service Sanity Check ==="
log "Domain: $DOMAIN"
log "SSL: Let's Encrypt"
log ""

# Test main paths (browser-accessible services)
log "--- Testing Path-based Routes ---"
test_service "Keycloak Auth" "https://$DOMAIN/auth/"
test_service "Grafana Dashboard" "https://$DOMAIN/grafana/"
test_service "Vikunja Tasks" "https://$DOMAIN/vikunja/"
test_service "Vault UI" "https://$DOMAIN/vault/ui/"
test_service "Prometheus Metrics" "https://$DOMAIN/prometheus/"

log ""
log "--- Testing Port-based Routes ---"
test_service "Grafana (3001)" "https://$DOMAIN:3001/"
test_service "Keycloak (8080)" "https://$DOMAIN:8080/"
test_service "Prometheus (9090)" "https://$DOMAIN:9090/"

log ""
log "--- Testing SSL Certificate ---"
# Test SSL certificate validity
ssl_info=$(timeout 5 openssl s_client -connect $DOMAIN:443 -servername $DOMAIN </dev/null 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null || echo "SSL_ERROR")

if [[ "$ssl_info" == "SSL_ERROR" ]]; then
    log "❌ SSL Certificate: ERROR"
else
    log "✅ SSL Certificate: Valid"
    echo "$ssl_info" | while read line; do
        log "   $line"
    done
fi

log ""
log "=== Service Status Summary ==="

# Check container health
log "--- Container Health ---"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep purebliss | while read line; do
    if echo "$line" | grep -q "healthy"; then
        log "✅ $line"
    elif echo "$line" | grep -q "unhealthy"; then
        log "❌ $line"
    else
        log "⚠️  $line"
    fi
done

log ""
log "Sanity check complete. Full log: $LOG_FILE"
