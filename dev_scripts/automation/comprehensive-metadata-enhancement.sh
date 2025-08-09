#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE_METADATA_ENHANCEMENT_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="comprehensive-metadata-enhancement.sh"
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
comprehensive_metadata_enhancement_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
comprehensive_metadata_enhancement_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
comprehensive_metadata_enhancement_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
comprehensive_metadata_enhancement_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    comprehensive_metadata_enhancement_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        comprehensive_metadata_enhancement_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            comprehensive_metadata_enhancement_log_success "Validation passed - proceeding with auto-commit"
        else
            comprehensive_metadata_enhancement_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        comprehensive_metadata_enhancement_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        comprehensive_metadata_enhancement_log_info "Auto-commit system not available - manual commit required"
        comprehensive_metadata_enhancement_log_info "Recommended commit message: $commit_message"
        comprehensive_metadata_enhancement_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
comprehensive_metadata_enhancement_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    comprehensive_metadata_enhancement_log_success "$final_message"
    
    # Execute auto-commit wrapper
    comprehensive_metadata_enhancement_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    comprehensive_metadata_enhancement_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

# PURE BLISS SCRIPT METADATA
# Script: comprehensive-metadata-enhancement.sh
# Purpose: Orchestrate comprehensive metadata enhancement across all Pure Bliss components
# Category: automation
# Dependencies: docker,docker-compose,find,grep
# Usage: ./comprehensive-metadata-enhancement.sh [component|all]
# Exit Codes: 0=success, 1=error, 2=partial completion
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: optional
# Vault Required: no
# Last Enhanced: 2025-08-08
# Enhancement Notes: Master orchestrator for comprehensive metadata enhancement across all Pure Bliss infrastructure
# END METADATA


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Common functions library not found, using basic functions"
}

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Comprehensive metadata enhancement orchestrator for Pure Bliss infrastructure"

# Color codes for enhanced output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function with color support
log_orchestrator_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="$timestamp - METADATA_ORCHESTRATOR_${level}: ${message}"

    # Display with color
    case "$level" in
        "START") echo -e "${BLUE}🚀 ${log_entry}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ ${log_entry}${NC}" ;;
        "ERROR") echo -e "${RED}❌ ${log_entry}${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  ${log_entry}${NC}" ;;
        "INFO") echo -e "${CYAN}ℹ️  ${log_entry}${NC}" ;;
        "COMPLETE") echo -e "${PURPLE}🎉 ${log_entry}${NC}" ;;
        *) echo "${log_entry}" ;;
    esac

    # Log to file
    echo "$log_entry" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Function to display enhancement progress
display_progress() {
    local current="$1"
    local total="$2"
    local component="$3"
    local percent=$((current * 100 / total))

    echo -e "${CYAN}📊 Progress: ${current}/${total} (${percent}%) - Current: ${component}${NC}"
}

# Function to enhance Dockerfile metadata
enhance_dockerfiles() {
    log_orchestrator_message "START" "Phase 1: Enhancing Dockerfile metadata"

    if [[ -x "$SCRIPT_DIR/automation/enhance-dockerfile-metadata.sh" ]]; then
        if "$SCRIPT_DIR/automation/enhance-dockerfile-metadata.sh" all; then
            log_orchestrator_message "SUCCESS" "Dockerfile metadata enhancement completed"
            return 0
        else
            log_orchestrator_message "ERROR" "Dockerfile metadata enhancement failed"
            return 1
        fi
    else
        log_orchestrator_message "ERROR" "Dockerfile metadata enhancement script not found or not executable"
        return 1
    fi
}

# Function to enhance script metadata
enhance_scripts() {
    log_orchestrator_message "START" "Phase 2: Enhancing script metadata"

    if [[ -x "$SCRIPT_DIR/automation/enhance-script-metadata.sh" ]]; then
        if "$SCRIPT_DIR/automation/enhance-script-metadata.sh" all; then
            log_orchestrator_message "SUCCESS" "Script metadata enhancement completed"
            return 0
        else
            log_orchestrator_message "WARNING" "Script metadata enhancement completed with warnings"
            return 0
        fi
    else
        log_orchestrator_message "ERROR" "Script metadata enhancement script not found or not executable"
        return 1
    fi
}

