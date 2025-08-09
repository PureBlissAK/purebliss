#!/bin/bash
set -euo pipefail

# LetsEncrypt Certificate Management with Vault PKI Integration
# This script manages SSL certificates using LetsEncrypt with Vault PKI backend

SCRIPT_DIR="/opt/dev-purebliss/services/letsencrypt"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Vault configuration
VAULT_ADDR="http://vault:8200"
ROLE_ID_FILE="$SCRIPT_DIR/role_id"
SECRET_ID_FILE="$SCRIPT_DIR/secret_id"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - LETSENCRYPT_${level}: ${message}" | tee -a "$LOG_FILE"
}

# Function to authenticate with Vault using AppRole
vault_auth() {
    log_message "INFO" "Authenticating with Vault using AppRole"

    if [[ ! -f "$ROLE_ID_FILE" ]] || [[ ! -f "$SECRET_ID_FILE" ]]; then
        log_message "ERROR" "AppRole credential files not found"
        return 1
    fi

    local role_id=$(cat "$ROLE_ID_FILE")
    local secret_id=$(cat "$SECRET_ID_FILE")

    # Authenticate and get token
    local auth_response=$(env VAULT_ADDR="$VAULT_ADDR" \
        vault write -format=json auth/approle/login \
        role_id="$role_id" \
        secret_id="$secret_id" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        local token=$(echo "$auth_response" | jq -r '.auth.client_token' | tr -d '\n' | tr -d '\r' | xargs)
        echo -n "$token"
        log_message "SUCCESS" "Vault authentication successful"
        return 0
    else
        log_message "ERROR" "Vault authentication failed"
        return 1
    fi
}

# Function to issue certificate via Vault PKI
issue_certificate() {
    local domain="$1"
    local vault_token="$2"

    log_message "INFO" "Issuing certificate for domain: $domain"

    local cert_response=$(env VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$vault_token" \
        vault write -format=json pki/issue/letsencrypt-role \
        common_name="$domain" \
        ttl="720h" 2>&1)

    echo "$cert_response" > "$SCRIPT_DIR/certs/${domain}.debug.json"
    log_message "DEBUG" "Raw Vault PKI response for $domain written to $SCRIPT_DIR/certs/${domain}.debug.json"

    if echo "$cert_response" | jq -e '.data.certificate' >/dev/null 2>&1; then
        log_message "SUCCESS" "Certificate issued successfully for $domain"

        # Extract certificate components
        local certificate=$(echo "$cert_response" | jq -r '.data.certificate')
        local private_key=$(echo "$cert_response" | jq -r '.data.private_key')
        local ca_chain=$(echo "$cert_response" | jq -r '.data.ca_chain[]' | tr '\n' ' ')

        # Save certificate files
        echo "$certificate" > "$SCRIPT_DIR/certs/${domain}.crt"
        echo "$private_key" > "$SCRIPT_DIR/certs/${domain}.key"
        echo "$ca_chain" > "$SCRIPT_DIR/certs/${domain}_ca.crt"

        chmod 600 "$SCRIPT_DIR/certs/${domain}.key"

        log_message "SUCCESS" "Certificate files saved for $domain"
        return 0
    else
        log_message "ERROR" "Certificate issuance failed for $domain. See $SCRIPT_DIR/certs/${domain}.debug.json for details."
        return 1
    fi
}

# Function to revoke certificate
revoke_certificate() {
    local domain="$1"
    local vault_token="$2"

    log_message "INFO" "Revoking certificate for domain: $domain"

    if [[ -f "$SCRIPT_DIR/certs/${domain}.crt" ]]; then
        local cert_serial=$(openssl x509 -in "$SCRIPT_DIR/certs/${domain}.crt" -noout -serial | cut -d= -f2)

        env VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$vault_token" \
            vault write pki/revoke serial_number="$cert_serial"

        if [[ $? -eq 0 ]]; then
            log_message "SUCCESS" "Certificate revoked successfully for $domain"
            rm -f "$SCRIPT_DIR/certs/${domain}".*
            return 0
        else
            log_message "ERROR" "Certificate revocation failed for $domain"
            return 1
        fi
    else
        log_message "ERROR" "Certificate file not found for $domain"
        return 1
    fi
}

# Function to list certificates
list_certificates() {
    local vault_token="$1"

    log_message "INFO" "Listing issued certificates"

    env VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$vault_token" \
        vault list pki/certs
}

# Function to check certificate expiry
check_expiry() {
    local domain="$1"

    if [[ -f "$SCRIPT_DIR/certs/${domain}.crt" ]]; then
        local expiry_date=$(openssl x509 -in "$SCRIPT_DIR/certs/${domain}.crt" -noout -enddate | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_remaining=$(( (expiry_epoch - current_epoch) / 86400 ))

        log_message "INFO" "Certificate for $domain expires in $days_remaining days ($expiry_date)"

        if [[ $days_remaining -lt 30 ]]; then
            log_message "WARNING" "Certificate for $domain expires in less than 30 days"
            return 1
        fi
        return 0
    else
        log_message "ERROR" "Certificate file not found for $domain"
        return 1
    fi
}

# Main function
main() {
    local action="${1:-help}"
    local domain="${2:-dev.purebliss.app}"

    # Create certificates directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR/certs"

    case "$action" in
        "issue")
            log_message "START" "Certificate issuance process for $domain"
            local token=$(vault_auth)
            if [[ $? -eq 0 ]]; then
                issue_certificate "$domain" "$token"
            fi
            ;;
        "revoke")
            log_message "START" "Certificate revocation process for $domain"
            local token=$(vault_auth)
            if [[ $? -eq 0 ]]; then
                revoke_certificate "$domain" "$token"
            fi
            ;;
        "list")
            log_message "START" "Certificate listing process"
            local token=$(vault_auth)
            if [[ $? -eq 0 ]]; then
                list_certificates "$token"
            fi
            ;;
        "check")
            log_message "START" "Certificate expiry check for $domain"
            check_expiry "$domain"
            ;;
        "renew")
            log_message "START" "Certificate renewal process for $domain"
            local token=$(vault_auth)
            if [[ $? -eq 0 ]]; then
                revoke_certificate "$domain" "$token" || true
                issue_certificate "$domain" "$token"
            fi
            ;;
        "help"|*)
            echo "Usage: $0 {issue|revoke|list|check|renew} [domain]"
            echo "  issue [domain]  - Issue new certificate for domain (default: dev.purebliss.app)"
            echo "  revoke [domain] - Revoke certificate for domain"
            echo "  list           - List all issued certificates"
            echo "  check [domain]  - Check certificate expiry"
            echo "  renew [domain]  - Renew certificate (revoke + issue)"
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
