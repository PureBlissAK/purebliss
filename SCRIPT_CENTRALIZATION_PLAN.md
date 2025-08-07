# Script Centralization & Management Plan

## Overview
Centralize all Pure Bliss development scripts to `/opt/dev-purebliss/dev_scripts/` to eliminate duplicates, enhance integration, and improve maintainability across the platform.

## Current Script Distribution Analysis

### Primary Script Locations
- `/opt/dev-purebliss/` - Main development scripts (30+ files)
- `/opt/dev-purebliss/services/*/` - Service-specific scripts scattered across service directories
- `/opt/dev_scripts/` - Legacy scripts that need migration
- `/opt/pure-bliss-dev/tools/` - Development tools that need integration
- `/opt/dev-purebliss/container-configs/health-checks/` - Health check scripts
- `/opt/dev-purebliss/autonomous-scripts/` - Autonomous enhancement scripts

### Target Directory Structure

```
/opt/dev-purebliss/dev_scripts/
├── core/                          # Core infrastructure scripts
│   ├── validate-container-health.sh
│   ├── upstream-validation.sh
│   ├── container-scaffold.sh
│   └── start-all-services.sh
├── services/                      # Service-specific scripts
│   ├── vault/
│   │   ├── vault-entrypoint.sh
│   │   ├── vault-break-fix.sh
│   │   └── vault-secrets.sh
│   ├── postgres/
│   │   ├── postgres-entrypoint.sh
│   │   ├── postgres-health.sh
│   │   └── vault-entrypoint.sh
│   ├── redis/
│   │   ├── redis-entrypoint.sh
│   │   └── redis-health.sh
│   ├── nginx/
│   │   ├── nginx-entrypoint.sh
│   │   ├── nginx-health.sh
│   │   └── renew-certificates.sh
│   ├── keycloak/
│   ├── grafana/
│   ├── prometheus/
│   ├── loki/
│   ├── plane/
│   ├── codeserver/
│   └── letsencrypt/
├── automation/                    # Automation and enhancement scripts
│   ├── autonomous-enhancements.sh
│   ├── container-cleanup.sh
│   ├── enhance-container-with-vault.sh
│   └── script-enhancements.sh
├── health-checks/                 # Health validation scripts
│   ├── comprehensive-health-check.sh
│   ├── service-health-templates/
│   └── dependency-validation/
├── deployment/                    # Deployment and orchestration
│   ├── deploy-service-template.sh
│   ├── orchestrator-scripts/
│   └── sequential-startup.sh
├── utilities/                     # Utility and helper scripts
│   ├── env-management.sh
│   ├── log-management.sh
│   ├── backup-utilities.sh
│   └── template-generator.sh
└── legacy/                        # Temporary location for scripts being migrated
    └── migration-log.md
```

## Script Migration Priority Matrix

| Priority | Category | Scripts | Impact | Dependencies |
|----------|----------|---------|---------|--------------|
| **🔥 HIGH** | Core Infrastructure | validate-container-health.sh, upstream-validation.sh, container-scaffold.sh | Critical for all services | None |
| **🔥 HIGH** | Service Entrypoints | All service entrypoint.sh files | Service startup and health | Core scripts |
| **⚠️ MEDIUM** | Health Checks | service-specific health scripts | Service monitoring | Core validation |
| **⚠️ MEDIUM** | Automation | Enhancement and cleanup scripts | Development workflow | Service scripts |
| **📋 LOW** | Utilities | Template generators, log management | Development efficiency | None |
| **📋 LOW** | Legacy Migration | /opt/dev_scripts/, /opt/pure-bliss-dev/tools/ | Platform cleanup | All others |

## Migration Workflow

### Phase 1: Core Infrastructure Scripts (HIGH PRIORITY)
```bash
# 1. Create centralized directory structure
mkdir -p /opt/dev-purebliss/dev_scripts/{core,services,automation,health-checks,deployment,utilities,legacy}

# 2. Move and update core scripts
mv /opt/dev-purebliss/validate-container-health.sh /opt/dev-purebliss/dev_scripts/core/
mv /opt/dev-purebliss/upstream-validation.sh /opt/dev-purebliss/dev_scripts/core/
mv /opt/dev-purebliss/container-scaffold.sh /opt/dev-purebliss/dev_scripts/core/
mv /opt/dev-purebliss/start-all-services.sh /opt/dev-purebliss/dev_scripts/core/

# 3. Update script references in all calling scripts and documentation
```

