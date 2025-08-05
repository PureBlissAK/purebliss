#!/bin/bash
set -x

LOG_DIR="/opt/vault_stress_testing/logs"
K6_LOG_FILE="${LOG_DIR}/k6_output.log"
RUNNER_LOG_FILE="${LOG_DIR}/runner.log"

mkdir -p "${LOG_DIR}"

echo "[$(date)] Runner script started." > "${RUNNER_LOG_FILE}"

K6_BINARY_PATH="/opt/vault_stress_testing/bin/k6"
TEST_SCRIPT="/opt/vault_stress_testing/phase1_baseline/baseline_test.js"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

if [ ! -f "${VAULT_TOKEN_FILE}" ]; then
    echo "Vault token not found!" >> "${RUNNER_LOG_FILE}"
    exit 1
fi

export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN=$(cat "${VAULT_TOKEN_FILE}")

echo "Running k6..." >> "${RUNNER_LOG_FILE}"

"${K6_BINARY_PATH}" run "${TEST_SCRIPT}" > "${K6_LOG_FILE}" 2>&1

echo "k6 run finished." >> "${RUNNER_LOG_FILE}"
