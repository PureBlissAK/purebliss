#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# UPDATE_SCRIPT_METADATA_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="update-script-metadata.sh"
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
update_script_metadata_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
update_script_metadata_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
update_script_metadata_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
update_script_metadata_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    update_script_metadata_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        update_script_metadata_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            update_script_metadata_log_success "Validation passed - proceeding with auto-commit"
        else
            update_script_metadata_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        update_script_metadata_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        update_script_metadata_log_info "Auto-commit system not available - manual commit required"
        update_script_metadata_log_info "Recommended commit message: $commit_message"
        update_script_metadata_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
update_script_metadata_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    update_script_metadata_log_success "$final_message"
    
    # Execute auto-commit wrapper
    update_script_metadata_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    update_script_metadata_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# =============================================================================
# SCRIPT METADATA - CENTRALIZED INDEX SYSTEM
# =============================================================================
# Script Name: update-script-metadata.sh
# Version: 1.0.0
# Purpose: Add or update metadata headers in existing scripts
# Category: indexing
# Service Tags: all
# Dependencies: sed, grep, awk
# Environment: all
# Last Enhanced: 2025-08-09
# Enhancement Reason: Initial implementation for metadata standardization
# =============================================================================

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

# Logging
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Function to log messages
log_message() {
    echo "[$(date -Iseconds)] METADATA: $1" | tee -a "$LOG_FILE"
}

# Function to generate metadata header
generate_metadata_header() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")

    # Interactive prompts for metadata (with smart defaults)
    echo "Adding metadata to: $script_name"
    echo ""

    # Analyze script content for smart defaults
    local default_category="utility"
    local default_services="general"
    local default_purpose

    # Determine category from path and content
    if [[ "$script_path" =~ (health|validate|check) ]]; then
        default_category="health-check"
    elif [[ "$script_path" =~ (deploy|start|orchestrat) ]]; then
        default_category="deployment"
    elif [[ "$script_path" =~ (setup|install|config) ]]; then
        default_category="automation"
    elif [[ "$script_path" =~ (fix|troubleshoot|debug) ]]; then
        default_category="troubleshooting"
    elif [[ "$script_path" =~ (clean|maintain|backup) ]]; then
        default_category="maintenance"
    fi

    # Detect services from script content
    local detected_services=()
    local services=("vault" "postgres" "nginx" "keycloak" "grafana" "loki" "prometheus" "plane" "codeserver")

    for service in "${services[@]}"; do
        if grep -qi "$service" "$script_path" 2>/dev/null; then
            detected_services+=("$service")
        fi
    done

    if [[ ${#detected_services[@]} -gt 0 ]]; then
        default_services=$(IFS=,; echo "${detected_services[*]}")
    fi

    # Extract first comment as potential purpose
    default_purpose=$(grep -m1 "^#[^#!]" "$script_path" 2>/dev/null | sed 's/^# *//' || echo "Script automation")

    # Interactive metadata collection
    read -p "Version [1.0.0]: " version
    version=${version:-"1.0.0"}

    read -p "Purpose [$default_purpose]: " purpose
    purpose=${purpose:-"$default_purpose"}

    echo "Available categories: automation, health-check, deployment, utility, service-specific, troubleshooting, security, maintenance"
    read -p "Category [$default_category]: " category
    category=${category:-"$default_category"}

    read -p "Service Tags [$default_services]: " service_tags
    service_tags=${service_tags:-"$default_services"}

    read -p "Dependencies [bash]: " dependencies
    dependencies=${dependencies:-"bash"}

    read -p "Environment [all]: " environment
    environment=${environment:-"all"}

    # Generate the metadata header
    cat << EOF

# =============================================================================
# SCRIPT METADATA - CENTRALIZED INDEX SYSTEM
# =============================================================================
# Script Name: $script_name
# Version: $version
# Purpose: $purpose
# Category: $category
# Service Tags: $service_tags
# Dependencies: $dependencies
# Environment: $environment
# Last Enhanced: $(date +%Y-%m-%d)
# Enhancement Reason: Metadata standardization for centralized indexing
# =============================================================================

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

# MANDATORY UTILITY IMPORTS (if available)
if [[ -f "\$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "\$SCRIPT_DIR/utilities/common-functions-library.sh"
fi
if [[ -f "\$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "\$SCRIPT_DIR/utilities/retry-utils.sh"
fi
if [[ -f "\$SCRIPT_DIR/utilities/script-communication-bridge.sh" ]]; then
    source "\$SCRIPT_DIR/utilities/script-communication-bridge.sh"
fi

EOF
}

# Function to add metadata to script
add_metadata_to_script() {
    local script_path="$1"
    local backup_path="${script_path}.backup-$(date +%Y%m%d-%H%M%S)"

    # Create backup
    cp "$script_path" "$backup_path"
    log_message "Created backup: $backup_path"

    # Check if script already has metadata
    if grep -q "SCRIPT METADATA - CENTRALIZED INDEX SYSTEM" "$script_path"; then
        echo "Script already has metadata headers. Skipping: $script_path"
        rm "$backup_path"  # Remove unnecessary backup
        return 0
    fi

    # Generate new header
    local temp_file
    temp_file=$(mktemp)

    # Extract original shebang and set options if they exist
    local original_shebang
    local original_set_options

    original_shebang=$(head -n1 "$script_path" | grep "^#!" || echo "#!/bin/bash")
    original_set_options=$(grep -m1 "^set -" "$script_path" || echo "")

    # Generate metadata header (excluding shebang and set options as they'll be included)
    generate_metadata_header "$script_path" | tail -n +3 > "$temp_file"

    # Combine: metadata header + original script content (skip original shebang and set options)
    {
        echo "$original_shebang"
        echo "set -euo pipefail"
        echo ""
        cat "$temp_file"
        echo ""
        echo "# Original script content starts here"
        echo ""

        # Add original content, skipping shebang and set options
        tail -n +2 "$script_path" | grep -v "^set -" || tail -n +1 "$script_path" | grep -v "^#!/"
    } > "${script_path}.new"

    # Replace original with enhanced version
    mv "${script_path}.new" "$script_path"
    chmod +x "$script_path"

    # Cleanup
    rm "$temp_file"

    log_message "Added metadata to: $script_path"
    echo "✅ Metadata added successfully to: $script_path"
    echo "📋 Backup created at: $backup_path"
}

# Function to update existing metadata
update_existing_metadata() {
    local script_path="$1"
    local field="$2"
    local new_value="$3"

    if grep -q "SCRIPT METADATA - CENTRALIZED INDEX SYSTEM" "$script_path"; then
        # Update specific field
        case "$field" in
            "version")
                sed -i "s/^# Version: .*/# Version: $new_value/" "$script_path"
                ;;
            "purpose")
                sed -i "s/^# Purpose: .*/# Purpose: $new_value/" "$script_path"
                ;;
            "category")
                sed -i "s/^# Category: .*/# Category: $new_value/" "$script_path"
                ;;
            "service_tags")
                sed -i "s/^# Service Tags: .*/# Service Tags: $new_value/" "$script_path"
                ;;
            "dependencies")
                sed -i "s/^# Dependencies: .*/# Dependencies: $new_value/" "$script_path"
                ;;
            "environment")
                sed -i "s/^# Environment: .*/# Environment: $new_value/" "$script_path"
                ;;
            *)
                echo "Unknown field: $field"
                return 1
                ;;
        esac

        # Update enhancement date
        sed -i "s/^# Last Enhanced: .*/# Last Enhanced: $(date +%Y-%m-%d)/" "$script_path"
        sed -i "s/^# Enhancement Reason: .*/# Enhancement Reason: Updated $field metadata/" "$script_path"

        log_message "Updated $field in: $script_path"
        echo "✅ Updated $field in: $script_path"
    else
        echo "❌ Script does not have metadata headers: $script_path"
        return 1
    fi
}

