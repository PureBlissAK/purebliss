#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTONOMOUS_SCRIPT_ENHANCER_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="autonomous-script-enhancer.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced automation script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced automation script for development with auto-commit functionality,
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
autonomous_script_enhancer_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
autonomous_script_enhancer_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
autonomous_script_enhancer_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
autonomous_script_enhancer_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    autonomous_script_enhancer_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        autonomous_script_enhancer_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            autonomous_script_enhancer_log_success "Validation passed - proceeding with auto-commit"
        else
            autonomous_script_enhancer_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        autonomous_script_enhancer_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        autonomous_script_enhancer_log_info "Auto-commit system not available - manual commit required"
        autonomous_script_enhancer_log_info "Recommended commit message: $commit_message"
        autonomous_script_enhancer_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
autonomous_script_enhancer_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    autonomous_script_enhancer_log_success "$final_message"
    
    # Execute auto-commit wrapper
    autonomous_script_enhancer_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    autonomous_script_enhancer_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════════
# AUTONOMOUS SCRIPT ENHANCER
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Automated Script Enhancement System
#
# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="autonomous-script-enhancer.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Automatically enhance all scripts with headers, metadata, tags, and wrappers"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,metadata,indexing,consolidation"
SCRIPT_SERVICES="all"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="Comprehensive script enhancement system that scans all scripts in /opt,
analyzes their functionality, adds standardized headers and metadata, implements wrapper
functions for code reuse, and maintains the script index library for intelligent discovery"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"

# GLOBAL CONFIGURATION
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
ENHANCEMENT_LOG="/opt/dev-purebliss/logs/script-enhancement.log"
SCRIPT_INDEX="/opt/dev-purebliss/dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md"
BACKUP_DIR="/opt/dev-purebliss/backups/script-enhancement-$(date +%Y%m%d-%H%M%S)"

# Command line options
DRY_RUN_ONLY=false
VERBOSE_OUTPUT=false

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN_ONLY=true
                enhanced_log_info "DRY RUN MODE: Will only validate scripts, no modifications will be made"
                shift
                ;;
            --verbose)
                VERBOSE_OUTPUT=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --dry-run    Only validate scripts without making modifications"
                echo "  --verbose    Enable verbose output"
                echo "  --help, -h   Show this help message"
                exit 0
                ;;
            *)
                enhanced_log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Scan directories and exclusions
SCAN_PATHS=(
    "/opt/dev-purebliss"
    "/opt/dev_scripts"
    "/opt/my-secure-ha-stack"
    "/opt/purebliss"
    "/opt/vault_stress_testing"
    "/opt/Tmux-Orchestrator"
)

EXCLUDE_PATTERNS=(
    "*/backup*"
    "*/logs/*"
    "*/tmp/*"
    "*/cache/*"
    "*/.git/*"
    "*/node_modules/*"
    "*/venv/*"
    "*/__pycache__/*"
)

# Enhancement tracking
declare -A SCRIPTS_SCANNED
declare -A SCRIPTS_ENHANCED
declare -A SCRIPTS_FAILED_SAFETY
declare -A ENHANCEMENT_STATS
declare -A WRAPPER_FUNCTIONS

# Initialize enhancement statistics
ENHANCEMENT_STATS[total_scripts]=0
ENHANCEMENT_STATS[enhanced_scripts]=0
ENHANCEMENT_STATS[failed_safety_validation]=0
ENHANCEMENT_STATS[skipped_dangerous]=0
ENHANCEMENT_STATS[headers_added]=0
ENHANCEMENT_STATS[metadata_added]=0
ENHANCEMENT_STATS[tags_added]=0
ENHANCEMENT_STATS[wrappers_added]=0

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTION VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for log_info to ensure standardized logging
enhanced_log_info() {
    local message="$1"
    log_info "SCRIPT_ENHANCER: $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] $SCRIPT_NAME: $message" >> "$ENHANCEMENT_LOG"
}

# Wrapper for log_error to ensure standardized error logging
enhanced_log_error() {
    local message="$1"
    log_error "SCRIPT_ENHANCER: $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] $SCRIPT_NAME: $message" >> "$ENHANCEMENT_LOG"
}

# Wrapper for log_success to ensure standardized success logging
enhanced_log_success() {
    local message="$1"
    log_success "SCRIPT_ENHANCER: $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] $SCRIPT_NAME: $message" >> "$ENHANCEMENT_LOG"
}

