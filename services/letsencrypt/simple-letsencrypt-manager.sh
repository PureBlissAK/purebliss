#!/bin/bash
set -euo pipefail

# Simple LetsEncrypt Certificate Manager with Vault PKI Integration
# This script manages SSL certificates using LetsEncrypt with Vault PKI backend

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: common-functions-library.sh not found, using fallback functions"
}
source "$SCRIPT_DIR/utilities/retry-utils.sh" 2>/dev/null || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: retry-utils.sh not found, using fallback retry"
}
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh" 2>/dev/null || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: script-communication-bridge.sh not found"
}

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="LetsEncrypt Certificate Manager with Vault PKI Integration"

# Service-specific directories
SERVICE_DIR="/opt/dev-purebliss/services/letsencrypt"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Vault configuration
VAULT_ADDR="https://127.0.0.1:8200"
ROLE_ID_FILE="$SERVICE_DIR/role_id"
SECRET_ID_FILE="$SERVICE_DIR/secret_id"

# Centralized logging function (MANDATORY)
log_message() {
    local level="$1"
    local message="$2"
    local log_entry="$(date '+%Y-%m-%d %H:%M:%S') - LETSENCRYPT_${level}: ${message}"

    # Use centralized logging if available, fallback to direct logging
    if declare -f log_info >/dev/null 2>&1; then
        case "$level" in
            "INFO") log_info "$message" ;;
            "ERROR") log_error "$message" ;;
            "SUCCESS") log_success "$message" ;;
            *) echo "$log_entry" | tee -a "$LOG_FILE" ;;
        esac
    else
        echo "$log_entry" | tee -a "$LOG_FILE"
    fi
}

# Enhanced retry function with centralized fallback
retry_with_fallback() {
    local max_attempts="${1:-3}"
    local delay="${2:-5}"
    shift 2

    if declare -f retry_with_backoff >/dev/null 2>&1; then
        retry_with_backoff "$max_attempts" "$delay" "$@"
    else
        # Fallback retry implementation
        local attempt=1
        while [[ $attempt -le $max_attempts ]]; do
            if "$@"; then
                return 0
            fi
            log_message "WARN" "Attempt $attempt failed, retrying in ${delay}s..."
            sleep "$delay"
            ((attempt++))
        done
        return 1
    fi
}

# Enhanced function to get clean Vault token with centralized validation
get_vault_token() {
    if [[ ! -f "$ROLE_ID_FILE" ]] || [[ ! -f "$SECRET_ID_FILE" ]]; then
        log_message "ERROR" "AppRole credential files not found at $ROLE_ID_FILE or $SECRET_ID_FILE"
        return 1
    fi

    local role_id=$(cat "$ROLE_ID_FILE")
    local secret_id=$(cat "$SECRET_ID_FILE")

    # Validate credentials are not empty
    if [[ -z "$role_id" ]] || [[ -z "$secret_id" ]]; then
        log_message "ERROR" "AppRole credentials are empty"
        return 1
    fi

    # Use centralized vault authentication if available
    if declare -f vault_auth >/dev/null 2>&1; then
        vault_auth "$role_id" "$secret_id"
    else
        # Fallback implementation with proper error handling
        local auth_response
        auth_response=$(docker exec vault-dev-letsencrypt env VAULT_ADDR="$VAULT_ADDR" \
            vault write -format=json auth/approle/login \
            role_id="$role_id" \
            secret_id="$secret_id" 2>/dev/null)

        if [[ $? -eq 0 ]] && [[ -n "$auth_response" ]]; then
            echo "$auth_response" | jq -r '.auth.client_token' 2>/dev/null
        else
            log_message "ERROR" "Vault authentication failed"
            return 1
        fi
    fi
}

