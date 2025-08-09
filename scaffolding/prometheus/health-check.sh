#!/bin/sh
set -eu
# Health check for Prometheus container using /bin/sh and nc (busybox)
HOST="localhost"
PORT=9090
ENDPOINT="/-/healthy"

RESPONSE=$(echo -e "GET $ENDPOINT HTTP/1.1\r\nHost: $HOST\r\nConnection: close\r\n\r\n" | nc $HOST $PORT | head -n 1)

case "$RESPONSE" in
  *"200 OK"*)
    echo "Prometheus healthy"
    exit 0
    ;;
  *)
    echo "Prometheus unhealthy: $RESPONSE"
    exit 1
    ;;
esac
