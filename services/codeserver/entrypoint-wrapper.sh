#!/bin/sh
set -e

# Fetch secrets
python3 /home/coder/project/get_secret.py

# Execute the original entrypoint with arguments
exec /usr/bin/entrypoint.sh --bind-addr 0.0.0.0:8443
