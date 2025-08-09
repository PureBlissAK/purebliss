#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_ENTRYPOINT_ENHANCED_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-entrypoint-enhanced.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi
if [[ -f "$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "$SCRIPT_DIR/utilities/retry-utils.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
vault_entrypoint_enhanced_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_entrypoint_enhanced_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_entrypoint_enhanced_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

set -euo pipefail

# PostgreSQL Vault Integration Entrypoint - Enhanced Version
# Uses pre-installed Vault CLI to avoid internet download issues
# Pure Bliss Elite Standards: Security, Zero-Trust, Dynamic Secrets

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_info() {
    echo "[$(date)] POSTGRES_VAULT: $1" | tee -a "$LOG_FILE"
}

function log_error() {
    echo "[$(date)] POSTGRES_VAULT: ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ POSTGRES: $1" >&2
}

function log_success() {
    echo "[$(date)] POSTGRES_VAULT: SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ POSTGRES: $1"
}

function log_warning() {
    echo "[$(date)] POSTGRES_VAULT: WARNING: $1" | tee -a "$LOG_FILE"
    echo "⚠️  POSTGRES: $1"
}

# Enhanced Vault readiness check with graceful degradation
function wait_for_vault() {
    # Check if Vault integration is disabled
    if [[ "${VAULT_INTEGRATION:-enabled}" == "disabled" ]]; then
        log_info "Vault integration disabled, proceeding with standard PostgreSQL startup"
        return 1
    fi

    local max_attempts=10  # Reduced from 60 for faster fallback
    local attempt=1

    log_info "Waiting for Vault to be ready and unsealed..."

    # Install curl if not available
    if ! command -v curl >/dev/null 2>&1; then
        log_info "Installing curl for Vault connectivity checks..."
        apt-get update >/dev/null 2>&1 && apt-get install -y curl >/dev/null 2>&1
    fi

    while [[ $attempt -le $max_attempts ]]; do
        local vault_accessible=false

        # Try hostname first (preferred)
        if curl -s -k "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
            vault_accessible=true
            log_info "Vault accessible via hostname: $VAULT_ADDR"
        fi

        if [[ "$vault_accessible" == "true" ]]; then
            local vault_status
            vault_status=$(curl -s -k "$VAULT_ADDR/v1/sys/health" 2>/dev/null)

            # Check if Vault is unsealed
            if echo "$vault_status" | grep -q '"sealed":false'; then
                log_success "Vault is ready and unsealed"
                return 0
            else
                log_info "Vault is sealed, waiting for auto-unseal (attempt $attempt/$max_attempts)"
            fi
        else
            log_info "Waiting for Vault endpoint to be accessible (attempt $attempt/$max_attempts)"
        fi

        sleep 3
        ((attempt++))
    done

    log_warning "Vault not ready after $max_attempts attempts, falling back to standard PostgreSQL"
    return 1
}

# Install Vault CLI from container or use host mount
function install_vault_cli() {
    if command -v vault >/dev/null 2>&1; then
        log_success "Vault CLI already available"
        return 0
    fi

    log_info "Installing Vault CLI..."

    # Try to copy from host mount first (preferred approach)
    if [[ -f "/vault/bin/vault" ]]; then
        cp /vault/bin/vault /usr/local/bin/vault
        chmod +x /usr/local/bin/vault
        log_success "Vault CLI installed from host mount"
        return 0
    fi

    # Install dependencies
    apt-get update >/dev/null 2>&1 && apt-get install -y wget unzip >/dev/null 2>&1

    # Use specific version and validate download
    cd /tmp
    local vault_version="1.17.3"
    local vault_url="https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"
    local max_retries=3
    local retry=1

    while [[ $retry -le $max_retries ]]; do
        log_info "Downloading Vault CLI (attempt $retry/$max_retries)..."

        if wget -q --timeout=30 --tries=3 -O vault.zip "$vault_url"; then
            # Validate the download
            if [[ -f vault.zip ]] && [[ $(stat -c%s vault.zip) -gt 1000 ]]; then
                if unzip -q vault.zip && [[ -f vault ]]; then
                    mv vault /usr/local/bin/vault
                    chmod +x /usr/local/bin/vault
                    rm -f vault.zip
                    cd /
                    log_success "Vault CLI installed successfully"
                    return 0
                fi
            fi
        fi

        log_warning "Download attempt $retry failed, retrying..."
        rm -f vault.zip vault
        ((retry++))
        sleep 5
    done

    log_error "Failed to download Vault CLI after $max_retries attempts"
    return 1
}

# Fetch secrets from Vault
function fetch_postgres_secrets() {
    log_info "Fetching PostgreSQL secrets from Vault..."

    # Check for Vault token
    local vault_token=""

    if [[ -f "/vault/secrets/vault_token" ]]; then
        vault_token=$(cat /vault/secrets/vault_token)
        log_info "Using Vault token from secrets mount"
    elif [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
        vault_token=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
        log_info "Using Vault token from alternative location"
    else
        log_error "No Vault token available"
        return 1
    fi

    # Set Vault environment
    export VAULT_SKIP_VERIFY=1
    export VAULT_TOKEN="$vault_token"

    # Install Vault CLI
    if ! install_vault_cli; then
        log_error "Failed to install Vault CLI"
        return 1
    fi

    # Create secure secrets directory
    mkdir -p /run/secrets
    chmod 700 /run/secrets

    # Test Vault connectivity
    if ! vault token lookup >/dev/null 2>&1; then
        log_error "Vault token authentication failed"
        return 1
    fi

    log_success "Vault authentication successful"

    # Fetch or generate PostgreSQL bootstrap password
    local bootstrap_password
    if bootstrap_password=$(vault kv get -field=bootstrap_password secret/postgres 2>/dev/null); then
        echo "$bootstrap_password" > /run/secrets/postgres_bootstrap_password
        chmod 600 /run/secrets/postgres_bootstrap_password
        log_success "PostgreSQL bootstrap password fetched from Vault"
    else
        # Generate and store a new secure password
        log_info "Bootstrap password not found in Vault, generating secure password..."
        bootstrap_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

        # Store in Vault
        vault kv put secret/postgres \
            bootstrap_password="$bootstrap_password" \
            vault_admin_password="$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)" \
            description="PostgreSQL bootstrap credentials - auto-generated $(date)" \
            service="purebliss-postgres" \
            environment="development" >/dev/null 2>&1

        echo "$bootstrap_password" > /run/secrets/postgres_bootstrap_password
        chmod 600 /run/secrets/postgres_bootstrap_password
        log_success "Generated and stored new PostgreSQL bootstrap password in Vault"
    fi

    return 0
}

# Main entrypoint logic with graceful degradation
function main() {
    log_info "Starting PostgreSQL with Vault integration (Enhanced Version)..."

    # Step 1: Wait for Vault to be ready
    if wait_for_vault; then
        log_info "Vault available - using dynamic credentials"

        # Step 2: Fetch secrets from Vault
        if fetch_postgres_secrets; then
            # Step 3: Set environment variable for PostgreSQL
            export POSTGRES_PASSWORD_FILE=/run/secrets/postgres_bootstrap_password
            log_info "Starting PostgreSQL with Vault-managed credentials..."
        else
            log_warning "Failed to fetch secrets from Vault - falling back to environment credentials"
        fi
    else
        log_info "Vault not available - using environment credentials for PostgreSQL startup"
    fi

    # Step 4: Start PostgreSQL (with or without Vault credentials)
    log_success "PostgreSQL entrypoint configuration complete"

    # Check if we need to switch to postgres user
    if [[ "$(id -u)" = "0" ]]; then
        log_info "Running as root, delegating to postgres user"
        # Call the original docker-entrypoint.sh as postgres user
        exec gosu postgres docker-entrypoint.sh "$@"
    else
        # Execute the original PostgreSQL entrypoint
        exec docker-entrypoint.sh "$@"
    fi
}

# Signal handling for graceful shutdown
function cleanup() {
    log_info "Received termination signal, cleaning up..."
    # Cleanup is handled by PostgreSQL itself
}

trap cleanup TERM INT

# Execute main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
