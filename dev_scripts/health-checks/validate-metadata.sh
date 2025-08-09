#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VALIDATE_METADATA_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="validate-metadata.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced health-validation script for monitoring operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="health-validation"
SCRIPT_TAGS="enhancement,automation,auto-commit,monitoring"
SCRIPT_SERVICES="monitoring"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced health-validation script for monitoring with auto-commit functionality,
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
validate_metadata_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
validate_metadata_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
validate_metadata_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
validate_metadata_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    validate_metadata_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        validate_metadata_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            validate_metadata_log_success "Validation passed - proceeding with auto-commit"
        else
            validate_metadata_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        validate_metadata_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        validate_metadata_log_info "Auto-commit system not available - manual commit required"
        validate_metadata_log_info "Recommended commit message: $commit_message"
        validate_metadata_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
validate_metadata_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    validate_metadata_log_success "$final_message"
    
    # Execute auto-commit wrapper
    validate_metadata_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    validate_metadata_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

# PURE BLISS SCRIPT METADATA
# Script: validate-metadata.sh
# Purpose: Validate metadata completeness across all Pure Bliss containers and configurations
# Category: health-check
# Dependencies: find, grep, docker
# Usage: ./validate-metadata.sh [service-name] (optional)
# Exit Codes: 0=all metadata complete, 1=missing metadata found, 2=critical errors
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: optional
# Vault Required: no
# Last Enhanced: 2025-08-08
# Enhancement Notes: Initial creation for comprehensive metadata validation
# END METADATA


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Validate metadata completeness across Pure Bliss infrastructure"

# Logging function
log_validation_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - METADATA_VALIDATION_${level}: ${message}" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Function to validate Dockerfile metadata
validate_dockerfile_metadata() {
    local dockerfile="$1"
    local service_name="$2"
    local errors=0

    log_validation_message "INFO" "Validating Dockerfile metadata for $service_name"

    # Required metadata fields
    local required_fields=(
        "PURE BLISS CONTAINER METADATA"
        "Container:"
        "Purpose:"
        "Scaffolding Phase:"
        "Description:"
        "Dependencies:"
        "Network:"
        "Vault Integration:"
        "Last Enhanced:"
        "END METADATA"
    )

    for field in "${required_fields[@]}"; do
        if ! grep -q "$field" "$dockerfile" 2>/dev/null; then
            log_validation_message "ERROR" "Missing metadata field '$field' in $dockerfile"
            ((errors++))
        fi
    done

    # Check for metadata block completeness
    if grep -q "PURE BLISS CONTAINER METADATA" "$dockerfile" 2>/dev/null; then
        if ! grep -q "END METADATA" "$dockerfile" 2>/dev/null; then
            log_validation_message "ERROR" "Incomplete metadata block in $dockerfile (missing END METADATA)"
            ((errors++))
        fi
    fi

    return $errors
}

# Function to validate script metadata
validate_script_metadata() {
    local script_file="$1"
    local script_name="$2"
    local errors=0

    log_validation_message "INFO" "Validating script metadata for $script_name"

    # Required metadata fields for scripts
    local required_fields=(
        "PURE BLISS SCRIPT METADATA"
        "Script:"
        "Purpose:"
        "Category:"
        "Dependencies:"
        "Usage:"
        "Exit Codes:"
        "Log Output:"
        "Last Enhanced:"
        "END METADATA"
    )

    for field in "${required_fields[@]}"; do
        if ! grep -q "$field" "$script_file" 2>/dev/null; then
            log_validation_message "ERROR" "Missing metadata field '$field' in $script_file"
            ((errors++))
        fi
    done

    return $errors
}

# Function to validate Docker Compose metadata
validate_compose_metadata() {
    local compose_file="$1"
    local errors=0

    log_validation_message "INFO" "Validating Docker Compose metadata in $compose_file"

    # Check for service labels
    if ! grep -q "purebliss.service.name" "$compose_file" 2>/dev/null; then
        log_validation_message "WARNING" "No Pure Bliss service labels found in $compose_file"
        ((errors++))
    fi

    # Extract services and check for metadata
    local services=$(grep -E "^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*$" "$compose_file" | grep -v "version:\|services:\|volumes:\|networks:" | sed 's/://g' | xargs)

    for service in $services; do
        if ! grep -A 20 "^[[:space:]]*$service:" "$compose_file" | grep -q "purebliss.service.name"; then
            log_validation_message "WARNING" "Service '$service' missing Pure Bliss metadata labels"
            ((errors++))
        fi
    done

    return $errors
}

