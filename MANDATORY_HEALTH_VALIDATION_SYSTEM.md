# Mandatory Health Validation System

## Overview

The Mandatory Health Validation System ensures no task progression with unhealthy containers, implementing comprehensive health gates after every development task. This system prevents cascading failures and maintains service integrity throughout the development workflow.

## Core Components

### 1. Primary Health Validation Script
- **Location**: `/opt/dev-purebliss/validate-container-health.sh`
- **Purpose**: Comprehensive container health validation with service-specific checks
- **Usage**: `./validate-container-health.sh <service_name> [task_name]`

### 2. Integration Example
- **Location**: `/opt/dev-purebliss/health-validation-integration-example.sh`
- **Purpose**: Demonstrates proper integration of health validation in task workflows
- **Usage**: `./health-validation-integration-example.sh`

### 3. Health Validation Logs
- **Primary Log**: `/opt/my-secure-ha-stack/logs/container-health-validation.log`
- **Development Log**: `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`
- **Health Reports**: `/opt/my-secure-ha-stack/logs/health-reports/`

## Validation Workflow

### Step 1: Container Existence Validation
- Verifies container is running
- Checks container state if stopped
- Provides debug information for failures

### Step 2: Docker Health Status
- Monitors Docker native health checks
- Waits for health check completion (up to 60 seconds)
- Reports health check details on failure

### Step 3: Service-Specific Endpoint Validation
- **Nginx**: HTTP/HTTPS health endpoints, status page
- **Vault**: Health endpoint, initialization/seal status
- **PostgreSQL**: Connection readiness, database access
- **Redis**: Ping test, basic operations
- **Keycloak**: Health endpoint
- **Plane**: API health endpoint
- **CodeServer**: Health endpoint
- **Prometheus**: Health endpoint
- **Grafana**: API health endpoint
- **Loki**: Ready endpoint

### Step 4: Dependency Validation
- **Keycloak**: Requires PostgreSQL and Redis
- **Plane**: Requires PostgreSQL and Redis
- **Nginx**: Optional Vault dependency
- Network connectivity testing between services

### Step 5: Performance Baseline
- CPU usage monitoring (threshold: 80%)
- Memory usage monitoring (threshold: 90%)
- Performance trend tracking

### Step 6: Health Report Generation
- JSON health reports archived
- Detailed validation results
- Actionable next steps

## Exit Codes

| Code | Status | Action |
|------|--------|---------|
| 0 | Healthy | Proceed to next task |
| 1 | Unhealthy | Stop and remediate issues |
| 2 | Critical | Immediate intervention required |

## Integration Requirements

### Mandatory Usage
Every task MUST include health validation:

```bash
# After completing any task
if /opt/dev-purebliss/validate-container-health.sh "$SERVICE_NAME" "$TASK_NAME"; then
    echo "✅ Health validation passed - proceeding"
    # Continue to next task
else
    echo "❌ Health validation failed - stopping"
    exit 1
fi
```

### Task Integration Examples

#### Build Phase Integration
```bash
# Build container
docker-compose build nginx

# MANDATORY: Health validation
/opt/dev-purebliss/validate-container-health.sh nginx build-phase

# Only proceed if validation passes
```

#### Configuration Update Integration
```bash
# Update configuration
cp new-config.conf /opt/my-secure-ha-stack/nginx/

# Restart service
docker-compose restart nginx

# MANDATORY: Health validation
/opt/dev-purebliss/validate-container-health.sh nginx config-update

# Only proceed if validation passes
```

#### Integration Test Integration
```bash
# Run integration tests
./run-integration-tests.sh keycloak

# MANDATORY: Health validation
/opt/dev-purebliss/validate-container-health.sh keycloak integration-test

# Only proceed if validation passes
```

## Service-Specific Validation Details

### Nginx Validation
- HTTP health endpoint: `http://localhost/health`
- HTTPS health endpoint: `https://localhost/health`
- Status endpoint: `http://localhost/status`
- Optional Vault dependency check

