#!/bin/bash
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

set -euo pipefail

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
