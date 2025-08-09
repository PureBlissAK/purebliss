# Pure Bliss Elite Script Reference Guide

## 🎯 Centralized Script Location Standard

**ABSOLUTE PATH REQUIREMENT**: All scripts must reference centralized locations using absolute paths to ensure consistency across all automation workflows.

## 📍 Core Script Locations

### Essential Infrastructure Scripts

| Script | Location | Purpose | Dependencies |
|--------|----------|---------|--------------|
| `validate-container-health.sh` | `/opt/dev-purebliss/dev_scripts/core/` | 🏥 Mandatory health validation | common-functions-library.sh |
| `container-scaffold.sh` | `/opt/dev-purebliss/dev_scripts/core/` | 🏗️ Elite container building | retry-utils.sh |
| `comprehensive-health-check.sh` | `/opt/dev-purebliss/dev_scripts/core/` | 🔍 Deep health analysis | script-communication-bridge.sh |

### Shared Utility Scripts

| Script | Location | Purpose | Usage Pattern |
|--------|----------|---------|--------------|
| `retry-utils.sh` | `/opt/dev-purebliss/dev_scripts/utilities/` | 🔄 Retry functionality | `source "$SCRIPT_DIR/utilities/retry-utils.sh"` |
| `common-functions-library.sh` | `/opt/dev-purebliss/dev_scripts/utilities/` | 📚 Shared functions | `source "$SCRIPT_DIR/utilities/common-functions-library.sh"` |
| `script-communication-bridge.sh` | `/opt/dev-purebliss/dev_scripts/utilities/` | 🌉 Inter-script communication | `source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"` |

### Master Deployment Scripts

| Script | Location | Purpose | Integration |
|--------|----------|---------|-------------|
| `deploy-purebliss-complete.sh` | `/opt/dev-purebliss/dev_scripts/automation/` | 🚀 Single-command deployment | Orchestrates all other scripts |
| `deployment-orchestrator.sh` | `/opt/dev-purebliss/dev_scripts/deployment/` | 🎼 Service deployment coordination | Called by master deployment |

## 🔗 Standard Script Integration Pattern

### Required Script Header

```bash
#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="[Brief description of script purpose]"
```

### Mandatory Function Calls

```bash
# Health validation (REQUIRED after every significant action)
validate_health() {
    "$SCRIPT_DIR/core/validate-container-health.sh" "$1" "$2"
}

# Logging (REQUIRED for all actions)
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SCRIPT_NAME: $1" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Documentation updates (REQUIRED for automation actions)
update_docs() {
    "$SCRIPT_DIR/automation/documentation-automation.sh" update "$1" "$2"
}
```

## 🤝 Inter-Script Communication Protocol

### Calling Other Scripts

```bash
# Example: Service deployment calling container scaffolding
deploy_service() {
    local service="$1"

    # Use centralized container enhancement
    "$SCRIPT_DIR/core/container-scaffold.sh" build "$service" phase-6

    # Validate health
    validate_health "$service" "container-built"

    # Notify other scripts
    notify_script_completion "$SCRIPT_NAME" "container-scaffold" "success"

    # Update documentation
    update_docs "$service" "container-deployment-complete"
}
```

### Resource Coordination

```bash
# Example: Coordinating database access
coordinate_database_access() {
    local service="$1"

    # Acquire database lock
    acquire_resource_lock "postgres" "$SCRIPT_NAME"

    # Perform database operations
    "$SCRIPT_DIR/services/postgres/postgres-automation-suite.sh" create_user "$service"

    # Release lock automatically when script exits
    trap 'release_resource_lock "postgres" "$SCRIPT_NAME"' EXIT
}
```

## 📚 Documentation Integration Requirements

### Automatic Documentation Updates

```bash
# Example: Auto-updating service automation guide
update_service_automation_guide() {
    local service="$1"
    local action="$2"

    cat >> "$DOC_DIR/services/$service/AUTOMATION_GUIDE.md" <<EOF

## $(date): $action Automation

**Action**: $action
**Script**: $SCRIPT_NAME
**Status**: ✅ Complete
**Health Validation**: $(validate_health "$service" "$action" && echo "✅ Passed" || echo "❌ Failed")

### Commands Executed:
\`\`\`bash
$SCRIPT_DIR/path/to/script.sh $service $action
\`\`\`

### Validation Results:
- Container Health: ✅ Healthy
- Service Dependencies: ✅ Available
- Performance: ✅ Within thresholds

EOF
}
```

## 🔄 Script Enhancement and Reusability Guidelines

### Before Creating New Scripts

1. **Check Existing Functionality**: Search `/opt/dev-purebliss/dev_scripts/` for similar functionality
2. **Leverage Shared Libraries**: Use `common-functions-library.sh` for common operations
3. **Extend Existing Scripts**: Add parameters to existing scripts rather than creating new ones
4. **Document Dependencies**: Update this guide with new script relationships

### Script Naming Conventions

- **Service Scripts**: `{service}-{action}-automation.sh`
- **Utility Scripts**: `{function}-{utility}.sh`
- **Deployment Scripts**: `deploy-{component}.sh`
- **Management Scripts**: `{function}-manager.sh`

### Version Control Integration

```bash
# Standard git integration for all scripts
commit_script_changes() {
    local script_name="$1"
    local change_description="$2"

    git add .
    git commit -m "feat(scripts): $script_name - $change_description

🔗 SCRIPT INTEGRATION:
- References: Updated to use centralized utilities
- Documentation: Auto-updated with latest changes
- Health Validation: ✅ All validations passing
- Dependencies: All resolved through centralized system

Co-authored-by: GitHub Copilot <github-copilot@github.com>"

    # Auto-trigger push if configured
    "$SCRIPT_DIR/automation/auto-commit-trigger.sh" \
        "script-enhancement" "$change_description" "$script_name"
}
```

## 🚀 Master Deployment Integration

### Single-Command Deployment Pattern

All service scripts must be compatible with the master deployment workflow:

```bash
# Master deployment compatibility requirements
if [[ "$1" == "--master-deployment" ]]; then
    # Operate in non-interactive mode
    INTERACTIVE_MODE=false

    # Use centralized logging
    exec 1> >(tee -a /opt/my-secure-ha-stack/logs/master-deployment.log)
    exec 2> >(tee -a /opt/my-secure-ha-stack/logs/master-deployment.log >&2)

    # Skip user prompts
    SKIP_PROMPTS=true
fi
```

---

**Document Version**: 1.0
**Last Updated**: August 7, 2025
**Maintained By**: Pure Bliss Elite Automation Team
**Update Frequency**: Real-time via automation scripts
