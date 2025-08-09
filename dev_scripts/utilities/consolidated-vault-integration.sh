# Automated Vault Agent AppRole policy and provisioning for PKI integration
vault_agent_approle_setup() {
    local approle_name="vault-agent"
    local policy_name="vault-agent-pki"
    local policy_file="/opt/dev-purebliss/services/vault-agent/${policy_name}.hcl"
    local role_id_path="/opt/dev-purebliss/secrets/${approle_name}-role-id"
    local secret_id_path="/opt/dev-purebliss/secrets/${approle_name}-secret-id"
    local pki_path="pki-letsencrypt"  # Adjust if your PKI mount is different

    log_info "Creating Vault Agent PKI policy..."
    mkdir -p "/opt/dev-purebliss/services/vault-agent" || true
    cat > "$policy_file" <<EOF
path "auth/approle/login" {
  capabilities = ["create", "read"]
}
path "${pki_path}/*" {
  capabilities = ["read", "list", "create", "update"]
}
EOF

    vault policy write "$policy_name" "$policy_file"
    log_success "Vault Agent PKI policy written: $policy_name"

    log_info "Enabling AppRole auth method (if not already enabled)..."
    vault auth enable approle 2>/dev/null || true

    log_info "Creating AppRole for Vault Agent..."
    vault write auth/approle/role/$approle_name \
        token_policies="$policy_name" \
        secret_id_ttl="24h" \
        token_ttl="1h" \
        token_max_ttl="24h"

    log_info "Fetching AppRole credentials..."
    vault read -field=role_id auth/approle/role/$approle_name/role_id > "$role_id_path"
    vault write -f -field=secret_id auth/approle/role/$approle_name/secret_id > "$secret_id_path"
    chmod 600 "$role_id_path" "$secret_id_path"
    log_success "Vault Agent AppRole credentials written to $role_id_path and $secret_id_path"
}
#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0"
SCRIPT_PURPOSE="Consolidated functionality from multiple similar scripts"

# Consolidated Vault Integration Functions
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.1"
SCRIPT_PURPOSE="Consolidated Vault integration utilities (AppRole, DB roles, HTTPS enforcement)"

# Central development log
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Ensure HTTPS-only Vault addr
ensure_vault_https() {
    if [[ -z "${VAULT_ADDR:-}" ]]; then
        export VAULT_ADDR="https://127.0.0.1:8200"
    fi
}

