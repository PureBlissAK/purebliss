# Elite Container Scaffolding Framework - Usage Guide

## Overview

The Elite Container Scaffolding Framework implements a progressive 6-phase container build methodology designed to dramatically reduce errors during development and ensure robust, production-ready containers. This framework complements the infrastructure scaffolding to provide comprehensive error reduction throughout the entire development lifecycle.

## Quick Start

### 1. Generate Configuration Files
```bash
cd /opt/dev-purebliss
./container-config-generator.sh all
```

### 2. Generate Multi-Phase Dockerfile
```bash
./container-scaffold.sh generate nginx
./container-scaffold.sh generate redis
./container-scaffold.sh generate postgres
```

### 3. Build with Progressive Phases
```bash
# Build nginx through all 6 phases
./container-scaffold.sh build nginx

# Build only to phase 3 for testing
./container-scaffold.sh build redis 3

# Validate specific phase
./container-scaffold.sh validate postgres 2
```

## Framework Components

### Container Scaffolding Script (`container-scaffold.sh`)
- **Purpose**: Progressive container building with validation at each phase
- **Location**: `/opt/dev-purebliss/container-scaffold.sh`
- **Features**:
  - Multi-phase Dockerfile generation
  - Progressive build with validation
  - Phase-specific health checks
  - Automated error detection
  - Comprehensive logging

### Configuration Generator (`container-config-generator.sh`)
- **Purpose**: Generate phase-specific configuration files
- **Location**: `/opt/dev-purebliss/container-config-generator.sh`
- **Features**:
  - Service-specific configurations
  - Health check scripts
  - Monitoring configurations
  - Docker Compose overrides

## Phase Progression Strategy

### Phase 1: Minimal Container (Base Foundation)
```bash
./container-scaffold.sh build <service> 1
```
- **Features**: 20% of total functionality
- **Contents**: Minimal base image, core dependencies, basic health checks
- **Validation**: Container starts, basic functionality works
- **Use Case**: Initial development, proof of concept

### Phase 2: Enhanced Configuration (20% Features)
```bash
./container-scaffold.sh build <service> 2
```
- **Features**: 40% of total functionality
- **Contents**: Environment configuration, basic monitoring, structured logging
- **Validation**: Configuration syntax, logging verification
- **Use Case**: Development environment setup

### Phase 3: Service Integration (40% Features)
```bash
./container-scaffold.sh build <service> 3
```
- **Features**: 60% of total functionality
- **Contents**: Database connectivity, external APIs, service discovery
- **Validation**: Integration tests, connectivity verification
- **Use Case**: Integration testing, service mesh

### Phase 4: Advanced Features (60% Features)
```bash
./container-scaffold.sh build <service> 4
```
- **Features**: 80% of total functionality
- **Contents**: Advanced security, performance optimization, distributed tracing
- **Validation**: Security scans, performance tests
- **Use Case**: Staging environment, performance testing

### Phase 5: Production Readiness (80% Features)
```bash
./container-scaffold.sh build <service> 5
```
- **Features**: 95% of total functionality
- **Contents**: Production security, full observability, resilience features
- **Validation**: Production readiness checks, compliance validation
- **Use Case**: Pre-production, compliance testing

### Phase 6: Elite Features (100% Features)
```bash
./container-scaffold.sh build <service> 6
```
- **Features**: 100% of total functionality
- **Contents**: AI/ML integration, advanced analytics, chaos engineering
- **Validation**: Elite feature testing, self-healing validation
- **Use Case**: Production deployment, advanced operations

## Supported Services

### Currently Implemented
- **nginx**: Web server with progressive security and performance features
- **redis**: In-memory database with clustering and monitoring
- **postgres**: Database with replication and backup features
- **vault**: Secrets management with advanced security
- **prometheus**: Metrics collection with advanced alerting
- **grafana**: Visualization with custom dashboards
- **loki**: Log aggregation with advanced queries

### Generic Service Support
- Automatic Dockerfile generation for any service
- Configurable phase progression
- Standard validation framework

## Error Reduction Strategies

### 1. Progressive Complexity
- Start with minimal, working container
- Add complexity incrementally
- Validate at each step
- Catch errors early in simple configurations

### 2. Comprehensive Validation
- Health checks at every phase
- Configuration syntax validation
- Integration testing
- Performance benchmarking

### 3. Automated Recovery
- Rollback to previous phase on failure
- Detailed error logging and diagnosis
- Suggested fixes for common issues
- Automated retry with exponential backoff

### 4. Configuration Management
- Phase-specific configuration files
- Environment-based overrides
- Validation before deployment
- Backup and restore capabilities

## Usage Examples