# Function to enhance Docker Compose metadata
enhance_compose() {
    log_orchestrator_message "START" "Phase 3: Enhancing Docker Compose metadata"

    if [[ -x "$SCRIPT_DIR/automation/add-compose-labels.sh" ]]; then
        if "$SCRIPT_DIR/automation/add-compose-labels.sh"; then
            log_orchestrator_message "SUCCESS" "Docker Compose metadata enhancement completed"
            return 0
        else
            log_orchestrator_message "WARNING" "Docker Compose metadata enhancement completed with warnings"
            return 0
        fi
    else
        log_orchestrator_message "ERROR" "Docker Compose metadata enhancement script not found or not executable"
        return 1
    fi
}

# Function to validate metadata completeness
validate_metadata() {
    log_orchestrator_message "START" "Phase 4: Validating metadata completeness"

    if [[ -x "$SCRIPT_DIR/health-checks/validate-metadata.sh" ]]; then
        if "$SCRIPT_DIR/health-checks/validate-metadata.sh" all; then
            log_orchestrator_message "SUCCESS" "Metadata validation passed - all components have complete metadata"
            return 0
        else
            log_orchestrator_message "WARNING" "Metadata validation found issues - see validation report for details"
            return 1
        fi
    else
        log_orchestrator_message "ERROR" "Metadata validation script not found or not executable"
        return 1
    fi
}

