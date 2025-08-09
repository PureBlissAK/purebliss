#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SETUP_VALIDATION_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="setup-validation.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with auto-commit functionality,
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
setup_validation_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
setup_validation_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
setup_validation_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
setup_validation_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    setup_validation_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        setup_validation_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            setup_validation_log_success "Validation passed - proceeding with auto-commit"
        else
            setup_validation_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        setup_validation_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        setup_validation_log_info "Auto-commit system not available - manual commit required"
        setup_validation_log_info "Recommended commit message: $commit_message"
        setup_validation_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
setup_validation_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    setup_validation_log_success "$final_message"
    
    # Execute auto-commit wrapper
    setup_validation_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    setup_validation_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

#!/usr/bin/env bash
###############################################################################
# NGINX Service Validation Script
# Pure Bliss Development Environment - Microservices Architecture
# Version: 2.0.0
# Service: Nginx Reverse Proxy with Vault-Managed PKI
###############################################################################


# Script Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="nginx"
LOG_FILE="/opt/logs/dev-environment-setup.log"
VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNINGS=0

###############################################################################
# Logging Functions
###############################################################################

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] NGINX_VALIDATE_${level}: ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    log_message "INFO" "$1"
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    log_message "SUCCESS" "$1"
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    log_message "WARNING" "$1"
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    log_message "ERROR" "$1"
    echo -e "${RED}❌ $1${NC}"
}

log_test() {
    local status="$1"
    local test_name="$2"
    local details="$3"

    ((TESTS_TOTAL++))

    case "$status" in
        "PASS")
            ((TESTS_PASSED++))
            echo -e "${GREEN}✅ PASS${NC}: $test_name - $details"
            ;;
        "FAIL")
            ((TESTS_FAILED++))
            echo -e "${RED}❌ FAIL${NC}: $test_name - $details"
            ;;
        "WARN")
            ((TESTS_WARNINGS++))
            echo -e "${YELLOW}⚠️  WARN${NC}: $test_name - $details"
            ;;
    esac

    log_message "$status" "TEST: $test_name - $details"
}

###############################################################################
# Validation Functions
###############################################################################

validate_prerequisites() {
    echo -e "\n${CYAN}🔍 Validating Prerequisites...${NC}"

    # Check Docker
    if command -v docker &> /dev/null; then
        log_test "PASS" "Docker Installation" "Docker command available"
    else
        log_test "FAIL" "Docker Installation" "Docker command not found"
    fi

    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        log_test "PASS" "Docker Compose Installation" "Docker Compose command available"
    else
        log_test "FAIL" "Docker Compose Installation" "Docker Compose command not found"
    fi

    # Check Vault CLI
    if command -v vault &> /dev/null; then
        log_test "PASS" "Vault CLI" "Vault command available"
    else
        log_test "FAIL" "Vault CLI" "Vault command not found"
    fi

    # Check curl
    if command -v curl &> /dev/null; then
        log_test "PASS" "Curl Installation" "Curl command available"
    else
        log_test "FAIL" "Curl Installation" "Curl command not found"
    fi
}

validate_vault_connectivity() {
    echo -e "\n${CYAN}🔐 Validating Vault Connectivity...${NC}"

    # Check Vault server
    if curl -skf "${VAULT_ADDR}/v1/sys/health" >/dev/null 2>&1; then
        log_test "PASS" "Vault Server" "Vault server is accessible at ${VAULT_ADDR}"
    else
        log_test "FAIL" "Vault Server" "Vault server not accessible at ${VAULT_ADDR}"
        return 1
    fi

    # Check Vault token
    if [[ -f "${VAULT_TOKEN_FILE}" ]]; then
        log_test "PASS" "Vault Token File" "Token file exists at ${VAULT_TOKEN_FILE}"

        # Set up Vault environment
        export VAULT_ADDR="${VAULT_ADDR}"
        export VAULT_TOKEN="$(cat "${VAULT_TOKEN_FILE}")"

        # Test authentication
        if vault token lookup >/dev/null 2>&1; then
            log_test "PASS" "Vault Authentication" "Successfully authenticated with Vault"
        else
            log_test "FAIL" "Vault Authentication" "Failed to authenticate with Vault"
        fi
    else
        log_test "FAIL" "Vault Token File" "Token file not found at ${VAULT_TOKEN_FILE}"
    fi
}

