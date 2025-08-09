#!/bin/bash
set -e  # Removed strict error handling temporarily

# =============================================================================
# SCRIPT METADATA - CENTRALIZED INDEX SYSTEM
# =============================================================================
# Script Name: scan-all-scripts-simple.sh
# Version: 1.0.0
# Purpose: Simple script discovery and indexing for Pure Bliss development environment
# Category: indexing
# Service Tags: all
# Dependencies: find, grep, basic shell tools
# Environment: all
# Last Enhanced: 2025-08-09
# Enhancement Reason: Simplified version for robust script discovery
# =============================================================================

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

# Ensure directories exist
mkdir -p "$INDEX_DIR" "/opt/my-secure-ha-stack/logs"

# Initialize scan results
SCAN_DATE=$(date -Iseconds)
RESULTS_FILE="$INDEX_DIR/scan_results_simple.txt"

echo "=== Pure Bliss Script Discovery Report ===" > "$RESULTS_FILE"
echo "Scan Date: $SCAN_DATE" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Simple counter
script_count=0

echo "Starting script discovery across /opt..."

# Find all .sh files
while IFS= read -r script_path; do
    if [[ -f "$script_path" && -r "$script_path" && -s "$script_path" ]]; then
        script_name=$(basename "$script_path")

        echo "Found: $script_name at $script_path" >> "$RESULTS_FILE"

        # Try to extract basic info
        purpose="Unknown"
        category="utility"

        # Check first few non-empty, non-shebang lines for purpose
        first_comment=$(grep -m1 "^#[^!]" "$script_path" 2>/dev/null | sed 's/^# *//' || echo "")
        if [[ -n "$first_comment" ]]; then
            purpose="$first_comment"
        fi

        # Guess category from path/name
        if [[ "$script_path" =~ (health|validate|check) ]]; then
            category="health-check"
        elif [[ "$script_path" =~ (deploy|start|setup) ]]; then
            category="deployment"
        elif [[ "$script_path" =~ (clean|maintain) ]]; then
            category="maintenance"
        fi

        echo "  Purpose: $purpose" >> "$RESULTS_FILE"
        echo "  Category: $category" >> "$RESULTS_FILE"
        echo "" >> "$RESULTS_FILE"

        ((script_count++))

        # Show progress
        echo "  [$script_count] $script_name"
    fi
done < <(find /opt -name "*.sh" -type f 2>/dev/null)

echo "" >> "$RESULTS_FILE"
echo "=== Summary ===" >> "$RESULTS_FILE"
echo "Total scripts found: $script_count" >> "$RESULTS_FILE"
echo "Scan completed: $(date -Iseconds)" >> "$RESULTS_FILE"

# Save count
echo "$script_count" > "$INDEX_DIR/script_count.txt"

echo ""
echo "✅ Scan complete!"
echo "📊 Found $script_count shell scripts"
echo "📄 Results: $RESULTS_FILE"
echo ""

# Quick category breakdown
echo "📂 Quick category breakdown:"
grep -h "Category:" "$RESULTS_FILE" | sort | uniq -c | sort -nr

echo ""
echo "🔍 Use search utility: /opt/dev-purebliss/dev_scripts/indexing/search-scripts.sh"
