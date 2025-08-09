#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"
source "$SCRIPT_DIR/utilities/consolidated-vault-integration.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Configure Grafana Vault PostgreSQL role with safe revocation and validate"

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

main() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - GRAFANA_ROLE_SETUP: Starting" >> "$LOG_FILE"

    # HTTPS-only enforcement for Vault
    ensure_vault_https

    # Try Vault AppRole auth if grafana approle exists
    if [[ -f "/opt/dev-purebliss/secrets/grafana-role-id" && -f "/opt/dev-purebliss/secrets/grafana-secret-id" ]]; then
        vault_approle_auth grafana || true
    fi

    if ! configure_grafana_db_role; then
        log_error "Grafana DB role configuration failed"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - GRAFANA_ROLE_SETUP: ❌ ERROR configure_grafana_db_role" >> "$LOG_FILE"
        exit 1
    fi

    # Run a quick revocation test to validate cleanup
    if ! test_grafana_role_revocation; then
        log_error "Grafana role revocation test failed"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - GRAFANA_ROLE_SETUP: ❌ ERROR test_grafana_role_revocation" >> "$LOG_FILE"
        exit 1
    fi

    log_success "Grafana Vault DB role configured and revocation validated"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - GRAFANA_ROLE_SETUP: ✅ SUCCESS configuration and revocation validated" >> "$LOG_FILE"

    # MANDATORY HEALTH VALIDATION for postgres and grafana (stop if unhealthy)
    if ! "$SCRIPT_DIR/core/validate-container-health.sh" postgres grafana-role-setup; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - GRAFANA_ROLE_SETUP: ❌ postgres health validation failed" >> "$LOG_FILE"
        exit 1
    fi
    if ! "$SCRIPT_DIR/core/validate-container-health.sh" grafana grafana-role-setup; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - GRAFANA_ROLE_SETUP: ❌ grafana health validation failed" >> "$LOG_FILE"
        exit 1
    fi
}

main "$@"
