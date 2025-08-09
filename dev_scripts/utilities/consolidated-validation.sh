#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh" 
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0"
SCRIPT_PURPOSE="Consolidated functionality from multiple similar scripts"

# Consolidated Validation Functions

# Universal service health validation
validate_service_health() {
    local service_name="$1"
    local validation_type="${2:-standard}"
    
    log_info "Validating $service_name health ($validation_type)"
    
    # Check container status
    if ! docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$service_name" | grep -q "Up"; then
        log_error "❌ Container $service_name is not running"
        return 1
    fi
    
    # Check container health
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "unknown")
    if [[ "$health_status" == "healthy" ]]; then
        log_success "✅ Container $service_name is healthy"
    elif [[ "$health_status" == "unknown" ]]; then
        log_info "📋 Container $service_name health status unknown (no health check defined)"
    else
        log_error "❌ Container $service_name health status: $health_status"
        return 1
    fi
    
    return 0
}

# Universal endpoint validation
validate_service_endpoint() {
    local service_name="$1"
    local endpoint="$2"
    local expected_status="${3:-200}"
    
    log_info "Validating $service_name endpoint: $endpoint"
    
    local actual_status=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint" 2>/dev/null || echo "000")
    
    if [[ "$actual_status" == "$expected_status" ]]; then
        log_success "✅ Endpoint validation passed for $service_name ($actual_status)"
        return 0
    else
        log_error "❌ Endpoint validation failed for $service_name (expected: $expected_status, actual: $actual_status)"
        return 1
    fi
}


# Main execution function
main() {
    local action="${1:-help}"
    local service="${2:-}"
    
    case "$action" in
        "help"|"-h"|"--help")
            echo "Usage: $0 <action> [service]"
            echo "Actions: vault-auth, deploy, validate, health-check"
            ;;
        *)
            log_info "Consolidated script execution: $action for $service"
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