# Enhanced function to issue certificate via Vault PKI with health validation
issue_certificate() {
    local domain="$1"

    log_message "INFO" "Starting certificate issuance process for domain: $domain"

    # Create certificates directory if it doesn't exist
    mkdir -p "$SERVICE_DIR/certs"

    # Health validation before certificate issuance - use correct container name
    if declare -f health_check_service >/dev/null 2>&1; then
        if ! docker ps --format "table {{.Names}}" | grep -q "vault-dev-letsencrypt"; then
            log_message "ERROR" "Vault container 'vault-dev-letsencrypt' is not running"
            return 1
        fi
        log_message "INFO" "Vault container health check passed"
    fi

    local vault_token=$(get_vault_token)
    if [[ -z "$vault_token" ]] || [[ "$vault_token" == "null" ]]; then
        log_message "ERROR" "Failed to obtain Vault token"
        return 1
    fi

    log_message "SUCCESS" "Vault authentication successful"

    # Direct vault certificate issuance (bypass centralized function for now)
    local cert_response
    cert_response=$(docker exec vault-dev-letsencrypt env VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$vault_token" \
        vault write -format=json pki/issue/letsencrypt-role \
        common_name="$domain" \
        ttl="720h" 2>&1)

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_message "ERROR" "Vault PKI command failed with exit code: $exit_code"
    fi

    # Save debug response for troubleshooting
    echo "$cert_response" > "$SERVICE_DIR/certs/${domain}.debug.json"

    # Check if response contains certificate data
    if echo "$cert_response" | jq -e '.data.certificate' >/dev/null 2>&1; then
        log_message "SUCCESS" "Certificate issued successfully for $domain"

        # Extract certificate components
        local certificate=$(echo "$cert_response" | jq -r '.data.certificate')
        local private_key=$(echo "$cert_response" | jq -r '.data.private_key')
        local ca_chain=$(echo "$cert_response" | jq -r '.data.ca_chain[0]' 2>/dev/null || echo "")

        # Save certificate files with secure permissions
        echo "$certificate" > "$SERVICE_DIR/certs/${domain}.crt"
        echo "$private_key" > "$SERVICE_DIR/certs/${domain}.key"
        if [[ -n "$ca_chain" ]]; then
            echo "$ca_chain" > "$SERVICE_DIR/certs/${domain}_ca.crt"
        fi

        chmod 600 "$SERVICE_DIR/certs/${domain}.key"
        chmod 644 "$SERVICE_DIR/certs/${domain}.crt"

        log_message "SUCCESS" "Certificate files saved for $domain"

        # Update documentation if centralized functions available
        if declare -f update_automation_guide >/dev/null 2>&1; then
            update_automation_guide "letsencrypt" "Certificate issued for $domain"
        fi

        return 0
    else
        log_message "ERROR" "Certificate issuance failed for $domain. Check $SERVICE_DIR/certs/${domain}.debug.json"
        return 1
    fi
}

# Enhanced function to check certificate with detailed validation
check_certificate() {
    local domain="$1"

    log_message "INFO" "Checking certificate for domain: $domain"

    if [[ -f "$SERVICE_DIR/certs/${domain}.crt" ]]; then
        echo "Certificate details for $domain:"
        echo "----------------------------------------"

        # Show certificate information
        openssl x509 -in "$SERVICE_DIR/certs/${domain}.crt" -text -noout | head -20

        # Check certificate validity
        local expiry_date=$(openssl x509 -in "$SERVICE_DIR/certs/${domain}.crt" -noout -enddate | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

        if [[ $days_until_expiry -gt 30 ]]; then
            log_message "SUCCESS" "Certificate valid for $days_until_expiry days"
        elif [[ $days_until_expiry -gt 7 ]]; then
            log_message "WARN" "Certificate expires in $days_until_expiry days - consider renewal"
        else
            log_message "ERROR" "Certificate expires in $days_until_expiry days - immediate renewal required"
        fi

        return 0
    else
        log_message "ERROR" "Certificate file not found for $domain at $SERVICE_DIR/certs/${domain}.crt"
        return 1
    fi
}

# Enhanced health validation function
validate_letsencrypt_health() {
    log_message "INFO" "Starting LetsEncrypt service health validation"

    # Check Vault connectivity
    if ! docker exec vault-dev-letsencrypt env VAULT_ADDR="$VAULT_ADDR" vault status >/dev/null 2>&1; then
        log_message "ERROR" "Vault connectivity failed"
        return 1
    fi

    # Check AppRole credentials
    if [[ ! -f "$ROLE_ID_FILE" ]] || [[ ! -f "$SECRET_ID_FILE" ]]; then
        log_message "ERROR" "AppRole credential files missing"
        return 1
    fi

    # Test authentication
    local test_token=$(get_vault_token)
    if [[ -z "$test_token" ]] || [[ "$test_token" == "null" ]]; then
        log_message "ERROR" "Vault authentication test failed"
        return 1
    fi

    log_message "SUCCESS" "LetsEncrypt service health validation passed"
    return 0
}

# Enhanced main function with centralized integration
main() {
    local action="${1:-help}"
    local domain="${2:-dev.purebliss.app}"

    log_message "START" "LetsEncrypt manager starting: $action for $domain"

    # Create certificates directory if it doesn't exist
    mkdir -p "$SERVICE_DIR/certs"

    case "$action" in
        "issue")
            log_message "START" "Certificate issuance process for $domain"
            if issue_certificate "$domain"; then
                log_message "SUCCESS" "Certificate issuance completed for $domain"

                # Run health validation after issuance
                if declare -f health_check_service >/dev/null 2>&1; then
                    health_check_service "letsencrypt"
                fi

                # Notify upstream services if script communication available
                if declare -f notify_script_completion >/dev/null 2>&1; then
                    notify_script_completion "$SCRIPT_NAME" "nginx" "certificate_issued_$domain"
                fi
            else
                log_message "ERROR" "Certificate issuance failed for $domain"
                return 1
            fi
            ;;
        "check")
            log_message "START" "Certificate check for $domain"
            check_certificate "$domain"
            ;;
        "health")
            validate_letsencrypt_health
            ;;
        "help"|*)
            echo "Enhanced LetsEncrypt Certificate Manager v$SCRIPT_VERSION"
            echo "Usage: $0 {issue|check|health} [domain]"
            echo ""
            echo "Commands:"
            echo "  issue [domain]  - Issue new certificate for domain (default: dev.purebliss.app)"
            echo "  check [domain]  - Check certificate details and validity"
            echo "  health          - Validate LetsEncrypt service health"
            echo "  help            - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 issue dev.purebliss.app"
            echo "  $0 check dev.purebliss.app"
            echo "  $0 health"
            ;;
    esac

    log_message "COMPLETE" "LetsEncrypt manager operation completed: $action"
}

# Execute main function with all arguments and comprehensive error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@" 2>&1 | tee -a "$LOG_FILE"
    exit_code=$?

    # Log script completion with status
    if [[ $exit_code -eq 0 ]]; then
        log_message "SUCCESS" "Script execution completed successfully"
    else
        log_message "ERROR" "Script execution failed with exit code: $exit_code"
    fi

    exit $exit_code
fi
