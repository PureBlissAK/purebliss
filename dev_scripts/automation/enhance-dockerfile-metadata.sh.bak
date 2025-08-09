#!/bin/bash
# PURE BLISS SCRIPT METADATA
# Script: enhance-dockerfile-metadata.sh
# Purpose: Systematically add comprehensive metadata to all Dockerfiles in the Pure Bliss stack
# Category: automation
# Dependencies: find, grep, docker
# Usage: ./enhance-dockerfile-metadata.sh [service-name] (optional - enhances specific service)
# Exit Codes: 0=success, 1=error, 2=partial completion
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: required
# Vault Required: no
# Last Enhanced: 2025-08-08
# Enhancement Notes: Initial creation with comprehensive Dockerfile metadata enhancement
# END METADATA

set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Common functions library not found, using basic functions"
}

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Enhance Dockerfiles with comprehensive metadata for improved traceability and troubleshooting"

# Logging function
log_enhanced_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - METADATA_ENHANCE_${level}: ${message}" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Function to detect current scaffolding phase based on container features
detect_scaffolding_phase() {
    local dockerfile="$1"
    local phase="Phase1"

    if grep -q "vault" "$dockerfile" 2>/dev/null; then
        phase="Phase3"
    fi
    if grep -q "healthcheck" "$dockerfile" 2>/dev/null; then
        phase="Phase4"
    fi
    if grep -q "HEALTHCHECK" "$dockerfile" 2>/dev/null; then
        phase="Phase5"
    fi
    if grep -q "production" "$dockerfile" 2>/dev/null; then
        phase="Phase6"
    fi

    echo "$phase"
}

# Function to extract service dependencies from dockerfile
extract_dependencies() {
    local dockerfile="$1"
    local dependencies=""

    # Check for common dependencies
    if grep -q "postgres\|postgresql" "$dockerfile" 2>/dev/null; then
        dependencies="${dependencies}postgres,"
    fi
    if grep -q "redis" "$dockerfile" 2>/dev/null; then
        dependencies="${dependencies}redis,"
    fi
    if grep -q "vault" "$dockerfile" 2>/dev/null; then
        dependencies="${dependencies}vault,"
    fi
    if grep -q "keycloak" "$dockerfile" 2>/dev/null; then
        dependencies="${dependencies}keycloak,"
    fi

    # Remove trailing comma
    dependencies="${dependencies%,}"

    echo "${dependencies:-none}"
}

# Function to determine vault integration status
determine_vault_status() {
    local dockerfile="$1"

    if grep -q "VAULT_" "$dockerfile" 2>/dev/null; then
        echo "yes"
    elif grep -q "vault" "$dockerfile" 2>/dev/null; then
        echo "partial"
    else
        echo "pending"
    fi
}

# Function to add metadata to a Dockerfile
enhance_dockerfile_metadata() {
    local dockerfile_path="$1"
    local container_name="$2"
    local service_purpose="$3"

    log_enhanced_message "INFO" "Enhancing metadata for $dockerfile_path"

    # Check if metadata already exists
    if grep -q "PURE BLISS CONTAINER METADATA" "$dockerfile_path" 2>/dev/null; then
        log_enhanced_message "INFO" "Metadata already exists for $container_name, skipping"
        return 0
    fi

    # Create backup
    cp "$dockerfile_path" "${dockerfile_path}.backup-$(date '+%Y%m%d-%H%M%S')"

    # Detect current state
    local phase=$(detect_scaffolding_phase "$dockerfile_path")
    local dependencies=$(extract_dependencies "$dockerfile_path")
    local vault_status=$(determine_vault_status "$dockerfile_path")

    # Create metadata header
    local metadata_header="# PURE BLISS CONTAINER METADATA
# Container: $container_name
# Purpose: $service_purpose
# Scaffolding Phase: $phase
# Description: $service_purpose - Auto-enhanced with comprehensive metadata for improved traceability
# Production Status: development
# Dependencies: $dependencies
# Network: purebliss-net
# Vault Integration: $vault_status
# Last Enhanced: $(date '+%Y-%m-%d')
# Enhancement Notes: Initial metadata enhancement with auto-detected configuration
# END METADATA

"

    # Create temporary file with metadata header + original content
    {
        echo "$metadata_header"
        cat "$dockerfile_path"
    } > "${dockerfile_path}.tmp"

    # Replace original file
    mv "${dockerfile_path}.tmp" "$dockerfile_path"

    log_enhanced_message "SUCCESS" "Metadata added to $container_name ($dockerfile_path)"
}

