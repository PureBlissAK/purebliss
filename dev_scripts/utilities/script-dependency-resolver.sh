#!/bin/bash
# SCRIPT DEPENDENCY RESOLVER
# Manages script dependencies and inter-script communication

set -euo pipefail

SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# DEPENDENCY RESOLUTION FUNCTIONS
resolve_dependencies() {
    local script_name="$1"
    local dependency_file="/tmp/${script_name%.sh}.deps"

    if [[ -f "$dependency_file" ]]; then
        echo "🔗 Resolving dependencies for $script_name..."

        # Check required scripts
        local required_scripts=$(jq -r '.required_scripts[]?' "$dependency_file" 2>/dev/null || echo "")
        for script in $required_scripts; do
            if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
                echo "❌ Required script missing: $script"
                return 1
            fi
            echo "✅ Required script available: $script"
        done

        # Check required services
        local required_services=$(jq -r '.required_services[]?' "$dependency_file" 2>/dev/null || echo "")
        for service in $required_services; do
            if ! "$SCRIPT_DIR/core/validate-container-health.sh" "$service" "dependency-check" >/dev/null 2>&1; then
                echo "⚠️ Required service not healthy: $service"
                echo "🚀 Attempting to start $service..."
                "$SCRIPT_DIR/services/$service/${service}-automation-suite.sh" start || {
                    echo "❌ Failed to start required service: $service"
                    return 1
                }
            fi
            echo "✅ Required service healthy: $service"
        done

        echo "✅ All dependencies resolved for $script_name"
    else
        echo "ℹ️ No dependency file found for $script_name (optional)"
    fi
}

# CHECK DEPENDENCIES
check_dependencies() {
    local script_name="$1"
    echo "🔍 Checking dependencies for $script_name..."

    # Analyze script for common dependency patterns
    if [[ -f "$SCRIPT_DIR/$script_name" ]]; then
        # Check for source statements
        grep -n "^source" "$SCRIPT_DIR/$script_name" | while read -r line; do
            echo "📦 Found dependency: $line"
        done

        # Check for script executions
        grep -n '\$SCRIPT_DIR' "$SCRIPT_DIR/$script_name" | while read -r line; do
            echo "🔗 Found script call: $line"
        done

        # Check for service references
        grep -n 'validate-container-health.sh\|docker.*exec\|docker.*run' "$SCRIPT_DIR/$script_name" | while read -r line; do
            echo "🐳 Found service interaction: $line"
        done
    fi
}

# GENERATE DEPENDENCY MAP
generate_dependency_map() {
    local output_file="$DOC_DIR/automation/DEPENDENCY_MAP.md"

    echo "🗺️ Generating dependency map..."

    cat > "$output_file" <<EOF
# Pure Bliss Script Dependency Map

Generated: $(date)

## Core Infrastructure Dependencies

EOF

    for category in core utilities services automation deployment health-checks; do
        echo "### $category Scripts" >> "$output_file"
        echo "" >> "$output_file"

        if [[ -d "$SCRIPT_DIR/$category" ]]; then
            for script in "$SCRIPT_DIR/$category"/*.sh; do
                if [[ -f "$script" ]]; then
                    local script_name=$(basename "$script")
                    echo "#### $script_name" >> "$output_file"
                    echo "" >> "$output_file"

                    # Analyze dependencies
                    echo "**Dependencies:**" >> "$output_file"
                    grep -h "^source.*\.sh" "$script" 2>/dev/null | sed 's/source[[:space:]]*//g' | while read -r dep; do
                        echo "- $dep" >> "$output_file"
                    done || echo "- None detected" >> "$output_file"
                    echo "" >> "$output_file"

                    # Analyze service calls
                    echo "**Service Interactions:**" >> "$output_file"
                    grep -h "validate-container-health.sh" "$script" 2>/dev/null | sed 's/.*validate-container-health.sh[[:space:]]*//g' | head -3 | while read -r service; do
                        echo "- Health check: $service" >> "$output_file"
                    done || echo "- None detected" >> "$output_file"
                    echo "" >> "$output_file"
                fi
            done
        fi
    done

    echo "✅ Dependency map generated: $output_file"
}

# UPDATE SCRIPT REFERENCES
update_script_references() {
    local old_path="$1"
    local new_path="$2"

    echo "🔄 Updating script references from $old_path to $new_path..."

    # Find all scripts that reference the old path
    grep -r "$old_path" "$SCRIPT_DIR" --include="*.sh" | while IFS: read -r file line; do
        echo "📝 Updating reference in $file"
        sed -i "s|$old_path|$new_path|g" "$file"
    done

    echo "✅ Script references updated"
}

# VALIDATE SCRIPT INTEGRATION
validate_script_integration() {
    local script_name="$1"
    local full_path="$SCRIPT_DIR/$script_name"

    echo "🔍 Validating script integration for $script_name..."

    # Check if script follows integration standards
    local issues=0

    # Check for proper script header
    if ! grep -q "set -euo pipefail" "$full_path"; then
        echo "⚠️ Missing proper bash options (set -euo pipefail)"
        ((issues++))
    fi

    # Check for centralized script directory usage
    if ! grep -q "SCRIPT_DIR=" "$full_path"; then
        echo "⚠️ Not using centralized SCRIPT_DIR variable"
        ((issues++))
    fi

    # Check for health validation integration
    if grep -q "validate-container-health.sh" "$full_path"; then
        echo "✅ Health validation integration present"
    else
        echo "⚠️ No health validation integration found"
        ((issues++))
    fi

    # Check for logging integration
    if grep -q "dev-environment-setup.log" "$full_path"; then
        echo "✅ Centralized logging integration present"
    else
        echo "⚠️ No centralized logging found"
        ((issues++))
    fi

    if [[ $issues -eq 0 ]]; then
        echo "✅ Script integration validation passed"
        return 0
    else
        echo "❌ Script integration validation failed ($issues issues)"
        return 1
    fi
}

# MAIN FUNCTION
main() {
    local action="$1"
    shift

    case "$action" in
        "resolve")
            resolve_dependencies "$@"
            ;;
        "check")
            check_dependencies "$@"
            ;;
        "map")
            generate_dependency_map "$@"
            ;;
        "update")
            update_script_references "$@"
            ;;
        "validate")
            validate_script_integration "$@"
            ;;
        *)
            echo "Usage: $0 {resolve|check|map|update|validate} [args]"
            echo ""
            echo "Commands:"
            echo "  resolve <script>     - Resolve dependencies for script"
            echo "  check <script>       - Check dependencies for script"
            echo "  map                  - Generate dependency map"
            echo "  update <old> <new>   - Update script references"
            echo "  validate <script>    - Validate script integration"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
