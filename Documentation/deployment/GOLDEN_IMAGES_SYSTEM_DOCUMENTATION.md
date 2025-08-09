# Golden Container Images System Documentation

**Generated/Updated**: 2025-01-07 18:30:00
**Purpose**: Comprehensive documentation for golden container images creation and RAID storage deployment
**Consolidation Type**: deployment
**Services Covered**: All PureBliss services

## Overview

The Golden Container Images System provides enterprise-grade backup and rapid deployment capabilities for the PureBliss development environment. This system creates versioned, validated snapshots of all containers after they achieve 100% health validation, storing them in RAID storage for redundancy and disaster recovery.

## Key Features

### 🏆 Production-Ready Container Snapshots
- **100% Health Validation Required**: Only containers passing comprehensive health checks become golden images
- **Service-Specific Validation**: Custom health checks for each service type (Vault seal status, PostgreSQL connectivity, NGINX configuration validation)
- **Comprehensive Testing**: Full container lifecycle validation before image creation

### 💾 RAID Storage Integration
- **Storage Location**: `/opt/raid-storage/golden-images/`
- **Compressed Format**: Gzip compression for efficient storage utilization
- **Redundancy**: RAID array provides data protection and redundancy
- **Versioning**: Timestamped versions for rollback capabilities

### 🚀 Rapid Deployment and Recovery
- **One-Command Creation**: Single script execution creates all golden images
- **One-Command Restoration**: Complete environment restoration from golden images
- **Disaster Recovery**: 15-30 minute full environment restoration capability
- **Automated Backup**: Existing containers backed up before restoration

## Script Components

### Creation Script: `create-golden-images.sh`

**Location**: `/opt/dev-purebliss/dev_scripts/deployment/create-golden-images.sh`

**Purpose**: Creates golden images of all healthy containers with comprehensive validation

**Features**:
- **Health Validation Phase**: Validates all services before image creation
- **Service-Specific Checks**: Custom validation for each service type
- **Image Creation**: Docker commit with versioning and metadata
- **RAID Storage**: Compressed storage in RAID array
- **Manifest Generation**: JSON manifest with deployment instructions
- **Integrity Testing**: Validation of created golden images

**Usage**:
```bash
# Create golden images of all healthy containers
/opt/dev-purebliss/dev_scripts/deployment/create-golden-images.sh
```

**Output**:
- Golden images stored in `/opt/raid-storage/golden-images/`
- Comprehensive manifest: `golden-images-manifest.json`
- Detailed logging to development log
- Integrity validation reports

### Restoration Script: `restore-golden-images.sh`

**Location**: `/opt/dev-purebliss/dev_scripts/deployment/restore-golden-images.sh`

**Purpose**: Restores complete environment from golden images stored in RAID

**Features**:
- **Backup Creation**: Backs up existing containers before restoration
- **Sequential Restoration**: Follows proper service dependency order
- **Integrity Validation**: Validates golden images before loading
- **Health Validation**: Post-restoration health checks
- **Restoration Reporting**: Detailed restoration reports and logging

**Usage**:
```bash
# Restore environment from golden images
/opt/dev-purebliss/dev_scripts/deployment/restore-golden-images.sh
```

**Deployment Sequence**:
1. vault
2. postgres
3. redis
4. keycloak
5. nginx
6. prometheus
7. grafana
8. loki
9. plane
10. codeserver

## RAID Storage Structure

```
/opt/raid-storage/
├── golden-images/
│   ├── purebliss-vault-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-postgres-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-redis-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-nginx-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-keycloak-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-grafana-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-prometheus-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-loki-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-plane-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── purebliss-codeserver-golden-v1.0-golden-20250107-120000.tar.gz
│   ├── golden-images-manifest.json
│   └── restoration-report-20250107-130000.json
└── container-backups/
    └── 20250107-130000/
        ├── purebliss-vault-backup.tar
        ├── purebliss-postgres-backup.tar
        └── ...
```

## Golden Images Manifest

