#!/bin/bash
#
# Troubleshooting Orchestrator Agent
#
# This script systematically diagnoses connectivity issues between Nginx
# and a specified backend service within the Pure Bliss Docker environment.
#

set -euo pipefail

# --- Configuration ---
NGINX_CONTAINER="purebliss-nginx"
TARGET_SERVICE=$1
TARGET_URL=$2

# --- Colors for output ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

# --- Helper Functions ---
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

log_ok() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $1"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

# --- Main Logic ---
main() {
    if [[ -z "$TARGET_SERVICE" || -z "$TARGET_URL" ]]; then
        log_error "Usage: $0 <service_container_name> <internal_service_url>"
        echo "Example: $0 purebliss-vikunja http://purebliss-vikunja:3456"
        exit 1
    fi

    log_info "--- Starting Troubleshooting for Service: $TARGET_SERVICE ---"

    # 1. Check Nginx Container
    log_info "Step 1: Checking Nginx container '$NGINX_CONTAINER'..."
    if ! docker ps -q -f name="^${NGINX_CONTAINER}$"; then
        log_error "Nginx container '$NGINX_CONTAINER' is not running."
        exit 1
    fi
    NGINX_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$NGINX_CONTAINER")
    if [[ "$NGINX_STATUS" == "healthy" ]]; then
        log_ok "Nginx container is running and healthy."
    else
        log_warn "Nginx container is running but status is '$NGINX_STATUS'."
    fi
    log_info "Last 5 lines of Nginx error log:"
    docker exec "$NGINX_CONTAINER" tail -n 5 /var/log/nginx/error.log || log_warn "Could not read Nginx error log."

    # 2. Check Target Service Container
    log_info "\nStep 2: Checking target service container '$TARGET_SERVICE'..."
    if ! docker ps -q -f name="^${TARGET_SERVICE}$"; then
        log_error "Target service '$TARGET_SERVICE' is not running."
        exit 1
    fi
    log_ok "Target service container '$TARGET_SERVICE' is running."
    log_info "Last 10 lines of '$TARGET_SERVICE' logs:"
    docker logs "$TARGET_SERVICE" --tail 10

    # 3. Test Internal Network Connectivity
    log_info "\nStep 3: Testing network connectivity from Nginx to '$TARGET_SERVICE'..."
    if docker exec "$NGINX_CONTAINER" curl --fail -s -I "$TARGET_URL"; then
        log_ok "Successfully connected to '$TARGET_URL' from within the Nginx container."
    else
        log_error "Failed to connect to '$TARGET_URL' from the Nginx container."
        log_info "This indicates a Docker network or service issue, not an Nginx config problem."
    fi

    # 4. Test External Access via Nginx
    PUBLIC_URL="https://dev.purebliss.app/${TARGET_SERVICE#purebliss-}/"
    log_info "\nStep 4: Testing public access via Nginx at '$PUBLIC_URL'..."
    HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$PUBLIC_URL")
    log_info "Public URL returned HTTP status: $HTTP_STATUS"
    if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 400 ]]; then
        log_ok "Public URL is accessible with a success/redirect status."
    else
        log_error "Public URL is returning an error status code."
    fi
    log_info "Headers from public URL:"
    curl -k -s -I "$PUBLIC_URL"

    log_info "\n--- Troubleshooting Summary for $TARGET_SERVICE ---"
    echo " - Nginx Status: $NGINX_STATUS"
    echo " - Internal Connectivity: $(if docker exec "$NGINX_CONTAINER" curl -s --fail "$TARGET_URL" > /dev/null; then echo "OK"; else echo "FAILED"; fi)"
    echo " - Public HTTP Status: $HTTP_STATUS"
    log_info "--- End of Report ---"
}

main "$@"
