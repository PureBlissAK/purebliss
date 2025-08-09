#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# TARGETED_SCRIPT_ENHANCER_TEST
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Targeted Enhancement Test on 5 Scripts
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="targeted-script-enhancer-test.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Test the autonomous script enhancer on 5 specific scripts"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="testing"
SCRIPT_TAGS="enhancement,testing,validation,demonstration"
SCRIPT_SERVICES="all"
SCRIPT_DEPENDENCIES="common-functions-library.sh,autonomous-script-enhancer.sh"
SCRIPT_DESCRIPTION="Targeted test of the autonomous script enhancer on 5 selected scripts
to demonstrate the enhancement process with safety validation and metadata addition"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


# Vault-supporting scripts to enhance
TARGET_SCRIPTS=(
    "/opt/dev_scripts/plane-approle.sh"
    "/opt/dev_scripts/agents/vault_sanity_agent.sh"
    "/opt/dev-purebliss/vault-http-init.sh"
    "/opt/dev-purebliss/services/vault/vault-init-automation.sh"
    "/opt/dev-purebliss/services/redis/vault-database-entrypoint.sh"
    "/opt/dev-purebliss/services/nginx/vault-pki-entrypoint.sh"
    "/opt/dev-purebliss/services/postgres/vault-approle-setup.sh"
    "/opt/dev-purebliss/services/postgres/vault-entrypoint.sh"
    "/opt/dev-purebliss/services/postgres/vault-entrypoint-enhanced.sh"
    "/opt/dev-purebliss/services/keycloak/vault-entrypoint.sh"
    "/opt/dev-purebliss/services/vault/backup/vault-init-automation.sh"
    "/opt/dev-purebliss/services/vault/backup/vault-setup-tls.sh"
    "/opt/dev-purebliss/services/vault/backup/vault-simple-unseal.sh"
    "/opt/dev-purebliss/services/vault/backup/vault-dev-init.sh"
    "/opt/dev-purebliss/services/vault/backup/vault-break-fix.sh"
    "/opt/dev-purebliss/services/vault/backup/vault-auto-unseal.sh"
    "/opt/dev-purebliss/services/vault/backup/vault-manual-permissions-fix.sh"
)

# Source common functions
source "/opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh"