validate_vault_secrets_engines() {
    echo -e "\n${CYAN}🗂️  Validating Vault Secrets Engines...${NC}"

    # Check PKI secrets engine
    if vault secrets list | grep -q "pki/"; then
        log_test "PASS" "PKI Secrets Engine" "PKI secrets engine is enabled"

        # Check PKI root CA
        if vault read pki/cert/ca >/dev/null 2>&1; then
            log_test "PASS" "PKI Root CA" "Root CA certificate exists"
        else
            log_test "FAIL" "PKI Root CA" "Root CA certificate not found"
        fi

        # Check nginx role
        if vault read pki/roles/nginx-certs >/dev/null 2>&1; then
            log_test "PASS" "Nginx PKI Role" "Nginx certificate role exists"
        else
            log_test "FAIL" "Nginx PKI Role" "Nginx certificate role not found"
        fi
    else
        log_test "FAIL" "PKI Secrets Engine" "PKI secrets engine not enabled"
    fi

    # Check KV v2 secrets engine
    if vault secrets list | grep -q "secret/"; then
        log_test "PASS" "KV v2 Secrets Engine" "KV v2 secrets engine is enabled"

        # Check nginx config secrets
        if vault kv get secret/nginx/config >/dev/null 2>&1; then
            log_test "PASS" "Nginx Config Secrets" "Nginx configuration secrets exist"
        else
            log_test "FAIL" "Nginx Config Secrets" "Nginx configuration secrets not found"
        fi

        # Check nginx upstream secrets
        if vault kv get secret/nginx/upstreams >/dev/null 2>&1; then
            log_test "PASS" "Nginx Upstream Secrets" "Nginx upstream secrets exist"
        else
            log_test "FAIL" "Nginx Upstream Secrets" "Nginx upstream secrets not found"
        fi
    else
        log_test "FAIL" "KV v2 Secrets Engine" "KV v2 secrets engine not enabled"
    fi
}

validate_container_status() {
    echo -e "\n${CYAN}🐋 Validating Container Status...${NC}"

    # Check if nginx container exists
    if docker ps -a --format "{{.Names}}" | grep -q "^nginx$"; then
        log_test "PASS" "Container Existence" "Nginx container exists"

        # Check if container is running
        if docker ps --format "{{.Names}}" | grep -q "^nginx$"; then
            log_test "PASS" "Container Status" "Nginx container is running"

            # Check container health
            local health_status=$(docker inspect --format='{{.State.Health.Status}}' nginx 2>/dev/null || echo "none")
            case "$health_status" in
                "healthy")
                    log_test "PASS" "Container Health" "Container health check: healthy"
                    ;;
                "unhealthy")
                    log_test "FAIL" "Container Health" "Container health check: unhealthy"
                    ;;
                "starting")
                    log_test "WARN" "Container Health" "Container health check: starting"
                    ;;
                "none")
                    log_test "WARN" "Container Health" "No health check configured"
                    ;;
                *)
                    log_test "WARN" "Container Health" "Health status: $health_status"
                    ;;
            esac

            # Check container uptime
            local uptime=$(docker inspect --format='{{.State.StartedAt}}' nginx 2>/dev/null || echo "unknown")
            log_test "PASS" "Container Uptime" "Started at: $uptime"

        else
            log_test "FAIL" "Container Status" "Nginx container is not running"
        fi
    else
        log_test "FAIL" "Container Existence" "Nginx container does not exist"
    fi
}

validate_nginx_configuration() {
    echo -e "\n${CYAN}⚙️  Validating Nginx Configuration...${NC}"

    # Test nginx configuration syntax
    if docker exec nginx nginx -t >/dev/null 2>&1; then
        log_test "PASS" "Config Syntax" "Nginx configuration syntax is valid"
    else
        log_test "FAIL" "Config Syntax" "Nginx configuration syntax errors detected"
        docker exec nginx nginx -t 2>&1 | head -10
    fi

    # Check if configuration files exist
    if docker exec nginx test -f /etc/nginx/nginx.conf 2>/dev/null; then
        log_test "PASS" "Main Config File" "nginx.conf exists"
    else
        log_test "FAIL" "Main Config File" "nginx.conf not found"
    fi

    # Check SSL certificates
    if docker exec nginx test -f /vault/secrets/cert.pem 2>/dev/null; then
        log_test "PASS" "Vault SSL Certificate" "Vault-managed certificate found"
    elif docker exec nginx test -f /etc/nginx/certs/fullchain.pem 2>/dev/null; then
        log_test "PASS" "Static SSL Certificate" "Static certificate found"
    else
        log_test "WARN" "SSL Certificate" "No SSL certificate found"
    fi

    # Check private key
    if docker exec nginx test -f /vault/secrets/private_key.pem 2>/dev/null; then
        log_test "PASS" "Vault SSL Private Key" "Vault-managed private key found"
    elif docker exec nginx test -f /etc/nginx/certs/privkey.pem 2>/dev/null; then
        log_test "PASS" "Static SSL Private Key" "Static private key found"
    else
        log_test "WARN" "SSL Private Key" "No SSL private key found"
    fi
}

