#!/bin/sh
set -euo pipefail
echo "[health-endpoint.sh] Starting minimal HTTP health endpoint on port 8080..."
# Minimal HTTP health endpoint for container healthcheck
while true; do
  { echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nplane healthy"; } | nc -l -p 8080 -s 0.0.0.0
done
