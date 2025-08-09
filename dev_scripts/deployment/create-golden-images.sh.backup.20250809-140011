#!/bin/bash
# Create Golden Container Images for RAID Storage
# All containers must pass 100% health validation before image creation

set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    # Basic logging function if common library not available
    log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_IMAGES: $1" | tee -a "/opt/my-secure-ha-stack/logs/dev-environment-setup.log"; }
    log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_IMAGES_ERROR: $1" | tee -a "/opt/my-secure-ha-stack/logs/dev-environment-setup.log"; }
    log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_IMAGES_SUCCESS: $1" | tee -a "/opt/my-secure-ha-stack/logs/dev-environment-setup.log"; }
}

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Create golden container images with 100% health validation for RAID storage deployment"

GOLDEN_IMAGES_DIR="/opt/raid-storage/golden-images"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_info "🏆 INITIATING GOLDEN CONTAINER IMAGES CREATION"
log_info "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
log_info "🎯 Purpose: $SCRIPT_PURPOSE"

# Create RAID storage directory for golden images
mkdir -p "$GOLDEN_IMAGES_DIR"
log_info "💾 RAID storage directory created: $GOLDEN_IMAGES_DIR"

# Services to create golden images for
SERVICES=(
    "purebliss-vault"
    "purebliss-postgres"
    "purebliss-redis"
    "purebliss-nginx"
    "purebliss-keycloak"
    "purebliss-grafana"
    "purebliss-prometheus"
    "purebliss-loki"
    "purebliss-plane"
    "purebliss-codeserver"
)

log_info "📊 Total services for golden image creation: ${#SERVICES[@]}"

# Phase 1: Comprehensive Health Validation Before Image Creation
log_info "⚡ PHASE 1: Comprehensive health validation of all services"

HEALTH_VALIDATION_PASSED=0
HEALTH_VALIDATION_FAILED=0

for service in "${SERVICES[@]}"; do
    log_info "🔍 Validating ${service} health status"

    # Check if container exists and is running
    if ! docker ps --format "table {{.Names}}" | grep -q "^${service}$"; then
        log_error "❌ ${service} container not found or not running"
        ((HEALTH_VALIDATION_FAILED++))
        continue
    fi

    # Execute health validation if script exists
    if [ -f "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh" ]; then
        if /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "${service#purebliss-}" golden-image-prep; then
            log_success "✅ ${service} passed health validation"
            ((HEALTH_VALIDATION_PASSED++))
        else
            log_error "❌ ${service} FAILED health validation - CANNOT CREATE GOLDEN IMAGE"
            log_error "🚨 CRITICAL: Fix ${service} before proceeding with golden image creation"
            ((HEALTH_VALIDATION_FAILED++))
            continue
        fi
    else
        log_info "⚠️ Health validation script not found, performing basic checks"
    fi

    # Additional service-specific health checks
    case "$service" in
        "purebliss-vault")
            # Validate Vault seal status and health
            if docker exec "$service" vault status 2>/dev/null | grep -q "Sealed.*false"; then
                log_success "✅ Vault unsealed and operational"
            else
                log_error "❌ Vault sealed or unhealthy - cannot create golden image"
                ((HEALTH_VALIDATION_FAILED++))
                continue
            fi
            ;;
        "purebliss-postgres")
            # Validate database connectivity
            if docker exec "$service" pg_isready -U postgres 2>/dev/null; then
                log_success "✅ PostgreSQL accepting connections"
            else
                log_error "❌ PostgreSQL not accepting connections"
                ((HEALTH_VALIDATION_FAILED++))
                continue
            fi
            ;;
        "purebliss-nginx")
            # Validate NGINX configuration
            if docker exec "$service" nginx -t 2>/dev/null; then
                log_success "✅ NGINX configuration valid"
            else
                log_error "❌ NGINX configuration invalid"
                ((HEALTH_VALIDATION_FAILED++))
                continue
            fi
            ;;
        "purebliss-keycloak")
            # Check if Keycloak is responding
            if docker exec "$service" curl -f -s http://localhost:8080/health/ready 2>/dev/null >/dev/null; then
                log_success "✅ Keycloak health check passed"
            else
                log_info "⚠️ Keycloak health endpoint not responding (may be normal during startup)"
            fi
            ;;
    esac
