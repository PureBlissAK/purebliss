#!/bin/bash
set -euxo pipefail
echo "[$(date)] [debug_runner] Hello from the debug script!"
echo "[$(date)] [debug_runner] If you can see this, the shell is working."
LOG_FILE="/opt/vault_stress_testing/logs/debug_output.log"
echo "[$(date)] [debug_runner] Attempting to write to log file: ${LOG_FILE}"
echo "Debug log entry" > "${LOG_FILE}"
echo "[$(date)] [debug_runner] Log file write attempt finished."
echo "[$(date)] [debug_runner] Script finished."
