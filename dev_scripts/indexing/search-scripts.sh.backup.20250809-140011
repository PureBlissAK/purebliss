#!/bin/bash
set -euo pipefail

# =============================================================================
# SCRIPT METADATA - CENTRALIZED INDEX SYSTEM
# =============================================================================
# Script Name: search-scripts.sh
# Version: 1.0.0
# Purpose: Intelligent search and discovery of scripts by functionality, service, or metadata
# Category: indexing
# Service Tags: all
# Dependencies: grep, find, jq
# Environment: all
# Last Enhanced: 2025-08-09
# Enhancement Reason: Initial implementation for intelligent script discovery
# =============================================================================

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display colored output
color_echo() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to search by service
search_by_service() {
    local service="$1"
    echo "🔍 Searching scripts for service: $service"
    echo ""

    local found=0
    find /opt -name "*.sh" -type f 2>/dev/null | while read script_path; do
        if [[ -f "$script_path" && -s "$script_path" ]]; then
            if grep -qi "$service" "$script_path" 2>/dev/null; then
                local script_name
                script_name=$(basename "$script_path")

                # Get metadata if available
                local purpose category
                purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' || echo "No description")
                category=$(grep -m1 "^# Category:" "$script_path" 2>/dev/null | sed 's/^# Category: *//' || echo "unknown")

                echo "📄 $script_name"
                echo "   Path: $script_path"
                echo "   Category: $category"
                echo "   Purpose: $purpose"
                echo ""
                found=$((found + 1))
            fi
        fi
    done

    echo "✅ Search complete"
}

# Function to search by category
search_by_category() {
    local category="$1"
    color_echo $BLUE "🔍 Searching scripts by category: $category"
    echo ""

    local found=0
    while IFS= read -r script_path; do
        if [[ -f "$script_path" ]]; then
            local script_name
            script_name=$(basename "$script_path")

            # Get metadata
            local purpose service_tags
            purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' || echo "No description")
            service_tags=$(grep -m1 "^# Service Tags:" "$script_path" 2>/dev/null | sed 's/^# Service Tags: *//' || echo "general")

            color_echo $GREEN "📄 $script_name"
            echo "   Path: $script_path"
            echo "   Services: $service_tags"
            echo "   Purpose: $purpose"
            echo ""
            ((found++))
        fi
    done < <(grep -l "^# Category: $category" /opt --include="*.sh" -r 2>/dev/null)

    if [[ $found -eq 0 ]]; then
        color_echo $YELLOW "⚠️  No scripts found for category: $category"
    else
        color_echo $CYAN "✅ Found $found scripts in category: $category"
    fi
}

# Function to search by functionality
search_by_functionality() {
    local functionality="$1"
    color_echo $BLUE "🔍 Searching scripts by functionality: $functionality"
    echo ""

    local found=0

    # Search in purpose, filename, and content
    while IFS= read -r script_path; do
        if [[ -f "$script_path" ]]; then
            local script_name
            script_name=$(basename "$script_path")

            # Get metadata
            local purpose category service_tags
            purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' || echo "No description")
            category=$(grep -m1 "^# Category:" "$script_path" 2>/dev/null | sed 's/^# Category: *//' || echo "unknown")
            service_tags=$(grep -m1 "^# Service Tags:" "$script_path" 2>/dev/null | sed 's/^# Service Tags: *//' || echo "general")

            # Check if functionality matches purpose, filename, or content
            if [[ "$purpose" =~ $functionality ]] || [[ "$script_name" =~ $functionality ]] || grep -qi "$functionality" "$script_path" 2>/dev/null; then
                color_echo $GREEN "📄 $script_name"
                echo "   Path: $script_path"
                echo "   Category: $category"
                echo "   Services: $service_tags"
                echo "   Purpose: $purpose"
                echo ""
                ((found++))
            fi
        fi
    done < <(find /opt -name "*.sh" -type f 2>/dev/null)

    if [[ $found -eq 0 ]]; then
        color_echo $YELLOW "⚠️  No scripts found for functionality: $functionality"
    else
        color_echo $CYAN "✅ Found $found scripts with functionality: $functionality"
    fi
}

# Function to list all categories
list_categories() {
    color_echo $BLUE "📊 Available script categories:"
    echo ""

    local categories
    categories=$(grep -hr "^# Category:" /opt --include="*.sh" 2>/dev/null | sed 's/^# Category: *//' | sort | uniq -c | sort -nr)

    if [[ -n "$categories" ]]; then
        while read -r count category; do
            color_echo $GREEN "  $category ($count scripts)"
        done <<< "$categories"
    else
        color_echo $YELLOW "  No categorized scripts found"
    fi
    echo ""
}

