# Keycloak Automation Guide
**Pure Bliss Elite Standards - Service Independence & Vault Integration**
**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Overview

This guide covers the comprehensive automation for the Keycloak authentication service in the Pure Bliss development environment. The service provides enterprise-grade authentication, authorization, and SSO capabilities with full Vault integration and independent container operation.

## Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Keycloak      │    │     Vault       │    │   PostgreSQL    │
│   Container     │◄──►│   Secrets       │    │   Database      │
│  (Port 8080)    │    │   Management    │    │  (Port 5432)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │     Redis       │    │     Nginx       │
                    │    Caching      │    │    Gateway      │
                    │  (Port 6379)    │    │  (Port 80/443)  │
                    └─────────────────┘    └─────────────────┘
```

## Automation Components

### Container Management

**Base Image:** `quay.io/keycloak/keycloak:24.0.5`
**Container Name:** `purebliss-keycloak`
**Network:** `purebliss-net`
**Health Check:** `/realms/master` endpoint (Keycloak 24+ compatible)

### Entrypoint Features

**Enhanced Entrypoint:** `/opt/dev-purebliss/services/keycloak/entrypoint.sh`

1. **Dependency Management:**
   - PostgreSQL connectivity validation with exponential backoff
   - Redis connectivity validation for caching layer
   - Vault integration with multiple token source fallbacks

2. **Vault Integration:**
   - Dynamic secrets retrieval from `secret/keycloak/database`
   - Admin credentials from `secret/keycloak/admin`
   - Automatic fallback to environment defaults if Vault unavailable

3. **Database Configuration:**
   - Automatic PostgreSQL database creation if needed
   - User and permission management
   - Connection validation before service start

4. **Upstream Notification:**
   - Automatic nginx upstream notification when service healthy
   - Health monitoring with `/realms/master` endpoint
   - Integration with Pure Bliss upstream validation workflow

### Health Validation

**Health Check Script:** `/opt/dev-purebliss/validate-container-health.sh`

1. **Container Status Validation:**
   - Docker container running status
   - Health check status confirmation
   - Process validation

2. **Service Endpoint Testing:**
   - `/realms/master` endpoint for Keycloak 24+ compatibility
   - Response time and status code validation
   - Administrative console accessibility

3. **Dependency Validation:**
   - Sequential PostgreSQL connectivity and authentication
   - Redis connectivity for caching layer
   - Vault connectivity for secrets management

4. **Performance Monitoring:**
   - CPU and memory usage baselines
   - Container performance metrics
   - Resource utilization alerts

## Vault Integration Details

### Secrets Structure

```json
{
  "secret/keycloak/database": {
    "username": "keycloak",
    "password": "generated_secure_password",
    "database": "keycloak",
    "host": "purebliss-postgres",
    "port": "5432"
  },
  "secret/keycloak/admin": {
    "username": "admin",
    "password": "generated_secure_password",
    "realm": "master"
  }
}
```

### Authentication Flow

1. **Token Detection:** Multiple source priority
   - `VAULT_TOKEN` environment variable
   - `/opt/my-secure-ha-stack/secrets/vault_token` file
   - Root token from vault initialization

2. **Secrets Retrieval:** Dynamic credential fetching
3. **Fallback Handling:** Development defaults if Vault unavailable

## Deployment Automation

### Container Build

```bash
# Build enhanced Keycloak container
cd /opt/dev-purebliss/services/keycloak
docker build -f keycloak-enhanced-dockerfile -t keycloak:enhanced .
```

### Container Start

```bash
# Start with full automation
docker run -d --name purebliss-keycloak \
  --network purebliss-net \
  --env-file .env \
  keycloak:enhanced
```

### Health Validation

```bash
# Mandatory health validation
/opt/dev-purebliss/validate-container-health.sh keycloak startup
```

## Environment Configuration

### Required Environment Variables

```bash
# Vault Configuration
VAULT_ADDR=http://purebliss-vault:8200
VAULT_TOKEN=hvs.XXXXXXXXXXXXX

# Database Configuration
KC_DB=postgres
KC_DB_URL=jdbc:postgresql://purebliss-postgres:5432/keycloak
KC_DB_USERNAME=keycloak
KC_DB_PASSWORD=dynamic_from_vault

# Keycloak Configuration
KC_HOSTNAME=dev.purebliss.app
KC_PROXY=edge
KC_HTTP_RELATIVE_PATH=/auth
KC_HTTP_ENABLED=true
KC_HOSTNAME_STRICT=false

# Admin Configuration
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=dynamic_from_vault
```

### Optional Environment Variables

```bash
# Redis Configuration
REDIS_HOST=purebliss-redis
REDIS_PORT=6379
REDIS_DATABASE=1

# Monitoring
PROMETHEUS_METRICS_ENABLED=true
GRAFANA_DASHBOARD_ENABLED=true
```

## Monitoring & Alerting

### Health Endpoints

- **Primary Health:** `http://localhost:8080/realms/master`
- **Admin Console:** `http://localhost:8080/auth/admin`
- **User Portal:** `http://localhost:8080/auth`

