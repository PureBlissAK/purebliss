#!/bin/bash
set -euo pipefail

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
#!/bin/bash
set -euo pipefail

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