# Function to get service purpose
get_service_purpose() {
    local service_name="$1"

    case "$service_name" in
        "vault") echo "Core secrets management and PKI engine for Pure Bliss stack" ;;
        "postgres") echo "Primary database backend for all Pure Bliss services" ;;
        "redis") echo "Caching layer and session storage for Pure Bliss services" ;;
        "keycloak") echo "Authentication and identity management service for Pure Bliss" ;;
        "nginx") echo "API gateway, load balancer, and reverse proxy for Pure Bliss" ;;
        "grafana") echo "Monitoring dashboards and visualization for Pure Bliss metrics" ;;
        "prometheus") echo "Metrics collection and monitoring for Pure Bliss services" ;;
        "loki") echo "Log aggregation and query engine for Pure Bliss logs" ;;
        "plane") echo "Issue tracking and project management for Pure Bliss development" ;;
        "codeserver") echo "Web-based development environment for Pure Bliss coding" ;;
        "letsencrypt") echo "SSL/TLS certificate management via Vault PKI integration" ;;
        "vault-agent") echo "Vault API proxy and template processor for Pure Bliss services" ;;
        *) echo "Pure Bliss microservice component" ;;
    esac
}
    local service_name="$1"

    # Check multiple possible Dockerfile locations
    local dockerfile_paths=(
        "/opt/dev-purebliss/services/$service_name/Dockerfile"
        "/opt/dev-purebliss/services/$service_name/${service_name}-dockerfile"
        "/opt/dev-purebliss/services/$service_name/dockerfile"
    )

    local dockerfile_path=""
    for path in "${dockerfile_paths[@]}"; do
        if [[ -f "$path" ]]; then
            dockerfile_path="$path"
            break
        fi
    done

    if [[ -z "$dockerfile_path" ]]; then
        log_enhanced_message "WARNING" "No Dockerfile found for service: $service_name in standard locations"
        return 1
    fi
# Function to enhance specific service
enhance_service_dockerfile() {
    local service_purpose
    case "$service_name" in
        "vault") service_purpose="Core secrets management and PKI engine for Pure Bliss stack" ;;
        "postgres") service_purpose="Primary database backend for all Pure Bliss services" ;;
        "redis") service_purpose="Caching layer and session storage for Pure Bliss services" ;;
        "keycloak") service_purpose="Authentication and identity management service for Pure Bliss" ;;
        "nginx") service_purpose="API gateway, load balancer, and reverse proxy for Pure Bliss" ;;
        "grafana") service_purpose="Monitoring dashboards and visualization for Pure Bliss metrics" ;;
        "prometheus") service_purpose="Metrics collection and monitoring for Pure Bliss services" ;;
        "loki") service_purpose="Log aggregation and query engine for Pure Bliss logs" ;;
        "plane") service_purpose="Issue tracking and project management for Pure Bliss development" ;;
        "codeserver") service_purpose="Web-based development environment for Pure Bliss coding" ;;
        "letsencrypt") service_purpose="SSL/TLS certificate management via Vault PKI integration" ;;
        *) service_purpose="Pure Bliss microservice component" ;;
    esac

    enhance_dockerfile_metadata "$dockerfile_path" "purebliss-$service_name" "$service_purpose"
}

# Main enhancement function
main() {
    local target_service="${1:-all}"

    log_enhanced_message "START" "Dockerfile metadata enhancement process for: $target_service"

    if [[ "$target_service" != "all" ]]; then
        # Enhance specific service
        enhance_service_dockerfile "$target_service"
    else
        # Enhance all services
        local services_dir="/opt/dev-purebliss/services"
        local enhanced_count=0
        local failed_count=0

        for service_dir in "$services_dir"/*; do
            if [[ -d "$service_dir" ]]; then
                local service_name=$(basename "$service_dir")

                # Find and validate Dockerfile
                local dockerfile_paths=(
                    "$service_dir/Dockerfile"
                    "$service_dir/${service_name}-dockerfile"
                    "$service_dir/dockerfile"
                )

                for dockerfile in "${dockerfile_paths[@]}"; do
                    if [[ -f "$dockerfile" ]]; then
                        if enhance_dockerfile_metadata "$dockerfile" "purebliss-$service_name" "$(get_service_purpose "$service_name")"; then
                            ((enhanced_count++))
                        else
                            ((failed_count++))
                        fi
                        break
                    fi
                done
            fi
        done

        log_enhanced_message "SUMMARY" "Enhanced $enhanced_count Dockerfiles, $failed_count failed"
    fi

    # Run health validation if available and not a metadata-only operation
    if [[ -x "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh" && "$target_service" != "all" ]]; then
        log_enhanced_message "INFO" "Running health validation for service: $target_service"
        /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$target_service" metadata-enhancement || {
            log_enhanced_message "WARNING" "Health validation failed for $target_service - metadata enhancement completed but service may need attention"
        }
    fi

    log_enhanced_message "COMPLETE" "Dockerfile metadata enhancement completed"
}

# Execute main function with all arguments
main "$@"
