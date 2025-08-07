#!/bin/bash
# ULTIMATE DEBUG ENTRYPOINT
# This script is designed to be as resilient as possible to diagnose startup failures.

# 1. Do not exit on error, to ensure we get as much information as possible.
set -x

# 2. Log to a universally writable location first.
TMP_LOG="/tmp/nginx-debug-$(date +%s).log"
echo "[DEBUG] Nginx Entrypoint Started at $(date)" > "$TMP_LOG"
echo "[DEBUG] UID: $(id -u), GID: $(id -g), USER: $(whoami)" >> "$TMP_LOG"
echo "[DEBUG] Script path: $0" >> "$TMP_LOG"
echo "[DEBUG] Arguments: $@" >> "$TMP_LOG"
echo "[DEBUG] Environment:" >> "$TMP_LOG"
env >> "$TMP_LOG"
sync

# 3. Check filesystem and permissions.
echo "[DEBUG] Filesystem root:" >> "$TMP_LOG"
ls -la / >> "$TMP_LOG"
echo "[DEBUG] /opt directory:" >> "$TMP_LOG"
ls -la /opt/ >> "$TMP_LOG"
echo "[DEBUG] /opt/my-secure-ha-stack directory:" >> "$TMP_LOG"
ls -la /opt/my-secure-ha-stack/ >> "$TMP_LOG"
sync

# 4. Attempt to create and write to the final log file.
RAID_LOG_DIR="/opt/my-secure-ha-stack/logs"
RAID_LOG_FILE="$RAID_LOG_DIR/nginx-entrypoint.log"
echo "[DEBUG] Attempting to use RAID log directory: $RAID_LOG_DIR" >> "$TMP_LOG"

if [ ! -d "$RAID_LOG_DIR" ]; then
    echo "[DEBUG] RAID log directory does not exist. Creating it." >> "$TMP_LOG"
    mkdir -p "$RAID_LOG_DIR"
    if [ $? -ne 0 ]; then
        echo "[FATAL] Failed to create RAID log directory $RAID_LOG_DIR" >> "$TMP_LOG"
        sync
        sleep 300 # Sleep to allow inspection even on failure
        exit 1
    fi
fi

echo "[DEBUG] Writing to final log file: $RAID_LOG_FILE" >> "$TMP_LOG"
echo "--- Nginx Ultimate Debug Log ---" > "$RAID_LOG_FILE"
cat "$TMP_LOG" >> "$RAID_LOG_FILE"
echo "--- End Nginx Ultimate Debug Log ---" >> "$RAID_LOG_FILE"
sync

# 5. Keep the container alive for inspection.
echo "[DEBUG] Script finished. Sleeping for 300 seconds." >> "$TMP_LOG"
echo "[DEBUG] Script finished. Sleeping for 300 seconds." >> "$RAID_LOG_FILE"
sync
sleep 300
exit 0
