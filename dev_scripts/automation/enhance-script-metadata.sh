#!/bin/bash
# PURE BLISS SCRIPT METADATA
# Script: enhance-script-metadata.sh
# Purpose: Add comprehensive metadata headers to all Pure Bliss shell scripts
# Category: automation
# Dependencies: find, grep
# Usage: ./enhance-script-metadata.sh [script-path] (optional)
# Exit Codes: 0=success, 1=error
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: optional
# Vault Required: no
# Last Enhanced: 2025-08-08
# Enhancement Notes: Initial creation for comprehensive script metadata enhancement
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
SCRIPT_PURPOSE="Enhance shell scripts with comprehensive metadata headers"

# Logging function
log_script_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_METADATA_${level}: ${message}" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Function to determine script category
determine_script_category() {
    local script_file="$1"
    local filename=$(basename "$script_file")

    case "$filename" in
        *health*|*validate*|*check*) echo "health-check" ;;
        *deploy*|*start*|*launch*) echo "deployment" ;;
        *test*|*spec*) echo "testing" ;;
        *backup*|*restore*) echo "backup" ;;
        *clean*|*purge*) echo "cleanup" ;;
        *enhance*|*update*|*upgrade*) echo "automation" ;;
        *debug*|*troubleshoot*|*fix*) echo "troubleshooting" ;;
        *monitor*|*watch*) echo "monitoring" ;;
        *scaffold*|*setup*|*init*) echo "scaffolding" ;;
        *migrate*|*transform*) echo "migration" ;;
        *entrypoint*) echo "entrypoint" ;;
        *) echo "automation" ;;
    esac
}

# Function to determine vault requirement
determine_vault_requirement() {
    local script_file="$1"

    if grep -q "VAULT_" "$script_file" 2>/dev/null; then
        echo "yes"
    elif grep -q "vault" "$script_file" 2>/dev/null; then
        echo "conditional"
    else
        echo "no"
    fi
}

# Function to extract script dependencies
extract_script_dependencies() {
    local script_file="$1"
    local dependencies=()

    # Check for common dependencies
    if grep -q "docker" "$script_file" 2>/dev/null; then
        dependencies+=("docker")
    fi
    if grep -q "curl" "$script_file" 2>/dev/null; then
        dependencies+=("curl")
    fi
    if grep -q "jq" "$script_file" 2>/dev/null; then
        dependencies+=("jq")
    fi
    if grep -q "vault" "$script_file" 2>/dev/null; then
        dependencies+=("vault")
    fi
    if grep -q "psql\|postgres" "$script_file" 2>/dev/null; then
        dependencies+=("postgresql-client")
    fi
    if grep -q "redis-cli" "$script_file" 2>/dev/null; then
        dependencies+=("redis-tools")
    fi

    # Join array with commas
    local IFS=","
    echo "${dependencies[*]:-none}"
}

# Function to enhance script with metadata
enhance_script_metadata() {
    local script_file="$1"
    local script_name=$(basename "$script_file")

    log_script_message "INFO" "Enhancing metadata for $script_name"

    # Check if metadata already exists
    if grep -q "PURE BLISS SCRIPT METADATA" "$script_file" 2>/dev/null; then
        log_script_message "INFO" "Metadata already exists for $script_name, skipping"
        return 0
    fi

    # Create backup
    cp "$script_file" "${script_file}.backup-$(date '+%Y%m%d-%H%M%S')"

    # Determine script properties
    local category=$(determine_script_category "$script_file")
    local vault_required=$(determine_vault_requirement "$script_file")
    local dependencies=$(extract_script_dependencies "$script_file")

    # Determine purpose based on filename and content
    local purpose="Pure Bliss automation script"
    case "$script_name" in
        *health*) purpose="Health validation and monitoring for Pure Bliss services" ;;
        *deploy*) purpose="Deployment automation for Pure Bliss stack" ;;
        *enhance*) purpose="Enhancement and improvement automation for Pure Bliss" ;;
        *backup*) purpose="Backup and restore operations for Pure Bliss data" ;;
        *clean*) purpose="Cleanup and maintenance for Pure Bliss environment" ;;
        *test*) purpose="Testing and validation for Pure Bliss components" ;;
        *entrypoint*) purpose="Container entrypoint script for Pure Bliss service" ;;
        *init*) purpose="Initialization script for Pure Bliss service" ;;
        *start*) purpose="Service startup script for Pure Bliss component" ;;
    esac

    # Create metadata header
    local shebang_line=$(head -1 "$script_file")
    local metadata_header="# PURE BLISS SCRIPT METADATA
# Script: $script_name
# Purpose: $purpose
# Category: $category
# Dependencies: $dependencies
# Usage: ./$script_name [options]
# Exit Codes: 0=success, 1=error, 2=warning
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: optional
# Vault Required: $vault_required
# Last Enhanced: $(date '+%Y-%m-%d')
# Enhancement Notes: Initial metadata enhancement with auto-detected configuration
# END METADATA

"

    # Create temporary file with shebang + metadata + rest of file
    {
        echo "$shebang_line"
        echo "$metadata_header"
        tail -n +2 "$script_file"
    } > "${script_file}.tmp"

    # Replace original file
    mv "${script_file}.tmp" "$script_file"

    log_script_message "SUCCESS" "Metadata added to $script_name"
}

# Main function
main() {
    local target_script="${1:-all}"

    log_script_message "START" "Script metadata enhancement process for: $target_script"

    if [[ "$target_script" != "all" ]]; then
        # Enhance specific script
        if [[ -f "$target_script" ]]; then
            enhance_script_metadata "$target_script"
        else
            log_script_message "ERROR" "Script file not found: $target_script"
            exit 1
        fi
    else
        # Enhance all scripts
        local enhanced_count=0
        local failed_count=0

        # Find all shell scripts in the dev_scripts directory
        find /opt/dev-purebliss/dev_scripts -name "*.sh" -type f | while read -r script_file; do
            if enhance_script_metadata "$script_file"; then
                ((enhanced_count++))
            else
                ((failed_count++))
            fi
        done

        # Also enhance service scripts
        find /opt/dev-purebliss/services -name "*.sh" -type f | while read -r script_file; do
            if enhance_script_metadata "$script_file"; then
                ((enhanced_count++))
            else
                ((failed_count++))
            fi
        done

        log_script_message "SUMMARY" "Enhanced script metadata process completed"
    fi

    log_script_message "COMPLETE" "Script metadata enhancement completed"
}

# Execute main function with all arguments
main "$@"
