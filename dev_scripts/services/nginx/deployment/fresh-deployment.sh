#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# FRESH_DEPLOYMENT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="fresh-deployment.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced deployment script for infrastructure operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="deployment"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="infrastructure"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced deployment script for infrastructure with auto-commit functionality,
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
fresh_deployment_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
fresh_deployment_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
fresh_deployment_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
fresh_deployment_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    fresh_deployment_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        fresh_deployment_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            fresh_deployment_log_success "Validation passed - proceeding with auto-commit"
        else
            fresh_deployment_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        fresh_deployment_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        fresh_deployment_log_info "Auto-commit system not available - manual commit required"
        fresh_deployment_log_info "Recommended commit message: $commit_message"
        fresh_deployment_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
fresh_deployment_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    fresh_deployment_log_success "$final_message"
    
    # Execute auto-commit wrapper
    fresh_deployment_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    fresh_deployment_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

#!/usr/bin/env bash
###############################################################################
# NGINX Independent Fresh Start Service
# Pure Bliss Development Environment - Microservices Architecture
# Version: 2.0.0
# Service: Nginx Reverse Proxy with Vault-Managed PKI Certificates
###############################################################################


# Script Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="nginx"
LOG_FILE="/opt/logs/dev-environment-setup.log"
COMPOSE_FILE="${SCRIPT_DIR}/nginx-docker-compose-vault-enhanced.yml"
VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

###############################################################################
# Logging Functions
###############################################################################

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${level}: ${message}" | tee -a "${LOG_FILE}"
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

###############################################################################
# Utility Functions
###############################################################################

check_prerequisites() {
    log_info "Checking prerequisites for nginx service..."

    # Check if running as correct user
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi

    # Check Vault token
    if [[ ! -f "${VAULT_TOKEN_FILE}" ]]; then
        log_error "Vault token file not found: ${VAULT_TOKEN_FILE}"
        exit 1
    fi

    log_success "Prerequisites validated"
}

wait_for_vault() {
    log_info "Waiting for Vault to be available..."
    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if curl -skf "${VAULT_ADDR}/v1/sys/health" >/dev/null 2>&1; then
            log_success "Vault is available"
            return 0
        fi

        log_info "Attempt ${attempt}/${max_attempts}: Vault not ready, waiting 2 seconds..."
        sleep 2
        ((attempt++))
    done

    log_error "Vault is not available after ${max_attempts} attempts"
    exit 1
}

setup_vault_authentication() {
    log_info "Setting up Vault authentication..."

    export VAULT_ADDR="${VAULT_ADDR}"
    export VAULT_TOKEN="$(cat "${VAULT_TOKEN_FILE}")"

    # Verify Vault authentication
    if ! vault token lookup >/dev/null 2>&1; then
        log_error "Failed to authenticate with Vault"
        exit 1
    fi

    log_success "Vault authentication successful"
}

setup_vault_pki() {
    log_info "Setting up Vault PKI secrets engine for nginx..."

    # Enable PKI secrets engine if not already enabled
    if ! vault secrets list | grep -q "pki/"; then
        log_info "Enabling PKI secrets engine..."
        vault secrets enable pki
        vault secrets tune -max-lease-ttl=8760h pki
        log_success "PKI secrets engine enabled"
    else
        log_info "PKI secrets engine already enabled"
    fi

    # Configure PKI root CA if not exists
    if ! vault read pki/cert/ca >/dev/null 2>&1; then
        log_info "Configuring PKI root CA..."
        vault write pki/root/generate/internal \
            common_name="Pure Bliss Development CA" \
            ttl=8760h \
            organization="Pure Bliss Development" \
            country="US" \
            locality="Development" \
            province="Dev"
        log_success "PKI root CA configured"
    else
        log_info "PKI root CA already exists"
    fi

    # Configure PKI URLs
    vault write pki/config/urls \
        issuing_certificates="${VAULT_ADDR}/v1/pki/ca" \
        crl_distribution_points="${VAULT_ADDR}/v1/pki/crl"

    # Create role for nginx certificates
    vault write pki/roles/nginx-certs \
        allowed_domains="dev.purebliss.app,purebliss.app,localhost" \
        allow_subdomains=true \
        allow_localhost=true \
        allow_ip_sans=true \
        max_ttl=720h \
        ttl=720h

    log_success "Vault PKI configured for nginx"
}

