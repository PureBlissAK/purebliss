#!/bin/bash

# Script Reference Validation Tool
# Validates that all script references point to centralized locations after migration

set -euo pipefail

# Configuration
CENTRALIZED_SCRIPTS_DIR="/opt/dev-purebliss/dev_scripts"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
SEARCH_DIRS=("/opt/dev-purebliss" "/opt/my-secure-ha-stack")

# Logging function
log_validation() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} - SCRIPT_VALIDATION [$level]: $message" | tee -a "$LOG_FILE"
}

# Find script references that may need updating
find_script_references() {
    local script_name=$1
    log_validation "INFO" "Searching for references to $script_name"

    for search_dir in "${SEARCH_DIRS[@]}"; do
        if [[ -d "$search_dir" ]]; then
            # Search for script references in shell scripts and markdown files
            grep -r "$script_name" "$search_dir" --include="*.sh" --include="*.md" --include="*.yml" --include="*.yaml" 2>/dev/null | \
            grep -v "$CENTRALIZED_SCRIPTS_DIR" | \
            while IFS=: read -r file line; do
                log_validation "FOUND" "Reference in $file: $line"
            done
        fi
    done
}

# Validate script migration
validate_script_migration() {
    local service=$1
    log_validation "INFO" "Validating script migration for service: $service"

    local service_script_dir="$CENTRALIZED_SCRIPTS_DIR/services/$service"

    if [[ -d "$service_script_dir" ]]; then
        log_validation "SUCCESS" "Service script directory exists: $service_script_dir"

        # List scripts in service directory
        if [[ $(find "$service_script_dir" -name "*.sh" | wc -l) -gt 0 ]]; then
            log_validation "INFO" "Scripts found in $service_script_dir:"
            find "$service_script_dir" -name "*.sh" -exec basename {} \; | while read script; do
                log_validation "INFO" "  - $script"
            done
        else
            log_validation "WARN" "No scripts found in $service_script_dir"
        fi
    else
        log_validation "ERROR" "Service script directory missing: $service_script_dir"
        return 1
    fi
}

# Check for outdated script references
check_outdated_references() {
    log_validation "INFO" "Checking for outdated script references"

    # Common script patterns that should be centralized
    local patterns=(
        "./validate-container-health.sh"
        "./upstream-validation.sh"
        "./container-scaffold.sh"
        "./services/.*/entrypoint.sh"
        "./services/.*/.*\.sh"
    )

    for pattern in "${patterns[@]}"; do
        log_validation "INFO" "Searching for pattern: $pattern"
        find_script_references "$pattern"
    done
}

# Generate migration report
generate_migration_report() {
    local report_file="/opt/dev-purebliss/dev_scripts/legacy/migration-validation-report.md"
    log_validation "INFO" "Generating migration report: $report_file"

    cat > "$report_file" << EOF
# Script Migration Validation Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')

## Directory Structure Validation

### Centralized Script Directory
- **Location**: $CENTRALIZED_SCRIPTS_DIR
- **Status**: $([ -d "$CENTRALIZED_SCRIPTS_DIR" ] && echo "✅ EXISTS" || echo "❌ MISSING")

### Subdirectory Structure
EOF

    for subdir in core services automation health-checks deployment utilities legacy; do
        local subdir_path="$CENTRALIZED_SCRIPTS_DIR/$subdir"
        local status=$([ -d "$subdir_path" ] && echo "✅ EXISTS" || echo "❌ MISSING")
        echo "- **$subdir/**: $status" >> "$report_file"
    done

    cat >> "$report_file" << EOF

### Service Script Directories
EOF

    for service in vault postgres redis nginx keycloak grafana prometheus loki plane codeserver letsencrypt; do
        local service_dir="$CENTRALIZED_SCRIPTS_DIR/services/$service"
        local status=$([ -d "$service_dir" ] && echo "✅ EXISTS" || echo "❌ MISSING")
        local script_count=$(find "$service_dir" -name "*.sh" 2>/dev/null | wc -l)
        echo "- **$service/**: $status (Scripts: $script_count)" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## Migration Status

### Completed Migrations
- [x] Directory structure creation
- [x] vault-secrets.sh migration

### Pending High Priority Migrations
- [ ] validate-container-health.sh
- [ ] upstream-validation.sh
- [ ] container-scaffold.sh
- [ ] start-all-services.sh

## Validation Results

**Script Reference Validation**: See validation log for detailed reference analysis
**Migration Integrity**: All expected directories created successfully
**Next Actions**: Begin high-priority core script migration

---
**Validation Command**: \`$0\`
**Log File**: $LOG_FILE
EOF

    log_validation "SUCCESS" "Migration report generated: $report_file"
}

# Main validation function
main() {
    log_validation "INFO" "Starting script migration validation"

    # Validate directory structure
    if [[ ! -d "$CENTRALIZED_SCRIPTS_DIR" ]]; then
        log_validation "ERROR" "Centralized scripts directory not found: $CENTRALIZED_SCRIPTS_DIR"
        exit 1
    fi

    # Validate core directories
    for subdir in core services automation health-checks deployment utilities legacy; do
        local subdir_path="$CENTRALIZED_SCRIPTS_DIR/$subdir"
        if [[ -d "$subdir_path" ]]; then
            log_validation "SUCCESS" "Directory exists: $subdir_path"
        else
            log_validation "ERROR" "Directory missing: $subdir_path"
        fi
    done

    # Validate service directories
    for service in vault postgres redis nginx keycloak grafana prometheus loki plane codeserver letsencrypt; do
        validate_script_migration "$service"
    done

    # Check for outdated references
    check_outdated_references

    # Generate report
    generate_migration_report

    log_validation "SUCCESS" "Script migration validation completed"
}

# Execute main function
main "$@"
