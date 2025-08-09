#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# ENHANCE_DOCKERFILE_METADATA_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="enhance-dockerfile-metadata.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced automation script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced automation script for development with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
enhance_dockerfile_metadata_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
enhance_dockerfile_metadata_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
enhance_dockerfile_metadata_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
enhance_dockerfile_metadata_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    enhance_dockerfile_metadata_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        enhance_dockerfile_metadata_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            enhance_dockerfile_metadata_log_success "Validation passed - proceeding with auto-commit"
        else
            enhance_dockerfile_metadata_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        enhance_dockerfile_metadata_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        enhance_dockerfile_metadata_log_info "Auto-commit system not available - manual commit required"
        enhance_dockerfile_metadata_log_info "Recommended commit message: $commit_message"
        enhance_dockerfile_metadata_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
enhance_dockerfile_metadata_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    enhance_dockerfile_metadata_log_success "$final_message"
    
    # Execute auto-commit wrapper
    enhance_dockerfile_metadata_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    enhance_dockerfile_metadata_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT USAGE EXAMPLES - PURE BLISS ELITE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════════
#
# 📚 COMPLETE GUIDE: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md
#
# BASIC AUTO-COMMIT ON SUCCESS:
# Add this at the end of your main script logic:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed successfully"
#
# AUTO-COMMIT WITH VALIDATION:
# Add validation command to ensure script worked correctly:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed with validation" "docker ps | grep -q my-service"
#
# MANUAL AUTO-COMMIT TRIGGER:
# Use auto-commit wrapper directly with custom message:
#   ${WRAPPER_PREFIX}_auto_commit_wrapper "Custom commit: Feature implemented successfully"
#
# DIRECT PURE BLISS ELITE SYSTEM (Recommended):
# Use the official auto-commit trigger system:
#   /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
#       "${SCRIPT_CATEGORY}" "Description of accomplishment" "${SCRIPT_NAME}"
#
# CONDITIONAL AUTO-COMMIT:
# Only commit if certain conditions are met:
#   if [[ \$SUCCESS_FLAG == "true" ]]; then
#       ${WRAPPER_PREFIX}_auto_commit_wrapper "Conditional commit: Success flag set"
#   fi
#
# VALIDATION COMMAND EXAMPLES:
# - Container health check: "docker ps | grep -q healthy"
# - File existence: "test -f /path/to/expected/file"
# - Service response: "curl -s http://service/health | grep -q ok"
# - Custom function: "my_validation_function"
#
# ELITE COMMIT MESSAGE FORMAT:
# The Pure Bliss Elite system automatically generates comprehensive commit messages
# following the standard format with safety guarantees, validation results, and
# proper documentation references. See the AUTO_COMMIT_SYSTEM_GUIDE.md for details.
#
# ═══════════════════════════════════════════════════════════════════════════════════
