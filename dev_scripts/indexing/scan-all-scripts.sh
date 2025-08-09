#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SCAN_ALL_SCRIPTS_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="scan-all-scripts.sh"
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
scan_all_scripts_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
scan_all_scripts_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
scan_all_scripts_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
scan_all_scripts_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    scan_all_scripts_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        scan_all_scripts_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            scan_all_scripts_log_success "Validation passed - proceeding with auto-commit"
        else
            scan_all_scripts_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        scan_all_scripts_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        scan_all_scripts_log_info "Auto-commit system not available - manual commit required"
        scan_all_scripts_log_info "Recommended commit message: $commit_message"
        scan_all_scripts_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
scan_all_scripts_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    scan_all_scripts_log_success "$final_message"
    
    # Execute auto-commit wrapper
    scan_all_scripts_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    scan_all_scripts_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# =============================================================================
# SCRIPT METADATA - CENTRALIZED INDEX SYSTEM
# =============================================================================
# Script Name: scan-all-scripts.sh
# Version: 1.0.0
# Purpose: Discover and index all scripts across /opt directory structure
# Category: indexing
# Service Tags: all
# Dependencies: find, grep, awk, sed
# Environment: all
# Last Enhanced: 2025-08-09
# Enhancement Reason: Initial implementation for centralized script indexing
# =============================================================================

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

# Logging configuration
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SCAN_LOG="$INDEX_DIR/scan-results.log"

# Create indexing directories if they don't exist
mkdir -p "$INDEX_DIR"

# Function to log messages
log_message() {
    echo "[$(date -Iseconds)] INDEXING: $1" | tee -a "$LOG_FILE" "$SCAN_LOG"
}

# Function to extract script metadata
extract_script_metadata() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")

    # Skip empty files
    if [[ ! -s "$script_path" ]]; then
        log_message "Skipping empty file: $script_path"
        return 0
    fi

    # Extract metadata from script headers
    local version purpose category service_tags dependencies environment

    version=$(grep -m1 "^# Version:" "$script_path" 2>/dev/null | sed 's/^# Version: *//' || echo "Unknown")
    purpose=$(grep -m1 "^# Purpose:" "$script_path" 2>/dev/null | sed 's/^# Purpose: *//' || echo "No description")
    category=$(grep -m1 "^# Category:" "$script_path" 2>/dev/null | sed 's/^# Category: *//' || echo "utility")
    service_tags=$(grep -m1 "^# Service Tags:" "$script_path" 2>/dev/null | sed 's/^# Service Tags: *//' || echo "general")
    dependencies=$(grep -m1 "^# Dependencies:" "$script_path" 2>/dev/null | sed 's/^# Dependencies: *//' || echo "none")
    environment=$(grep -m1 "^# Environment:" "$script_path" 2>/dev/null | sed 's/^# Environment: *//' || echo "all")

    # Determine if script has metadata headers
    local has_metadata="false"
    if grep -q "SCRIPT METADATA - CENTRALIZED INDEX SYSTEM" "$script_path" 2>/dev/null; then
        has_metadata="true"
    fi

    # Check script age
    local last_modified
    last_modified=$(stat -c %Y "$script_path" 2>/dev/null || echo "0")
    local age_days=$(( ($(date +%s) - last_modified) / 86400 ))

    # Determine script status
    local status="active"
    if [[ $age_days -gt 90 ]]; then
        status="legacy"
    elif [[ "$has_metadata" == "false" ]]; then
        status="needs-enhancement"
    fi

    # Output metadata in structured format
    cat << EOF >> "$INDEX_DIR/discovered_scripts.txt"
PATH: $script_path
NAME: $script_name
VERSION: $version
PURPOSE: $purpose
CATEGORY: $category
SERVICE_TAGS: $service_tags
DEPENDENCIES: $dependencies
ENVIRONMENT: $environment
HAS_METADATA: $has_metadata
STATUS: $status
AGE_DAYS: $age_days
LAST_MODIFIED: $last_modified
SCAN_DATE: $(date -Iseconds)
---
EOF
}

# Function to discover scripts
discover_scripts() {
    log_message "Starting comprehensive script discovery across /opt"

    # Clear previous discovery results
    > "$INDEX_DIR/discovered_scripts.txt"

    local script_count=0

    # Search for shell scripts in relevant directories
    while IFS= read -r script_path; do
        if [[ -f "$script_path" && -r "$script_path" && -s "$script_path" ]]; then
            # Skip non-executable or test files, but include .sh files
            if [[ "$script_path" =~ \.(sh|bash)$ ]] || [[ -x "$script_path" ]]; then
                log_message "Indexing: $script_path"
                if extract_script_metadata "$script_path"; then
                    ((script_count++))
                fi
            fi
        fi
    done < <(find /opt -type f \( -name "*.sh" -o -name "*.bash" \) -not -path "*/.*" -not -path "*/tmp/*" -not -path "*/backup*" 2>/dev/null | head -50)

    log_message "Discovery complete: $script_count scripts indexed"
    echo "$script_count" > "$INDEX_DIR/script_count.txt"
}

