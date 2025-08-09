#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# ADD_COMPOSE_LABELS_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="add-compose-labels.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with auto-commit functionality,
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
add_compose_labels_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
add_compose_labels_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
add_compose_labels_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
add_compose_labels_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"

    add_compose_labels_log_info "Starting auto-commit wrapper for successful execution"

    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        add_compose_labels_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            add_compose_labels_log_success "Validation passed - proceeding with auto-commit"
        else
            add_compose_labels_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi

    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        add_compose_labels_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        add_compose_labels_log_info "Auto-commit system not available - manual commit required"
        add_compose_labels_log_info "Recommended commit message: $commit_message"
        add_compose_labels_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
add_compose_labels_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"

    # Log successful completion
    add_compose_labels_log_success "$final_message"

    # Execute auto-commit wrapper
    add_compose_labels_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"

    # Final status
    add_compose_labels_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

# PURE BLISS SCRIPT METADATA
# Script: add-compose-labels.sh
# Purpose: Add metadata labels to specific services in Docker Compose files
# Category: automation
# Dependencies: docker-compose
# Usage: ./add-compose-labels.sh [compose-file]
# Exit Codes: 0=success, 1=error
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: optional
# Vault Required: no
# Last Enhanced: 2025-08-08
# Enhancement Notes: Manual approach for adding Docker Compose labels without breaking YAML syntax
# END METADATA


# Logging function
log_compose_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - COMPOSE_LABELS_${level}: ${message}" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Function to add labels to a specific service
add_service_labels() {
    local compose_file="$1"
    local service_name="$2"
    local purpose="$3"
    local phase="$4"
    local dependencies="$5"
    local health_endpoint="$6"
    local vault_required="$7"

    log_compose_message "INFO" "Adding labels to service: $service_name"

    # Create backup
    cp "$compose_file" "${compose_file}.backup-$(date '+%Y%m%d-%H%M%S')"

    # Check if service already has labels
    if grep -A 20 "^  $service_name:" "$compose_file" | grep -q "labels:"; then
        log_compose_message "INFO" "Service $service_name already has labels, skipping"
        return 0
    fi

    # Find the service section and add labels after the image line
    awk -v service="$service_name" -v purpose="$purpose" -v phase="$phase" -v deps="$dependencies" -v health="$health_endpoint" -v vault="$vault_required" '
    BEGIN { in_service=0; added_labels=0 }
    /^  [a-zA-Z0-9_-]+:/ {
        if ($0 ~ "^  " service ":") {
            in_service=1
            print $0
        } else {
            in_service=0
            added_labels=0
            print $0
        }
        next
    }
    in_service && /^    image:/ && !added_labels {
        print $0
        print "    labels:"
        print "      - \"purebliss.service.name=" service "\""
        print "      - \"purebliss.service.purpose=" purpose "\""
        print "      - \"purebliss.service.phase=" phase "\""
        print "      - \"purebliss.service.dependencies=" deps "\""
        print "      - \"purebliss.service.health.endpoint=" health "\""
        print "      - \"purebliss.service.vault.required=" vault "\""
        print "      - \"purebliss.service.network=purebliss-net\""
        print "      - \"purebliss.service.enhanced=2025-08-08\""
        added_labels=1
        next
    }
    { print $0 }
    ' "$compose_file" > "${compose_file}.tmp"

    mv "${compose_file}.tmp" "$compose_file"

    log_compose_message "SUCCESS" "Labels added to $service_name"
}

# Main function
main() {
    local compose_file="${1:-/opt/my-secure-ha-stack/docker-compose.yml}"

    log_compose_message "START" "Adding metadata labels to Docker Compose services"

    # Add labels for each service
    add_service_labels "$compose_file" "vault" "Core secrets management and PKI engine" "Phase3" "none" "vault:8200/v1/sys/health" "true"
    add_service_labels "$compose_file" "vault-agent" "Vault API proxy and template processor" "Phase3" "vault" "none" "true"
    add_service_labels "$compose_file" "nginx" "API gateway and reverse proxy" "Phase4" "vault,keycloak" "nginx:80/health" "true"

    # Validate syntax
    if docker-compose -f "$compose_file" config > /dev/null 2>&1; then
        log_compose_message "SUCCESS" "Docker Compose syntax validation passed"
    else
        log_compose_message "ERROR" "Docker Compose syntax validation failed, restoring backup"
        local backup_file=$(ls -t "${compose_file}.backup-"* | head -1)
        cp "$backup_file" "$compose_file"
        exit 1
    fi

    log_compose_message "COMPLETE" "Docker Compose metadata labels added successfully"
}

# Execute main function
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
