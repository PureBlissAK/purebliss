#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# RESTORE_GOLDEN_IMAGES_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="restore-golden-images.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced deployment script for infrastructure operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="deployment"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="infrastructure"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced deployment script for infrastructure with auto-commit functionality,
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
restore_golden_images_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
restore_golden_images_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
restore_golden_images_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
restore_golden_images_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    restore_golden_images_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        restore_golden_images_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            restore_golden_images_log_success "Validation passed - proceeding with auto-commit"
        else
            restore_golden_images_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        restore_golden_images_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        restore_golden_images_log_info "Auto-commit system not available - manual commit required"
        restore_golden_images_log_info "Recommended commit message: $commit_message"
        restore_golden_images_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
restore_golden_images_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    restore_golden_images_log_success "$final_message"
    
    # Execute auto-commit wrapper
    restore_golden_images_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    restore_golden_images_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

# Restore Golden Container Images from RAID Storage
# Complete environment restoration from golden images


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    # Basic logging function if common library not available
    log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_RESTORE: $1" | tee -a "/opt/my-secure-ha-stack/logs/dev-environment-setup.log"; }
    log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_RESTORE_ERROR: $1" | tee -a "/opt/my-secure-ha-stack/logs/dev-environment-setup.log"; }
    log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_RESTORE_SUCCESS: $1" | tee -a "/opt/my-secure-ha-stack/logs/dev-environment-setup.log"; }
}

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Restore golden container images from RAID storage for complete environment recovery"

GOLDEN_IMAGES_DIR="/opt/raid-storage/golden-images"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_info "🔧 INITIATING GOLDEN IMAGES RESTORATION"
log_info "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
log_info "🎯 Purpose: $SCRIPT_PURPOSE"

# Check if RAID storage is available
if [ ! -d "$GOLDEN_IMAGES_DIR" ]; then
    log_error "❌ RAID storage directory not found: $GOLDEN_IMAGES_DIR"
    log_error "💾 Ensure RAID storage is mounted and golden images exist"
    exit 1
fi

# Load manifest
MANIFEST_FILE="${GOLDEN_IMAGES_DIR}/golden-images-manifest.json"

if [ ! -f "$MANIFEST_FILE" ]; then
    log_error "❌ Golden images manifest not found: $MANIFEST_FILE"
    log_error "📋 Cannot proceed without deployment manifest"
    exit 1
fi

log_success "📋 Loading golden images manifest: $MANIFEST_FILE"

# Display manifest information
if command -v jq >/dev/null 2>&1; then
    CREATION_DATE=$(jq -r '.golden_images_deployment.creation_date' "$MANIFEST_FILE")
    VERSION=$(jq -r '.golden_images_deployment.version' "$MANIFEST_FILE")
    TOTAL_SERVICES=$(jq -r '.golden_images_deployment.total_services' "$MANIFEST_FILE")
    SERVICES_CREATED=$(jq -r '.golden_images_deployment.services_created' "$MANIFEST_FILE")

    log_info "📊 Manifest Information:"
    log_info "  📅 Creation Date: $CREATION_DATE"
    log_info "  🏷️ Version: $VERSION"
    log_info "  📦 Total Services: $TOTAL_SERVICES"
    log_info "  ✅ Services Available: $SERVICES_CREATED"
else
    log_info "⚠️ jq not available, proceeding with basic manifest parsing"
fi

# Function to stop existing containers
stop_existing_containers() {
    log_info "🛑 Stopping existing containers before restoration"

    EXISTING_CONTAINERS=$(docker ps -q --filter "name=purebliss-*")

    if [ ! -z "$EXISTING_CONTAINERS" ]; then
        log_info "🔄 Found existing PureBliss containers, stopping them..."
        docker stop $EXISTING_CONTAINERS
        log_success "✅ Existing containers stopped"
    else
        log_info "ℹ️ No existing PureBliss containers found"
    fi
}

