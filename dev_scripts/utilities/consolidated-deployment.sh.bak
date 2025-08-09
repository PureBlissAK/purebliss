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

# Consolidated Deployment Functions

# Universal pre-deployment validation
pre_deployment_validation() {
    local service_name="$1"
    log_info "Running pre-deployment validation for $service_name"
    
    # Check if service is already running
    if docker ps --format "table {{.Names}}" | grep -q "^${service_name}$"; then
        log_info "Service $service_name is already running - checking health"
        if ! /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$service_name" "pre-deployment"; then
            log_error "Existing $service_name container is unhealthy"
            return 1
        fi
    fi
    
    # Validate dependencies
    validate_service_dependencies "$service_name"
    
    log_success "✅ Pre-deployment validation passed for $service_name"
    return 0
}

# Universal container deployment
deploy_container() {
    local service_name="$1"
    local deployment_config="${2:-docker-compose.yml}"
    
    log_info "Deploying container: $service_name"
    
    # Run pre-deployment validation
    if ! pre_deployment_validation "$service_name"; then
        log_error "Pre-deployment validation failed for $service_name"
        return 1
    fi
    
    # Deploy using docker-compose
    if docker-compose -f "$deployment_config" up -d "$service_name"; then
        log_success "✅ Container deployed successfully: $service_name"
        
        # Run post-deployment health check
        sleep 10  # Allow container to initialize
        if /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$service_name" "post-deployment"; then
            log_success "✅ Post-deployment health check passed for $service_name"
            return 0
        else
            log_error "❌ Post-deployment health check failed for $service_name"
            return 1
        fi
    else
        log_error "❌ Container deployment failed: $service_name"
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