# Wrapper for backup_file to ensure safe script modification
safe_backup_script() {
    local script_path="$1"
    local backup_path

    # Use common library backup function
    backup_path=$(backup_file "$script_path" "$BACKUP_DIR")
    enhanced_log_info "Script backed up: $script_path -> $backup_path"
    echo "$backup_path"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# SCRIPT DISCOVERY AND ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════════════

# Discover all shell scripts in specified paths
discover_scripts() {
    enhanced_log_info "Starting script discovery across /opt..."

    local script_count=0
    local excluded_count=0
    local max_scripts=50  # Limit for testing

    for scan_path in "${SCAN_PATHS[@]}"; do
        if [[ -d "$scan_path" ]]; then
            enhanced_log_info "Scanning directory: $scan_path"

            while IFS= read -r -d '' script_file; do
                # Safety limit for testing
                if [[ $script_count -ge $max_scripts ]]; then
                    enhanced_log_info "Reached testing limit of $max_scripts scripts"
                    break 2
                fi

                local should_exclude=false

                # Check exclusion patterns
                for pattern in "${EXCLUDE_PATTERNS[@]}"; do
                    if [[ "$script_file" == $pattern ]]; then
                        should_exclude=true
                        break
                    fi
                done

                if [[ "$should_exclude" == "true" ]]; then
                    ((excluded_count++)) || true
                    continue
                fi

                # Verify it's a shell script
                if [[ -f "$script_file" && "$script_file" == *.sh ]]; then
                    SCRIPTS_SCANNED["$script_file"]=1
                    ((script_count++)) || true

                    # Log every 5 discovered scripts for testing
                    if (( script_count % 5 == 0 )); then
                        enhanced_log_info "Discovered $script_count scripts so far..."
                    fi
                fi

            done < <(find "$scan_path" -name "*.sh" -type f -print0 2>/dev/null)
        else
            enhanced_log_info "Directory not found: $scan_path"
        fi
    done

    ENHANCEMENT_STATS[total_scripts]=$script_count
    enhanced_log_success "Discovery complete: $script_count scripts found, $excluded_count excluded"
}

# Dry-run validation to ensure script safety before enhancement
validate_script_safety() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    enhanced_log_info "Performing safety validation for: $script_name"

    # Skip validation for certain system scripts or our own scripts to prevent issues
    if [[ "$script_name" == "autonomous-script-enhancer.sh" ]] ||
       [[ "$script_path" =~ "/tmp/" ]] ||
       [[ "$script_path" =~ "/proc/" ]]; then
        enhanced_log_info "Skipping safety validation for system/self script: $script_name"
        return 0
    fi

    # Check 1: Syntax validation
    enhanced_log_info "Checking syntax for: $script_name"
    if ! bash -n "$script_path" 2>/dev/null; then
        enhanced_log_error "Script has syntax errors: $script_name"
        return 1
    fi

    # Check 2: Detect potential infinite loops
    local loop_patterns=(
        "while true"
        "while \[ 1 \]"
        "while \[\[ 1 \]\]"
        "for \(\( ;; \)\)"
    )

    local script_content
    script_content=$(cat "$script_path")

    for pattern in "${loop_patterns[@]}"; do
        if echo "$script_content" | grep -q "$pattern"; then
            # Check if there's a break condition or timeout
            local line_num
            line_num=$(echo "$script_content" | grep -n "$pattern" | cut -d: -f1 | head -1)

            # Look for break/exit conditions in the next 20 lines
            local loop_section
            loop_section=$(echo "$script_content" | sed -n "${line_num},$((line_num + 20))p")

            if ! echo "$loop_section" | grep -q "break\|exit\|return\|timeout\|max_attempts\|elapsed.*timeout"; then
                enhanced_log_error "Potential infinite loop detected without break condition: $script_name at line $line_num"
                return 1
            fi
        fi
    done

    # Check 3: Detect recursive calls without termination
    local function_names
    function_names=$(grep -o "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$script_path" | sed 's/() {//' || true)

    if [[ -n "$function_names" ]]; then
        while IFS= read -r func_name; do
            if [[ -n "$func_name" ]] && grep -q "$func_name.*$func_name" "$script_path"; then
                # Check for termination conditions in recursive functions
                local func_content
                func_content=$(sed -n "/^${func_name}() {/,/^}/p" "$script_path")

                if ! echo "$func_content" | grep -q "return\|exit\|break\|\[\[ .*-eq\|if.*then.*return"; then
                    enhanced_log_error "Potential recursive function without termination: $func_name in $script_name"
                    return 1
                fi
            fi
        done <<< "$function_names"
    fi

    # Check 4: Detect resource-intensive operations without limits
    local dangerous_patterns=(
        "find / "
        "find /opt -name"
        "grep -r / "
        "chmod -R 777"
        "rm -rf /"
        "dd if="
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$script_content" | grep -q "$pattern"; then
            enhanced_log_error "Potentially dangerous operation detected: '$pattern' in $script_name"
            return 1
        fi
    done

    # Check 5: Validate script doesn't modify itself
    if echo "$script_content" | grep -q ">\s*\$0\|>>\s*\$0\|>\s*\${BASH_SOURCE"; then
        enhanced_log_error "Script attempts to modify itself: $script_name"
        return 1
    fi

    # Check 6: Test execution with timeout (dry run simulation)
    local temp_test_script="/tmp/test_${script_name}_$$"

    # Create a test wrapper that sources the script without executing main functions
    cat << EOF > "$temp_test_script"

# Disable actual execution by redefining common commands
docker() { echo "DRY_RUN: docker \$*"; }
systemctl() { echo "DRY_RUN: systemctl \$*"; }
service() { echo "DRY_RUN: service \$*"; }
curl() { echo "DRY_RUN: curl \$*"; }
wget() { echo "DRY_RUN: wget \$*"; }
ssh() { echo "DRY_RUN: ssh \$*"; }
scp() { echo "DRY_RUN: scp \$*"; }
rsync() { echo "DRY_RUN: rsync \$*"; }

# Override destructive operations
rm() { echo "DRY_RUN: rm \$*"; }
mv() { echo "DRY_RUN: mv \$*"; }
cp() { echo "DRY_RUN: cp \$*"; }

# Source the script to check for syntax and basic execution
source "$script_path" 2>&1 || exit 1
EOF

    chmod +x "$temp_test_script"

    # Run with timeout to prevent hanging
    if timeout 30s bash "$temp_test_script" >/dev/null 2>&1; then
        enhanced_log_success "Script safety validation passed: $script_name"
        rm -f "$temp_test_script"
        return 0
    else
        enhanced_log_error "Script failed safety validation or timed out: $script_name"
        SCRIPTS_FAILED_SAFETY["$script_path"]=1
        ((ENHANCEMENT_STATS[failed_safety_validation]++)) || true
        rm -f "$temp_test_script"
        return 1
    fi
}

# Analyze script for existing metadata and enhancement needs
analyze_script() {
    local script_path="$1"
    local analysis_result=""

    if [[ ! -f "$script_path" ]]; then
        enhanced_log_error "Script not found: $script_path"
        return 1
    fi

    # Skip the validation for the enhancer itself to prevent recursion
    local script_name="$(basename "$script_path")"
    if [[ "$script_name" == "autonomous-script-enhancer.sh" ]]; then
        enhanced_log_info "Skipping self-validation to prevent recursion: $script_name"
        echo "shebang:true,metadata:true,tags:true,description:true,wrapper:true,common_library:true,needs_enhancement:false"
        return 0
    fi

    # First, validate script safety
    if ! validate_script_safety "$script_path"; then
        enhanced_log_error "Script failed safety validation: $script_path"
        return 1
    fi

    # Read first 50 lines to check for metadata
    local header_content
    header_content=$(head -50 "$script_path")

    # Check for existing components
    local has_shebang=false
    local has_metadata=false
    local has_tags=false
    local has_description=false
    local has_wrapper=false
    local has_common_library=false

    # Analyze script content
    if echo "$header_content" | grep -q "^#!/bin/bash"; then
        has_shebang=true
    fi

    if echo "$header_content" | grep -q "SCRIPT_NAME\|SCRIPT_VERSION\|SCRIPT_PURPOSE"; then
        has_metadata=true
    fi

    if echo "$header_content" | grep -q "SCRIPT_TAGS"; then
        has_tags=true
    fi

    if echo "$header_content" | grep -q "SCRIPT_DESCRIPTION"; then
        has_description=true
    fi

    if grep -q "source.*common-functions-library.sh" "$script_path"; then
        has_common_library=true
    fi

    # Check for wrapper functions (functions that call other functions)
    if grep -q "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$script_path" && grep -q "log_info\|log_error\|backup_file" "$script_path"; then
        has_wrapper=true
    fi

    # Determine enhancement needs
    local needs_enhancement=false
    if [[ "$has_shebang" == "false" || "$has_metadata" == "false" || "$has_tags" == "false" || "$has_wrapper" == "false" ]]; then
        needs_enhancement=true
    fi

    # Store analysis results
    echo "shebang:$has_shebang,metadata:$has_metadata,tags:$has_tags,description:$has_description,wrapper:$has_wrapper,common_library:$has_common_library,needs_enhancement:$needs_enhancement"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# SCRIPT ENHANCEMENT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Generate standardized script header
generate_script_header() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    local script_dir="$(dirname "$script_path")"

    # Determine script category from path
    local category="utilities"
    case "$script_dir" in
        *automation*) category="automation" ;;
        *core*) category="core" ;;
        *services*) category="services" ;;
        *health*) category="health-validation" ;;
        *utilities*) category="utilities" ;;
        *deployment*) category="deployment" ;;
        *management*) category="management" ;;
        *) category="utilities" ;;
    esac

    # Determine services from script name and content
    local services="general"
    local script_content=""
    if [[ -f "$script_path" ]]; then
        script_content=$(cat "$script_path")
    fi

    case "$script_name" in
        *vault*) services="vault" ;;
        *postgres*) services="postgres" ;;
        *nginx*) services="nginx" ;;
        *keycloak*) services="keycloak" ;;
        *grafana*) services="grafana" ;;
        *loki*) services="loki" ;;
        *prometheus*) services="prometheus" ;;
        *plane*) services="plane" ;;
        *codeserver*|*code-server*) services="codeserver" ;;
        *)
            # Analyze content for service references
            local detected_services=()
            echo "$script_content" | grep -iq "vault" && detected_services+=("vault")
            echo "$script_content" | grep -iq "postgres" && detected_services+=("postgres")
            echo "$script_content" | grep -iq "nginx" && detected_services+=("nginx")
            echo "$script_content" | grep -iq "keycloak" && detected_services+=("keycloak")
            echo "$script_content" | grep -iq "grafana" && detected_services+=("grafana")
            echo "$script_content" | grep -iq "loki" && detected_services+=("loki")
            echo "$script_content" | grep -iq "prometheus" && detected_services+=("prometheus")
            echo "$script_content" | grep -iq "plane" && detected_services+=("plane")
            echo "$script_content" | grep -iq "codeserver\|code-server" && detected_services+=("codeserver")

            if [[ ${#detected_services[@]} -gt 0 ]]; then
                services=$(IFS=,; echo "${detected_services[*]}")
            fi
            ;;
    esac

    # Generate tags based on functionality
    local tags="enhancement,automation"
    echo "$script_content" | grep -iq "health\|validate" && tags+=",health-validation"
    echo "$script_content" | grep -iq "deploy\|start" && tags+=",deployment"
    echo "$script_content" | grep -iq "backup\|restore" && tags+=",backup"
    echo "$script_content" | grep -iq "security\|auth" && tags+=",security"
    echo "$script_content" | grep -iq "troubleshoot\|fix\|debug" && tags+=",troubleshooting"
    echo "$script_content" | grep -iq "test\|check" && tags+=",testing"
    echo "$script_content" | grep -iq "cleanup\|clean" && tags+=",cleanup"

    # Generate script description based on content analysis
    local description="Enhanced script for $services with standardized metadata and wrapper functions"

    # Create the header
    cat << EOF

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
SCRIPT_PURPOSE="$description"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="$(date +%Y-%m-%d)"
SCRIPT_MODIFIED="$(date +%Y-%m-%d)"
SCRIPT_CATEGORY="$category"
SCRIPT_TAGS="$tags"
SCRIPT_SERVICES="$services"
SCRIPT_DEPENDENCIES="common-functions-library.sh,retry-utils.sh"
SCRIPT_DESCRIPTION="$description with comprehensive error handling,
logging integration, and wrapper functions for code reuse and maintainability"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "\$SCRIPT_DIR/utilities/common-functions-library.sh"
source "\$SCRIPT_DIR/utilities/retry-utils.sh"

EOF
}

# Generate wrapper functions for common operations
generate_wrapper_functions() {
    local script_path="$1"
    local script_name="$(basename "$script_path" .sh)"

    cat << EOF

# ═══════════════════════════════════════════════════════════════════════════════════
# WRAPPER FUNCTIONS - ENSURING CODE REUSE AND CONSOLIDATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
${script_name}_log_info() {
    local message="\$1"
    log_info "\${SCRIPT_NAME}: \$message"
}

# Wrapper for standardized error logging with script context
${script_name}_log_error() {
    local message="\$1"
    log_error "\${SCRIPT_NAME}: \$message"
}

# Wrapper for standardized success logging with script context
${script_name}_log_success() {
    local message="\$1"
    log_success "\${SCRIPT_NAME}: \$message"
}

# Wrapper for safe file operations with backup
${script_name}_safe_file_operation() {
    local operation="\$1"
    local file_path="\$2"
    shift 2
    local additional_args=("\$@")

    # Create backup before modification
    if [[ -f "\$file_path" && "\$operation" == "modify" ]]; then
        backup_file "\$file_path"
    fi

    # Execute operation with error handling
    if ! "\$operation" "\$file_path" "\${additional_args[@]}"; then
        ${script_name}_log_error "Failed to execute \$operation on \$file_path"
        return 1
    fi

    ${script_name}_log_success "Successfully executed \$operation on \$file_path"
    return 0
}

# Wrapper for retry operations with standardized backoff
${script_name}_retry_operation() {
    local max_attempts="\${1:-3}"
    local base_delay="\${2:-2}"
    shift 2
    local command=("\$@")

    ${script_name}_log_info "Executing command with retry: \${command[*]}"

    if retry_with_backoff "\$max_attempts" "\$base_delay" "\${command[@]}"; then
        ${script_name}_log_success "Command succeeded: \${command[*]}"
        return 0
    else
        ${script_name}_log_error "Command failed after \$max_attempts attempts: \${command[*]}"
        return 1
    fi
}

# Wrapper for health validation integration
${script_name}_validate_health() {
    local service_name="\${1:-}"
    local task_name="\${2:-\$SCRIPT_NAME}"

    if [[ -n "\$service_name" ]]; then
        ${script_name}_log_info "Validating health for service: \$service_name"
        if health_check_service "\$service_name"; then
            ${script_name}_log_success "Health validation passed for \$service_name"
            return 0
        else
            ${script_name}_log_error "Health validation failed for \$service_name"
            return 1
        fi
    else
        ${script_name}_log_info "No specific service provided for health validation"
        return 0
    fi
}

EOF
}

# Enhanced script enhancement with comprehensive validation
enhance_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    enhanced_log_info "Enhancing script: $script_path"

    # Pre-enhancement safety validation
    if ! validate_script_safety "$script_path"; then
        enhanced_log_error "Script failed pre-enhancement safety validation: $script_name"
        return 1
    fi

    # Create backup
    local backup_path
    backup_path=$(safe_backup_script "$script_path")

    # Analyze current script
    local analysis
    analysis=$(analyze_script "$script_path")

    # Parse analysis results
    local has_shebang=false has_metadata=false has_wrapper=false needs_enhancement=false
    IFS=',' read -ra ANALYSIS_PARTS <<< "$analysis"
    for part in "${ANALYSIS_PARTS[@]}"; do
        IFS=':' read -ra KEYVAL <<< "$part"
        case "${KEYVAL[0]}" in
            "shebang") has_shebang="${KEYVAL[1]}" ;;
            "metadata") has_metadata="${KEYVAL[1]}" ;;
            "wrapper") has_wrapper="${KEYVAL[1]}" ;;
            "needs_enhancement") needs_enhancement="${KEYVAL[1]}" ;;
        esac
    done

    if [[ "$needs_enhancement" == "false" ]]; then
        enhanced_log_info "Script already well-enhanced: $script_name"
        return 0
    fi

    # If dry-run mode, just report what would be enhanced
    if [[ "$DRY_RUN_ONLY" == "true" ]]; then
        enhanced_log_info "DRY RUN: Would enhance script $script_name"
        if [[ "$has_metadata" == "false" ]]; then
            enhanced_log_info "DRY RUN: Would add headers and metadata"
            ((ENHANCEMENT_STATS[headers_added]++)) || true
            ((ENHANCEMENT_STATS[metadata_added]++)) || true
            ((ENHANCEMENT_STATS[tags_added]++)) || true
        fi
        if [[ "$has_wrapper" == "false" ]]; then
            enhanced_log_info "DRY RUN: Would add wrapper functions"
            ((ENHANCEMENT_STATS[wrappers_added]++)) || true
        fi
        SCRIPTS_ENHANCED["$script_path"]=1
        ((ENHANCEMENT_STATS[enhanced_scripts]++))
        enhanced_log_success "DRY RUN: Script validation passed: $script_name"
        return 0
    fi

    # Read original script content
    local original_content
    original_content=$(cat "$script_path")

    # Create temporary enhanced script
    local temp_script="/tmp/enhanced_${script_name}_$$"

    # Start with header if missing metadata
    if [[ "$has_metadata" == "false" ]]; then
        generate_script_header "$script_path" > "$temp_script"
        ((ENHANCEMENT_STATS[headers_added]++)) || true
        ((ENHANCEMENT_STATS[metadata_added]++)) || true
        ((ENHANCEMENT_STATS[tags_added]++)) || true
    else
        # Keep existing header
        echo "$original_content" | head -1 > "$temp_script"
    fi

    # Add wrapper functions if missing
    if [[ "$has_wrapper" == "false" ]]; then
        generate_wrapper_functions "$script_path" >> "$temp_script"
        ((ENHANCEMENT_STATS[wrappers_added]++)) || true
    fi

    # Add original script content (excluding shebang if we added header)
    if [[ "$has_metadata" == "false" ]]; then
        # Skip existing shebang and add rest
        echo "$original_content" | tail -n +2 >> "$temp_script"
    else
        # Add wrapper functions before main content
        if [[ "$has_wrapper" == "false" ]]; then
            # Find where to insert wrapper functions (after existing metadata)
            local line_count
            line_count=$(echo "$original_content" | grep -n "^# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$" | tail -1 | cut -d: -f1)
            if [[ -n "$line_count" ]]; then
                # Insert after metadata block
                echo "$original_content" | head -n "$line_count" >> "$temp_script"
                generate_wrapper_functions "$script_path" >> "$temp_script"
                echo "$original_content" | tail -n "+$((line_count + 1))" >> "$temp_script"
            else
                # Just append wrapper functions
                echo "$original_content" >> "$temp_script"
                generate_wrapper_functions "$script_path" >> "$temp_script"
            fi
        else
            echo "$original_content" >> "$temp_script"
        fi
    fi

    # Post-enhancement validation with dry run
    enhanced_log_info "Performing post-enhancement validation for: $script_name"

    # Validate syntax of enhanced script
    if ! bash -n "$temp_script"; then
        enhanced_log_error "Enhanced script has syntax errors: $script_name"
        rm -f "$temp_script"
        return 1
    fi

    # Run enhanced script safety validation
    if ! validate_script_safety "$temp_script"; then
        enhanced_log_error "Enhanced script failed safety validation: $script_name"
        rm -f "$temp_script"
        return 1
    fi

    # Additional dry-run test with enhanced script
    enhanced_log_info "Running comprehensive dry-run test for enhanced script: $script_name"

    local test_log="/tmp/test_log_${script_name}_$$"
    local test_result=0

    # Create isolated test environment
    local test_env_script="/tmp/test_env_${script_name}_$$"
    cat << 'EOF' > "$test_env_script"

