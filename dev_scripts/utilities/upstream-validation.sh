#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utilities/retry-utils.sh" 2>/dev/null || true

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="[Enhanced with centralized structure]"

# upstream-validation.sh - Smart upstream validation and nginx notification system
# This script should be called by each service when it comes online

set -euo pipefail

# Configuration
SERVICE_NAME="${1:-unknown}"
SERVICE_PORT="${2:-8080}"
SERVICE_HEALTH_ENDPOINT="${3:-/health}"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
NGINX_CONTAINER_NAME="${NGINX_CONTAINER_NAME:-purebliss-nginx}"

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] UPSTREAM_VALIDATION [$level]: $message" | tee -a "$LOG_FILE"
}

# Validate service is healthy and ready
validate_service_health() {
    local service=$1
    local port=$2
    local health_endpoint=$3
    local max_attempts=30
    local attempt=1

    log_message "INFO" "Validating $service health on port $port with endpoint $health_endpoint"

    while [[ $attempt -le $max_attempts ]]; do
        # Check if service is responding
        if curl -f -s "http://localhost:$port$health_endpoint" >/dev/null 2>&1; then
            log_message "SUCCESS" "$service is healthy and ready (attempt $attempt/$max_attempts)"
            return 0
        elif nc -z localhost "$port" >/dev/null 2>&1; then
            log_message "INFO" "$service port $port is open but health endpoint not ready (attempt $attempt/$max_attempts)"
        else
            log_message "WARN" "$service not ready on port $port (attempt $attempt/$max_attempts)"
        fi

        sleep 2
        attempt=$((attempt + 1))
    done

    log_message "ERROR" "$service failed health validation after $max_attempts attempts"
    return 1
}

# Notify nginx about service availability
notify_nginx() {
    local service=$1

    log_message "INFO" "Notifying nginx about $service availability"

    # Check if nginx container is running
    if docker ps --format "{{.Names}}" | grep -q "^$NGINX_CONTAINER_NAME$"; then
        log_message "INFO" "Nginx container found: $NGINX_CONTAINER_NAME"

        # Execute upstream check script in nginx container
        if docker exec "$NGINX_CONTAINER_NAME" /opt/scripts/check-upstream-services.sh "$service" 2>/dev/null; then
            log_message "SUCCESS" "Nginx notified successfully about $service"

            # Verify nginx can reach the service
            if docker exec "$NGINX_CONTAINER_NAME" timeout 5 curl -f -s "http://purebliss-$service:$SERVICE_PORT$SERVICE_HEALTH_ENDPOINT" >/dev/null 2>&1; then
                log_message "SUCCESS" "Nginx can successfully reach $service upstream"
            else
                log_message "WARN" "Nginx cannot reach $service upstream yet - may need network time to propagate"
            fi
        else
            log_message "WARN" "Failed to notify nginx about $service - nginx may be starting"
        fi
    else
        log_message "WARN" "Nginx container not found or not running - will be configured on nginx startup"
    fi
}

# Test nginx proxy functionality for this service
test_nginx_proxy() {
    local service=$1
    local port=$2
    local health_endpoint=$3

    log_message "INFO" "Testing nginx proxy functionality for $service"

    # Wait a moment for nginx to reload configuration
    sleep 3

    # Test through nginx proxy
    local nginx_endpoint=""
    case $service in
        "codeserver") nginx_endpoint="/code-server$health_endpoint" ;;
        *) nginx_endpoint="/$service$health_endpoint" ;;
    esac

    # Try HTTP first (nginx should redirect to HTTPS)
    if curl -f -s -L "http://dev.purebliss.app$nginx_endpoint" >/dev/null 2>&1; then
        log_message "SUCCESS" "Nginx proxy test passed for $service (HTTP->HTTPS redirect working)"
    elif curl -f -s -k "https://dev.purebliss.app$nginx_endpoint" >/dev/null 2>&1; then
        log_message "SUCCESS" "Nginx proxy test passed for $service (HTTPS direct)"
    else
        log_message "WARN" "Nginx proxy test failed for $service - may need more time for configuration propagation"

        # Log nginx status for debugging
        if docker exec "$NGINX_CONTAINER_NAME" curl -s "http://localhost/status" 2>/dev/null; then
            log_message "INFO" "Nginx status retrieved for debugging"
        fi
    fi
}

# Create service validation marker
create_validation_marker() {
    local service=$1
    local marker_dir="/opt/my-secure-ha-stack/logs/upstream-validation"
    local marker_file="$marker_dir/$service-validated.marker"

    mkdir -p "$marker_dir"
    echo "$(date -Iseconds)" > "$marker_file"
    log_message "INFO" "Created validation marker for $service at $marker_file"
}

# Main validation workflow
main() {
    if [[ -z "$SERVICE_NAME" ]] || [[ "$SERVICE_NAME" == "unknown" ]]; then
        echo "Usage: $0 <service_name> [port] [health_endpoint]"
        echo ""
        echo "Examples:"
        echo "  $0 keycloak 8080 /health"
        echo "  $0 plane 3000 /api/health"
        echo "  $0 prometheus 9090 /-/healthy"
        echo ""
        echo "Environment variables:"
        echo "  NGINX_CONTAINER_NAME  - Name of nginx container (default: purebliss-nginx)"
        exit 1
    fi

    log_message "INFO" "Starting upstream validation for $SERVICE_NAME on port $SERVICE_PORT"

    # Step 1: Validate service health
    if validate_service_health "$SERVICE_NAME" "$SERVICE_PORT" "$SERVICE_HEALTH_ENDPOINT"; then
        log_message "SUCCESS" "$SERVICE_NAME passed health validation"

        # Step 2: Notify nginx
        notify_nginx "$SERVICE_NAME"

        # Step 3: Test nginx proxy (optional)
        test_nginx_proxy "$SERVICE_NAME" "$SERVICE_PORT" "$SERVICE_HEALTH_ENDPOINT"

        # Step 4: Create validation marker
        create_validation_marker "$SERVICE_NAME"

        log_message "SUCCESS" "Upstream validation completed successfully for $SERVICE_NAME"

        # Log summary to project plan tracking
        echo "$(date '+%Y-%m-%d %H:%M:%S') - SERVICE_ONLINE: $SERVICE_NAME validated and nginx updated" >> "$LOG_FILE"

    else
        log_message "ERROR" "$SERVICE_NAME failed health validation - nginx not updated"
        exit 1
    fi
}

# Handle script being sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