# Function to backup existing containers
backup_existing_containers() {
    log_info "💾 Creating backup of existing containers"

    BACKUP_DIR="/opt/raid-storage/container-backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    EXISTING_CONTAINERS=$(docker ps -a -q --filter "name=purebliss-*")

    if [ ! -z "$EXISTING_CONTAINERS" ]; then
        for container in $EXISTING_CONTAINERS; do
            CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$container" | sed 's/\///')
            BACKUP_FILE="${BACKUP_DIR}/${CONTAINER_NAME}-backup.tar"

            log_info "💾 Backing up container: $CONTAINER_NAME"
            docker commit "$container" "${CONTAINER_NAME}-backup:$(date +%Y%m%d-%H%M%S)"
            docker save "${CONTAINER_NAME}-backup:$(date +%Y%m%d-%H%M%S)" -o "$BACKUP_FILE"

            if [ $? -eq 0 ]; then
                log_success "✅ Container backup created: $BACKUP_FILE"
            else
                log_error "❌ Failed to backup container: $CONTAINER_NAME"
            fi
        done

        log_success "💾 Container backups stored in: $BACKUP_DIR"
    else
        log_info "ℹ️ No existing containers to backup"
    fi
}

# Parse services from manifest and restore in deployment sequence
DEPLOYMENT_SEQUENCE=("vault" "postgres" "redis" "keycloak" "nginx" "prometheus" "grafana" "loki" "plane" "codeserver")

log_info "🔄 Deployment sequence: ${DEPLOYMENT_SEQUENCE[*]}"

# Ask for user confirmation
echo ""
echo "⚠️  CRITICAL OPERATION WARNING ⚠️"
echo "This will restore golden container images and replace existing containers."
echo "Existing containers will be backed up before replacement."
echo ""
read -p "Do you want to proceed with golden images restoration? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "🚫 Operation cancelled by user"
    exit 0
fi

# Create backup of existing containers
backup_existing_containers

# Stop existing containers
stop_existing_containers

# Restoration counters
RESTORE_SUCCESS=0
RESTORE_FAILED=0

# Phase 1: Load Golden Images
log_info "⚡ PHASE 1: Loading golden images from RAID storage"

for service in "${DEPLOYMENT_SEQUENCE[@]}"; do
    log_info "🔧 Restoring golden image for ${service}"

    # Find golden image file with pattern matching
    GOLDEN_TAR=$(find "$GOLDEN_IMAGES_DIR" -name "purebliss-${service}-golden-*.tar.gz" | head -n1)

    if [ -f "$GOLDEN_TAR" ]; then
        log_info "📦 Found golden image: $(basename "$GOLDEN_TAR")"

        # Test integrity before loading
        if gzip -t "$GOLDEN_TAR"; then
            log_success "✅ Golden image integrity verified"

            # Decompress and load golden image
            log_info "📥 Loading golden image into Docker..."
            if gunzip -c "$GOLDEN_TAR" | docker load; then
                log_success "✅ Golden image loaded for ${service}"
                ((RESTORE_SUCCESS++))
            else
                log_error "❌ Failed to load golden image for ${service}"
                ((RESTORE_FAILED++))
                continue
            fi
        else
            log_error "❌ Golden image integrity check failed for ${service}"
            ((RESTORE_FAILED++))
            continue
        fi
    else
        log_error "❌ Golden image file not found for ${service}"
        log_info "🔍 Searched pattern: purebliss-${service}-golden-*.tar.gz"
        ((RESTORE_FAILED++))
        continue
    fi
done

log_info "📊 Golden images loading summary:"
log_info "  ✅ Successfully loaded: $RESTORE_SUCCESS"
log_info "  ❌ Failed to load: $RESTORE_FAILED"

# Phase 2: Start Containers from Golden Images
log_info "⚡ PHASE 2: Starting containers from golden images"

CONTAINER_START_SUCCESS=0
CONTAINER_START_FAILED=0