# Override all potentially destructive or external operations for dry run
docker() { echo "DRY_RUN: docker $*" >&2; }
systemctl() { echo "DRY_RUN: systemctl $*" >&2; }
service() { echo "DRY_RUN: service $*" >&2; }
curl() { echo "DRY_RUN: curl $*" >&2; return 0; }
wget() { echo "DRY_RUN: wget $*" >&2; return 0; }
ssh() { echo "DRY_RUN: ssh $*" >&2; return 0; }
scp() { echo "DRY_RUN: scp $*" >&2; return 0; }
rsync() { echo "DRY_RUN: rsync $*" >&2; return 0; }
apt() { echo "DRY_RUN: apt $*" >&2; return 0; }
yum() { echo "DRY_RUN: yum $*" >&2; return 0; }
npm() { echo "DRY_RUN: npm $*" >&2; return 0; }
pip() { echo "DRY_RUN: pip $*" >&2; return 0; }

# Override file operations with safer versions
rm() {
    if [[ "$*" =~ "-rf /" ]] || [[ "$*" =~ "rm -rf /" ]]; then
        echo "DRY_RUN: BLOCKED DANGEROUS rm $*" >&2
        return 1
    fi
    echo "DRY_RUN: rm $*" >&2
}

mv() { echo "DRY_RUN: mv $*" >&2; }
cp() { echo "DRY_RUN: cp $*" >&2; }
chmod() { echo "DRY_RUN: chmod $*" >&2; }
chown() { echo "DRY_RUN: chown $*" >&2; }