### Example 1: New Service Development
```bash
# Start with basic nginx
./container-scaffold.sh build nginx 1

# Add enhanced configuration
./container-scaffold.sh build nginx 2

# Continue through phases as needed
./container-scaffold.sh build nginx 3
```

### Example 2: Production Deployment
```bash
# Generate all configurations
./container-config-generator.sh all

# Build production-ready container
./container-scaffold.sh build nginx 6

# Validate production readiness
./container-scaffold.sh validate nginx 5
./container-scaffold.sh validate nginx 6
```

### Example 3: Debugging Container Issues
```bash
# Start from minimal configuration
./container-scaffold.sh build redis 1

# Progressively add features until error occurs
./container-scaffold.sh build redis 2  # Success
./container-scaffold.sh build redis 3  # Failure

# Debug phase 3 specifically
./container-scaffold.sh validate redis 3
```

### Example 4: Multiple Service Orchestration
```bash
# Build all services to phase 3 for integration testing
./container-scaffold.sh build nginx 3
./container-scaffold.sh build redis 3
./container-scaffold.sh build postgres 3

# Use Docker Compose override for phase 3
docker-compose -f docker-compose.yml -f container-configs/compose/docker-compose.phase3.yml up
```

## Integration with Infrastructure Scaffolding

### Stage Correlation
- **Infrastructure Stage 1-2**: Use Container Phase 1-2
- **Infrastructure Stage 3-4**: Use Container Phase 3-4
- **Infrastructure Stage 5-6**: Use Container Phase 5-6

### Combined Workflow
```bash
# Check infrastructure stage
./scaffold-build.sh assess

# Build containers to matching phase
./container-scaffold.sh build nginx $INFRASTRUCTURE_STAGE
./container-scaffold.sh build redis $INFRASTRUCTURE_STAGE
```

## Monitoring and Observability

### Build Logs
- **Container Build Log**: `/raid-storage/logs/container-scaffold.log`
- **Development Log**: `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`
- **Phase-specific logs**: Per-container validation logs

### Health Monitoring
- Phase-specific health checks
- Automated monitoring setup
- Integration with Prometheus/Grafana
- Real-time build status

### Performance Metrics
- Build time per phase
- Container startup time
- Resource utilization
- Error rates and patterns

## Troubleshooting

### Common Issues

1. **Phase Build Failure**
   ```bash
   # Check specific phase logs
   ./container-scaffold.sh validate <service> <phase>

   # Rebuild from previous phase
   ./container-scaffold.sh build <service> $((phase-1))
   ```

2. **Configuration Errors**
   ```bash
   # Regenerate configurations
   ./container-config-generator.sh <service>

   # Validate configuration syntax
   docker run --rm -v "$PWD:/config" <service>:phase1 <service> -t -c /config/<service>.conf
   ```

3. **Health Check Failures**
   ```bash
   # Run manual health check
   ./container-configs/health-checks/<service>-health.sh

   # Check container logs
   docker logs <service>_phase<N>_test
   ```

### Debug Mode
```bash
# Enable detailed logging
export CONTAINER_SCAFFOLD_DEBUG=true
./container-scaffold.sh build <service> <phase>
```

## Advanced Features

### Custom Phase Configuration
- Extend phase definitions
- Service-specific validation
- Custom health checks
- Integration with CI/CD

### Automation Integration
```bash
# CI/CD integration
./container-scaffold.sh build all 6

# Automated testing
./container-scaffold.sh validate all 6
```

### Container Registry Integration
```bash
# Tag and push after successful build
docker tag <service>:phase6 registry.purebliss.app/<service>:latest
docker push registry.purebliss.app/<service>:latest
```

## Best Practices

1. **Always start with Phase 1** for new services
2. **Validate each phase** before proceeding
3. **Use phase-specific configurations** for different environments
4. **Monitor build performance** and optimize bottlenecks
5. **Implement automated rollback** for production deployments
6. **Document custom phases** for complex services
7. **Regular validation** of existing containers
8. **Integration testing** between phases

## Files and Locations

### Core Scripts
- `/opt/dev-purebliss/container-scaffold.sh` - Main scaffolding script
- `/opt/dev-purebliss/container-config-generator.sh` - Configuration generator

### Generated Files
- `/opt/dev-purebliss/container-builds/` - Multi-phase Dockerfiles
- `/opt/dev-purebliss/container-configs/` - Phase-specific configurations
- `/opt/dev-purebliss/container-configs/health-checks/` - Health check scripts
- `/opt/dev-purebliss/container-configs/compose/` - Docker Compose overrides

### Logs
- `/raid-storage/logs/container-scaffold.log` - Container scaffolding logs
- `/opt/my-secure-ha-stack/logs/dev-environment-setup.log` - Development logs

This framework ensures that container builds are robust, error-free, and progressively enhanced while maintaining full compatibility with existing infrastructure and development workflows.
