#!/bin/bash
# Simple non-blocking entrypoint that allows nginx to start
# This can be enhanced later for full Vault PKI integration

echo "INFO: Nginx starting with basic configuration"
echo "Vault PKI integration available but not required for basic operation"

# Create basic cert directory structure
mkdir -p /certs/dev.purebliss.app

# For now, just let nginx start normally
# Future enhancement: Add optional Vault PKI certificate generation here
echo "INFO: Nginx ready to start with default configuration"

exit 0
