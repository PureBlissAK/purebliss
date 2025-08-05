#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
TEST_SCRIPT="/opt/vault_stress_testing/phase3_chaos/resilience_test.js"
K6_BINARY_PATH="/opt/vault_stress_testing/bin/k6"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"
K6_PID_FILE="/tmp/k6_chaos_test.pid"

# --- Helper Functions ---
log_info() {
    echo "[$(date)] [phase3_runner] INFO: $1" | tee -a $LOG_FILE
}

log_error() {
    echo "[$(date)] [phase3_runner] ERROR: $1" | tee -a $LOG_FILE
}

# --- Pre-flight Checks ---
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

log_info "Starting Phase 3: Resilience Test (background load generation)."
log_info "The test will run for 10 minutes. You can now start manual chaos experiments."
log_info "To stop the test manually, run: kill \$(cat ${K6_PID_FILE})"

# Run the test in the background, passing the Vault address and token as environment variables
nohup VAULT_ADDR="http://127.0.0.1:8200" \
VAULT_TOKEN="$VAULT_TOKEN" \
"$K6_BINARY_PATH" run "$TEST_SCRIPT" > /tmp/k6_chaos_output.log 2>&1 &

# Store the PID of the background k6 process
K6_PID=$!
echo $K6_PID > "$K6_PID_FILE"

log_info "k6 process started in the background with PID: ${K6_PID}. Output is logged to /tmp/k6_chaos_output.log"
log_info "See chaos_runbook.md for experiment steps."