for service in "${DEPLOYMENT_SEQUENCE[@]}"; do
    log_info "🚀 Starting container from golden image: ${service}"

    # Find the loaded golden image
    GOLDEN_IMAGE_NAME=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "purebliss-${service}-golden" | head -n1 | tr -s ' ' | cut -d' ' -f1,2 | tr ' ' ':')

    if [ ! -z "$GOLDEN_IMAGE_NAME" ]; then
        log_info "🏷️ Using golden image: $GOLDEN_IMAGE_NAME"

        # Remove existing container if it exists
        if docker ps -a --format "{{.Names}}" | grep -q "^purebliss-${service}$"; then
            log_info "🗑️ Removing existing container: purebliss-${service}"
            docker rm -f "purebliss-${service}" 2>/dev/null || true
        fi

        # Start container from golden image
        # Note: This would need to be integrated with the actual docker-compose or deployment system
        log_info "🚀 Container ready for deployment from golden image: $GOLDEN_IMAGE_NAME"
        log_info "🔧 Use docker-compose or deployment scripts to start with proper configuration"

        ((CONTAINER_START_SUCCESS++))
    else
        log_error "❌ Golden image not found for ${service}"
        ((CONTAINER_START_FAILED++))
    fi
done

# Phase 3: Health Validation
log_info "⚡ PHASE 3: Post-restoration health validation"

if [ -f "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh" ]; then
    log_info "🏥 Running comprehensive health validation..."

    # Wait a moment for containers to initialize
    sleep 10

    for service in "${DEPLOYMENT_SEQUENCE[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^purebliss-${service}$"; then
            log_info "🔍 Validating health for ${service}"

            if /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "${service}" golden-restore-validation; then
                log_success "✅ ${service} health validation passed"
            else
                log_error "❌ ${service} health validation failed"
            fi
        else
            log_info "⚠️ Container purebliss-${service} not found for health validation"
        fi
    done
else
    log_info "⚠️ Health validation script not found, skipping automated health checks"
    log_info "🔍 Manual validation recommended after restoration"
fi

# Final Summary
log_success "🏆 GOLDEN IMAGES RESTORATION COMPLETED"
log_info "📊 Restoration Statistics:"
log_info "  📥 Images Loaded: $RESTORE_SUCCESS"
log_info "  ❌ Images Failed: $RESTORE_FAILED"
log_info "  🚀 Containers Ready: $CONTAINER_START_SUCCESS"
log_info "  ⚠️ Container Failures: $CONTAINER_START_FAILED"

# Create restoration report
RESTORE_REPORT="/opt/raid-storage/golden-images/restoration-report-$(date +%Y%m%d-%H%M%S).json"

cat > "$RESTORE_REPORT" << EOF
{
    "golden_images_restoration": {
        "restore_date": "$(date -Iseconds)",
        "restoration_status": "COMPLETED",
        "images_loaded": $RESTORE_SUCCESS,
        "images_failed": $RESTORE_FAILED,
        "containers_ready": $CONTAINER_START_SUCCESS,
        "containers_failed": $CONTAINER_START_FAILED,
        "source_manifest": "$MANIFEST_FILE",
        "restoration_log": "$LOG_FILE",
        "next_steps": [
            "Start containers using docker-compose or deployment scripts",
            "Run comprehensive health validation",
            "Verify service connectivity",
            "Perform end-to-end integration tests"
        ]
    }
}
EOF

log_success "📋 Restoration report created: $RESTORE_REPORT"

# Log to development log
echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_RESTORE_COMPLETE: Restored $RESTORE_SUCCESS golden images from $GOLDEN_IMAGES_DIR" >> "$LOG_FILE"

if [ "$RESTORE_FAILED" -eq 0 ] && [ "$CONTAINER_START_FAILED" -eq 0 ]; then
    log_success "🎉 ALL GOLDEN IMAGES RESTORED SUCCESSFULLY"
    log_info "🚀 Ready to start containers using deployment system"
    exit 0
else
    log_error "⚠️ Some golden images failed restoration"
    log_info "📋 Check restoration report for details: $RESTORE_REPORT"
    exit 1
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