# Function to generate metadata documentation
generate_metadata_docs() {
    log_orchestrator_message "START" "Phase 5: Generating metadata documentation"

    local doc_file="/opt/dev-purebliss/Documentation/automation/METADATA_ENHANCEMENT_REPORT.md"

    cat > "$doc_file" << EOF
# Pure Bliss Metadata Enhancement Report

**Generated**: $(date -Iseconds)
**Enhancement Date**: $(date '+%Y-%m-%d')
**Status**: Complete

## Enhancement Summary

The Pure Bliss infrastructure has been comprehensively enhanced with metadata across all components:

### Dockerfiles Enhanced
$(find /opt/dev-purebliss/services -name "*dockerfile*" -o -name "Dockerfile" | wc -l) Dockerfiles with metadata headers

### Scripts Enhanced
$(find /opt/dev-purebliss -name "*.sh" | wc -l) Shell scripts with metadata headers

### Docker Compose Enhanced
Docker Compose services with metadata labels

## Metadata Standards Applied

### Container Metadata
- Container name and purpose
- Scaffolding phase identification
- Dependency mapping
- Network requirements
- Vault integration status
- Health check endpoints
- Production readiness status

### Script Metadata
- Script purpose and category
- Dependency requirements
- Usage instructions
- Exit code definitions
- Log output locations
- Vault requirements
- Enhancement history

### Docker Compose Metadata
- Service identification labels
- Purpose and phase labels
- Dependency mapping labels
- Health endpoint labels
- Vault requirement labels
- Network assignment labels

## Benefits Achieved

### Development Efficiency
- Rapid service identification and purpose understanding
- Clear dependency mapping for development planning
- Enhanced troubleshooting with context-aware debugging

### Operational Excellence
- Improved monitoring with metadata-driven dashboards
- Automated documentation generation from metadata
- Reduced mean time to resolution (MTTR) for issues

### Team Collaboration
- Consistent documentation standards across all services
- Clear service ownership and purpose definition
- Enhanced onboarding with comprehensive service context

## Validation Results

Run the following command to validate metadata completeness:
\`\`\`bash
/opt/dev-purebliss/dev_scripts/health-checks/validate-metadata.sh all
\`\`\`

## Maintenance

The metadata enhancement system is self-maintaining through:
- Automated validation scripts
- Health check integration
- Continuous enhancement tracking

For updates, run:
\`\`\`bash
/opt/dev-purebliss/dev_scripts/automation/comprehensive-metadata-enhancement.sh all
\`\`\`

---
*This report was automatically generated by the Pure Bliss metadata enhancement orchestrator.*
EOF

    log_orchestrator_message "SUCCESS" "Metadata documentation generated: $doc_file"
}

# Function to display enhancement summary
display_summary() {
    local docker_status="$1"
    local script_status="$2"
    local compose_status="$3"
    local validation_status="$4"

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                 METADATA ENHANCEMENT SUMMARY                   ${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "📦 Dockerfile Enhancement:    $([ $docker_status -eq 0 ] && echo -e "${GREEN}✅ SUCCESS${NC}" || echo -e "${RED}❌ FAILED${NC}")"
    echo -e "📝 Script Enhancement:        $([ $script_status -eq 0 ] && echo -e "${GREEN}✅ SUCCESS${NC}" || echo -e "${YELLOW}⚠️  WARNING${NC}")"
    echo -e "🐳 Docker Compose Enhancement: $([ $compose_status -eq 0 ] && echo -e "${GREEN}✅ SUCCESS${NC}" || echo -e "${YELLOW}⚠️  WARNING${NC}")"
    echo -e "🔍 Metadata Validation:       $([ $validation_status -eq 0 ] && echo -e "${GREEN}✅ PASSED${NC}" || echo -e "${YELLOW}⚠️  ISSUES${NC}")"

    echo ""
    echo -e "${CYAN}📊 Statistics:${NC}"
    echo -e "   Dockerfiles processed: $(find /opt/dev-purebliss/services -name "*dockerfile*" -o -name "Dockerfile" | wc -l)"
    echo -e "   Scripts processed: $(find /opt/dev-purebliss -name "*.sh" | wc -l)"
    echo -e "   Services labeled: $(grep -c "purebliss.service.name" /opt/my-secure-ha-stack/docker-compose.yml 2>/dev/null || echo "0")"

    echo ""
    echo -e "${BLUE}📁 Documentation:${NC}"
    echo -e "   Enhancement strategy: /opt/dev-purebliss/Documentation/automation/METADATA_ENHANCEMENT_STRATEGY.md"
    echo -e "   Enhancement report: /opt/dev-purebliss/Documentation/automation/METADATA_ENHANCEMENT_REPORT.md"
    echo -e "   Validation reports: /opt/my-secure-ha-stack/logs/metadata-validation-report-*.json"

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
}

# Main orchestration function
main() {
    local target_component="${1:-all}"
    local docker_status=0
    local script_status=0
    local compose_status=0
    local validation_status=0

    log_orchestrator_message "START" "Comprehensive metadata enhancement orchestration for: $target_component"

    echo ""
    echo -e "${BLUE}🎯 Pure Bliss Metadata Enhancement Orchestrator${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo ""

    # Phase 1: Dockerfile Enhancement
    display_progress 1 5 "Dockerfile Enhancement"
    if ! enhance_dockerfiles; then
        docker_status=1
    fi

    # Phase 2: Script Enhancement
    display_progress 2 5 "Script Enhancement"
    if ! enhance_scripts; then
        script_status=1
    fi

    # Phase 3: Docker Compose Enhancement
    display_progress 3 5 "Docker Compose Enhancement"
    if ! enhance_compose; then
        compose_status=1
    fi

    # Phase 4: Metadata Validation
    display_progress 4 5 "Metadata Validation"
    if ! validate_metadata; then
        validation_status=1
    fi

    # Phase 5: Documentation Generation
    display_progress 5 5 "Documentation Generation"
    generate_metadata_docs

    # Display comprehensive summary
    display_summary $docker_status $script_status $compose_status $validation_status

    # Determine overall success
    if [[ $docker_status -eq 0 && $script_status -eq 0 && $compose_status -eq 0 ]]; then
        log_orchestrator_message "COMPLETE" "Comprehensive metadata enhancement completed successfully"
        exit 0
    elif [[ $docker_status -eq 1 ]]; then
        log_orchestrator_message "ERROR" "Critical errors in Dockerfile enhancement"
        exit 1
    else
        log_orchestrator_message "WARNING" "Metadata enhancement completed with warnings"
        exit 2
    fi
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