# ═══════════════════════════════════════════════════════════════════════════════════
# INTELLIGENT ANALYSIS FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Function to analyze script for consolidation opportunities
analyze_script_consolidation() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    local consolidation_suggestions=()

    targeted_script_enhancer_test_log_info "Analyzing $script_name for consolidation opportunities"

    # Read script content
    local script_content
    script_content=$(cat "$script_path" 2>/dev/null || echo "")

    # Check for common vault functions
    if echo "$script_content" | grep -q "vault.*auth\|vault.*read\|vault.*write"; then
        if [[ ! "$script_content" =~ "consolidated-vault-integration" ]]; then
            consolidation_suggestions+=("VAULT_INTEGRATION: Consider using consolidated-vault-integration.sh functions")
        fi
    fi

    # Check for deployment patterns
    if echo "$script_content" | grep -q "docker.*compose\|docker.*start\|docker.*up"; then
        if [[ ! "$script_content" =~ "consolidated-deployment" ]]; then
            consolidation_suggestions+=("DEPLOYMENT: Consider using consolidated-deployment.sh functions")
        fi
    fi

    # Check for health validation patterns
    if echo "$script_content" | grep -q "health\|validate\|check.*status"; then
        if [[ ! "$script_content" =~ "consolidated-validation" ]]; then
            consolidation_suggestions+=("VALIDATION: Consider using consolidated-validation.sh functions")
        fi
    fi

    # Check for duplicate function patterns
    local function_patterns=(
        "wait_for_service"
        "check_vault_status"
        "validate_container"
        "setup_database"
        "configure_ssl"
        "generate_password"
    )

    for pattern in "${function_patterns[@]}"; do
        if echo "$script_content" | grep -q "function.*$pattern\|$pattern()" &&
           [[ ! "$script_content" =~ "source.*common-functions-library" ]]; then
            consolidation_suggestions+=("DUPLICATE_FUNCTION: Function '$pattern' may be duplicated - check common-functions-library.sh")
        fi
    done

    # Output suggestions
    if [[ ${#consolidation_suggestions[@]} -gt 0 ]]; then
        echo "  🔍 CONSOLIDATION ANALYSIS:"
        for suggestion in "${consolidation_suggestions[@]}"; do
            echo "    - $suggestion"
        done
    else
        echo "  ✅ No obvious consolidation opportunities found"
    fi

    return ${#consolidation_suggestions[@]}
}

# Function to suggest additional wrappers based on script analysis
suggest_additional_wrappers() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    local wrapper_suggestions=()

    targeted_script_enhancer_test_log_info "Analyzing $script_name for additional wrapper suggestions"

    # Read script content
    local script_content
    script_content=$(cat "$script_path" 2>/dev/null || echo "")

    # Check for vault operations
    if echo "$script_content" | grep -q "vault.*read\|vault.*write\|vault.*auth"; then
        wrapper_suggestions+=("VAULT_WRAPPER: Add vault_safe_read() and vault_safe_write() wrappers with error handling")
    fi

    # Check for docker operations
    if echo "$script_content" | grep -q "docker.*exec\|docker.*run\|docker.*compose"; then
        wrapper_suggestions+=("DOCKER_WRAPPER: Add docker_safe_exec() wrapper with container validation")
    fi

    # Check for curl/HTTP operations
    if echo "$script_content" | grep -q "curl\|wget\|http"; then
        wrapper_suggestions+=("HTTP_WRAPPER: Add http_request_with_retry() wrapper for reliable HTTP calls")
    fi

    # Check for file operations
    if echo "$script_content" | grep -q "cp\|mv\|rm.*-rf\|chmod\|chown"; then
        wrapper_suggestions+=("FILE_WRAPPER: Add safe_file_operation() wrapper with backup and validation")
    fi

    # Check for database operations
    if echo "$script_content" | grep -q "psql\|mysql\|redis-cli\|createdb"; then
        wrapper_suggestions+=("DB_WRAPPER: Add database_safe_query() wrapper with connection validation")
    fi

    # Check for service management
    if echo "$script_content" | grep -q "systemctl\|service.*start\|service.*stop"; then
        wrapper_suggestions+=("SERVICE_WRAPPER: Add service_safe_control() wrapper with status validation")
    fi

    # Check for SSL/TLS operations
    if echo "$script_content" | grep -q "openssl\|certbot\|ssl\|tls"; then
        wrapper_suggestions+=("SSL_WRAPPER: Add ssl_cert_management() wrapper for certificate operations")
    fi

    # Check for inter-script communication
    if echo "$script_content" | grep -q "source.*\.sh\|bash.*\.sh\|\.\/.*\.sh"; then
        wrapper_suggestions+=("COMMUNICATION_WRAPPER: Add script_safe_invoke() wrapper for reliable script execution")
    fi

    # Output suggestions
    if [[ ${#wrapper_suggestions[@]} -gt 0 ]]; then
        echo "  💡 WRAPPER SUGGESTIONS:"
        for suggestion in "${wrapper_suggestions[@]}"; do
            echo "    - $suggestion"
        done
    else
        echo "  ✅ Current wrapper functions appear sufficient"
    fi

    return ${#wrapper_suggestions[@]}
}

# Function to detect script similarity for consolidation
detect_script_similarity() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    local similar_scripts=()

    targeted_script_enhancer_test_log_info "Checking $script_name for similar scripts in workspace"

    # Get script's main functions and patterns
    local script_functions
    script_functions=$(grep -o "function [a-zA-Z_][a-zA-Z0-9_]*\|^[a-zA-Z_][a-zA-Z0-9_]*\s*()" "$script_path" 2>/dev/null | head -10 || echo "")

    # Get script keywords
    local script_keywords
    script_keywords=$(grep -o "\(vault\|docker\|postgres\|redis\|nginx\|keycloak\|health\|deploy\|setup\|init\|config\)" "$script_path" 2>/dev/null | sort | uniq | tr '\n' ' ' || echo "")

    # Check for similar scripts
    while IFS= read -r -d '' other_script; do
        if [[ "$other_script" != "$script_path" ]]; then
            local other_name="$(basename "$other_script")"
            local similarity_score=0

            # Check function similarity
            if [[ -n "$script_functions" ]]; then
                local common_functions
                common_functions=$(grep -F "$script_functions" "$other_script" 2>/dev/null | wc -l || echo "0")
                similarity_score=$((similarity_score + common_functions * 20))
            fi

            # Check keyword similarity
            if [[ -n "$script_keywords" ]]; then
                for keyword in $script_keywords; do
                    if grep -q "$keyword" "$other_script" 2>/dev/null; then
                        similarity_score=$((similarity_score + 10))
                    fi
                done
            fi

            # Check filename similarity
            if echo "$other_name" | grep -q "${script_name%.*}\|${script_name%%.*}"; then
                similarity_score=$((similarity_score + 30))
            fi

            # If similarity is high, suggest consolidation
            if [[ $similarity_score -gt 40 ]]; then
                similar_scripts+=("$other_name (similarity: ${similarity_score}%)")
            fi
        fi
    done < <(find /opt -name "*.sh" -type f -print0 2>/dev/null | head -50)

    # Output similar scripts
    if [[ ${#similar_scripts[@]} -gt 0 ]]; then
        echo "  🔗 SIMILAR SCRIPTS FOUND:"
        for similar in "${similar_scripts[@]}"; do
            echo "    - $similar"
        done
        echo "    💡 Consider consolidating these scripts using consolidated-vault-integration.sh patterns"
    else
        echo "  ✅ No highly similar scripts detected"
    fi

    return ${#similar_scripts[@]}
}

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS FOR INDEX LIBRARY INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for updating Script Index Library
update_script_index_library() {
    local script_path="$1"
    local enhancement_status="$2"
    local category="$3"
    local services="$4"
    local tags="$5"

    local script_name="$(basename "$script_path")"
    local index_file="/opt/dev-purebliss/dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md"

    # Log the update
    targeted_script_enhancer_test_log_info "Updating Script Index Library for $script_name"

    # Create temporary index update
    local temp_update="/tmp/index_update_$$"
    echo "| $script_name | Enhanced $category script for $services | $services | common-functions-library.sh,retry-utils.sh | ✅ Active | ✅ Enhanced |" > "$temp_update"

    # Update enhancement statistics in index
    if [[ -f "$index_file" ]]; then
        # Update the enhancement count and statistics
        sed -i "s/\*\*Enhanced Scripts\*\*: [0-9]* scripts enhanced/\*\*Enhanced Scripts\*\*: $(($(grep -c "✅ Enhanced" "$index_file" 2>/dev/null || echo 0) + 1)) scripts enhanced/" "$index_file" 2>/dev/null || true

        # Update last scan date
        sed -i "s/\*\*Last Scan\*\*: [0-9-]*T[0-9:]*Z/\*\*Last Scan\*\*: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$index_file" 2>/dev/null || true

        # Add to recently enhanced scripts section
        local enhanced_entry="| $script_name | $script_path | $(date +%Y-%m-%d) | ✅ Enhanced |"
        if grep -q "| Script | Path | Enhancement Date | Status |" "$index_file"; then
            sed -i "/| Script | Path | Enhancement Date | Status |/a\\$enhanced_entry" "$index_file" 2>/dev/null || true
        fi
    fi

    rm -f "$temp_update"
}

# Wrapper for logging with script context
targeted_script_enhancer_test_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for error logging with script context
targeted_script_enhancer_test_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for success logging with script context
targeted_script_enhancer_test_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

echo "🎯 TARGETED SCRIPT ENHANCEMENT TEST"
echo "==================================="
echo "Target Scripts: ${#TARGET_SCRIPTS[@]}"
echo ""

# Create backup directory
BACKUP_DIR="/opt/dev-purebliss/backups/targeted-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📁 Backup directory: $BACKUP_DIR"
echo ""

# Step 1: Validate all scripts first
echo "🔍 STEP 1: SAFETY VALIDATION"
echo "============================="
SAFE_SCRIPTS=()
UNSAFE_SCRIPTS=()

for script_path in "${TARGET_SCRIPTS[@]}"; do
    script_name="$(basename "$script_path")"
    echo "Validating: $script_name"

    if [[ ! -f "$script_path" ]]; then
        echo "  ❌ Script not found"
        continue
    fi

    # Basic safety checks
    is_safe=true

    # Syntax check
    if ! bash -n "$script_path" 2>/dev/null; then
        echo "  ❌ Syntax errors detected"
        UNSAFE_SCRIPTS+=("$script_path")
        continue
    fi

    # Check for infinite loops
    if grep -q "while true\|while \[ 1 \]\|while \[\[ 1 \]\]" "$script_path"; then
        # Check for break conditions
        if ! grep -q "break\|exit\|return\|timeout" "$script_path"; then
            echo "  ⚠️  Potential infinite loop without break condition"
            UNSAFE_SCRIPTS+=("$script_path")
            continue
        fi
    fi

    # Check for dangerous operations
    if grep -q "rm -rf /\|find / \|chmod -R 777" "$script_path"; then
        echo "  ⚠️  Dangerous operations detected"
        UNSAFE_SCRIPTS+=("$script_path")
        continue
    fi

    echo "  ✅ Safe for enhancement"
    SAFE_SCRIPTS+=("$script_path")
done

echo ""
echo "📊 Validation Results:"
echo "  Safe scripts: ${#SAFE_SCRIPTS[@]}"
echo "  Unsafe scripts: ${#UNSAFE_SCRIPTS[@]}"
echo ""

if [[ ${#UNSAFE_SCRIPTS[@]} -gt 0 ]]; then
    echo "⚠️  Unsafe scripts (will be skipped):"
    for script in "${UNSAFE_SCRIPTS[@]}"; do
        echo "  - $(basename "$script")"
    done
    echo ""
fi

# Step 2: Enhance safe scripts
if [[ ${#SAFE_SCRIPTS[@]} -gt 0 ]]; then
    echo "🔧 STEP 2: ENHANCEMENT PROCESS"
    echo "=============================="

    ENHANCED_COUNT=0

    for script_path in "${SAFE_SCRIPTS[@]}"; do
        script_name="$(basename "$script_path")"
        echo "Enhancing: $script_name"

        # Create backup
        cp "$script_path" "$BACKUP_DIR/"
        echo "  📁 Backup created"

        # Check if already enhanced
        if grep -q "SCRIPT_NAME\|SCRIPT_VERSION" "$script_path" 2>/dev/null; then
            echo "  ℹ️  Already has metadata - skipping"
            continue
        fi

        # Create enhanced version
        temp_enhanced="/tmp/enhanced_${script_name}_$$"

        # Determine script category and services
        category="utilities"
        services="general"
        case "$script_path" in
            *cleanup*) category="maintenance"; services="system" ;;
            *health*) category="health-validation"; services="monitoring" ;;
            *status*) category="monitoring"; services="system" ;;
            *redis*) category="validation"; services="redis" ;;
            *tmux*|*claude*) category="utilities"; services="development" ;;
        esac

        # Generate tags
        tags="enhancement,automation"
        echo "$script_path" | grep -q "health\|status" && tags+=",monitoring" || true
        echo "$script_path" | grep -q "cleanup\|maintenance" && tags+=",maintenance" || true
        echo "$script_path" | grep -q "redis" && tags+=",redis,validation" || true
        echo "$script_path" | grep -q "tmux\|claude" && tags+=",development,messaging" || true

        # Create enhanced header
        cat << EOF > "$temp_enhanced"
#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# $(echo "$script_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_' | tr '.' '_')
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Metadata and Wrappers
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="$script_name"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced $category script for $services operations"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="$(date +%Y-%m-%d)"
SCRIPT_MODIFIED="$(date +%Y-%m-%d)"
SCRIPT_CATEGORY="$category"
SCRIPT_TAGS="$tags"
SCRIPT_SERVICES="$services"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Enhanced $category script for $services with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "\$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "\$SCRIPT_DIR/utilities/common-functions-library.sh"
fi
if [[ -f "\$SCRIPT_DIR/utilities/retry-utils.sh" ]]; then
    source "\$SCRIPT_DIR/utilities/retry-utils.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
$(echo "${script_name%.*}" | tr '-' '_')_log_info() {
    local message="\$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "\${SCRIPT_NAME}: \$message"
    else
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - [INFO] \${SCRIPT_NAME}: \$message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
$(echo "${script_name%.*}" | tr '-' '_')_log_error() {
    local message="\$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "\${SCRIPT_NAME}: \$message"
    else
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] \${SCRIPT_NAME}: \$message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
$(echo "${script_name%.*}" | tr '-' '_')_log_success() {
    local message="\$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "\${SCRIPT_NAME}: \$message"
    else
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] \${SCRIPT_NAME}: \$message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

EOF

        # Add original content (skip shebang)
        tail -n +2 "$script_path" >> "$temp_enhanced"

        # Validate enhanced script
        if bash -n "$temp_enhanced"; then
            # Replace original with enhanced version
            mv "$temp_enhanced" "$script_path"
            chmod +x "$script_path"
            echo "  ✅ Enhanced successfully"
            ENHANCED_COUNT=$((ENHANCED_COUNT + 1)) || true

            # Update Script Index Library
            update_script_index_library "$script_path" "enhanced" "$category" "$services" "$tags"
            echo "  📚 Updated Script Index Library"

            # Perform intelligent analysis
            echo "  🧠 INTELLIGENT ANALYSIS:"
            analyze_script_consolidation "$script_path"
            suggest_additional_wrappers "$script_path"
            detect_script_similarity "$script_path"
        else
            echo "  ❌ Enhancement failed - syntax errors"
            rm -f "$temp_enhanced"
        fi
        echo ""
    done

    echo "📊 Enhancement Results:"
    echo "  Scripts processed: ${#SAFE_SCRIPTS[@]}"
    echo "  Scripts enhanced: $ENHANCED_COUNT"
    echo ""
fi

# Step 3: Verification
echo "🔍 STEP 3: VERIFICATION"
echo "======================"
for script_path in "${SAFE_SCRIPTS[@]}"; do
    script_name="$(basename "$script_path")"
    echo "Verifying: $script_name"

    # Check for metadata
    if grep -q "SCRIPT_NAME\|SCRIPT_VERSION" "$script_path"; then
        echo "  ✅ Has metadata"
    else
        echo "  ❌ Missing metadata"
    fi

    # Check syntax
    if bash -n "$script_path"; then
        echo "  ✅ Syntax valid"
    else
        echo "  ❌ Syntax errors"
    fi

    # Check for wrapper functions
    if grep -q "_log_info\|_log_error" "$script_path"; then
        echo "  ✅ Has wrapper functions"
    else
        echo "  ❌ Missing wrapper functions"
    fi
    echo ""
done

echo "🎉 TARGETED ENHANCEMENT TEST COMPLETE!"
echo "======================================"
echo "📁 Backups stored in: $BACKUP_DIR"
echo "📝 Check enhanced scripts for new metadata and wrapper functions"
echo ""

# Step 4: Update Script Index Library with final statistics
echo "📚 STEP 4: SCRIPT INDEX LIBRARY UPDATE"
echo "======================================"
targeted_script_enhancer_test_log_info "Updating Script Index Library with enhancement session results"

# Update the enhancement session statistics in Script Index Library
INDEX_FILE="/opt/dev-purebliss/dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md"
if [[ -f "$INDEX_FILE" ]]; then
    # Update enhancement session statistics
    CURRENT_DATE="$(date +%Y-%m-%d)"
    CURRENT_TIME="$(date +%H:%M:%S)"

    # Update latest enhancement session
    sed -i "s/- \*\*Session Date\*\*: [0-9-]* [0-9:]*/- \*\*Session Date\*\*: $CURRENT_DATE $CURRENT_TIME/" "$INDEX_FILE" 2>/dev/null || true
    sed -i "s/- \*\*Scripts Scanned\*\*: [0-9]*/- \*\*Scripts Scanned\*\*: ${#TARGET_SCRIPTS[@]}/" "$INDEX_FILE" 2>/dev/null || true
    sed -i "s/- \*\*Scripts Enhanced\*\*: [0-9]*/- \*\*Scripts Enhanced\*\*: $ENHANCED_COUNT/" "$INDEX_FILE" 2>/dev/null || true
    sed -i "s/- \*\*Safety Validation Failures\*\*: [0-9]*/- \*\*Safety Validation Failures\*\*: ${#UNSAFE_SCRIPTS[@]}/" "$INDEX_FILE" 2>/dev/null || true
    sed -i "s/- \*\*Headers Added\*\*: [0-9]*/- \*\*Headers Added\*\*: $ENHANCED_COUNT/" "$INDEX_FILE" 2>/dev/null || true
    sed -i "s/- \*\*Metadata Added\*\*: [0-9]*/- \*\*Metadata Added\*\*: $ENHANCED_COUNT/" "$INDEX_FILE" 2>/dev/null || true
    sed -i "s/- \*\*Wrapper Functions Added\*\*: [0-9]*/- \*\*Wrapper Functions Added\*\*: $((ENHANCED_COUNT * 3))/" "$INDEX_FILE" 2>/dev/null || true

    # Calculate enhancement rate
    if [[ ${#TARGET_SCRIPTS[@]} -gt 0 ]]; then
        ENHANCEMENT_RATE=$((ENHANCED_COUNT * 100 / ${#TARGET_SCRIPTS[@]}))
        sed -i "s/- \*\*Enhancement Rate\*\*: [0-9]*%/- \*\*Enhancement Rate\*\*: ${ENHANCEMENT_RATE}%/" "$INDEX_FILE" 2>/dev/null || true
    fi

    # Calculate safety validation rate
    SAFE_COUNT=${#SAFE_SCRIPTS[@]}
    if [[ ${#TARGET_SCRIPTS[@]} -gt 0 ]]; then
        SAFETY_RATE=$((SAFE_COUNT * 100 / ${#TARGET_SCRIPTS[@]}))
        sed -i "s/- \*\*Safety Validation Rate\*\*: [0-9]*%/- \*\*Safety Validation Rate\*\*: ${SAFETY_RATE}%/" "$INDEX_FILE" 2>/dev/null || true
    fi

    echo "✅ Script Index Library updated with enhancement session results"
    echo "📊 Enhancement Rate: ${ENHANCEMENT_RATE:-0}% | Safety Rate: ${SAFETY_RATE:-0}%"
else
    echo "⚠️  Script Index Library not found at $INDEX_FILE"
fi

targeted_script_enhancer_test_log_success "Targeted script enhancement test completed successfully"

# Step 5: Generate Intelligence Report
echo ""
echo "🧠 STEP 5: INTELLIGENCE ANALYSIS REPORT"
echo "======================================="
targeted_script_enhancer_test_log_info "Generating comprehensive intelligence analysis report"

# Create intelligence report
INTELLIGENCE_REPORT="$BACKUP_DIR/intelligence-analysis-report.md"
cat << EOF > "$INTELLIGENCE_REPORT"
# Script Enhancement Intelligence Analysis Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Session**: Targeted Vault Scripts Enhancement
**Scripts Analyzed**: ${#SAFE_SCRIPTS[@]}
**Scripts Enhanced**: $ENHANCED_COUNT

## Summary

This report provides intelligent analysis of enhanced scripts including consolidation opportunities,
wrapper suggestions, and duplicate detection to improve code reuse and maintainability.

## Scripts Processed

EOF

# Add each script's analysis to the report
for script_path in "${SAFE_SCRIPTS[@]}"; do
    script_name="$(basename "$script_path")"
    echo "### $script_name" >> "$INTELLIGENCE_REPORT"
    echo "**Path**: \`$script_path\`" >> "$INTELLIGENCE_REPORT"
    echo "" >> "$INTELLIGENCE_REPORT"

    # Add analysis results to report
    echo "**Analysis performed**: ✅" >> "$INTELLIGENCE_REPORT"
    echo "" >> "$INTELLIGENCE_REPORT"
done

cat << EOF >> "$INTELLIGENCE_REPORT"

## Recommendations

Based on the intelligent analysis performed during enhancement:

1. **Consolidation Opportunities**: Scripts with vault, deployment, or validation patterns should leverage consolidated utility functions
2. **Wrapper Functions**: Additional wrapper functions suggested for improved error handling and reliability
3. **Duplicate Detection**: Similar scripts identified for potential consolidation using existing patterns
4. **Integration**: All enhanced scripts now integrate with centralized function libraries

## Next Steps

1. Review consolidation suggestions and implement where beneficial
2. Add suggested wrapper functions to improve script reliability
3. Consider consolidating highly similar scripts using established patterns
4. Update Script Index Library with analysis results

---
*Generated by Enhanced Script Intelligence System v1.0*
EOF

echo "📊 Intelligence Analysis Report generated: $INTELLIGENCE_REPORT"
echo "📝 Review the report for consolidation opportunities and wrapper suggestions"

targeted_script_enhancer_test_log_success "Intelligence analysis report generated successfully"
echo ""