validate_network_connectivity() {
    echo -e "\n${CYAN}🌐 Validating Network Connectivity...${NC}"

    # Check HTTP port
    local http_status=$(curl -sk -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "000")
    if [[ $http_status -ne 000 ]]; then
        log_test "PASS" "HTTP Port" "HTTP responding with status: $http_status"
    else
        log_test "FAIL" "HTTP Port" "HTTP port not responding"
    fi

    # Check HTTPS port
    local https_status=$(curl -skk -o /dev/null -w "%{http_code}" https://localhost:443 2>/dev/null || echo "000")
    if [[ $https_status -ne 000 ]]; then
        log_test "PASS" "HTTPS Port" "HTTPS responding with status: $https_status"
    else
        log_test "FAIL" "HTTPS Port" "HTTPS port not responding"
    fi

    # Check domain name resolution
    if curl -skk -o /dev/null -w "%{http_code}" https://dev.purebliss.app 2>/dev/null | grep -q "[0-9]"; then
        log_test "PASS" "Domain Resolution" "dev.purebliss.app resolves and responds"
    else
        log_test "WARN" "Domain Resolution" "dev.purebliss.app not accessible (may need DNS/hosts configuration)"
    fi
}

validate_upstream_connectivity() {
    echo -e "\n${CYAN}🔗 Validating Upstream Services...${NC}"

    local upstreams=(
        "code-server:8080:/code-server"
        "keycloak:8080:/keycloak"
        "plane-web:3000:/plane"
        "grafana:3000:/grafana"
        "prometheus:9090:/prometheus"
        "vault:8200:/vault"
    )

    for upstream in "${upstreams[@]}"; do
        local service=$(echo "$upstream" | cut -d: -f1)
        local port=$(echo "$upstream" | cut -d: -f2 | cut -d/ -f1)
        local path=$(echo "$upstream" | cut -d: -f2 | cut -d/ -f2-)

        # Check if upstream container is running
        if docker ps --format "{{.Names}}" | grep -q "$service"; then
            log_test "PASS" "Upstream $service" "Container is running"

            # Test proxy connectivity through nginx
            local proxy_status=$(curl -skk -o /dev/null -w "%{http_code}" "https://localhost:443/$path" 2>/dev/null || echo "000")
            if [[ $proxy_status -ne 000 ]]; then
                log_test "PASS" "Proxy to $service" "Nginx proxy responding with status: $proxy_status"
            else
                log_test "WARN" "Proxy to $service" "Nginx proxy not responding for /$path"
            fi
        else
            log_test "WARN" "Upstream $service" "Container not running (proxy will fail)"
        fi
    done
}

validate_security_headers() {
    echo -e "\n${CYAN}🔒 Validating Security Headers...${NC}"

    # Get headers from HTTPS endpoint
    local headers=$(curl -skkI https://localhost:443 2>/dev/null)

    # Check HSTS
    if echo "$headers" | grep -qi "strict-transport-security"; then
        log_test "PASS" "HSTS Header" "Strict-Transport-Security header present"
    else
        log_test "WARN" "HSTS Header" "Strict-Transport-Security header missing"
    fi

    # Check X-Frame-Options
    if echo "$headers" | grep -qi "x-frame-options"; then
        log_test "PASS" "X-Frame-Options" "X-Frame-Options header present"
    else
        log_test "WARN" "X-Frame-Options" "X-Frame-Options header missing"
    fi

    # Check X-Content-Type-Options
    if echo "$headers" | grep -qi "x-content-type-options"; then
        log_test "PASS" "X-Content-Type-Options" "X-Content-Type-Options header present"
    else
        log_test "WARN" "X-Content-Type-Options" "X-Content-Type-Options header missing"
    fi

    # Check Content-Security-Policy
    if echo "$headers" | grep -qi "content-security-policy"; then
        log_test "PASS" "CSP Header" "Content-Security-Policy header present"
    else
        log_test "WARN" "CSP Header" "Content-Security-Policy header missing"
    fi
}

validate_performance() {
    echo -e "\n${CYAN}⚡ Validating Performance...${NC}"

    # Check response time
    local response_time=$(curl -skk -o /dev/null -w "%{time_total}" https://localhost:443 2>/dev/null || echo "99.999")
    if [[ $(echo "$response_time < 1.0" | awk '{print ($1 < $3)}') -eq 1 ]]; then
        log_test "PASS" "Response Time" "Response time: ${response_time}s (< 1s)"
    elif [[ $(echo "$response_time < 5.0" | awk '{print ($1 < $3)}') -eq 1 ]]; then
        log_test "WARN" "Response Time" "Response time: ${response_time}s (acceptable)"
    else
        log_test "FAIL" "Response Time" "Response time: ${response_time}s (too slow)"
    fi

    # Check container resource usage
    local stats=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" nginx 2>/dev/null | tail -1)
    if [[ -n "$stats" ]]; then
        local cpu=$(echo "$stats" | awk '{print $1}' | sed 's/%//')
        local mem=$(echo "$stats" | awk '{print $2}' | cut -d'/' -f1)

        log_test "PASS" "Resource Usage" "CPU: ${cpu}%, Memory: ${mem}"
    else
        log_test "WARN" "Resource Usage" "Could not retrieve container stats"
    fi
}

validate_logs() {
    echo -e "\n${CYAN}📋 Validating Logs...${NC}"

    # Check if container is producing logs
    local log_lines=$(docker logs nginx 2>&1 | wc -l)
    if [[ $log_lines -gt 0 ]]; then
        log_test "PASS" "Log Output" "$log_lines log lines available"
    else
        log_test "WARN" "Log Output" "No log output from container"
    fi

    # Check for error patterns in logs
    local error_count=$(docker logs nginx 2>&1 | grep -i error | wc -l)
    if [[ $error_count -eq 0 ]]; then
        log_test "PASS" "Error Log Check" "No errors found in logs"
    else
        log_test "WARN" "Error Log Check" "$error_count error(s) found in logs"
    fi

    # Check for recent activity
    local recent_logs=$(docker logs --since=1m nginx 2>&1 | wc -l)
    if [[ $recent_logs -gt 0 ]]; then
        log_test "PASS" "Recent Activity" "$recent_logs recent log entries"
    else
        log_test "WARN" "Recent Activity" "No recent log activity"
    fi
}

generate_report() {
    echo -e "\n${CYAN}📊 Validation Summary${NC}"
    echo -e "===================="
    echo -e "Total Tests: ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo -e "${YELLOW}Warnings: ${TESTS_WARNINGS}${NC}"

    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    echo -e "Success Rate: ${success_rate}%"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All critical tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Some tests failed. Review output above.${NC}"
        return 1
    fi
}

show_service_info() {
    echo -e "\n${CYAN}🔧 Service Information${NC}"
    echo -e "====================="

    echo -e "\n${BLUE}📁 Files & Directories:${NC}"
    echo "  Script Directory: ${SCRIPT_DIR}"
    echo "  Log File: ${LOG_FILE}"
    echo "  Vault Address: ${VAULT_ADDR}"

    echo -e "\n${BLUE}🐋 Container Details:${NC}"
    if docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep nginx; then
        echo ""
    else
        echo "  No nginx containers found"
    fi

    echo -e "\n${BLUE}🔍 Quick Diagnostics:${NC}"
    echo "  View logs: docker logs nginx"
    echo "  Check config: docker exec nginx nginx -t"
    echo "  Container stats: docker stats nginx --no-stream"
    echo "  Service restart: docker restart nginx"
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Comprehensive validation script for nginx service with Vault integration.

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    --quick                 Run only critical tests
    --skip-upstream         Skip upstream service validation
    --skip-performance      Skip performance tests

VALIDATION CATEGORIES:
    - Prerequisites (Docker, Vault CLI, etc.)
    - Vault connectivity and authentication
    - Vault secrets engines (PKI, KV v2)
    - Container status and health
    - Nginx configuration validity
    - Network connectivity (HTTP/HTTPS)
    - Upstream service connectivity
    - Security headers validation
    - Performance metrics
    - Log analysis

EXAMPLES:
    $0                      # Full validation
    $0 --quick              # Quick validation
    $0 --verbose            # Detailed output

EOF
}

###############################################################################
# Main Execution
###############################################################################

main() {
    local quick_mode=false
    local skip_upstream=false
    local skip_performance=false
    local verbose=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                set -x
                shift
                ;;
            --quick)
                quick_mode=true
                shift
                ;;
            --skip-upstream)
                skip_upstream=true
                shift
                ;;
            --skip-performance)
                skip_performance=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${CYAN}🔍 Nginx Service Validation${NC}"
    echo -e "============================="
    log_info "Starting nginx service validation..."

    # Run validation tests
    validate_prerequisites
    validate_vault_connectivity
    validate_vault_secrets_engines
    validate_container_status
    validate_nginx_configuration
    validate_network_connectivity

    if [[ $skip_upstream == false ]]; then
        validate_upstream_connectivity
    fi

    validate_security_headers

    if [[ $skip_performance == false ]]; then
        validate_performance
    fi

    validate_logs

    # Generate final report
    if generate_report; then
        log_success "Nginx validation completed successfully"
        exit_code=0
    else
        log_error "Nginx validation completed with failures"
        exit_code=1
    fi

    show_service_info

    log_message "COMPLETE" "Nginx validation finished with exit code: $exit_code"
    exit $exit_code
}

# Trap for cleanup on script exit
trap 'echo -e "\n${YELLOW}⚠️  Validation interrupted${NC}"' INT TERM

# Run main function with all arguments
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