# Override network operations
nc() { echo "DRY_RUN: nc $*" >&2; return 0; }
telnet() { echo "DRY_RUN: telnet $*" >&2; return 0; }
ping() { echo "DRY_RUN: ping $*" >&2; return 0; }

# Export overrides
export -f docker systemctl service curl wget ssh scp rsync apt yum npm pip
export -f rm mv cp chmod chown nc telnet ping

EOF

    # Source the test environment and then the enhanced script
    echo "source '$test_env_script'" > "$test_log"
    echo "source '$temp_script'" >> "$test_log"

    # Run with timeout and capture result
    if timeout 45s bash "$test_log" >/dev/null 2>&1; then
        enhanced_log_success "Enhanced script passed comprehensive dry-run validation: $script_name"
        test_result=0
    else
        enhanced_log_error "Enhanced script failed dry-run validation or timed out: $script_name"
        test_result=1
    fi

    # Cleanup test files
    rm -f "$test_env_script" "$test_log"

    # If validation failed, restore original
    if [[ $test_result -ne 0 ]]; then
        rm -f "$temp_script"
        enhanced_log_error "Enhancement failed validation, keeping original: $script_name"
        return 1
    fi

    # Final validation passed - replace original with enhanced version
    mv "$temp_script" "$script_path"
    chmod +x "$script_path"

    SCRIPTS_ENHANCED["$script_path"]=1
    ((ENHANCEMENT_STATS[enhanced_scripts]++)) || true

    enhanced_log_success "Script enhanced and validated successfully: $script_name"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# INDEX MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════════