The `golden-images-manifest.json` file contains comprehensive metadata for deployment:

```json
{
    "golden_images_deployment": {
        "creation_date": "2025-01-07T12:00:00Z",
        "version": "v1.0-golden-20250107-120000",
        "total_services": 10,
        "services_created": 10,
        "services_failed": 0,
        "raid_storage_path": "/opt/raid-storage/golden-images",
        "health_validation": "100% PASSED",
        "deployment_status": "READY",
        "services": [
            {
                "service_name": "vault",
                "container_name": "purebliss-vault",
                "golden_image": "purebliss-vault-golden:v1.0-golden-20250107-120000",
                "storage_file": "purebliss-vault-golden-v1.0-golden-20250107-120000.tar.gz",
                "compressed_size": "245M",
                "health_status": "VALIDATED",
                "deployment_ready": true
            }
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
            "backup_location": "/opt/raid-storage/golden-images",
            "restore_time_estimate": "15-30 minutes",
            "rollback_capability": true,
            "automated_restore": true
        }
    }
}
```

## Health Validation Integration

### Pre-Creation Validation
- **Container Status**: Verify container is running and responsive
- **Service-Specific Checks**: Custom validation for each service type
- **Vault**: Seal status and health endpoint validation
- **PostgreSQL**: Connection acceptance and readiness checks
- **NGINX**: Configuration validation and syntax checking
- **Keycloak**: Health endpoint and authentication service validation

### Post-Restoration Validation
- **Container Health**: Comprehensive health validation after restoration
- **Service Connectivity**: Verify inter-service communication
- **Integration Testing**: End-to-end functionality validation
- **Performance Baseline**: Ensure restored services meet performance requirements

## Operational Procedures

### Creating Golden Images

1. **Prerequisites**:
   - All services must be running and healthy
   - 100% health validation must pass for all services
   - RAID storage must be available and mounted

2. **Execution**:
   ```bash
   # Verify all services are healthy
   /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh all comprehensive

   # Create golden images
   /opt/dev-purebliss/dev_scripts/deployment/create-golden-images.sh
   ```

3. **Validation**:
   - Review creation logs for any failures
   - Verify golden images exist in RAID storage
   - Validate manifest file creation
   - Check integrity of compressed images

### Restoring from Golden Images

1. **Prerequisites**:
   - RAID storage must be available and mounted
   - Golden images manifest must exist
   - Backup existing environment (handled automatically)

2. **Execution**:
   ```bash
   # Restore from golden images
   /opt/dev-purebliss/dev_scripts/deployment/restore-golden-images.sh
   ```

3. **Post-Restoration**:
   - Execute comprehensive health validation
   - Verify service connectivity
   - Run integration tests
   - Confirm operational status

## Integration with Fort Knox Security

### Critical Timing Requirement
**🚨 CRITICAL**: Golden images must be created BEFORE Fort Knox security hardening deployment.

**Reason**: Fort Knox security hardening implements maximum security measures that may affect container behavior. Golden images should capture the clean, functional baseline before security hardening.

**Workflow**:
1. Complete all service development and integration
2. Achieve 100% health validation across all services
3. **CREATE GOLDEN IMAGES** (baseline containers)
4. Deploy Fort Knox security hardening
5. Create post-security golden images (optional, for hardened baseline)

### Security Considerations
- **Access Control**: RAID storage protected with appropriate file permissions
- **Encryption**: Consider encryption-at-rest for golden images containing sensitive data
- **Audit Trail**: All golden image operations logged to development log
- **Integrity Validation**: Cryptographic checksums for golden image integrity

## Disaster Recovery Procedures

### Complete Environment Loss Scenario

1. **Immediate Response**:
   - Assess scope of environment loss
   - Ensure RAID storage integrity
   - Validate golden images availability

2. **Recovery Execution**:
   ```bash
   # Mount RAID storage (if needed)
   # Restore complete environment
   /opt/dev-purebliss/dev_scripts/deployment/restore-golden-images.sh
   ```

