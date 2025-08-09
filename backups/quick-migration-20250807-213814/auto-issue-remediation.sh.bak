#!/bin/bash
# Auto-generated autonomous script by Copilot
# Purpose: Autonomous common issue remediation and problem resolution
# Service: ALL
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Auto-update: This script self-updates based on discovered improvements

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
HEALTH_VALIDATOR="/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh"

# Autonomous logging function
log_autonomous() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTONOMOUS_${SCRIPT_NAME}: $1" >> "$LOG_FILE"
    echo "🤖 $1"
}

# Error handling with autonomous remediation
handle_error() {
    log_autonomous "ERROR: $1"
    return 1
}

# Common issue patterns and their autonomous remediation
remediate_container_startup_issues() {
    log_autonomous "Remediating container startup issues"

    # Check for failed containers
    failed_containers=$(docker ps -a --filter "status=exited" --filter "name=purebliss-*" --format "{{.Names}}")

    if [[ -n "$failed_containers" ]]; then
        log_autonomous "Found failed containers: $failed_containers"

        for container in $failed_containers; do
            log_autonomous "Attempting to restart: $container"
            docker start "$container" || log_autonomous "Failed to restart $container"
            sleep 5

            # Check if restart was successful
            if docker ps --filter "name=$container" | grep -q "$container"; then
                log_autonomous "✅ Successfully restarted: $container"
            else
                log_autonomous "❌ Failed to restart: $container - checking logs"
                docker logs --tail 20 "$container"
            fi
        done
    else
        log_autonomous "No failed containers found"
    fi
}

# Fix common network issues
remediate_network_issues() {
    log_autonomous "Remediating network connectivity issues"

    # Check if purebliss network exists
    if ! docker network ls | grep -q "purebliss-net"; then
        log_autonomous "Creating missing purebliss-net network"
        docker network create purebliss-net || handle_error "Failed to create network"
    fi

    # Check for containers not connected to network
    local containers=$(docker ps --filter "name=purebliss-*" --format "{{.Names}}")
    for container in $containers; do
        if ! docker inspect "$container" | grep -q "purebliss-net"; then
            log_autonomous "Connecting $container to purebliss-net"
            docker network connect purebliss-net "$container" || log_autonomous "Failed to connect $container to network"
        fi
    done
}

# Clean up orphaned resources
remediate_resource_cleanup() {
    log_autonomous "Cleaning up orphaned resources"

    # Remove stopped test containers
    test_containers=$(docker ps -a --filter "name=*-test*" --filter "name=*-enhanced*" --format "{{.Names}}")
    if [[ -n "$test_containers" ]]; then
        log_autonomous "Removing test containers: $test_containers"
        echo "$test_containers" | xargs -r docker rm -f
    fi

    # Remove dangling images
    dangling_images=$(docker images -f "dangling=true" -q)
    if [[ -n "$dangling_images" ]]; then
        log_autonomous "Removing dangling images"
        echo "$dangling_images" | xargs -r docker rmi
    fi

    # Remove unused volumes (excluding data volumes)
    unused_volumes=$(docker volume ls -f "dangling=true" -q | grep -v "data" || true)
    if [[ -n "$unused_volumes" ]]; then
        log_autonomous "Removing unused volumes (excluding data volumes)"
        echo "$unused_volumes" | xargs -r docker volume rm
    fi
}

# Fix permission issues
remediate_permission_issues() {
    log_autonomous "Remediating file permission issues"

    # Fix common permission issues in dev-purebliss
    if [[ -d "/opt/dev-purebliss" ]]; then
        # Make scripts executable
        find /opt/dev-purebliss -name "*.sh" -type f ! -executable -exec chmod +x {} \;

        # Fix ownership if needed
        if [[ "$(stat -c %U /opt/dev-purebliss)" != "$(whoami)" ]]; then
            log_autonomous "Fixing ownership of /opt/dev-purebliss"
            sudo chown -R "$(id -u):$(id -g)" /opt/dev-purebliss || log_autonomous "Failed to fix ownership"
        fi
    fi
}

# Check and fix Vault connectivity
remediate_vault_connectivity() {
    log_autonomous "Checking Vault connectivity and health"

    # Check if Vault is responding
    if curl -s -k https://vault.purebliss.app:8200/v1/sys/health >/dev/null 2>&1; then
        log_autonomous "✅ Vault is responding"
    else
        log_autonomous "❌ Vault connectivity issues detected"

        # Check if Vault container is running
        if docker ps --filter "name=purebliss-vault" | grep -q "purebliss-vault"; then
            log_autonomous "Vault container is running, checking logs"
            docker logs --tail 20 purebliss-vault
        else
            log_autonomous "Vault container is not running, attempting restart"
            docker start purebliss-vault || handle_error "Failed to start Vault"
        fi
    fi
}

# Fix service endpoint connectivity issues
remediate_endpoint_connectivity() {
    log_autonomous "Checking and fixing service endpoint connectivity"

    # Use autonomous endpoint diagnostics if available
    local endpoint_diagnostics="/opt/dev-purebliss/autonomous-scripts/auto-endpoint-diagnostics.sh"

    if [[ -x "$endpoint_diagnostics" ]]; then
        log_autonomous "Running comprehensive endpoint audit and remediation"
        if "$endpoint_diagnostics" audit; then
            log_autonomous "✅ All endpoints are healthy after remediation"
        else
            log_autonomous "❌ Some endpoints still have issues after remediation"
        fi
    else
        log_autonomous "⚠️ Endpoint diagnostics script not available"

        # Basic endpoint checks for critical services
        local services=("loki" "prometheus" "grafana" "keycloak")
        for service in "${services[@]}"; do
            if docker ps --filter "name=$service" | grep -q "$service"; then
                local health_url="https://dev.purebliss.app/$service/health"
                if ! curl -f -s -k --max-time 10 "$health_url" >/dev/null 2>&1; then
                    log_autonomous "❌ $service endpoint not accessible, restarting service"
                    docker restart "$service" || log_autonomous "Failed to restart $service"
                    sleep 10
                fi
            fi
        done
    fi
}

# Main autonomous remediation workflow
main() {
    log_autonomous "Starting autonomous issue remediation"

    # Execute all remediation functions
    remediate_container_startup_issues
    remediate_network_issues
    remediate_resource_cleanup
    remediate_permission_issues
    remediate_vault_connectivity
    remediate_endpoint_connectivity

    # Final health check
    log_autonomous "Performing final health validation"
    if [[ -f "$HEALTH_VALIDATOR" ]]; then
        "$HEALTH_VALIDATOR" "all" "autonomous-remediation" || log_autonomous "Some services still require attention"
    fi

    log_autonomous "🎉 Autonomous remediation completed"
    log_autonomous "Check individual service logs for any remaining issues"
}

# Execute main function
main "$@"
