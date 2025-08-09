#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT_HTTP_INIT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="vault-http-init.sh"
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
vault_http_init_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
vault_http_init_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
vault_http_init_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

set -euo pipefail

# Vault HTTP Development Initialization
# Simple initialization for HTTP-enabled Vault in development

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
VAULT_ADDR="http://127.0.0.1:18200"  # Using external port mapping
VAULT_OUTPUT_FILE="/opt/my-secure-ha-stack/vault-init-output.txt"
VAULT_UNSEAL_KEYS_ENV="/opt/my-secure-ha-stack/vault-unseal-keys.env"

echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Starting Vault HTTP initialization" | tee -a "$LOG_FILE"

# Function to check if Vault is accessible
check_vault_accessibility() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Checking Vault accessibility at $VAULT_ADDR" | tee -a "$LOG_FILE"

    for i in {1..10}; do
        if curl -f "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault is accessible" | tee -a "$LOG_FILE"
            return 0
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Attempt $i/10 - Vault not accessible yet, waiting..." | tee -a "$LOG_FILE"
        sleep 2
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Vault is not accessible after 10 attempts" | tee -a "$LOG_FILE"
    return 1
}

# Function to check if Vault is initialized
is_vault_initialized() {
    local response
    response=$(curl -s "$VAULT_ADDR/v1/sys/health" 2>/dev/null || echo '{"initialized":false}')
    if echo "$response" | grep -q '"initialized":true'; then
        return 0
    else
        return 1
    fi
}

# Function to initialize Vault
initialize_vault() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Initializing Vault with 5 key shares and threshold of 3" | tee -a "$LOG_FILE"

    # Initialize Vault
    local init_response
    init_response=$(curl -s -X POST \
        -d '{"secret_shares": 5, "secret_threshold": 3}' \
        "$VAULT_ADDR/v1/sys/init")

    if [[ $? -ne 0 ]] || [[ -z "$init_response" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Failed to initialize Vault" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Save full initialization response
    echo "$init_response" > "$VAULT_OUTPUT_FILE"
    chmod 600 "$VAULT_OUTPUT_FILE"

    # Extract unseal keys and root token
    local key1 key2 key3 key4 key5 root_token
    key1=$(echo "$init_response" | jq -r '.keys[0]')
    key2=$(echo "$init_response" | jq -r '.keys[1]')
    key3=$(echo "$init_response" | jq -r '.keys[2]')
    key4=$(echo "$init_response" | jq -r '.keys[3]')
    key5=$(echo "$init_response" | jq -r '.keys[4]')
    root_token=$(echo "$init_response" | jq -r '.root_token')

    # Create unseal keys environment file
    cat > "$VAULT_UNSEAL_KEYS_ENV" << EOF
# Vault Unseal Keys - Generated $(date)
export VAULT_UNSEAL_KEY_1="$key1"
export VAULT_UNSEAL_KEY_2="$key2"
export VAULT_UNSEAL_KEY_3="$key3"
export VAULT_UNSEAL_KEY_4="$key4"
export VAULT_UNSEAL_KEY_5="$key5"
export VAULT_ROOT_TOKEN="$root_token"
export VAULT_ADDR="$VAULT_ADDR"
EOF

    chmod 600 "$VAULT_UNSEAL_KEYS_ENV"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault initialized successfully" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🔐 Keys saved to $VAULT_UNSEAL_KEYS_ENV" | tee -a "$LOG_FILE"

    return 0
}

# Function to unseal Vault
unseal_vault() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Unsealing Vault with 3 keys (threshold)" | tee -a "$LOG_FILE"

    # Source the unseal keys
    source "$VAULT_UNSEAL_KEYS_ENV"

    # Unseal with first 3 keys
    for i in 1 2 3; do
        local key_var="VAULT_UNSEAL_KEY_$i"
        local key_value="${!key_var}"

        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Using unseal key $i/3" | tee -a "$LOG_FILE"

        local unseal_response
        unseal_response=$(curl -s -X POST \
            -d "{\"key\": \"$key_value\"}" \
            "$VAULT_ADDR/v1/sys/unseal")

        # Check current seal status
        local sealed
        sealed=$(echo "$unseal_response" | jq -r '.sealed')
        if [[ "$sealed" == "false" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault unsealed after $i keys" | tee -a "$LOG_FILE"
            return 0
        fi
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Failed to unseal Vault after 3 keys" | tee -a "$LOG_FILE"
    return 1
}

# Function to verify Vault is ready
verify_vault_ready() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Verifying Vault is ready for use" | tee -a "$LOG_FILE"

    # Source the root token
    source "$VAULT_UNSEAL_KEYS_ENV"

    # Test basic Vault operation
    local test_response
    test_response=$(curl -s -H "X-Vault-Token: $VAULT_ROOT_TOKEN" \
        "$VAULT_ADDR/v1/sys/health")

    if echo "$test_response" | grep -q '"sealed":false'; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault is ready for use" | tee -a "$LOG_FILE"
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Vault verification failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main function
main() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: Starting Vault HTTP initialization process" | tee -a "$LOG_FILE"

    # Check if Vault is accessible
    if ! check_vault_accessibility; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ Cannot access Vault. Ensure container is running." | tee -a "$LOG_FILE"
        exit 1
    fi

    # Check if already initialized
    if is_vault_initialized; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ℹ️ Vault is already initialized" | tee -a "$LOG_FILE"

        # Check if we need to unseal
        local health_response
        health_response=$(curl -s "$VAULT_ADDR/v1/sys/health")
        if echo "$health_response" | grep -q '"sealed":true'; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🔓 Vault is sealed, attempting unseal" | tee -a "$LOG_FILE"
            if [[ -f "$VAULT_UNSEAL_KEYS_ENV" ]]; then
                unseal_vault
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ❌ No unseal keys found. Manual intervention required." | tee -a "$LOG_FILE"
                exit 1
            fi
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: ✅ Vault is already unsealed" | tee -a "$LOG_FILE"
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🚀 Initializing Vault for first time" | tee -a "$LOG_FILE"
        initialize_vault
        unseal_vault
    fi

    # Verify Vault is ready
    verify_vault_ready

    # Display summary
    echo ""
    echo "🎉 Vault initialization complete!"
    echo "📋 Summary:"
    echo "   - Vault Address: $VAULT_ADDR"
    echo "   - Status: Initialized and unsealed"
    echo "   - Keys saved to: $VAULT_UNSEAL_KEYS_ENV"
    echo "   - Full init output: $VAULT_OUTPUT_FILE"
    echo ""
    echo "💡 To use Vault:"
    echo "   source $VAULT_UNSEAL_KEYS_ENV"
    echo "   vault status"
    echo ""

    echo "$(date '+%Y-%m-%d %H:%M:%S') - VAULT_INIT: 🎉 Vault HTTP initialization completed successfully" | tee -a "$LOG_FILE"
}

# Run main function
main "$@"