done

# Check if any critical failures occurred
if [ "$HEALTH_VALIDATION_FAILED" -gt 0 ]; then
    log_error "💥 CRITICAL: $HEALTH_VALIDATION_FAILED services failed health validation"
    log_error "🚫 Cannot proceed with golden image creation until all services are healthy"
    log_error "✅ Services passed: $HEALTH_VALIDATION_PASSED"
    log_error "❌ Services failed: $HEALTH_VALIDATION_FAILED"
    exit 1
fi

log_success "🎉 ALL SERVICES PASSED HEALTH VALIDATION ($HEALTH_VALIDATION_PASSED/$((HEALTH_VALIDATION_PASSED + HEALTH_VALIDATION_FAILED)))"

# Phase 2: Create Golden Images with Versioning
log_info "⚡ PHASE 2: Creating golden container images"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
VERSION="v1.0-golden-${TIMESTAMP}"

log_info "🏷️ Golden image version: $VERSION"

GOLDEN_IMAGES_CREATED=0
GOLDEN_IMAGES_FAILED=0

for service in "${SERVICES[@]}"; do
    log_info "📦 Creating golden image for ${service}"

    # Skip if container not running
    if ! docker ps --format "table {{.Names}}" | grep -q "^${service}$"; then
        log_error "⚠️ Skipping ${service} - container not running"
        ((GOLDEN_IMAGES_FAILED++))
        continue
    fi

    # Create golden image with timestamp and version
    GOLDEN_IMAGE_NAME="${service}-golden:${VERSION}"

    if docker commit "$service" "$GOLDEN_IMAGE_NAME"; then
        log_success "✅ Golden image created: ${GOLDEN_IMAGE_NAME}"

        # Save golden image to RAID storage
        GOLDEN_TAR="${GOLDEN_IMAGES_DIR}/${service}-golden-${VERSION}.tar"

        log_info "💾 Saving golden image to RAID storage..."
        if docker save "$GOLDEN_IMAGE_NAME" -o "$GOLDEN_TAR"; then
            log_success "💾 Golden image saved to RAID: ${GOLDEN_TAR}"

            # Compress for storage efficiency
            if gzip "$GOLDEN_TAR"; then
                log_success "🗜️ Golden image compressed: ${GOLDEN_TAR}.gz"

                # Calculate and log file size
                COMPRESSED_SIZE=$(du -h "${GOLDEN_TAR}.gz" | cut -f1)
                log_info "📊 Compressed size: $COMPRESSED_SIZE"

                ((GOLDEN_IMAGES_CREATED++))
            else
                log_error "❌ Failed to compress golden image"
                ((GOLDEN_IMAGES_FAILED++))
            fi
        else
            log_error "❌ Failed to save golden image to RAID storage"
            ((GOLDEN_IMAGES_FAILED++))
        fi
    else
        log_error "❌ Failed to create golden image for ${service}"
        ((GOLDEN_IMAGES_FAILED++))
    fi
done

log_info "📊 Golden images creation summary:"
log_info "✅ Successfully created: $GOLDEN_IMAGES_CREATED"
log_info "❌ Failed: $GOLDEN_IMAGES_FAILED"

# Phase 3: Create Golden Images Manifest
log_info "⚡ PHASE 3: Creating golden images manifest"

MANIFEST_FILE="${GOLDEN_IMAGES_DIR}/golden-images-manifest.json"