# Function to process multiple scripts
process_batch() {
    local pattern="$1"

    echo "Processing scripts matching pattern: $pattern"

    while IFS= read -r script_path; do
        if [[ -f "$script_path" && -w "$script_path" ]]; then
            echo ""
            echo "Processing: $script_path"
            read -p "Add metadata to this script? (y/n/s to skip all): " choice

            case "$choice" in
                y|Y)
                    add_metadata_to_script "$script_path"
                    ;;
                s|S)
                    echo "Skipping remaining scripts..."
                    break
                    ;;
                *)
                    echo "Skipping: $script_path"
                    ;;
            esac
        fi
    done < <(find /opt -name "$pattern" -type f 2>/dev/null)
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTION] [SCRIPT_PATH]

Options:
  -a, --add SCRIPT_PATH        Add metadata to specific script
  -u, --update SCRIPT_PATH FIELD VALUE  Update specific metadata field
  -b, --batch PATTERN          Process multiple scripts matching pattern
  -l, --list-missing           List scripts missing metadata
  -h, --help                   Show this help message

Fields for update:
  version, purpose, category, service_tags, dependencies, environment

Examples:
  $0 -a /opt/dev-purebliss/my-script.sh
  $0 -u /opt/dev-purebliss/my-script.sh version 1.1.0
  $0 -b "*.sh"
  $0 -l

EOF
}

# Function to list scripts missing metadata
list_missing_metadata() {
    echo "Scripts missing metadata headers:"
    find /opt -name "*.sh" -type f -exec grep -L "SCRIPT METADATA - CENTRALIZED INDEX SYSTEM" {} \; 2>/dev/null | head -20
}

# Main execution
main() {
    case "${1:-}" in
        -a|--add)
            if [[ -n "${2:-}" ]]; then
                add_metadata_to_script "$2"
            else
                echo "Error: Script path required"
                show_usage
                exit 1
            fi
            ;;
        -u|--update)
            if [[ -n "${2:-}" && -n "${3:-}" && -n "${4:-}" ]]; then
                update_existing_metadata "$2" "$3" "$4"
            else
                echo "Error: Script path, field, and value required"
                show_usage
                exit 1
            fi
            ;;
        -b|--batch)
            if [[ -n "${2:-}" ]]; then
                process_batch "$2"
            else
                echo "Error: Pattern required"
                show_usage
                exit 1
            fi
            ;;
        -l|--list-missing)
            list_missing_metadata
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            echo "Interactive mode: Adding metadata to scripts"
            echo ""
            read -p "Enter script path: " script_path
            if [[ -f "$script_path" ]]; then
                add_metadata_to_script "$script_path"
            else
                echo "File not found: $script_path"
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
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