setup_nginx_secrets() {
    log_info "Setting up nginx secrets in Vault KV store..."

    # Enable KV v2 secrets engine if not already enabled
    if ! vault secrets list | grep -q "secret/"; then
        log_info "Enabling KV v2 secrets engine..."
        vault secrets enable -version=2 kv
        log_success "KV v2 secrets engine enabled"
    else
        log_info "KV v2 secrets engine already enabled"
    fi

    # Store nginx configuration secrets
    vault kv put secret/nginx/config \
        server_name="dev.purebliss.app" \
        worker_processes="auto" \
        worker_connections="2048" \
        keepalive_timeout="15" \
        client_max_body_size="100M" \
        ssl_protocols="TLSv1.2 TLSv1.3" \
        ssl_ciphers="ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384" \
        ssl_prefer_server_ciphers="off" \
        hsts_max_age="31536000"

    # Store nginx upstream configuration
    vault kv put secret/nginx/upstreams \
        code_server_host="code-server" \
        code_server_port="8080" \
        keycloak_host="keycloak" \
        keycloak_port="8080" \
        plane_host="plane-web" \
        plane_port="3000" \
        grafana_host="grafana" \
        grafana_port="3000" \
        prometheus_host="prometheus" \
        prometheus_port="9090" \
        vault_host="vault" \
        vault_port="8200"

    log_success "Nginx secrets stored in Vault"
}

cleanup_existing_containers() {
    log_info "Cleaning up existing nginx containers..."

    # Stop and remove existing containers
    if docker ps -a --format "table {{.Names}}" | grep -q "^nginx$"; then
        log_info "Stopping existing nginx container..."
        docker stop nginx >/dev/null 2>&1 || true
        docker rm nginx >/dev/null 2>&1 || true
        log_success "Existing nginx container removed"
    fi

    # Clean up orphaned containers
    docker container prune -f >/dev/null 2>&1 || true

    log_success "Container cleanup completed"
}

start_nginx_service() {
    log_info "Starting nginx service with Vault integration..."

    # Change to service directory
    cd "${SCRIPT_DIR}"

    # Create necessary directories
    mkdir -p logs certs config

    # Start the service using Docker Compose
    docker-compose -f "${COMPOSE_FILE}" up -d

    log_success "Nginx service started"
}

wait_for_service() {
    log_info "Waiting for nginx service to be ready..."
    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "nginx" | grep -q "Up"; then
            log_success "Nginx container is running"
            break
        fi

        log_info "Attempt ${attempt}/${max_attempts}: Nginx not ready, waiting 2 seconds..."
        sleep 2
        ((attempt++))

        if [[ $attempt -gt $max_attempts ]]; then
            log_error "Nginx service failed to start within timeout"
            docker logs nginx 2>&1 | tail -20
            exit 1
        fi
    done

    # Wait for HTTP response
    attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if curl -skf http://localhost:80 >/dev/null 2>&1; then
            log_success "Nginx HTTP endpoint is responding"
            break
        fi

        log_info "Attempt ${attempt}/${max_attempts}: Nginx HTTP not responding, waiting 2 seconds..."
        sleep 2
        ((attempt++))

        if [[ $attempt -gt $max_attempts ]]; then
            log_warning "Nginx HTTP endpoint not responding (may be normal if SSL-only)"
        fi
    done

    # Wait for HTTPS response
    attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if curl -skfk https://localhost:443 >/dev/null 2>&1; then
            log_success "Nginx HTTPS endpoint is responding"
            break
        fi

        log_info "Attempt ${attempt}/${max_attempts}: Nginx HTTPS not responding, waiting 2 seconds..."
        sleep 2
        ((attempt++))

        if [[ $attempt -gt $max_attempts ]]; then
            log_warning "Nginx HTTPS endpoint not responding"
        fi
    done
}