### Vault Validation
- Health endpoint: `http://localhost:8200/v1/sys/health`
- Initialization status check
- Seal status verification
- Development mode considerations

### PostgreSQL Validation
- Ready check: `pg_isready`
- Connection test: Basic SQL query
- Database accessibility verification

### Redis Validation
- Ping connectivity test
- Basic operations: SET/GET/DEL
- Memory and performance checks

### Keycloak Validation
- Health endpoint: `http://localhost:8080/health`
- PostgreSQL dependency validation
- Redis dependency validation

### Plane Validation
- API health endpoint: `http://localhost:3000/api/health`
- PostgreSQL dependency validation
- Redis dependency validation

## Troubleshooting Guide

### Health Validation Failures

#### Container Not Running
1. Check container status: `docker ps -a`
2. Review container logs: `docker logs purebliss-<service>`
3. Check docker-compose configuration
4. Verify service dependencies

#### Endpoint Not Responding
1. Verify service is fully started
2. Check port mappings and networking
3. Review service-specific configuration
4. Test endpoint manually with curl

#### Dependency Failures
1. Verify dependent services are running
2. Check network connectivity between containers
3. Review service startup order
4. Validate service configurations

#### Performance Issues
1. Monitor resource usage: `docker stats`
2. Check system resources
3. Review container resource limits
4. Optimize service configurations

### Log Analysis

#### Health Validation Log
```bash
tail -f /opt/my-secure-ha-stack/logs/container-health-validation.log
```

#### Development Environment Log
```bash
grep "HEALTH_VALIDATION" /opt/my-secure-ha-stack/logs/dev-environment-setup.log
```

#### Health Reports
```bash
ls -la /opt/my-secure-ha-stack/logs/health-reports/
cat /opt/my-secure-ha-stack/logs/health-reports/health-report-nginx-build-phase.json
```

## Best Practices

### 1. Never Skip Health Validation
- Health validation is MANDATORY after every task
- No exceptions for "simple" tasks
- Always wait for validation completion

### 2. Use Descriptive Task Names
- Include task type: build, config, test, integration
- Use consistent naming: `service-task-type`
- Examples: `nginx-smart-upstream-config`, `vault-ssl-integration`

### 3. Monitor Health Trends
- Review health reports regularly
- Track performance baselines
- Identify recurring issues

### 4. Remediate Before Proceeding
- Address ALL health validation failures
- Do not mask or ignore issues
- Verify fixes with re-validation

### 5. Log Everything
- All health validations are logged
- Include context and task information
- Archive reports for trend analysis

## Integration with Smart Upstream Solution

The health validation system integrates seamlessly with the smart upstream solution:

1. **Nginx Smart Upstream**: Validates upstream configuration and fallback logic
2. **Service Notification**: Confirms services properly notify nginx when healthy
3. **Dynamic Reconfiguration**: Validates nginx reconfiguration after upstream changes
4. **End-to-End Testing**: Ensures complete upstream workflow health

## Automation Integration

### CI/CD Pipeline Integration
```yaml
# Example GitHub Actions integration
- name: Health Validation
  run: |
    /opt/dev-purebliss/validate-container-health.sh ${{ matrix.service }} ci-build
  continue-on-error: false
```

### Monitoring Integration
- Health validation results feed into Prometheus metrics
- Grafana dashboards track validation trends
- Loki logs provide detailed validation history

## Future Enhancements

### Planned Features
1. **Custom Health Checks**: Service-specific health check definitions
2. **Performance Profiling**: Detailed performance analysis and recommendations
3. **Automated Remediation**: Basic issue auto-fixing capabilities
4. **Health Metrics**: Integration with monitoring stack for health trends
5. **Notification System**: Alert on health validation failures

### Extension Points
- Custom endpoint validators
- Service-specific performance thresholds
- Integration with external monitoring systems
- Automated health reporting