### Prometheus Metrics

```yaml
# Keycloak metrics exposure
- job_name: 'keycloak'
  static_configs:
    - targets: ['purebliss-keycloak:8080']
  metrics_path: '/metrics'
```

### Log Monitoring

```bash
# Container logs
docker logs purebliss-keycloak --tail 50

# Development logs
tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log | grep -i keycloak
```

## Integration Workflows

### Nginx Upstream Integration

1. **Service Startup:** Keycloak starts and initializes
2. **Health Check:** Validates `/realms/master` endpoint
3. **Upstream Notification:** Calls `/opt/dev-purebliss/upstream-validation.sh`
4. **Nginx Reconfiguration:** Nginx detects healthy upstream and routes traffic

### Database Integration

1. **Vault Authentication:** Retrieves database credentials
2. **Connection Validation:** Tests PostgreSQL connectivity
3. **Database Setup:** Creates database and user if needed
4. **Schema Migration:** Keycloak handles schema automatically

### SSO Integration

1. **Google Workspace SAML/OIDC:** Configure in Keycloak admin console
2. **Realm Configuration:** Set up authentication realms
3. **User Federation:** Connect to external identity providers
4. **Session Management:** Redis caching for session storage

## Troubleshooting Automation

### Common Issues and Automated Solutions

#### Database Connection Failures
- **Detection:** Health validation failure on PostgreSQL
- **Automation:** Automatic retry with exponential backoff
- **Escalation:** Logs to development log for manual intervention

#### Vault Connectivity Issues
- **Detection:** Token authentication failure
- **Automation:** Fallback to environment defaults
- **Notification:** Warning logs for security team

#### Upstream Notification Failures
- **Detection:** nginx upstream validation timeout
- **Automation:** Retry mechanism with backoff
- **Recovery:** Service continues operation independently

### Performance Issues
- **Memory Usage:** Automatic JVM tuning based on available resources
- **Connection Pools:** Dynamic adjustment based on load
- **Cache Optimization:** Redis integration for session management

## Maintenance Automation

### Regular Tasks

1. **Health Monitoring:** Continuous validation via health check script
2. **Log Rotation:** Automatic log management and archival
3. **Certificate Management:** Vault PKI integration for SSL/TLS
4. **Backup Procedures:** Database and configuration backup automation

### Updates and Upgrades

1. **Container Updates:** Automated rebuild with version management
2. **Configuration Changes:** Version-controlled environment updates
3. **Security Patches:** Automated security update integration
4. **Testing Validation:** Comprehensive health validation after changes

## Security Automation

### Secrets Management
- **Dynamic Rotation:** Vault-managed credential rotation
- **Access Control:** Least privilege via Vault policies
- **Audit Logging:** Comprehensive access and change logging

### SSL/TLS Automation
- **Certificate Provisioning:** Vault PKI certificate management
- **Renewal Automation:** Automatic certificate renewal workflow
- **Security Headers:** HSTS and security header enforcement

### Access Control
- **Authentication:** Multi-factor authentication support
- **Authorization:** Role-based access control (RBAC)
- **Session Management:** Secure session handling with Redis

## API Integration

### Admin API Automation

```bash
# Get realm configuration
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8080/auth/admin/realms/master

# Create new user
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"username":"newuser","enabled":true}' \
  http://localhost:8080/auth/admin/realms/master/users
```

### Monitoring API

```bash
# Service health check
curl -f http://localhost:8080/realms/master

# Metrics collection
curl http://localhost:8080/metrics
```

## Development Workflow

### Local Development

1. **Environment Setup:** Configure `.env` file with development settings
2. **Container Start:** Use development mode with hot reload
3. **Testing:** Comprehensive validation using health check script
4. **Debugging:** Access logs and metrics for troubleshooting

### Production Deployment

1. **Configuration Validation:** Verify all environment variables
2. **Security Check:** Validate Vault integration and SSL/TLS
3. **Health Validation:** Confirm all dependencies operational
4. **Performance Testing:** Load testing and optimization
5. **Monitoring Setup:** Configure alerts and dashboards

## Support and Maintenance

### Documentation
- **Automation Guide:** This document
- **Break-Fix Report:** Comprehensive troubleshooting guide
- **API Documentation:** Service API reference
- **Configuration Reference:** Environment variable documentation

### Support Contacts
- **Development Team:** Pure Bliss Development Team
- **Security Team:** Vault and secrets management
- **Operations Team:** Infrastructure and monitoring

### Emergency Procedures
- **Service Recovery:** Automated failover and recovery procedures
- **Security Incidents:** Incident response and notification workflows
- **Performance Issues:** Automatic scaling and optimization procedures

---

**Last Updated:** $(date '+%Y-%m-%d %H:%M:%S')
**Version:** 1.0.0
**Compliance:** Pure Bliss Elite Standards