### Phase 2: Service-Specific Scripts (HIGH PRIORITY)
```bash
# Create service subdirectories
for service in vault postgres redis nginx keycloak grafana prometheus loki plane codeserver letsencrypt; do
    mkdir -p /opt/dev-purebliss/dev_scripts/services/$service
done

# Move service scripts (per service during container work)
# Example for postgres:
mv /opt/dev-purebliss/services/postgres/*.sh /opt/dev-purebliss/dev_scripts/services/postgres/
```

### Phase 3: Automation & Enhancement Scripts (MEDIUM PRIORITY)
```bash
# Move automation scripts
mv /opt/dev-purebliss/enhance-*.sh /opt/dev-purebliss/dev_scripts/automation/
mv /opt/dev-purebliss/container-cleanup.sh /opt/dev-purebliss/dev_scripts/automation/
mv /opt/dev-purebliss/autonomous-scripts/* /opt/dev-purebliss/dev_scripts/automation/
```

### Phase 4: Health Check & Utility Scripts (MEDIUM PRIORITY)
```bash
# Move health check scripts
mv /opt/dev-purebliss/container-configs/health-checks/* /opt/dev-purebliss/dev_scripts/health-checks/
mv /opt/dev-purebliss/comprehensive-health-check.sh /opt/dev-purebliss/dev_scripts/health-checks/

# Move utility scripts
mv /opt/pure-bliss-dev/tools/env-*.sh /opt/dev-purebliss/dev_scripts/utilities/
mv /opt/pure-bliss-dev/tools/log-*.sh /opt/dev-purebliss/dev_scripts/utilities/
```

### Phase 5: Legacy Script Migration (LOW PRIORITY)
```bash
# Move legacy scripts for evaluation and potential integration
mv /opt/dev_scripts/* /opt/dev-purebliss/dev_scripts/legacy/
mv /opt/pure-bliss-dev/tools/* /opt/dev-purebliss/dev_scripts/legacy/
```

## Reference Update Strategy

### Automated Reference Detection
```bash
# Find all references to scripts that will be moved
grep -r "validate-container-health.sh" /opt/dev-purebliss/ --include="*.sh" --include="*.md"
grep -r "upstream-validation.sh" /opt/dev-purebliss/ --include="*.sh" --include="*.md"
grep -r "/services/.*\.sh" /opt/dev-purebliss/ --include="*.sh" --include="*.md"
```

### Reference Update Patterns
```bash
# Old reference patterns to find and replace:
./validate-container-health.sh                    → /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh
./upstream-validation.sh                          → /opt/dev-purebliss/dev_scripts/core/upstream-validation.sh
/opt/dev-purebliss/services/postgres/entrypoint.sh → /opt/dev-purebliss/dev_scripts/services/postgres/entrypoint.sh
./services/*/entrypoint.sh                        → /opt/dev-purebliss/dev_scripts/services/*/entrypoint.sh
```

## Integration Benefits

### Eliminate Script Duplication
- **Before**: 15+ copies of similar health check scripts across services
- **After**: Single centralized health check framework with service-specific configurations

### Enhanced Script Discovery
- **Before**: Scripts scattered across 10+ directories
- **After**: Logical categorization in single location with clear hierarchy

### Improved Maintenance
- **Before**: Updates require changes in multiple locations
- **After**: Single source of truth for all script modifications

### Better Version Control
- **Before**: Inconsistent script versions across services
- **After**: Centralized versioning and dependency management

## Implementation Timeline

### Per-Service Migration (During Container Work)
When working on each service container:
1. **Pre-Migration**: Identify all scripts used by the service
2. **Migration**: Move scripts to centralized location with proper categorization
3. **Reference Update**: Update all references in service files
4. **Validation**: Test service functionality with new script locations
5. **Service Restart Validation**: Guarantee 100% functionality through controlled restart
6. **Documentation**: Update service documentation with new script paths

### Service Restart Validation for 100% Functionality

**ENHANCEMENT**: After script migration, guarantee 100% functionality through controlled service restart and comprehensive validation.

#### Service Restart Validation Process
```bash
# Perform guaranteed functionality validation after script migration
/opt/dev-purebliss/dev_scripts/utilities/service-restart-validation.sh <service> --full-validation

# Example for PostgreSQL service after script migration
/opt/dev-purebliss/dev_scripts/utilities/service-restart-validation.sh postgres --full-validation

# Force restart for critical validation
/opt/dev-purebliss/dev_scripts/utilities/service-restart-validation.sh nginx --force --wait-time 60
```