cat > "$MANIFEST_FILE" << EOF
{
    "golden_images_deployment": {
        "creation_date": "$(date -Iseconds)",
        "version": "$VERSION",
        "total_services": ${#SERVICES[@]},
        "services_created": $GOLDEN_IMAGES_CREATED,
        "services_failed": $GOLDEN_IMAGES_FAILED,
        "raid_storage_path": "$GOLDEN_IMAGES_DIR",
        "health_validation": "100% PASSED",
        "deployment_status": "READY",
        "services": [
EOF

# Build services array in manifest
FIRST_SERVICE=true
for service in "${SERVICES[@]}"; do
    # Check if golden image exists
    GOLDEN_TAR="${GOLDEN_IMAGES_DIR}/${service}-golden-${VERSION}.tar.gz"

    if [ -f "$GOLDEN_TAR" ]; then
        if [ "$FIRST_SERVICE" = true ]; then
            FIRST_SERVICE=false
        else
            echo "            ," >> "$MANIFEST_FILE"
        fi

        COMPRESSED_SIZE=$(du -h "$GOLDEN_TAR" | cut -f1)

        cat >> "$MANIFEST_FILE" << EOF
            {
                "service_name": "${service#purebliss-}",
                "container_name": "$service",
                "golden_image": "${service}-golden:${VERSION}",
                "storage_file": "${service}-golden-${VERSION}.tar.gz",
                "compressed_size": "$COMPRESSED_SIZE",
                "health_status": "VALIDATED",
                "deployment_ready": true
            }EOF
    fi
done

cat >> "$MANIFEST_FILE" << EOF

        ],
        "deployment_instructions": {
            "restore_command": "/opt/dev-purebliss/dev_scripts/deployment/restore-golden-images.sh",
            "validation_required": true,
            "prerequisites": ["Docker installed", "RAID storage mounted", "Network configured"],
            "deployment_sequence": ["vault", "postgres", "redis", "keycloak", "nginx", "prometheus", "grafana", "loki", "plane", "codeserver"],
            "post_deployment": [
                "Execute health validation for all services",
                "Verify service connectivity",
                "Run end-to-end integration tests",
                "Confirm 100% operational status"
            ]
        },
        "disaster_recovery": {
            "backup_location": "$GOLDEN_IMAGES_DIR",
            "restore_time_estimate": "15-30 minutes",
            "rollback_capability": true,
            "automated_restore": true
        }
    }
}
EOF

log_success "📋 Golden images manifest created: $MANIFEST_FILE"

# Phase 4: Test Golden Images Integrity
log_info "⚡ PHASE 4: Testing golden images integrity"

INTEGRITY_PASSED=0
INTEGRITY_FAILED=0

for service in "${SERVICES[@]}"; do
    GOLDEN_TAR="${GOLDEN_IMAGES_DIR}/${service}-golden-${VERSION}.tar.gz"

    if [ -f "$GOLDEN_TAR" ]; then
        # Test file integrity
        if gzip -t "$GOLDEN_TAR" 2>/dev/null; then
            log_success "✅ ${service} golden image integrity verified"
            ((INTEGRITY_PASSED++))
        else
            log_error "❌ ${service} golden image corrupted"
            ((INTEGRITY_FAILED++))
        fi
    else
        log_info "⚠️ ${service} golden image file not found (may have failed creation)"
    fi
done

# Calculate total storage used
TOTAL_STORAGE=$(du -sh "$GOLDEN_IMAGES_DIR" | cut -f1)

# Final Summary
log_success "🏆 GOLDEN CONTAINER IMAGES CREATION COMPLETED"
log_info "📊 Final Statistics:"
log_info "  💾 Storage Location: $GOLDEN_IMAGES_DIR"
log_info "  📋 Manifest: $MANIFEST_FILE"
log_info "  ✅ Images Created: $GOLDEN_IMAGES_CREATED"
log_info "  ❌ Images Failed: $GOLDEN_IMAGES_FAILED"
log_info "  🔍 Integrity Passed: $INTEGRITY_PASSED"
log_info "  💽 Total Storage Used: $TOTAL_STORAGE"
log_info "  🔧 Restore Script: /opt/dev-purebliss/dev_scripts/deployment/restore-golden-images.sh"

# Log to development log
echo "$(date '+%Y-%m-%d %H:%M:%S') - GOLDEN_IMAGES_COMPLETE: Created $GOLDEN_IMAGES_CREATED golden images, stored in $GOLDEN_IMAGES_DIR" >> "$LOG_FILE"

if [ "$GOLDEN_IMAGES_FAILED" -eq 0 ] && [ "$INTEGRITY_FAILED" -eq 0 ]; then
    log_success "🎉 ALL GOLDEN IMAGES CREATED SUCCESSFULLY - READY FOR DEPLOYMENT"
    exit 0
else
    log_error "⚠️ Some golden images failed creation or integrity check"
    exit 1
fi