validate_service() {
    log_info "Validating nginx service..."

    # Check container status
    if ! docker ps --format "table {{.Names}}\t{{.Status}}" | grep "nginx" | grep -q "Up"; then
        log_error "Nginx container is not running"
        return 1
    fi

    # Check Vault integration
    if docker exec nginx test -f /vault/secrets/cert.pem 2>/dev/null; then
        log_success "Vault-managed certificate found"
    else
        log_warning "Vault-managed certificate not found (may be using existing certs)"
    fi

    # Check nginx configuration
    if docker exec nginx nginx -t >/dev/null 2>&1; then
        log_success "Nginx configuration is valid"
    else
        log_error "Nginx configuration is invalid"
        docker exec nginx nginx -t
        return 1
    fi

    # Check basic connectivity
    local http_status=$(curl -sk -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "000")
    local https_status=$(curl -skk -o /dev/null -w "%{http_code}" https://localhost:443 2>/dev/null || echo "000")

    if [[ $http_status -eq 200 ]] || [[ $http_status -eq 301 ]] || [[ $http_status -eq 302 ]]; then
        log_success "HTTP endpoint responding (status: ${http_status})"
    else
        log_warning "HTTP endpoint not responding (status: ${http_status})"
    fi

    if [[ $https_status -eq 200 ]] || [[ $https_status -eq 301 ]] || [[ $https_status -eq 302 ]]; then
        log_success "HTTPS endpoint responding (status: ${https_status})"
    else
        log_warning "HTTPS endpoint not responding (status: ${https_status})"
    fi

    log_success "Nginx service validation completed"
}

display_service_info() {
    log_info "Nginx service information:"

    echo -e "\n${BLUE}🔧 Service Details:${NC}"
    echo "  📁 Service Directory: ${SCRIPT_DIR}"
    echo "  📄 Compose File: ${COMPOSE_FILE}"
    echo "  🔐 Vault Address: ${VAULT_ADDR}"

    echo -e "\n${BLUE}🌐 Endpoints:${NC}"
    echo "  🌍 HTTP: http://localhost:80"
    echo "  🔒 HTTPS: https://localhost:443"
    echo "  🔒 External: https://dev.purebliss.app"

    echo -e "\n${BLUE}🐋 Container Status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep nginx || echo "  No nginx containers found"

    echo -e "\n${BLUE}📊 Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep nginx || echo "  No nginx containers found"

    echo -e "\n${BLUE}🔍 Quick Commands:${NC}"
    echo "  📋 View logs: docker logs nginx"
    echo "  🔧 Service status: docker ps | grep nginx"
    echo "  ✋ Stop service: docker stop nginx"
    echo "  🔄 Restart service: docker restart nginx"
    echo "  🧪 Test config: docker exec nginx nginx -t"
    echo "  📊 Full validation: ${SCRIPT_DIR}/validate-nginx-vault-integration.sh"
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Fresh start script for nginx service with Vault integration.

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    --skip-cleanup  Skip container cleanup step
    --skip-vault    Skip Vault setup (use existing configuration)

DESCRIPTION:
    This script provides a complete fresh start for the nginx service with:
    - Vault PKI certificate management
    - Dynamic configuration from Vault KV store
    - SSL/TLS termination and reverse proxy functionality
    - Health monitoring and validation

EXAMPLES:
    $0                    # Standard fresh start
    $0 --verbose          # Verbose output
    $0 --skip-cleanup     # Keep existing containers

EOF
}

###############################################################################
# Main Execution
###############################################################################

main() {
    local skip_cleanup=false
    local skip_vault=false
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
            --skip-cleanup)
                skip_cleanup=true
                shift
                ;;
            --skip-vault)
                skip_vault=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    log_info "Starting nginx fresh start process..."
    log_info "Script directory: ${SCRIPT_DIR}"
    log_info "Service: ${SERVICE_NAME}"
    log_info "Compose file: ${COMPOSE_FILE}"

    # Execute setup steps
    check_prerequisites

    if [[ $skip_vault == false ]]; then
        wait_for_vault
        setup_vault_authentication
        setup_vault_pki
        setup_nginx_secrets
    else
        log_info "Skipping Vault setup as requested"
    fi

    if [[ $skip_cleanup == false ]]; then
        cleanup_existing_containers
    else
        log_info "Skipping container cleanup as requested"
    fi

    start_nginx_service
    wait_for_service
    validate_service
    display_service_info

    echo -e "\n${GREEN}🎉 SUCCESS: Nginx service fresh start completed!${NC}"
    echo -e "${BLUE}📖 Run validation: ${SCRIPT_DIR}/validate-nginx-vault-integration.sh${NC}"

    log_success "Nginx fresh start process completed successfully"
}

# Trap for cleanup on script exit
trap 'echo -e "\n${YELLOW}⚠️  Script interrupted${NC}"' INT TERM

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