# Function to categorize scripts
categorize_scripts() {
    log_message "Categorizing discovered scripts"

    # Create category files
    local categories=("automation" "health-check" "deployment" "utility" "service-specific" "troubleshooting" "security" "maintenance")

    for category in "${categories[@]}"; do
        > "$INDEX_DIR/category_${category}.txt"
    done

    # Process each script and categorize
    if [[ -f "$INDEX_DIR/discovered_scripts.txt" ]]; then
        # Process the structured text format
        awk '
        BEGIN { RS="---"; FS="\n" }
        {
            path=""; name=""; purpose=""; category=""
            for (i=1; i<=NF; i++) {
                if ($i ~ /^PATH:/) { gsub(/^PATH: /, "", $i); path = $i }
                if ($i ~ /^NAME:/) { gsub(/^NAME: /, "", $i); name = $i }
                if ($i ~ /^PURPOSE:/) { gsub(/^PURPOSE: /, "", $i); purpose = $i }
                if ($i ~ /^CATEGORY:/) { gsub(/^CATEGORY: /, "", $i); category = $i }
            }
            if (path && name && category) {
                print path "|" name "|" purpose > "'$INDEX_DIR'/category_" category ".txt"
            }
        }' "$INDEX_DIR/discovered_scripts.txt"
    fi

    log_message "Script categorization complete"
}

# Function to identify service associations
identify_service_associations() {
    log_message "Identifying service associations"

    local services=("vault" "postgres" "nginx" "keycloak" "grafana" "loki" "prometheus" "plane" "codeserver")

    for service in "${services[@]}"; do
        > "$INDEX_DIR/service_${service}.txt"

        # Find scripts mentioning this service
        while IFS= read -r script_path; do
            if grep -qi "$service" "$script_path" 2>/dev/null; then
                echo "$script_path" >> "$INDEX_DIR/service_${service}.txt"
            fi
        done < <(find /opt -name "*.sh" -type f 2>/dev/null)

        # Count scripts for this service
        local count
        count=$(wc -l < "$INDEX_DIR/service_${service}.txt" 2>/dev/null || echo "0")
        log_message "Service $service: $count associated scripts"
    done
}

# Function to detect consolidation opportunities
detect_consolidation_opportunities() {
    log_message "Analyzing consolidation opportunities"

    > "$INDEX_DIR/consolidation_opportunities.txt"

    # Find scripts with similar names
    find /opt -name "*.sh" -type f -printf "%f %p\n" 2>/dev/null | \
    sort | \
    awk '{
        base = $1; gsub(/[0-9-].*\.sh$/, ".sh", base);
        scripts[base] = scripts[base] ? scripts[base] "\n" $0 : $0
    }
    END {
        for (base in scripts) {
            if (gsub(/\n/, "\n", scripts[base]) > 0) {
                print "=== Similar scripts for " base " ==="
                print scripts[base]
                print ""
            }
        }
    }' >> "$INDEX_DIR/consolidation_opportunities.txt"

    log_message "Consolidation analysis complete"
}

# Function to generate enhancement recommendations
generate_enhancement_recommendations() {
    log_message "Generating enhancement recommendations"

    > "$INDEX_DIR/enhancement_queue.txt"

    # Find scripts without metadata headers
    echo "=== Scripts Needing Metadata Enhancement ===" >> "$INDEX_DIR/enhancement_queue.txt"
    find /opt -name "*.sh" -type f -exec grep -L "SCRIPT METADATA - CENTRALIZED INDEX SYSTEM" {} \; 2>/dev/null | \
    head -20 >> "$INDEX_DIR/enhancement_queue.txt"

    echo "" >> "$INDEX_DIR/enhancement_queue.txt"
    echo "=== Legacy Scripts (>90 days old) ===" >> "$INDEX_DIR/enhancement_queue.txt"
    find /opt -name "*.sh" -type f -mtime +90 2>/dev/null | \
    head -10 >> "$INDEX_DIR/enhancement_queue.txt"

    log_message "Enhancement recommendations generated"
}

# Function to update the main index library
update_index_library() {
    log_message "Updating main script index library"

    local total_scripts
    total_scripts=$(cat "$INDEX_DIR/script_count.txt" 2>/dev/null || echo "0")

    local timestamp
    timestamp=$(date -Iseconds)

    # Update header information in the main index
    if [[ -f "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md" ]]; then
        sed -i "s/\*\*Total Scripts\*\*:.*/\*\*Total Scripts\*\*: $total_scripts | \*\*Last Scan\*\*: $timestamp/" "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
        sed -i "s/\*\*Generated\*\*:.*/\*\*Generated\*\*: $timestamp/" "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
    fi

    log_message "Index library updated with $total_scripts scripts"
}

# Main execution
main() {
    log_message "Starting automated script indexing scan"

    # Ensure required directories exist
    mkdir -p "$INDEX_DIR"

    # Run discovery and analysis
    discover_scripts
    categorize_scripts
    identify_service_associations
    detect_consolidation_opportunities
    generate_enhancement_recommendations
    update_index_library

    # Generate summary report
    local total_scripts
    total_scripts=$(cat "$INDEX_DIR/script_count.txt" 2>/dev/null || echo "0")

    log_message "Script indexing scan complete"
    log_message "Summary: $total_scripts scripts indexed across /opt directory"
    log_message "Results available in: $INDEX_DIR"
    log_message "Main index: $INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"

    # Display quick summary
    echo ""
    echo "=== Script Indexing Summary ==="
    echo "Total Scripts Discovered: $total_scripts"
    echo "Scan Timestamp: $(date -Iseconds)"
    echo "Index Location: $INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
    echo ""
    echo "Quick Access Commands:"
    echo "  View index: cat $INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
    echo "  Enhancement queue: cat $INDEX_DIR/enhancement_queue.txt"
    echo "  Consolidation opportunities: cat $INDEX_DIR/consolidation_opportunities.txt"
    echo ""
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
