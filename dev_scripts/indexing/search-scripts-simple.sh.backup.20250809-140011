#!/bin/bash

# Simple script search utility for Pure Bliss
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

# Function to search by service
search_by_service() {
    local service="$1"
    echo "🔍 Searching for $service scripts..."
    echo ""

    local found=0
    find /opt -name "*.sh" -type f 2>/dev/null | while read script_path; do
        if [[ -f "$script_path" && -s "$script_path" ]]; then
            if grep -qi "$service" "$script_path" 2>/dev/null; then
                script_name=$(basename "$script_path")
                purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' | head -c 80 || echo "No description")

                echo "📄 $script_name"
                echo "   Path: $script_path"
                echo "   Purpose: $purpose"
                echo ""
                found=$((found + 1))
            fi
        fi
    done

    echo "Found scripts containing '$service'"
}

# Function to search by functionality
search_by_functionality() {
    local func="$1"
    echo "🔍 Searching for '$func' functionality..."
    echo ""

    find /opt -name "*.sh" -type f 2>/dev/null | while read script_path; do
        if [[ -f "$script_path" && -s "$script_path" ]]; then
            script_name=$(basename "$script_path")
            if [[ "$script_name" =~ $func ]] || grep -qi "$func" "$script_path" 2>/dev/null; then
                purpose=$(grep -m1 "^#" "$script_path" 2>/dev/null | head -1 | sed 's/^# *//' || echo "No description")

                echo "📄 $script_name"
                echo "   Path: $script_path"
                echo "   Purpose: $purpose"
                echo ""
            fi
        fi
    done
}

# Function to list services with script counts
list_services() {
    echo "🏢 Services with scripts:"
    echo ""

    for service in vault postgres nginx keycloak grafana loki prometheus plane codeserver; do
        count=$(find /opt -name "*.sh" -type f -exec grep -l "$service" {} \; 2>/dev/null | wc -l)
        echo "  $service: $count scripts"
    done
    echo ""
}

# Function to show usage
show_usage() {
    echo "Pure Bliss Script Search Utility"
    echo ""
    echo "Usage: $0 [OPTION] [SEARCH_TERM]"
    echo ""
    echo "Options:"
    echo "  -s SERVICE    Search scripts for specific service"
    echo "  -f FUNCTION   Search scripts by functionality"
    echo "  -ls           List all services with script counts"
    echo "  -la           List all scripts"
    echo "  -h            Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 -s vault"
    echo "  $0 -f health"
    echo "  $0 -ls"
    echo ""
}

# Function to list all scripts
list_all_scripts() {
    echo "📚 All shell scripts in /opt:"
    echo ""

    find /opt -name "*.sh" -type f 2>/dev/null | sort | while read script_path; do
        if [[ -f "$script_path" && -s "$script_path" ]]; then
            script_name=$(basename "$script_path")
            purpose=$(grep -m1 "^#[^!]" "$script_path" 2>/dev/null | sed 's/^# *//' | head -c 60 || echo "No description")

            echo "📄 $script_name"
            echo "   $script_path"
            echo "   $purpose"
            echo ""
        fi
    done
}

# Main execution
case "${1:-}" in
    -s|--service)
        if [[ -n "${2:-}" ]]; then
            search_by_service "$2"
        else
            echo "Error: Service name required"
            show_usage
        fi
        ;;
    -f|--functionality)
        if [[ -n "${2:-}" ]]; then
            search_by_functionality "$2"
        else
            echo "Error: Functionality term required"
            show_usage
        fi
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
        echo "Interactive mode:"
        echo "1) Search by service"
        echo "2) Search by functionality"
        echo "3) List services"
        echo "4) List all scripts"
        echo ""
        read -p "Enter choice (1-4): " choice

        case "$choice" in
            1)
                read -p "Enter service name: " service
                search_by_service "$service"
                ;;
            2)
                read -p "Enter functionality: " func
                search_by_functionality "$func"
                ;;
            3)
                list_services
                ;;
            4)
                list_all_scripts
                ;;
            *)
                echo "Invalid choice"
                ;;
        esac
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        ;;
esac