# Function to generate metadata report
generate_metadata_report() {
    local target_service="$1"
    local report_file="/opt/my-secure-ha-stack/logs/metadata-validation-report-$(date '+%Y%m%d-%H%M%S').json"

    log_validation_message "INFO" "Generating metadata validation report: $report_file"

    local report_data='{"validation_timestamp":"'$(date -Iseconds)'","target":"'$target_service'","results":{'

    # Add Dockerfile validation results
    report_data+='"dockerfiles":['
    local dockerfile_results=""

    if [[ "$target_service" == "all" ]]; then
        for service_dir in /opt/dev-purebliss/services/*; do
            if [[ -d "$service_dir" ]]; then
                local service_name=$(basename "$service_dir")
                local dockerfile_paths=(
                    "$service_dir/Dockerfile"
                    "$service_dir/${service_name}-dockerfile"
                    "$service_dir/dockerfile"
                )

                for dockerfile in "${dockerfile_paths[@]}"; do
                    if [[ -f "$dockerfile" ]]; then
                        validate_dockerfile_metadata "$dockerfile" "$service_name" >/dev/null 2>&1
                        local result=$?
                        dockerfile_results+="{\"service\":\"$service_name\",\"file\":\"$dockerfile\",\"valid\":$([ $result -eq 0 ] && echo "true" || echo "false"),\"errors\":$result},"
                        break
                    fi
                done
            fi
        done
    fi

    dockerfile_results="${dockerfile_results%,}"
    report_data+="$dockerfile_results],"

    # Add script validation results
    report_data+='"scripts":['
    local script_results=""

    for script_file in /opt/dev-purebliss/dev_scripts/**/*.sh; do
        if [[ -f "$script_file" ]]; then
            local script_name=$(basename "$script_file")
            validate_script_metadata "$script_file" "$script_name" >/dev/null 2>&1
            local result=$?
            script_results+="{\"script\":\"$script_name\",\"file\":\"$script_file\",\"valid\":$([ $result -eq 0 ] && echo "true" || echo "false"),\"errors\":$result},"
        fi
    done

    script_results="${script_results%,}"
    report_data+="$script_results],"

    # Add compose validation results
    report_data+='"compose_files":['
    validate_compose_metadata "/opt/my-secure-ha-stack/docker-compose.yml" >/dev/null 2>&1
    local compose_result=$?
    report_data+="{\"file\":\"/opt/my-secure-ha-stack/docker-compose.yml\",\"valid\":$([ $compose_result -eq 0 ] && echo "true" || echo "false"),\"errors\":$compose_result}]"

    report_data+='}}'

    echo "$report_data" | jq '.' > "$report_file" 2>/dev/null || echo "$report_data" > "$report_file"

    log_validation_message "SUCCESS" "Metadata validation report generated: $report_file"
}

# Main validation function
main() {
    local target_service="${1:-all}"
    local total_errors=0

    log_validation_message "START" "Metadata validation process for: $target_service"

    if [[ "$target_service" != "all" ]]; then
        # Validate specific service
        local service_dir="/opt/dev-purebliss/services/$target_service"

        if [[ ! -d "$service_dir" ]]; then
            log_validation_message "ERROR" "Service directory not found: $service_dir"
            exit 2
        fi

        # Find and validate Dockerfile
        local dockerfile_paths=(
            "$service_dir/Dockerfile"
            "$service_dir/${target_service}-dockerfile"
            "$service_dir/dockerfile"
        )

        for dockerfile in "${dockerfile_paths[@]}"; do
            if [[ -f "$dockerfile" ]]; then
                validate_dockerfile_metadata "$dockerfile" "$target_service"
                total_errors+=$?
                break
            fi
        done

    else
        # Validate all services
        log_validation_message "INFO" "Performing comprehensive metadata validation"

        # Validate all Dockerfiles
        for service_dir in /opt/dev-purebliss/services/*; do
            if [[ -d "$service_dir" ]]; then
                local service_name=$(basename "$service_dir")
                local dockerfile_paths=(
                    "$service_dir/Dockerfile"
                    "$service_dir/${service_name}-dockerfile"
                    "$service_dir/dockerfile"
                )

                for dockerfile in "${dockerfile_paths[@]}"; do
                    if [[ -f "$dockerfile" ]]; then
                        validate_dockerfile_metadata "$dockerfile" "$service_name"
                        total_errors+=$?
                        break
                    fi
                done
            fi
        done

        # Validate all scripts
        find /opt/dev-purebliss/dev_scripts -name "*.sh" -type f | while read -r script_file; do
            local script_name=$(basename "$script_file")
            validate_script_metadata "$script_file" "$script_name"
            total_errors+=$?
        done

        # Validate Docker Compose
        if [[ -f "/opt/my-secure-ha-stack/docker-compose.yml" ]]; then
            validate_compose_metadata "/opt/my-secure-ha-stack/docker-compose.yml"
            total_errors+=$?
        fi
    fi

    # Generate comprehensive report
    generate_metadata_report "$target_service"

    # Summary
    if [[ $total_errors -eq 0 ]]; then
        log_validation_message "SUCCESS" "All metadata validation checks passed"
        exit 0
    else
        log_validation_message "ERROR" "Metadata validation found $total_errors issues"
        exit 1
    fi
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
