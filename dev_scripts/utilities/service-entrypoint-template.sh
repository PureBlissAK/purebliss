#!/bin/bash
# Service Entrypoint Template with Nginx Upstream Validation
# Copy this template to each service entrypoint and customize for the specific service

set -euo pipefail

# Service Configuration - CUSTOMIZE THESE VALUES
SERVICE_NAME="SERVICE_NAME_PLACEHOLDER"  # e.g., "keycloak", "plane", "codeserver"
SERVICE_PORT="SERVICE_PORT_PLACEHOLDER"  # e.g., 8080, 3000, 9090
SERVICE_HEALTH_ENDPOINT="/health"        # e.g., "/health", "/api/health", "/-/healthy"
SERVICE_BINARY="SERVICE_BINARY_PLACEHOLDER"  # e.g., "keycloak", "plane", "code-server"

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SERVICE_NAME [$level]: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Wait for dependencies (customize based on service requirements)
wait_for_dependencies() {
    log_message "INFO" "Checking dependencies for $SERVICE_NAME"

    # Example dependency checks - customize as needed
    # if [[ "$SERVICE_NAME" == "keycloak" ]]; then
    #     # Wait for postgres
    #     until nc -z purebliss-postgres 5432; do
    #         log_message "WARN" "Waiting for postgres to be available..."
    #         sleep 2
    #     done
    #     log_message "SUCCESS" "Postgres is available"
    # fi

    # Add more dependency checks as needed
    log_message "SUCCESS" "All dependencies satisfied for $SERVICE_NAME"
}

# Service-specific initialization (customize based on service)
initialize_service() {
    log_message "INFO" "Initializing $SERVICE_NAME"

    # Example service initialization - customize as needed
    # if [[ "$SERVICE_NAME" == "keycloak" ]]; then
    #     # Initialize Keycloak database, admin user, etc.
    #     log_message "INFO" "Setting up Keycloak database and admin user"
    # fi

    log_message "SUCCESS" "$SERVICE_NAME initialization complete"
}

# Start the service
start_service() {
    log_message "INFO" "Starting $SERVICE_NAME service"

    # Start service in background to allow health checking
    # Customize this command based on your service
    # Examples:
    # exec java -jar keycloak.jar start &  # For Keycloak
    # exec code-server --bind-addr 0.0.0.0:8080 &  # For CodeServer
    # exec prometheus --config.file=/etc/prometheus/prometheus.yml &  # For Prometheus

    # PLACEHOLDER: Replace with actual service start command
    echo "CUSTOMIZE: Add actual service start command here"
    # exec $SERVICE_BINARY &

    SERVICE_PID=$!
    log_message "SUCCESS" "$SERVICE_NAME started with PID $SERVICE_PID"
}

# Wait for service to be healthy
wait_for_service_health() {
    log_message "INFO" "Waiting for $SERVICE_NAME to become healthy"

    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s "http://localhost:$SERVICE_PORT$SERVICE_HEALTH_ENDPOINT" >/dev/null 2>&1; then
            log_message "SUCCESS" "$SERVICE_NAME is healthy (attempt $attempt/$max_attempts)"
            return 0
        elif nc -z localhost "$SERVICE_PORT" >/dev/null 2>&1; then
            log_message "INFO" "$SERVICE_NAME port $SERVICE_PORT is open but health endpoint not ready (attempt $attempt/$max_attempts)"
        else
            log_message "WARN" "$SERVICE_NAME not ready on port $SERVICE_PORT (attempt $attempt/$max_attempts)"
        fi

        sleep 2
        attempt=$((attempt + 1))
    done

    log_message "ERROR" "$SERVICE_NAME failed health check after $max_attempts attempts"
    return 1
}

# Notify nginx about service availability
notify_nginx_upstream() {
    log_message "INFO" "Notifying nginx about $SERVICE_NAME availability"

    # Call the upstream validation script
    if [[ -x "/opt/dev-purebliss/upstream-validation.sh" ]]; then
        if /opt/dev-purebliss/upstream-validation.sh "$SERVICE_NAME" "$SERVICE_PORT" "$SERVICE_HEALTH_ENDPOINT"; then
            log_message "SUCCESS" "Nginx successfully notified about $SERVICE_NAME"
        else
            log_message "WARN" "Failed to notify nginx about $SERVICE_NAME - continuing anyway"
        fi
    else
        log_message "WARN" "Upstream validation script not found - nginx will detect service on next reload"
    fi
}

# Main entrypoint workflow
main() {
    log_message "INFO" "Starting $SERVICE_NAME entrypoint"

    # Step 1: Wait for dependencies
    wait_for_dependencies

    # Step 2: Initialize service
    initialize_service

    # Step 3: Start service
    start_service

    # Step 4: Wait for service to be healthy
    if wait_for_service_health; then
        log_message "SUCCESS" "$SERVICE_NAME is healthy and ready"

        # Step 5: Notify nginx about upstream availability
        notify_nginx_upstream

        log_message "SUCCESS" "$SERVICE_NAME startup workflow completed successfully"
    else
        log_message "ERROR" "$SERVICE_NAME failed to become healthy"
        exit 1
    fi

    # Keep container running
    if [[ -n "${SERVICE_PID:-}" ]]; then
        wait $SERVICE_PID
    else
        # If service wasn't started in background, exec the service directly
        log_message "INFO" "Executing $SERVICE_NAME directly"
        # exec $SERVICE_BINARY  # Customize based on service
    fi
}

# Handle different entrypoint arguments
case "${1:-start}" in
    "start"|"")
        main
        ;;
    "health")
        # Health check endpoint
        if curl -f -s "http://localhost:$SERVICE_PORT$SERVICE_HEALTH_ENDPOINT" >/dev/null 2>&1; then
            echo "$SERVICE_NAME is healthy"
            exit 0
        else
            echo "$SERVICE_NAME is not healthy"
            exit 1
        fi
        ;;
    "notify-nginx")
        # Manual nginx notification
        notify_nginx_upstream
        ;;
    *)
        log_message "ERROR" "Unknown command: $1"
        echo "Usage: $0 [start|health|notify-nginx]"
        exit 1
        ;;
esac