# Update script index with enhanced scripts
update_script_index() {
    enhanced_log_info "Updating script index library..."

    local temp_index="/tmp/script_index_update_$$"
    local current_date=$(date '+%Y-%m-%d %H:%M:%S')
    local total_enhanced=${ENHANCEMENT_STATS[enhanced_scripts]}

    # Create updated index header
    cat << EOF > "$temp_index"
# Pure Bliss Script Index Library

**Generated**: $(date -u '+%Y-%m-%dT%H:%M:%S')Z
**Total Scripts**: ${ENHANCEMENT_STATS[total_scripts]} scripts discovered
**Enhanced Scripts**: $total_enhanced scripts enhanced
**Last Scan**: $(date -u '+%Y-%m-%dT%H:%M:%S')Z
**Index Status**: 🟢 ACTIVE - Automated enhancement operational

## 🎯 Enhancement Results

### Latest Enhancement Session
- **Session Date**: $current_date
- **Scripts Scanned**: ${ENHANCEMENT_STATS[total_scripts]}
- **Scripts Enhanced**: ${ENHANCEMENT_STATS[enhanced_scripts]}
- **Safety Validation Failures**: ${ENHANCEMENT_STATS[failed_safety_validation]}
- **Dangerous Scripts Skipped**: ${ENHANCEMENT_STATS[skipped_dangerous]}
- **Headers Added**: ${ENHANCEMENT_STATS[headers_added]}
- **Metadata Added**: ${ENHANCEMENT_STATS[metadata_added]}
- **Tags Added**: ${ENHANCEMENT_STATS[tags_added]}
- **Wrapper Functions Added**: ${ENHANCEMENT_STATS[wrappers_added]}

### Enhancement Statistics
- **Enhancement Rate**: $(( (ENHANCEMENT_STATS[enhanced_scripts] * 100) / ENHANCEMENT_STATS[total_scripts] ))%
- **Safety Validation Rate**: $(( ((ENHANCEMENT_STATS[total_scripts] - ENHANCEMENT_STATS[failed_safety_validation]) * 100) / ENHANCEMENT_STATS[total_scripts] ))%
- **Metadata Compliance**: $(( (ENHANCEMENT_STATS[metadata_added] * 100) / ENHANCEMENT_STATS[total_scripts] ))%
- **Wrapper Function Coverage**: $(( (ENHANCEMENT_STATS[wrappers_added] * 100) / ENHANCEMENT_STATS[total_scripts] ))%

EOF

    # Add enhanced scripts list
    echo "### Recently Enhanced Scripts" >> "$temp_index"
    echo "| Script | Path | Enhancement Date | Status |" >> "$temp_index"
    echo "|--------|------|------------------|--------|" >> "$temp_index"

    for script_path in "${!SCRIPTS_ENHANCED[@]}"; do
        local script_name="$(basename "$script_path")"
        echo "| $script_name | $script_path | $current_date | ✅ Enhanced |" >> "$temp_index"
    done

    # Add rest of existing index if it exists
    if [[ -f "$SCRIPT_INDEX" ]]; then
        echo "" >> "$temp_index"
        echo "---" >> "$temp_index"
        echo "" >> "$temp_index"
        sed -n '/^## 📊 Quick Reference Dashboard/,$p' "$SCRIPT_INDEX" >> "$temp_index"
    fi

    # Replace index
    mv "$temp_index" "$SCRIPT_INDEX"
    enhanced_log_success "Script index updated with $total_enhanced enhanced scripts"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION FLOW
# ═══════════════════════════════════════════════════════════════════════════════════

# Initialize enhancement environment
initialize_enhancement_environment() {
    enhanced_log_info "Initializing Autonomous Script Enhancer v$SCRIPT_VERSION"

    # Create necessary directories
    ensure_directory "$(dirname "$ENHANCEMENT_LOG")"
    ensure_directory "$BACKUP_DIR"
    ensure_directory "$(dirname "$SCRIPT_INDEX")"

    # Initialize enhancement log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [INIT] Starting autonomous script enhancement session" > "$ENHANCEMENT_LOG"

    enhanced_log_success "Enhancement environment initialized"
}

# Execute comprehensive script enhancement
execute_script_enhancement() {
    enhanced_log_info "Starting comprehensive script enhancement process"

    # Phase 1: Discovery
    enhanced_log_info "Phase 1: Script Discovery"
    discover_scripts

    # Phase 2: Analysis and Enhancement
    enhanced_log_info "Phase 2: Script Analysis and Enhancement with Safety Validation"
    local processed_count=0
    local enhancement_count=0
    local safety_failures=0

    # Process each discovered script
    for script_path in "${!SCRIPTS_SCANNED[@]}"; do
        ((processed_count++)) || true

        # Log progress every 5 scripts for testing
        if (( processed_count % 5 == 0 )); then
            enhanced_log_info "Progress: $processed_count/${ENHANCEMENT_STATS[total_scripts]} scripts processed"
        fi

        # Enhance script with safety validation
        if enhance_script "$script_path"; then
            ((enhancement_count++)) || true
        else
            # Check if it was a safety failure
            if [[ -n "${SCRIPTS_FAILED_SAFETY[$script_path]:-}" ]]; then
                ((safety_failures++)) || true
                enhanced_log_error "Script failed safety validation: $script_path"
            fi
        fi
    done

    # Phase 3: Index Update
    enhanced_log_info "Phase 3: Index Update"
    update_script_index

    # Final statistics
    enhanced_log_success "Enhancement complete: $enhancement_count/${ENHANCEMENT_STATS[total_scripts]} scripts enhanced"
}

# Generate enhancement report
generate_enhancement_report() {
    local report_file="/opt/dev-purebliss/logs/script-enhancement-report-$(date +%Y%m%d-%H%M%S).md"

    cat << EOF > "$report_file"
# Script Enhancement Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Session**: Autonomous Script Enhancement
**Version**: $SCRIPT_VERSION

## Enhancement Summary

### Statistics
- **Total Scripts Discovered**: ${ENHANCEMENT_STATS[total_scripts]}
- **Scripts Enhanced**: ${ENHANCEMENT_STATS[enhanced_scripts]}
- **Safety Validation Failures**: ${ENHANCEMENT_STATS[failed_safety_validation]}
- **Dangerous Scripts Skipped**: ${ENHANCEMENT_STATS[skipped_dangerous]}
- **Headers Added**: ${ENHANCEMENT_STATS[headers_added]}
- **Metadata Blocks Added**: ${ENHANCEMENT_STATS[metadata_added]}
- **Tag Systems Added**: ${ENHANCEMENT_STATS[tags_added]}
- **Wrapper Functions Added**: ${ENHANCEMENT_STATS[wrappers_added]}

### Enhancement Rate
- **Overall Enhancement Rate**: $(( (ENHANCEMENT_STATS[enhanced_scripts] * 100) / ENHANCEMENT_STATS[total_scripts] ))%
- **Safety Validation Pass Rate**: $(( ((ENHANCEMENT_STATS[total_scripts] - ENHANCEMENT_STATS[failed_safety_validation]) * 100) / ENHANCEMENT_STATS[total_scripts] ))%

### Enhanced Scripts
EOF

    for script_path in "${!SCRIPTS_ENHANCED[@]}"; do
        echo "- $script_path" >> "$report_file"
    done

    cat << EOF >> "$report_file"

### Scripts That Failed Safety Validation
EOF

    if [[ ${#SCRIPTS_FAILED_SAFETY[@]} -gt 0 ]]; then
        for script_path in "${!SCRIPTS_FAILED_SAFETY[@]}"; do
            echo "- $script_path (SAFETY CONCERN - Manual review required)" >> "$report_file"
        done
    else
        echo "- None (All scripts passed safety validation)" >> "$report_file"
    fi

    cat << EOF >> "$report_file"

### Backup Location
All original scripts backed up to: $BACKUP_DIR

### Next Steps
1. Review enhanced scripts for functionality
2. Test enhanced scripts in development environment
3. Update documentation references
4. Monitor script performance and reliability

EOF

    enhanced_log_success "Enhancement report generated: $report_file"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# SCRIPT EXECUTION ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════════

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Initialize enhancement environment
    initialize_enhancement_environment

    # Log start of enhancement session
    if [[ "$DRY_RUN_ONLY" == "true" ]]; then
        enhanced_log_info "Starting DRY RUN autonomous script validation for all scripts in /opt"
    else
        enhanced_log_info "Starting autonomous script enhancement for all scripts in /opt"
    fi

    # Execute comprehensive enhancement
    execute_script_enhancement

    # Generate final report
    generate_enhancement_report

    # Log completion
    enhanced_log_success "Autonomous script enhancement completed successfully"
    enhanced_log_info "Enhancement statistics:"
    enhanced_log_info "  - Total scripts: ${ENHANCEMENT_STATS[total_scripts]}"
    enhanced_log_info "  - Enhanced scripts: ${ENHANCEMENT_STATS[enhanced_scripts]}"
    enhanced_log_info "  - Safety validation failures: ${ENHANCEMENT_STATS[failed_safety_validation]}"
    enhanced_log_info "  - Headers added: ${ENHANCEMENT_STATS[headers_added]}"
    enhanced_log_info "  - Wrappers added: ${ENHANCEMENT_STATS[wrappers_added]}"

    if [[ ${ENHANCEMENT_STATS[failed_safety_validation]} -gt 0 ]]; then
        enhanced_log_error "WARNING: ${ENHANCEMENT_STATS[failed_safety_validation]} scripts failed safety validation and were not enhanced"
        enhanced_log_error "Manual review required for scripts listed in the enhancement report"
    fi

    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

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