3. **Post-Recovery Validation**:
   - Comprehensive health validation
   - Service connectivity testing
   - Data integrity verification
   - Performance baseline confirmation

4. **Recovery Time Objective**: 15-30 minutes for complete environment restoration

### Partial Service Recovery

1. **Service-Specific Restoration**:
   - Identify failed service
   - Restore specific golden image
   - Validate service integration

2. **Integration Testing**:
   - Verify restored service connectivity
   - Test dependent services
   - Confirm end-to-end functionality

## Monitoring and Alerting

### Golden Images Health Monitoring
- **Storage Space**: Monitor RAID storage utilization
- **Image Integrity**: Periodic integrity validation
- **Creation Frequency**: Track golden image creation patterns
- **Restoration Testing**: Regular restoration testing in isolated environments

### Automated Alerts
- **Storage Threshold**: Alert when RAID storage reaches capacity thresholds
- **Integrity Failures**: Immediate alerts for golden image corruption
- **Creation Failures**: Alerts for failed golden image creation attempts
- **Restoration Issues**: Alerts for restoration failures or performance degradation

## Troubleshooting Guide

### Common Issues

#### Golden Image Creation Failures
**Symptom**: Script fails during image creation
**Causes**:
- Container not healthy/running
- Insufficient RAID storage space
- Docker daemon issues
- Permission problems

**Resolution**:
1. Verify container health status
2. Check RAID storage availability
3. Validate Docker daemon functionality
4. Verify script permissions and execution rights

#### Restoration Failures
**Symptom**: Golden image restoration fails
**Causes**:
- Corrupted golden images
- RAID storage unavailable
- Docker load failures
- Insufficient system resources

**Resolution**:
1. Validate golden image integrity
2. Check RAID storage mount status
3. Verify Docker functionality
4. Monitor system resource utilization

#### Performance Issues
**Symptom**: Slow golden image operations
**Causes**:
- RAID performance degradation
- Network storage latency
- System resource constraints
- Large container sizes

**Resolution**:
1. Monitor RAID performance metrics
2. Optimize storage configuration
3. Increase system resources
4. Consider container optimization

## Best Practices

### Creation Best Practices
- **Regular Schedule**: Create golden images after major updates or changes
- **Pre-Security Baseline**: Always create baseline images before security hardening
- **Validation Testing**: Test golden images in isolated environments
- **Documentation**: Maintain detailed logs of all golden image operations

### Storage Best Practices
- **RAID Configuration**: Use appropriate RAID level for redundancy and performance
- **Capacity Planning**: Monitor storage growth and plan capacity accordingly
- **Backup Strategy**: Consider off-site backup of critical golden images
- **Retention Policy**: Implement retention policy for older golden images

### Operational Best Practices
- **Change Management**: Coordinate golden image creation with change management
- **Testing Protocol**: Establish regular testing of restoration procedures
- **Access Control**: Implement proper access controls for golden image operations
- **Monitoring Integration**: Integrate with existing monitoring and alerting systems

## Future Enhancements

### Planned Improvements
- **Automated Scheduling**: Cron-based automated golden image creation
- **Incremental Backups**: Differential backup capabilities for efficiency
- **Cloud Integration**: Cloud storage backup integration
- **Encryption**: Encryption-at-rest for enhanced security
- **Compression Optimization**: Advanced compression algorithms for space efficiency

### Integration Opportunities
- **CI/CD Pipeline**: Integration with continuous deployment workflows
- **Monitoring Stack**: Enhanced integration with Prometheus/Grafana monitoring
- **Vault Integration**: Secure credential management for golden image operations
- **Automated Testing**: Automated validation testing of restored environments

## Conclusion

The Golden Container Images System provides enterprise-grade backup and disaster recovery capabilities for the PureBliss development environment. With comprehensive health validation, RAID storage redundancy, and automated restoration capabilities, this system ensures business continuity and rapid recovery from any environment failures.

The integration with the overall security and development workflow ensures that golden images capture clean, functional baselines while supporting the progression to Fort Knox security hardening and production-ready deployments.