# Function to list all services
list_services() {
    color_echo $BLUE "🏢 Available services with scripts:"
    echo ""

    local services=("vault" "postgres" "nginx" "keycloak" "grafana" "loki" "prometheus" "plane" "codeserver")

    for service in "${services[@]}"; do
        local count
        count=$(grep -rl "$service" /opt --include="*.sh" 2>/dev/null | wc -l)
        if [[ $count -gt 0 ]]; then
            color_echo $GREEN "  $service ($count scripts)"
        else
            color_echo $YELLOW "  $service (0 scripts)"
        fi
    done
    echo ""
}

# Function to show script details
show_script_details() {
    local script_path="$1"

    if [[ ! -f "$script_path" ]]; then
        color_echo $RED "❌ Script not found: $script_path"
        return 1
    fi

    local script_name
    script_name=$(basename "$script_path")

    color_echo $BLUE "📋 Script Details: $script_name"
    echo ""

    # Extract all metadata
    local version purpose category service_tags dependencies environment last_enhanced enhancement_reason
    version=$(grep -m1 "^# Version:" "$script_path" 2>/dev/null | sed 's/^# Version: *//' || echo "Unknown")
    purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' || echo "No description")
    category=$(grep -m1 "^# Category:" "$script_path" 2>/dev/null | sed 's/^# Category: *//' || echo "unknown")
    service_tags=$(grep -m1 "^# Service Tags:" "$script_path" 2>/dev/null | sed 's/^# Service Tags: *//' || echo "general")
    dependencies=$(grep -m1 "^# Dependencies:" "$script_path" 2>/dev/null | sed 's/^# Dependencies: *//' || echo "unknown")
    environment=$(grep -m1 "^# Environment:" "$script_path" 2>/dev/null | sed 's/^# Environment: *//' || echo "all")
    last_enhanced=$(grep -m1 "^# Last Enhanced:" "$script_path" 2>/dev/null | sed 's/^# Last Enhanced: *//' || echo "unknown")
    enhancement_reason=$(grep -m1 "^# Enhancement Reason:" "$script_path" 2>/dev/null | sed 's/^# Enhancement Reason: *//' || echo "unknown")

    # Check if executable
    local executable="No"
    if [[ -x "$script_path" ]]; then
        executable="Yes"
    fi

    # Get file statistics
    local size last_modified
    size=$(stat -c %s "$script_path" 2>/dev/null || echo "unknown")
    last_modified=$(stat -c %y "$script_path" 2>/dev/null || echo "unknown")

    # Display information
    echo "Path: $script_path"
    echo "Version: $version"
    echo "Purpose: $purpose"
    echo "Category: $category"
    echo "Service Tags: $service_tags"
    echo "Dependencies: $dependencies"
    echo "Environment: $environment"
    echo "Last Enhanced: $last_enhanced"
    echo "Enhancement Reason: $enhancement_reason"
    echo "Executable: $executable"
    echo "Size: $size bytes"
    echo "Last Modified: $last_modified"
    echo ""

    # Show usage if available
    if grep -q "show_usage\|--help" "$script_path" 2>/dev/null; then
        color_echo $CYAN "💡 Script has help/usage information available"
        read -p "Show usage information? (y/n): " show_help
        if [[ "$show_help" =~ ^[Yy] ]]; then
            echo ""
            color_echo $PURPLE "📖 Usage Information:"
            bash "$script_path" --help 2>/dev/null || bash "$script_path" -h 2>/dev/null || echo "Usage information not accessible"
        fi
    fi
}

