#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
TEST_SCRIPT="/opt/vault_stress_testing/phase2_bottlenecks/bottleneck_test.js"
K6_BINARY_PATH="/opt/vault_stress_testing/bin/k6"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

# --- Helper Functions ---
log_info() {
    echo "[$(date)] [phase2_runner] INFO: $1" | tee -a $LOG_FILE
}

log_error() {
    echo "[$(date)] [phase2_runner] ERROR: $1" | tee -a $LOG_FILE
}

usage() {
    echo "Usage: $0 {kv|db|oidc}"
    echo "  kv   - Run the KV secrets engine stress test."
    echo "  db   - Run the Database secrets engine stress test."
    echo "  oidc - Run the OIDC auth method stress test."
    exit 1
}

# --- Pre-flight Checks ---
if [ "$#" -ne 1 ]; then
    usage
fi

SCENARIO_NAME="$1"
case "$SCENARIO_NAME" in
    kv)
        TARGET_SCENARIO="kv_stress"
        ;;
    db)
        TARGET_SCENARIO="db_creds_stress"
        ;;
    oidc)
        TARGET_SCENARIO="oidc_stress"
        ;;
    *)
        log_error "Invalid scenario name: ${SCENARIO_NAME}"
        usage
        ;;
esac

if [ ! -x "$K6_BINARY_PATH" ]; then
    log_error "k6 is not installed or not executable at ${K6_BINARY_PATH}. Please run install_k6.sh first."
    exit 1
fi

if [ ! -f "$VAULT_TOKEN_FILE" ]; then
    log_error "Vault token file not found at ${VAULT_TOKEN_FILE}."
    exit 1
fi

# --- Test Execution ---
VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")

log_info "Starting Phase 2: Bottleneck Test for scenario: ${TARGET_SCENARIO}"
log_info "Running k6 test script: ${TEST_SCRIPT}"

# Run the specific test scenario, passing the Vault address and token as environment variables
VAULT_ADDR="http://127.0.0.1:8200" \
VAULT_TOKEN="$VAULT_TOKEN" \
"$K6_BINARY_PATH" run "$TEST_SCRIPT" --scenario "$TARGET_SCENARIO"

log_info "Phase 2 test for scenario '${TARGET_SCENARIO}' finished."
