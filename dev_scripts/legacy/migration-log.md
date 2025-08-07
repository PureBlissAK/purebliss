# Script Migration Tracking Log

## Migration Progress

### Phase 1: Directory Structure Setup ✅ COMPLETED
- **Date**: $(date '+%Y-%m-%d %H:%M:%S')
- **Action**: Created centralized directory structure
- **Location**: `/opt/dev-purebliss/dev_scripts/`
- **Subdirectories**: core, services, automation, health-checks, deployment, utilities, legacy
- **Service Directories**: vault, postgres, redis, nginx, keycloak, grafana, prometheus, loki, plane, codeserver, letsencrypt

### Initial Migration ✅ COMPLETED
- **vault-secrets.sh**: `/opt/dev-purebliss/dev_scripts/vault-secrets.sh` → `/opt/dev-purebliss/dev_scripts/services/vault/vault-secrets.sh`
- **postgres/vault-entrypoint.sh**: `/opt/dev-purebliss/services/postgres/vault-entrypoint.sh` → `/opt/dev-purebliss/dev_scripts/services/postgres/vault-entrypoint.sh` ✅ **MIGRATED**

## Pending Migrations

### Core Infrastructure Scripts (HIGH PRIORITY)
- [ ] `/opt/dev-purebliss/validate-container-health.sh` → `/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh`
- [ ] `/opt/dev-purebliss/upstream-validation.sh` → `/opt/dev-purebliss/dev_scripts/core/upstream-validation.sh`
- [ ] `/opt/dev-purebliss/container-scaffold.sh` → `/opt/dev-purebliss/dev_scripts/core/container-scaffold.sh`
- [ ] `/opt/dev-purebliss/start-all-services.sh` → `/opt/dev-purebliss/dev_scripts/core/start-all-services.sh`

### Service-Specific Scripts (Per Service During Container Work)
#### PostgreSQL Service Scripts
- [ ] `/opt/dev-purebliss/services/postgres/entrypoint.sh` → `/opt/dev-purebliss/dev_scripts/services/postgres/entrypoint.sh`
- [ ] `/opt/dev-purebliss/services/postgres/vault-entrypoint.sh` → `/opt/dev-purebliss/dev_scripts/services/postgres/vault-entrypoint.sh`
- [ ] `/opt/dev-purebliss/services/postgres/start-postgres-vault.sh` → `/opt/dev-purebliss/dev_scripts/services/postgres/start-postgres-vault.sh`

#### Redis Service Scripts
- [ ] `/opt/dev-purebliss/services/redis/*.sh` → `/opt/dev-purebliss/dev_scripts/services/redis/`

#### Nginx Service Scripts
- [ ] `/opt/dev-purebliss/services/nginx/*.sh` → `/opt/dev-purebliss/dev_scripts/services/nginx/`

### Automation Scripts (MEDIUM PRIORITY)
- [ ] `/opt/dev-purebliss/enhance-*.sh` → `/opt/dev-purebliss/dev_scripts/automation/`
- [ ] `/opt/dev-purebliss/container-cleanup.sh` → `/opt/dev-purebliss/dev_scripts/automation/`
- [ ] `/opt/dev-purebliss/autonomous-scripts/*` → `/opt/dev-purebliss/dev_scripts/automation/`

### Health Check Scripts (MEDIUM PRIORITY)
- [ ] `/opt/dev-purebliss/comprehensive-health-check.sh` → `/opt/dev-purebliss/dev_scripts/health-checks/`
- [ ] `/opt/dev-purebliss/container-configs/health-checks/*` → `/opt/dev-purebliss/dev_scripts/health-checks/`

### Utility Scripts (LOW PRIORITY)
- [ ] Various utility scripts from `/opt/pure-bliss-dev/tools/` → `/opt/dev-purebliss/dev_scripts/utilities/`

### Legacy Scripts (LOW PRIORITY)
- [ ] `/opt/dev_scripts/*` → `/opt/dev-purebliss/dev_scripts/legacy/` (for evaluation)
- [ ] `/opt/pure-bliss-dev/tools/*` → `/opt/dev-purebliss/dev_scripts/legacy/` (for evaluation)

## Migration Rules

1. **Service-Specific Migration**: Migrate scripts during individual service container work
2. **Reference Updates**: Update all script references in files that call migrated scripts
3. **Testing**: Validate functionality after each migration
4. **Documentation**: Update service documentation with new script paths
5. **Git Integration**: Include script migration in service enhancement commits
6. **Backup**: Original script locations preserved until migration validation complete

## Reference Update Tracking

### Scripts That Need Reference Updates
When migrating these scripts, update references in:

#### validate-container-health.sh
- Called from: service deployment scripts, project automation, manual validation
- Reference pattern: `./validate-container-health.sh`
- New pattern: `/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh`

#### upstream-validation.sh
- Called from: service entrypoints, nginx configuration scripts
- Reference pattern: `./upstream-validation.sh`
- New pattern: `/opt/dev-purebliss/dev_scripts/core/upstream-validation.sh`

#### Service Entrypoints
- Called from: docker-compose files, manual service startup
- Reference pattern: `./services/<service>/entrypoint.sh`
- New pattern: `/opt/dev-purebliss/dev_scripts/services/<service>/entrypoint.sh`

## Success Metrics

### Completed Migrations
- [x] Directory structure creation
- [x] Initial vault-secrets.sh migration

### Target Metrics
- [ ] 50% reduction in total script files through deduplication
- [ ] 100% of script references updated to new centralized paths
- [ ] Zero "script not found" errors after migration
- [ ] All migrated scripts pass existing functionality tests

## Next Actions

1. **Phase 2**: During PostgreSQL container work, migrate postgres service scripts
2. **Core Migration**: Move core infrastructure scripts (validate-container-health.sh, upstream-validation.sh)
3. **Reference Updates**: Update all calling scripts and documentation
4. **Validation**: Test each migration thoroughly before proceeding

---
**Last Updated**: $(date '+%Y-%m-%d %H:%M:%S')
**Migration Status**: Directory structure complete, ready for progressive script migration during container work