# Function to find similar scripts
find_similar_scripts() {
    local search_term="$1"
    color_echo $BLUE "🔗 Finding scripts similar to: $search_term"
    echo ""

    local found=0

    # Search by similar purpose or name
    while IFS= read -r script_path; do
        if [[ -f "$script_path" ]]; then
            local script_name
            script_name=$(basename "$script_path")

            # Get metadata
            local purpose category
            purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' || echo "No description")
            category=$(grep -m1 "^# Category:" "$script_path" 2>/dev/null | sed 's/^# Category: *//' || echo "unknown")

            # Calculate similarity (simple word matching)
            local similarity=0
            for word in $search_term; do
                if [[ "$purpose" =~ $word ]] || [[ "$script_name" =~ $word ]]; then
                    ((similarity++))
                fi
            done

            if [[ $similarity -gt 0 ]]; then
                color_echo $GREEN "📄 $script_name (similarity: $similarity)"
                echo "   Path: $script_path"
                echo "   Category: $category"
                echo "   Purpose: $purpose"
                echo ""
                ((found++))
            fi
        fi
    done < <(find /opt -name "*.sh" -type f 2>/dev/null)

    if [[ $found -eq 0 ]]; then
        color_echo $YELLOW "⚠️  No similar scripts found for: $search_term"
    else
        color_echo $CYAN "✅ Found $found similar scripts"
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
$(color_echo $BLUE "🔍 Pure Bliss Script Search Utility")

$(color_echo $GREEN "Usage:") $0 [OPTION] [SEARCH_TERM]

$(color_echo $YELLOW "Search Options:")
  -s, --service SERVICE        Search scripts for specific service
  -c, --category CATEGORY      Search scripts by category
  -f, --functionality FUNC     Search scripts by functionality
  -d, --details SCRIPT_PATH    Show detailed information about script
  -m, --similar TERM           Find scripts similar to search term

$(color_echo $YELLOW "List Options:")
  -lc, --list-categories       List all available categories
  -ls, --list-services         List all services with script counts
  -la, --list-all              List all indexed scripts

$(color_echo $YELLOW "General Options:")
  -h, --help                   Show this help message

$(color_echo $PURPLE "Examples:")
  $0 -s vault                  # Find all vault-related scripts
  $0 -c deployment             # Find all deployment scripts
  $0 -f "health check"         # Find health check functionality
  $0 -d /opt/dev-purebliss/my-script.sh  # Show script details
  $0 -m "nginx configuration"  # Find scripts similar to nginx config

$(color_echo $PURPLE "Available Categories:")
  automation, health-check, deployment, utility, service-specific,
  troubleshooting, security, maintenance

$(color_echo $PURPLE "Available Services:")
  vault, postgres, nginx, keycloak, grafana, loki, prometheus,
  plane, codeserver

EOF
}

# Function to list all scripts
list_all_scripts() {
    color_echo $BLUE "📚 All indexed scripts:"
    echo ""

    local total=0
    while IFS= read -r script_path; do
        if [[ -f "$script_path" ]]; then
            local script_name
            script_name=$(basename "$script_path")

            local category purpose
            category=$(grep -m1 "^# Category:" "$script_path" 2>/dev/null | sed 's/^# Category: *//' || echo "unknown")
            purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' || echo "No description")

            color_echo $GREEN "📄 $script_name"
            echo "   Category: $category"
            echo "   Purpose: $purpose"
            echo "   Path: $script_path"
            echo ""
            ((total++))
        fi
    done < <(find /opt -name "*.sh" -type f 2>/dev/null | sort)

    color_echo $CYAN "📊 Total scripts found: $total"
}

# Main execution
main() {
    case "${1:-}" in
        -s|--service)
            if [[ -n "${2:-}" ]]; then
                search_by_service "$2"
            else
                echo "Error: Service name required"
                show_usage
                exit 1
            fi
            ;;
        -c|--category)
            if [[ -n "${2:-}" ]]; then
                search_by_category "$2"
            else
                echo "Error: Category name required"
                show_usage
                exit 1
            fi
            ;;
        -f|--functionality)
            if [[ -n "${2:-}" ]]; then
                search_by_functionality "$2"
            else
                echo "Error: Functionality term required"
                show_usage
                exit 1
            fi
            ;;
        -d|--details)
            if [[ -n "${2:-}" ]]; then
                show_script_details "$2"
            else
                echo "Error: Script path required"
                show_usage
                exit 1
            fi
            ;;
        -m|--similar)
            if [[ -n "${2:-}" ]]; then
                find_similar_scripts "$2"
            else
                echo "Error: Search term required"
                show_usage
                exit 1
            fi
            ;;
        -lc|--list-categories)
            list_categories
            ;;
        -ls|--list-services)
            list_services
            ;;
        -la|--list-all)
            list_all_scripts
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            color_echo $YELLOW "🔍 Interactive Script Search"
            echo ""
            echo "Choose search method:"
            echo "1) Search by service"
            echo "2) Search by category"
            echo "3) Search by functionality"
            echo "4) List all categories"
            echo "5) List all services"
            echo "6) List all scripts"
            echo ""
            read -p "Enter choice (1-6): " choice

            case "$choice" in
                1)
                    list_services
                    read -p "Enter service name: " service
                    search_by_service "$service"
                    ;;
                2)
                    list_categories
                    read -p "Enter category name: " category
                    search_by_category "$category"
                    ;;
                3)
                    read -p "Enter functionality to search for: " functionality
                    search_by_functionality "$functionality"
                    ;;
                4)
                    list_categories
                    ;;
                5)
                    list_services
                    ;;
                6)
                    list_all_scripts
                    ;;
                *)
                    echo "Invalid choice"
                    exit 1
                    ;;
            esac
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