# Vault health check over HTTPS (respects VAULT_ADDR and TLS policy)
vault_health_check() {
    local service_name="${1:-unknown}"
    ensure_vault_https
    local addr="${VAULT_ADDR:-https://127.0.0.1:8200}"

    # Enforce HTTPS-only
    if [[ "$addr" =~ ^http:// ]]; then
        log_error "Vault address must use HTTPS (got: $addr)"
        return 1
    fi

    # Build curl options: allow self-signed in dev only if VAULT_SKIP_VERIFY=1
    local curl_opts=("-sS" "-o" "/dev/null" "-w" "%{http_code}")
    if [[ "${VAULT_SKIP_VERIFY:-}" == "1" ]]; then
        curl_opts+=("-k")
    else
        # If a CA cert is present, use it
        local ca_candidates=(
            "/opt/my-secure-ha-stack/vault/certs/ca.pem"
            "/opt/my-secure-ha-stack/vault/certs/ca.crt"
            "/opt/my-secure-ha-stack/vault/certs/rootCA.pem"
        )
        for ca in "${ca_candidates[@]}"; do
            if [[ -f "$ca" ]]; then
                curl_opts+=("--cacert" "$ca")
                break
            fi
        done
    fi

    log_info "Checking Vault health for $service_name"
    local code
    code=$(curl "${curl_opts[@]}" "${addr%/}/v1/sys/health" 2>/dev/null || true)

    # Accept 200 (active) and 429 (standby) as reachable/healthy-enough for client operations
    if [[ "$code" == "200" || "$code" == "429" ]]; then
        log_success "Vault health check passed for $service_name (code: $code)"
        return 0
    fi

    log_error "Vault health check failed for $service_name (code: ${code:-N/A})"
    return 1
}

# Universal AppRole authentication
vault_approle_auth() {
    local service_name="$1"
    local role_id_path="/opt/dev-purebliss/secrets/${service_name}-role-id"
    local secret_id_path="/opt/dev-purebliss/secrets/${service_name}-secret-id"
    log_info "Authenticating $service_name with Vault AppRole"
    if [[ -f "$role_id_path" && -f "$secret_id_path" ]]; then
        local role_id; role_id=$(cat "$role_id_path")
        local secret_id; secret_id=$(cat "$secret_id_path")
        local token
        if token=$(vault write -field=token auth/approle/login role_id="$role_id" secret_id="$secret_id" 2>/dev/null) && [[ -n "$token" ]]; then
            export VAULT_TOKEN="$token"
            log_success "Vault authentication successful for $service_name"
            return 0
        fi
    fi
    log_error "Vault authentication failed for $service_name"
    return 1
}

# Automated Vault Agent AppRole policy and provisioning for PKI integration (retained)
vault_agent_approle_setup() {
    local approle_name="vault-agent"
    local policy_name="vault-agent-pki"
    local policy_file="/opt/dev-purebliss/services/vault-agent/${policy_name}.hcl"
    local role_id_path="/opt/dev-purebliss/secrets/${approle_name}-role-id"
    local secret_id_path="/opt/dev-purebliss/secrets/${approle_name}-secret-id"
    local pki_path="pki-letsencrypt"  # Adjust if your PKI mount is different

    log_info "Creating Vault Agent PKI policy..."
    mkdir -p "/opt/dev-purebliss/services/vault-agent" || true
    cat > "$policy_file" <<EOF
path "auth/approle/login" {
  capabilities = ["create", "read"]
}
path "${pki_path}/*" {
  capabilities = ["read", "list", "create", "update"]
}
EOF
    vault policy write "$policy_name" "$policy_file"
    log_success "Vault Agent PKI policy written: $policy_name"

    log_info "Enabling AppRole auth method (if not already enabled)..."
    vault auth enable approle 2>/dev/null || true

    log_info "Creating AppRole for Vault Agent..."
    vault write auth/approle/role/$approle_name \
        token_policies="$policy_name" \
        secret_id_ttl="24h" \
        token_ttl="1h" \
        token_max_ttl="24h"

    log_info "Fetching AppRole credentials..."
    vault read -field=role_id auth/approle/role/$approle_name/role_id > "$role_id_path"
    vault write -f -field=secret_id auth/approle/role/$approle_name/secret_id > "$secret_id_path"
    chmod 600 "$role_id_path" "$secret_id_path"
    log_success "Vault Agent AppRole credentials written to $role_id_path and $secret_id_path"
}

# Configure Grafana DB role in Vault with safe revocation
configure_grafana_db_role() {
    ensure_vault_https
    local db_config_path="database/config/postgres-app"
    local role_path="database/roles/grafana-role"
    local service_tag="GRAFANA_VAULT_ROLE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: Starting configuration for $role_path" >> "$LOG_FILE"

    if ! vault_health_check grafana; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag [ERROR]: Vault health check failed" >> "$LOG_FILE"
        return 1
    fi

    if ! vault read -format=json "$db_config_path" >/dev/null 2>&1; then
        log_error "Vault database config not found at $db_config_path"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag [ERROR]: Missing $db_config_path; configure DB connection before role" >> "$LOG_FILE"
        return 1
    fi

    local creation_stmt revocation_stmt rollback_stmt
    # Heredocs with single-quote delimiter to avoid expansion
    read -r -d '' creation_stmt <<'SQL'
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT CONNECT ON DATABASE grafana TO "{{name}}";
GRANT USAGE ON SCHEMA public TO "{{name}}";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "{{name}}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "{{name}}";
SQL
    read -r -d '' revocation_stmt <<'SQL'
ALTER ROLE "{{name}}" NOLOGIN;
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = '{{name}}';
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
DROP OWNED BY "{{name}}";
DROP ROLE IF EXISTS "{{name}}";
SQL
    read -r -d '' rollback_stmt <<'SQL'
ALTER ROLE "{{name}}" NOLOGIN;
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = '{{name}}';
DROP OWNED BY "{{name}}";
DROP ROLE IF EXISTS "{{name}}";
SQL

    if vault write "$role_path" \
        db_name="postgres-app" \
        creation_statements="$creation_stmt" \
        revocation_statements="$revocation_stmt" \
        rollback_statements="$rollback_stmt" \
        default_ttl="1h" \
        max_ttl="24h" >/dev/null 2>&1; then
        log_success "Grafana Vault DB role configured at $role_path"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: SUCCESS configured $role_path with safe revocation" >> "$LOG_FILE"
    else
        log_error "Failed to configure Grafana Vault DB role"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: ERROR failed to configure $role_path" >> "$LOG_FILE"
        return 1
    fi
    return 0
}

# Validate revocation behavior for grafana-role by issuing creds, connecting, then revoking
test_grafana_role_revocation() {
    ensure_vault_https
    local service_tag="GRAFANA_VAULT_ROLE_TEST"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: Starting revocation test" >> "$LOG_FILE"

    local creds_json username password lease_id
    if ! creds_json=$(vault read -format=json database/creds/grafana-role 2>/dev/null); then
        log_error "Failed to obtain dynamic credentials for grafana-role"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: ERROR obtaining dynamic credentials" >> "$LOG_FILE"
        return 1
    fi
    username=$(echo "$creds_json" | jq -r '.data.username')
    password=$(echo "$creds_json" | jq -r '.data.password')
    lease_id=$(echo "$creds_json" | jq -r '.lease_id')
    if [[ -z "$username" || -z "$password" || -z "$lease_id" || "$username" == "null" ]]; then
        log_error "Invalid credentials payload from Vault"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: ERROR invalid creds payload" >> "$LOG_FILE"
        return 1
    fi

    if docker exec purebliss-postgres bash -lc "PGPASSWORD='$password' psql -h localhost -U '$username' -d grafana -c 'SELECT 1;' >/dev/null 2>&1"; then
        log_success "Dynamic user $username can connect to grafana DB"
    else
        log_error "Dynamic user $username failed to connect to grafana DB"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: ERROR connection failed for $username" >> "$LOG_FILE"
        return 1
    fi

    if ! vault lease revoke "$lease_id" >/dev/null 2>&1; then
        log_error "Failed to revoke lease $lease_id"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: ERROR lease revoke failed ($lease_id)" >> "$LOG_FILE"
        return 1
    fi
    sleep 2

    if docker exec purebliss-postgres bash -lc "psql -U postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname = '$username'\"" | grep -q 1; then
        log_error "Revocation failed: role $username still exists"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: ERROR role still exists $username" >> "$LOG_FILE"
        return 1
    else
        log_success "Revocation success: role $username removed"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $service_tag: SUCCESS revocation removed $username" >> "$LOG_FILE"
    fi
    return 0
}

# Universal dynamic secret retrieval
vault_get_dynamic_secret() {
    local service_name="$1"; local secret_path="$2"
    log_info "Retrieving dynamic secret for $service_name from $secret_path"
    if vault_approle_auth "$service_name"; then
        local secret_data
        secret_data=$(vault read -format=json "$secret_path" 2>/dev/null || true)
        if [[ -n "${secret_data:-}" ]]; then
            echo "$secret_data"; log_success "Dynamic secret retrieved for $service_name"; return 0
        fi
    fi
    log_error "Failed to retrieve dynamic secret for $service_name"; return 1
}

# Main execution function
main() {
    local action="${1:-help}"
    case "$action" in
        help|-h|--help)
            echo "Usage: $0 <action>"
            echo "Actions: setup-vault-agent-approle | setup-grafana-db-role | test-grafana-revocation"
            ;;
        setup-vault-agent-approle)
            vault_agent_approle_setup ;;
        setup-grafana-db-role)
            configure_grafana_db_role ;;
        test-grafana-revocation)
            test_grafana_role_revocation ;;
        *)
            log_info "Consolidated script execution: $action" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
