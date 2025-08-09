#!/bin/bash

# Simple script counter and basic indexing
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
INDEX_DIR="/opt/dev-purebliss/dev_scripts/indexing"

mkdir -p "$INDEX_DIR"

echo "🔍 Pure Bliss Script Discovery"
echo "=============================="

# Count all scripts
total_scripts=$(find /opt -name "*.sh" -type f 2>/dev/null | wc -l)
echo "📊 Total .sh scripts found: $total_scripts"

# Create basic index
results_file="$INDEX_DIR/basic_script_index.txt"
echo "=== Pure Bliss Script Index ===" > "$results_file"
echo "Generated: $(date)" >> "$results_file"
echo "Total Scripts: $total_scripts" >> "$results_file"
echo "" >> "$results_file"

echo "📝 Creating basic index..."

# List scripts by location
echo "=== Scripts by Location ===" >> "$results_file"
find /opt -name "*.sh" -type f 2>/dev/null | while read script; do
    echo "$script" >> "$results_file"
done

echo "" >> "$results_file"
echo "=== Scripts by Category (Estimated) ===" >> "$results_file"

# Count by probable categories
health_scripts=$(find /opt -name "*health*" -o -name "*check*" -o -name "*validate*" | grep "\.sh$" | wc -l)
deploy_scripts=$(find /opt -name "*deploy*" -o -name "*start*" -o -name "*setup*" | grep "\.sh$" | wc -l)
backup_scripts=$(find /opt -name "*backup*" -o -name "*restore*" | grep "\.sh$" | wc -l)

echo "Health/Validation Scripts: $health_scripts" >> "$results_file"
echo "Deployment Scripts: $deploy_scripts" >> "$results_file"
echo "Backup Scripts: $backup_scripts" >> "$results_file"

echo "" >> "$results_file"
echo "=== Top Directories with Scripts ===" >> "$results_file"
find /opt -name "*.sh" -type f 2>/dev/null | xargs dirname | sort | uniq -c | sort -nr | head -20 >> "$results_file"

# Update main index library with discovered count
if [[ -f "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md" ]]; then
    sed -i "s/\*\*Total Scripts\*\*:.*/\*\*Total Scripts\*\*: $total_scripts | \*\*Last Scan\*\*: $(date -Iseconds)/" "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
    sed -i "s/Index Status.*/Index Status**: 🟢 ACTIVE - $total_scripts scripts discovered/" "$INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
fi

echo "$total_scripts" > "$INDEX_DIR/script_count.txt"

echo ""
echo "✅ Basic indexing complete!"
echo "📄 Results saved to: $results_file"
echo "📊 Found $total_scripts scripts across /opt"
echo ""
echo "Quick Statistics:"
echo "  Health/Check scripts: $health_scripts"
echo "  Deployment scripts: $deploy_scripts"
echo "  Backup scripts: $backup_scripts"
echo ""
echo "🔧 Next steps:"
echo "  1. Use search utility: $INDEX_DIR/search-scripts.sh"
echo "  2. Add metadata to scripts: $INDEX_DIR/update-script-metadata.sh"
echo "  3. View main index: $INDEX_DIR/SCRIPT_INDEX_LIBRARY.md"
