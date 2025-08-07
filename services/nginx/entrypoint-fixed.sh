#!/bin/bash

set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Nginx entrypoint started. This is the final test."

# Start Nginx
nginx -g 'daemon off;'
