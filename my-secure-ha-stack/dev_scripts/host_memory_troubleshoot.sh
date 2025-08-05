#!/bin/bash
set -euo pipefail
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
echo "[$(date)] INFO: Starting host memory troubleshooting" | tee -a "$LOG_FILE"

# 1. Log current memory usage
echo "[$(date)] INFO: Host memory usage (free -h):" | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"

echo "[$(date)] INFO: Top 10 memory-consuming processes:" | tee -a "$LOG_FILE"
ps aux --sort=-%mem | head -n 11 | tee -a "$LOG_FILE"

# 2. Log Docker container memory usage
echo "[$(date)] INFO: Docker container memory usage (docker stats snapshot):" | tee -a "$LOG_FILE"
docker stats --no-stream | tee -a "$LOG_FILE"

# 3. Log zombie processes
echo "[$(date)] INFO: Checking for zombie processes:" | tee -a "$LOG_FILE"
ps -eo stat,pid,ppid,cmd | awk '$1 ~ /Z/ {print}' | tee -a "$LOG_FILE"

# 4. Drop filesystem caches (safe, does not kill processes)
echo "[$(date)] INFO: Dropping filesystem caches (sync; echo 3 > /proc/sys/vm/drop_caches)" | tee -a "$LOG_FILE"
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
echo "[$(date)] INFO: Filesystem caches dropped." | tee -a "$LOG_FILE"

# 5. Log memory usage after cache drop
echo "[$(date)] INFO: Host memory usage after dropping caches (free -h):" | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"

echo "[$(date)] INFO: Memory troubleshooting completed." | tee -a "$LOG_FILE"