#### Restart Validation Features
- **Pre-restart Log Backup**: Automatic backup of service logs before restart
- **Dependency Validation**: Confirms all service dependencies are healthy
- **Graceful Restart**: Controlled shutdown and startup with proper wait times
- **Comprehensive Health Validation**: Full health check integration with retry logic
- **Functionality Testing**: Service-specific functionality validation
- **Performance Baseline**: Ensures service performance meets standards
- **Integration Verification**: Confirms service integration with dependencies

#### Validation Process Steps
1. **Pre-Restart Health Check**: Validates current service state
2. **Log Backup**: Creates timestamped backup of service logs
3. **Dependency Validation**: Confirms all required dependencies are healthy
4. **Graceful Shutdown**: Stops service with proper cleanup
5. **Service Restart**: Starts service with monitored initialization
6. **Health Validation**: Comprehensive health check with retry logic
7. **Functionality Test**: Service-specific operation validation
8. **Integration Verification**: Confirms service works with dependencies
9. **Performance Check**: Validates service meets performance baselines

#### Success Criteria
- ✅ **Service Health**: Container reports healthy status
- ✅ **Functionality**: Service-specific operations work correctly
- ✅ **Dependencies**: All required dependencies accessible and functional
- ✅ **Performance**: Service meets response time and resource usage baselines
- ✅ **Integration**: Service properly integrated with other components
- ✅ **Logging**: All operations properly logged and monitored
6. **Git Commit**: Commit migration as part of service enhancement

### Batch Migration Tasks
- **Week 1**: Core infrastructure scripts (validate-container-health.sh, upstream-validation.sh)
- **Week 2-3**: Service scripts (during individual service container work)
- **Week 4**: Automation and utility scripts
- **Week 5**: Legacy script evaluation and cleanup

## Success Metrics

### Quantitative Goals
- **Script Reduction**: 50% reduction in total script files through deduplication
- **Reference Accuracy**: 100% of script references updated to new locations
- **Test Coverage**: All migrated scripts pass existing functionality tests
- **Documentation**: 100% of services have updated script path documentation

### Quality Improvements
- **Consistency**: Standardized script structure and naming conventions
- **Maintainability**: Single location for script updates and enhancements
- **Integration**: Improved cross-service script sharing and reuse
- **Error Reduction**: Elimination of "script not found" errors from path changes

## Risk Mitigation

### Backup Strategy
```bash
# Create backup of current script distribution before migration
tar -czf /opt/dev-purebliss/backups/scripts-pre-centralization-$(date +%Y%m%d).tar.gz \
    /opt/dev-purebliss/*.sh \
    /opt/dev-purebliss/services/ \
    /opt/dev-purebliss/container-configs/ \
    /opt/dev_scripts/ \
    /opt/pure-bliss-dev/tools/
```

### Rollback Procedures
- **Git-based rollback**: All migrations committed atomically per service
- **Script backup**: Original scripts preserved in /opt/dev-purebliss/dev_scripts/legacy/
- **Reference mapping**: Complete mapping of old→new paths for quick restoration

### Testing Strategy
- **Functionality testing**: Each migrated script tested in isolation
- **Integration testing**: Service-level testing after script migration
- **Health validation**: Comprehensive health checks after each service migration
- **Rollback testing**: Verify rollback procedures work before migration

---

## Implementation Commands

### Create Directory Structure
```bash
# Execute this during Phase 1 of migration
mkdir -p /opt/dev-purebliss/dev_scripts/{core,services,automation,health-checks,deployment,utilities,legacy}
for service in vault postgres redis nginx keycloak grafana prometheus loki plane codeserver letsencrypt; do
    mkdir -p /opt/dev-purebliss/dev_scripts/services/$service
done
echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_CENTRALIZATION: Created centralized directory structure" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
```

### Migration Validation Command
```bash
# Validate script migration for each service
validate_script_migration() {
    local service=$1
    echo "Validating script migration for $service..."

    # Check all expected scripts are in new location
    local script_dir="/opt/dev-purebliss/dev_scripts/services/$service"
    if [[ -d "$script_dir" ]]; then
        echo "✓ Service script directory exists: $script_dir"
        ls -la "$script_dir"
    else
        echo "✗ Service script directory missing: $script_dir"
        return 1
    fi

    # Test script execution from new location
    if [[ -f "$script_dir/entrypoint.sh" ]]; then
        echo "✓ Service entrypoint script found"
        bash -n "$script_dir/entrypoint.sh" && echo "✓ Entrypoint syntax valid" || echo "✗ Entrypoint syntax error"
    fi

    return 0
}
```

This comprehensive script centralization plan will be implemented progressively during our container enhancement work, ensuring no disruption to existing functionality while significantly improving our development workflow and script management.
