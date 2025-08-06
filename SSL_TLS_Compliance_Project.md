# Pure Bliss SSL/TLS/HTTPS Compliance, Vault Integration, and Zero Hardcoded Password Project

## Objective
Ensure all Pure Bliss services are fully compliant with SSL/TLS/HTTPS enforcement, use the correct backend services (PostgreSQL, Redis), integrate with HashiCorp Vault for dynamic secrets management, eliminate all hardcoded passwords, and are integrated with Prometheus and Loki. Automate these requirements in container .yml files and enhance start-all-services.sh for robust, secure, and observable deployments.

### Key Security Requirements
- **Zero Hardcoded Passwords**: All credentials must be retrieved from Vault at runtime
- **Dynamic Secrets**: Use Vault's dynamic secret engines where possible (database credentials, API tokens)
- **Vault Agent Integration**: Implement Vault Agent sidecar pattern for secure secret delivery
- **Secret Rotation**: Automated credential rotation with lease management
- **Least Privilege**: AppRole-based authentication with minimal required permissions

---


## Sequential Problem-Solving Approach

Per copilot-instructions.md, all tasks must be addressed one at a time, in strict sequence. Do not begin work on the next checklist item until the current one is 100% complete, verified, and logged. This ensures focus, prevents context switching, and guarantees robust, auditable progress.

For each checklist item:
- Complete all subtasks and validations for the current item.
- Log all actions, results, and verifications to /opt/my-secure-ha-stack/logs/dev-environment-setup.log.
- Only proceed to the next item after confirming full compliance and documenting the resolution.

---


## Service-Specific Compliance Checklists

**Recommended Execution Order:**

1. **Vault (secrets management)** - ✅ **COMPLETED - PRIORITY #1**
   - ✅ Initialize Vault with TLS certificates and unseal
   - 🔄 Configure AppRole authentication for each service
   - ✅ Set up dynamic secret engines (database, Keycloak admin)
   - 🔄 Implement Vault Agent sidecars for secret delivery
   - **📚 Vault Troubleshooting Resources:**
     - Complete automation guide: `/opt/dev-purebliss/services/vault/VAULT_AUTOMATION_GUIDE.md`
     - Break/fix procedures: `/opt/dev-purebliss/services/vault/vault-break-fix-report.md`
     - Automated fix script: `/opt/dev-purebliss/services/vault/vault-break-fix.sh`

2. **Let's Encrypt (certificate manager)** - ✅ **COMPLETED**
   - ✅ Issue and auto-renew SSL/TLS certs for all domains
   - ✅ Store certificates in Vault for centralized management

3. **PostgreSQL (database)** - ✅ **COMPLETED - VAULT INTEGRATED**
   - ✅ Configure dynamic database credentials via Vault
   - ✅ Enforce SSL connections (`sslmode=require`)
   - ✅ Eliminate hardcoded database passwords
   - **🚀 NEXT STEP**: Configure Redis with Vault-managed credentials
   - **📋 Current Status**: PostgreSQL is running and fully integrated with Vault for dynamic credentials.
   - **🛠️ Troubleshooting**: Use PostgreSQL section in VAULT_AUTOMATION_GUIDE.md and `vault-break-fix.sh postgresql_integration`

4. **Redis (caching)** - ✅ **COMPLETED - VAULT INTEGRATED**
   - ✅ Retrieve Redis AUTH password from Vault
   - ✅ Enable independent container startup with comprehensive entrypoint
   - ✅ Configure AOF persistence and TTL
   - **📋 Current Status**: Redis running with independent container startup and Vault integration
   - **🚀 NEXT STEP**: Configure Nginx with Vault-managed certificates

5. **Loki (logging)** - ✅ **COMPLETED - CONTAINER ISSUES RESOLVED**
   - ✅ Fixed container permission issues (User ID 10001 data directory access)
   - ✅ Resolved configuration parsing errors (compactor.enabled field removal)
   - ✅ Validated HTTPS log ingestion capability
   - **📋 Current Status**: Loki running successfully with proper permissions and configuration
   - **🛠️ Common Fix Pattern**: Container user/permission issues documented for reuse across services

5. **Loki (logging)** - ✅ **COMPLETED - CONTAINER ISSUES RESOLVED**
   - ✅ Fixed container permission issues (User ID 10001 data directory access)
   - ✅ Resolved configuration parsing errors (compactor.enabled field removal)
   - ✅ Validated HTTPS log ingestion capability
   - **📋 Current Status**: Loki running successfully with proper permissions and configuration
   - **🛠️ Common Fix Pattern**: Container user/permission issues documented for reuse across services

6. **Nginx (gateway)**
   - Configure HTTPS, HSTS, and proxy to services
   - Retrieve SSL certificates from Vault

7. **Keycloak (authentication)**
   - Validate HTTPS, dynamic DB credentials, and Redis integration
   - Store Keycloak admin credentials in Vault

8. **Plane (issue tracking)**
   - Validate HTTPS, dynamic DB credentials, and Redis integration
   - Configure Vault-based secret management

9. **CodeServer (development environment)**
   - Configure secure access with Vault-managed credentials
   - Implement HTTPS and monitoring integration

10. **Grafana (visualization)**
    - Validate HTTPS and Prometheus metrics
    - Store Grafana admin credentials in Vault

11. **Prometheus (metrics)**
    - Validate HTTPS and self-scraping
    - Configure secure authentication

---

## 🔧 **Common Container Issues and Solutions**

### **Container Permission Issues Pattern**

When containerized services fail with permission errors, follow this standard troubleshooting pattern:

#### **Symptoms:**
- Permission denied creating directories (`mkdir: cannot create directory`)
- Failed to write to mounted volumes
- Container restart loops with "permission denied" errors

#### **Root Cause Analysis:**
1. **Check container user ID**: `docker inspect <container> | grep User`
2. **Check host directory ownership**: `ls -la /path/to/mounted/directory`
3. **Verify volume mount configuration** in docker-compose.yml

#### **Standard Fix Pattern:**
```bash
# 1. Identify the container's user ID (e.g., 10001 for Loki)
docker inspect purebliss-<service> | grep User

# 2. Fix host directory permissions
sudo mkdir -p /path/to/service/data
sudo chown -R <user_id>:<user_id> /path/to/service/data

# 3. Restart the service
docker compose -f <service>-docker-compose.yml restart
```

#### **Services Using This Pattern:**
- **Loki**: User ID 10001, requires `/raid-storage/loki/data` ownership
- **Grafana**: User ID 472, requires data directory access
- **Prometheus**: User ID 65534 (nobody), requires `/prometheus` directory
- **Redis**: User ID 999, requires `/data` directory access

### **Configuration Parsing Issues Pattern**

#### **Symptoms:**
- `failed parsing config` errors in container logs
- `field not found in type` configuration errors
- Container starts but immediately exits with config errors

#### **Standard Fix Pattern:**
1. **Check service-specific configuration syntax** for the version being used
2. **Remove deprecated configuration fields** that are no longer supported
3. **Use configuration validation tools** when available
4. **Test configuration in isolated environment** before deployment

#### **Example Fix - Loki Configuration:**
```yaml
# ❌ WRONG - 'enabled' field not supported in compactor config
compactor:
  enabled: false
  working_directory: /loki/boltdb-shipper-compactor

# ✅ CORRECT - Remove unsupported fields
compactor:
  working_directory: /loki/boltdb-shipper-compactor
  shared_store: filesystem
```

---

## 🛠️ **Vault Troubleshooting and Automation Resources**

When working with Vault during SSL/TLS compliance implementation, use these comprehensive troubleshooting resources:

### **Primary Troubleshooting Documents**

1. **Complete Automation Guide**: `/opt/dev-purebliss/services/vault/VAULT_AUTOMATION_GUIDE.md`
   - **Purpose**: Comprehensive guide covering all Vault automation, break/fix procedures, and service integrations
   - **Contains**: Step-by-step troubleshooting for PostgreSQL, Redis, Keycloak, Nginx, Let's Encrypt, and Prometheus
   - **When to Use**: When setting up new service integrations or understanding automation workflows

2. **Detailed Break/Fix Report**: `/opt/dev-purebliss/services/vault/vault-break-fix-report.md`
   - **Purpose**: Detailed procedures for 12+ automated fix procedures with manual intervention steps
   - **Contains**: Specific commands, common issues, and manual fixes for each service integration
   - **When to Use**: When automated fixes fail or when you need detailed manual troubleshooting steps

3. **Automated Fix Script**: `/opt/dev-purebliss/services/vault/vault-break-fix.sh`
   - **Purpose**: Main automation script for detecting and fixing Vault-related issues
   - **Contains**: 12+ automated fix procedures that can be run individually or collectively
   - **When to Use**: First line of defense for any Vault issue

### **Common Vault Troubleshooting Commands**

```bash
# Quick diagnostic check
/opt/dev-purebliss/services/vault/vault-break-fix.sh diagnostic

# Fix specific issues
/opt/dev-purebliss/services/vault/vault-break-fix.sh permissions
/opt/dev-purebliss/services/vault/vault-break-fix.sh tls_config
/opt/dev-purebliss/services/vault/vault-break-fix.sh network
/opt/dev-purebliss/services/vault/vault-break-fix.sh container_startup

# Service-specific integration fixes
/opt/dev-purebliss/services/vault/vault-break-fix.sh postgresql_integration
/opt/dev-purebliss/services/vault/vault-break-fix.sh letsencrypt_vault_integration
/opt/dev-purebliss/services/vault/vault-break-fix.sh prometheus_vault_integration
/opt/dev-purebliss/services/vault/vault-break-fix.sh nginx_pki_integration

# Apply all fixes sequentially
/opt/dev-purebliss/services/vault/vault-break-fix.sh all

# Emergency complete rebuild
/opt/dev-purebliss/services/vault/vault-break-fix.sh emergency
```

### **Integration-Specific Troubleshooting**

#### **PostgreSQL + Vault Issues**
- **Resource**: Section "PostgreSQL Integration (100% Complete)" in VAULT_AUTOMATION_GUIDE.md
- **Fix Script**: `vault-break-fix.sh postgresql_integration`
- **Validation**: `/opt/dev-purebliss/services/postgres/validate-setup.sh`

#### **Let's Encrypt + Vault Issues**
- **Resource**: Section "LETSENCRYPT VAULT INTEGRATION & AUTOMATION" in VAULT_AUTOMATION_GUIDE.md
- **Fix Script**: `vault-break-fix.sh letsencrypt_vault_integration`
- **Manual Fix**: Procedure 11 in vault-break-fix-report.md

#### **Nginx + Vault PKI Issues**
- **Resource**: Section "NGINX PKI AUTOMATION & TROUBLESHOOTING" in VAULT_AUTOMATION_GUIDE.md
- **Fix Script**: `vault-break-fix.sh nginx_pki_integration`
- **Certificate Renewal**: `/opt/dev-purebliss/services/nginx/update_vault_certificates.sh`

#### **Prometheus + Vault Issues**
- **Resource**: Section "PROMETHEUS VAULT INTEGRATION & MONITORING" in VAULT_AUTOMATION_GUIDE.md
- **Fix Script**: `vault-break-fix.sh prometheus_vault_integration`
- **Manual Fix**: Procedure 12 in vault-break-fix-report.md

### **When to Use Each Resource**

| Issue Type | First Try | Detailed Help | Manual Steps |
|------------|-----------|---------------|--------------|
| Service won't start | `vault-break-fix.sh <service>_integration` | VAULT_AUTOMATION_GUIDE.md | vault-break-fix-report.md |
| Permission errors | `vault-break-fix.sh permissions` | VAULT_AUTOMATION_GUIDE.md | `sudo vault-manual-permissions-fix.sh` |
| Network connectivity | `vault-break-fix.sh network` | VAULT_AUTOMATION_GUIDE.md | vault-break-fix-report.md |
| TLS/Certificate issues | `vault-break-fix.sh tls_config` | VAULT_AUTOMATION_GUIDE.md | vault-break-fix-report.md |
| Understanding automation | N/A | VAULT_AUTOMATION_GUIDE.md | start-all-services.sh source code |

### **Logging and Monitoring**

All Vault troubleshooting actions are logged to: `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`

**Monitor logs in real-time:**
```bash
tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log | grep -i vault
```

**Filter for specific service integration:**
```bash
grep "postgresql\|postgres" /opt/my-secure-ha-stack/logs/dev-environment-setup.log
grep "letsencrypt" /opt/my-secure-ha-stack/logs/dev-environment-setup.log
grep "nginx" /opt/my-secure-ha-stack/logs/dev-environment-setup.log
```

---

## Vault Integration Requirements

### 1. Vault Server Configuration
- [ ] **TLS/HTTPS Enforcement**
  - [ ] Configure Vault with Let's Encrypt certificates
  - [ ] Enforce HTTPS-only access (port 8200)
  - [ ] Set up proper certificate rotation with Vault Agent
  - [ ] Configure HSTS headers and strong cipher suites

- [ ] **Authentication and Authorization**
  - [ ] Set up AppRole authentication method for all services
  - [ ] Create service-specific roles with least privilege policies
  - [ ] Configure lease durations and renewal policies
  - [ ] Implement secret rotation schedules

- [ ] **Secret Engines Configuration**
  - [ ] Enable database secret engine for PostgreSQL dynamic credentials
  - [ ] Configure KV secret engine v2 for static secrets
  - [ ] Set up transit engine for encryption/decryption operations
  - [ ] Configure PKI engine for internal certificate management

- [ ] **Monitoring and Logging**
  - [ ] Enable Vault audit logging to Loki
  - [ ] Expose Vault metrics to Prometheus
  - [ ] Configure health checks and alerting
  - [ ] Set up performance monitoring

### 2. Vault Agent Implementation
- [ ] **Sidecar Pattern Deployment**
  - [ ] Create Vault Agent configurations for each service
  - [ ] Implement tmpfs shared volumes for secret delivery
  - [ ] Configure auto-renewal and rotation
  - [ ] Set up proper file permissions and ownership

- [ ] **Template Configuration**
  - [ ] Create Consul Template files for dynamic secret rendering
  - [ ] Configure service restart triggers on secret changes
  - [ ] Implement graceful secret rotation handling
  - [ ] Set up error handling and retry logic

### 3. Zero Hardcoded Password Implementation
- [ ] **Database Credentials**
  - [ ] Remove all hardcoded PostgreSQL passwords from configs
  - [ ] Implement dynamic database user creation via Vault
  - [ ] Configure automatic credential rotation (24-hour leases)
  - [ ] Set up connection pooling with dynamic credentials

- [ ] **Service Credentials**
  - [ ] Store Keycloak admin credentials in Vault
  - [ ] Manage Redis AUTH passwords via Vault
  - [ ] Centralize all API tokens and keys in Vault
  - [ ] Implement secure credential distribution

- [ ] **TLS Certificate Management**
  - [ ] Store Let's Encrypt certificates in Vault
  - [ ] Automate certificate deployment to services
  - [ ] Configure certificate renewal notifications
  - [ ] Implement certificate backup and recovery

---
## Detailed Service-Specific Compliance Checklists

### 1. Vault (secrets management) - **COMPLETE FIRST**

- [ ] **TLS/HTTPS Configuration**
  - [ ] Configure Vault with Let's Encrypt certificates
  - [ ] Enforce HTTPS-only access on port 8200
  - [ ] Implement HSTS headers and strong cipher suites
  - [ ] Configure certificate auto-renewal

- [ ] **Authentication Setup**
  - [ ] Enable AppRole authentication method
  - [ ] Create role for each service: postgres, keycloak, plane, grafana, etc.
  - [ ] Configure token policies with least privilege
  - [ ] Set appropriate lease durations and renewal policies

- [ ] **Secret Engines**
  - [ ] Enable database secret engine for PostgreSQL
  - [ ] Configure KV secret engine v2 for static secrets
  - [ ] Set up transit engine for encryption operations
  - [ ] Configure PKI engine for internal certificates

- [ ] **Dynamic Database Integration**
  - [ ] Configure PostgreSQL connection in Vault
  - [ ] Create database roles for each service
  - [ ] Set credential rotation periods (24 hours)
  - [ ] Test credential generation and rotation

- [ ] **Monitoring and Logging**
  - [ ] Enable audit logging to file and Loki
  - [ ] Expose metrics to Prometheus (/v1/sys/metrics)
  - [ ] Configure health checks and alerting
  - [ ] Ship logs to Loki with `service="vault"`

### 2. Vault Agent Configuration

- [ ] **Service-Specific Agents**
  - [ ] Create Vault Agent config for PostgreSQL service
  - [ ] Create Vault Agent config for Keycloak service
  - [ ] Create Vault Agent config for Plane service
  - [ ] Create Vault Agent config for Nginx service

- [ ] **Template Files**
  - [ ] PostgreSQL connection template with dynamic credentials
  - [ ] Keycloak database configuration template
  - [ ] Redis AUTH password template
  - [ ] SSL certificate deployment templates

- [ ] **Docker Integration**
  - [ ] Add Vault Agent sidecars to docker-compose.yml
  - [ ] Configure shared tmpfs volumes for secret delivery
  - [ ] Set proper file permissions (vault:vault 1000:1000)
  - [ ] Implement graceful restart on secret changes

### 3. Let's Encrypt (certificate manager)

- [ ] **Vault Integration**
  - [ ] Store certificates in Vault KV store
  - [ ] Configure automated certificate renewal workflow
  - [ ] Set up certificate deployment via Vault Agent
  - [ ] Ship certificate issuance logs to Loki with `service="letsencrypt"`

- [ ] **Certificate Management**
  - [ ] Auto-issue SSL/TLS certificates for all domains
  - [ ] Configure Nginx to retrieve certs from Vault
  - [ ] Implement certificate backup and recovery
  - [ ] Set up certificate expiry monitoring

### 4. PostgreSQL (database)

- [ ] **Vault Dynamic Credentials**
  - [ ] Remove all hardcoded database passwords
  - [ ] Configure Vault database secret engine integration
  - [ ] Implement dynamic user creation and rotation
  - [ ] Test credential lifecycle management

- [ ] **SSL/TLS Configuration**
  - [ ] Require SSL connections (`sslmode=require`)
  - [ ] Configure server certificates from Vault
  - [ ] Restrict access to internal network only
  - [ ] Implement certificate validation

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus (pg_exporter)
  - [ ] Ship logs to Loki with `service="postgres"`
  - [ ] Configure database performance monitoring
  - [ ] Set up connection pool monitoring

### 5. Redis (caching)

- [ ] **Vault Integration**
  - [ ] Retrieve Redis AUTH password from Vault
  - [ ] Configure Vault Agent template for Redis password
  - [ ] Remove hardcoded AUTH credentials
  - [ ] Implement password rotation handling

- [ ] **Security Configuration**
  - [ ] Enable TLS or restrict to internal network
  - [ ] Configure AOF persistence and TTLs
  - [ ] Set up proper access controls
  - [ ] Implement secure client connections

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus (redis_exporter)
  - [ ] Ship logs to Loki with `service="redis"`
  - [ ] Monitor memory usage and performance
  - [ ] Set up connection monitoring

### 6. Nginx (gateway)

- [ ] **Vault Certificate Integration**
  - [ ] Retrieve SSL certificates from Vault
  - [ ] Configure automatic certificate deployment
  - [ ] Implement certificate reload without downtime
  - [ ] Set up certificate monitoring

- [ ] **HTTPS Enforcement**
  - [ ] Redirect all HTTP traffic to HTTPS
  - [ ] Enforce HSTS and strong cipher suites
  - [ ] Configure proper SSL/TLS settings
  - [ ] Implement security headers

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus (nginx_exporter)
  - [ ] Ship access and error logs to Loki with `service="nginx"`
  - [ ] Monitor performance and error rates
  - [ ] Set up uptime monitoring

### 7. Keycloak (authentication)

- [ ] **Vault Integration**
  - [ ] Retrieve database credentials from Vault dynamically
  - [ ] Store Keycloak admin credentials in Vault
  - [ ] Configure Vault Agent for credential delivery
  - [ ] Remove all hardcoded passwords

- [ ] **Database Configuration**
  - [ ] Use Vault-managed PostgreSQL credentials
  - [ ] Configure SSL database connections
  - [ ] Implement connection pool with dynamic credentials
  - [ ] Set up credential refresh handling

- [ ] **HTTPS and Security**
  - [ ] Enforce HTTPS-only access
  - [ ] Configure proper SSL/TLS settings
  - [ ] Enable HSTS and security headers
  - [ ] Implement proper session management

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus
  - [ ] Ship logs to Loki with `service="keycloak"`
  - [ ] Monitor authentication performance
  - [ ] Set up security event alerting

### 8. Plane (issue tracking)

- [ ] **Vault Integration**
  - [ ] Configure dynamic database credentials via Vault
  - [ ] Store API keys and secrets in Vault
  - [ ] Implement Vault Agent for secret delivery
  - [ ] Remove hardcoded configuration values

- [ ] **Database and Caching**
  - [ ] Use Vault-managed PostgreSQL credentials
  - [ ] Configure Redis with Vault-managed AUTH
  - [ ] Implement SSL database connections
  - [ ] Set up proper connection handling

- [ ] **HTTPS and Security**
  - [ ] Enforce HTTPS-only access
  - [ ] Configure proper SSL/TLS settings
  - [ ] Implement security headers
  - [ ] Set up proper authentication

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus
  - [ ] Ship logs to Loki with `service="plane"`
  - [ ] Monitor application performance
  - [ ] Set up error tracking

### 9. CodeServer (development environment)

- [ ] **Vault Integration**
  - [ ] Store authentication credentials in Vault
  - [ ] Configure access tokens via Vault
  - [ ] Implement secure configuration management
  - [ ] Remove hardcoded authentication

- [ ] **HTTPS and Security**
  - [ ] Enforce HTTPS-only access
  - [ ] Configure proper SSL/TLS settings
  - [ ] Implement proper authentication
  - [ ] Set up secure development environment

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus
  - [ ] Ship logs to Loki with `service="codeserver"`
  - [ ] Monitor resource usage
  - [ ] Set up development activity tracking

### 10. Grafana (visualization)

- [ ] **Vault Integration**
  - [ ] Store admin credentials in Vault
  - [ ] Configure datasource credentials via Vault
  - [ ] Implement Vault Agent for secret delivery
  - [ ] Remove hardcoded configuration

- [ ] **HTTPS and Security**
  - [ ] Enforce HTTPS-only access
  - [ ] Configure proper SSL/TLS settings
  - [ ] Implement proper authentication
  - [ ] Set up user management

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus (self-monitoring)
  - [ ] Ship logs to Loki with `service="grafana"`
  - [ ] Monitor dashboard performance
  - [ ] Set up alerting configuration

### 11. Prometheus (metrics)

- [ ] **HTTPS and Security**
  - [ ] Enforce HTTPS-only access
  - [ ] Configure proper SSL/TLS settings
  - [ ] Implement authentication for web UI
  - [ ] Set up secure scraping configuration

- [ ] **Monitoring and Logging**
  - [ ] Configure self-monitoring metrics
  - [ ] Ship logs to Loki with `service="prometheus"`
  - [ ] Monitor scraping performance
  - [ ] Set up storage and retention policies

### 12. Loki (logging)

- [ ] **HTTPS and Security**
  - [ ] Enforce HTTPS-only access
  - [ ] Configure proper SSL/TLS settings
  - [ ] Implement authentication for API access
  - [ ] Set up secure log ingestion

- [ ] **Monitoring and Logging**
  - [ ] Expose metrics to Prometheus
  - [ ] Configure self-monitoring
  - [ ] Monitor log ingestion performance
  - [ ] Set up retention policies

---

## Enhanced Project Checklist

### 1. Vault Integration and Zero Hardcoded Passwords

- [ ] **Vault Server Setup**
  - [ ] Deploy Vault with TLS/HTTPS enforcement
  - [ ] Configure AppRole authentication for all services
  - [ ] Enable database secret engine for dynamic PostgreSQL credentials
  - [ ] Set up KV secret engine v2 for static secrets
  - [ ] Configure audit logging and metrics exposure
  - [ ] Implement proper backup and disaster recovery

- [ ] **Dynamic Secret Management**
  - [ ] Configure PostgreSQL integration in Vault for dynamic credentials
  - [ ] Set up 24-hour credential rotation for all database users
  - [ ] Create service-specific database roles with minimal privileges
  - [ ] Implement credential refresh handling in all applications
  - [ ] Test credential lifecycle and rotation processes
  - [ ] Monitor credential usage and lease management

- [ ] **Vault Agent Implementation**
  - [ ] Deploy Vault Agent sidecars for each service
  - [ ] Configure tmpfs shared volumes for secure secret delivery
  - [ ] Create Consul Template files for each service configuration
  - [ ] Implement graceful service restart on secret changes
  - [ ] Set up proper file permissions and ownership (1000:1000)
  - [ ] Test agent authentication and secret delivery

- [ ] **Static Secret Migration**
  - [ ] Move all Keycloak admin credentials to Vault
  - [ ] Store Redis AUTH passwords in Vault
  - [ ] Migrate API keys and tokens to Vault KV store
  - [ ] Configure SSL certificate storage in Vault
  - [ ] Remove all hardcoded secrets from configurations
  - [ ] Update all docker-compose.yml files to remove static secrets

### 2. SSL/TLS/HTTPS Enforcement

- [ ] **Certificate Management**
  - [ ] Integrate Let's Encrypt with Vault for centralized certificate storage
  - [ ] Configure automatic certificate deployment via Vault Agent
  - [ ] Set up certificate renewal automation with Vault integration
  - [ ] Implement certificate backup and recovery procedures
  - [ ] Monitor certificate expiry and renewal status
  - [ ] Test certificate rollback procedures

- [ ] **Service HTTPS Enforcement**
  - [ ] Audit all Nginx configs to ensure HTTP to HTTPS redirection
  - [ ] Validate SSL/TLS certs are deployed from Vault to all services
  - [ ] Enforce HSTS and strong cipher suites across all services
  - [ ] Configure proper security headers (CSP, X-Frame-Options, etc.)
  - [ ] Implement TLS 1.3 where supported
  - [ ] Test SSL configuration with security scanners

- [ ] **Internal Service Security**
  - [ ] Ensure PostgreSQL requires SSL connections (`sslmode=require`)
  - [ ] Configure Redis with TLS or restrict to internal network only
  - [ ] Implement service-to-service TLS communication
  - [ ] Set up proper certificate validation
  - [ ] Configure mutual TLS where applicable
  - [ ] Test internal communication security

### 3. Backend Service Standardization with Vault

- [ ] **PostgreSQL Integration**
  - [ ] Configure all services to use Vault dynamic database credentials
  - [ ] Update connection strings to use SSL and Vault-provided credentials
  - [ ] Implement connection pooling with credential refresh capabilities
  - [ ] Set up database monitoring with secure credential access
  - [ ] Configure backup procedures with Vault-managed credentials
  - [ ] Test database failover and credential rotation scenarios

- [ ] **Redis Integration**
  - [ ] Configure all caching services to use Vault-managed Redis AUTH
  - [ ] Implement Redis connection handling with credential refresh
  - [ ] Set up Redis clustering with secure authentication
  - [ ] Configure AOF persistence and appropriate TTLs
  - [ ] Monitor Redis performance and security metrics
  - [ ] Test Redis failover with Vault integration

### 4. Monitoring and Logging Integration with Security

- [ ] **Prometheus Integration**
  - [ ] Ensure all services expose metrics with proper authentication
  - [ ] Configure Vault metrics monitoring and alerting
  - [ ] Set up security-focused metrics (failed authentications, etc.)
  - [ ] Implement service discovery with secure configuration
  - [ ] Monitor credential rotation and vault operations
  - [ ] Create dashboards for security and compliance metrics

- [ ] **Loki Integration**
  - [ ] Configure all services to ship logs with proper service labels
  - [ ] Set up centralized logging for Vault operations and audits
  - [ ] Implement log filtering and retention policies
  - [ ] Configure secure log transmission (TLS)
  - [ ] Set up security event alerting based on logs
  - [ ] Create security-focused log queries and dashboards

### 5. Container and Orchestration Security

- [ ] **Docker Compose Enhancement**
  - [ ] Update all service definitions to include Vault Agent sidecars
  - [ ] Configure tmpfs volumes for secure secret sharing
  - [ ] Remove all hardcoded environment variables containing secrets
  - [ ] Implement proper container networking and isolation
  - [ ] Set up container resource limits and security contexts
  - [ ] Configure health checks with secure endpoints

- [ ] **Service Configuration Files**
  - [ ] Update all Dockerfiles to remove static secret handling
  - [ ] Configure services to read secrets from Vault Agent-provided files
  - [ ] Implement configuration validation and error handling
  - [ ] Set up proper file permissions and ownership
  - [ ] Create service-specific configuration templates
  - [ ] Test configuration reload capabilities

### 6. Automation and Script Enhancements

- [ ] **Enhanced start-all-services.sh**
  - [ ] Add Vault initialization and unsealing automation
  - [ ] Implement service-specific startup functions with Vault integration
  - [ ] Configure pre-startup Vault connectivity and credential validation
  - [ ] Add SSL/TLS certificate validation before service startup
  - [ ] Implement health check validation for all services
  - [ ] Create rollback procedures for failed deployments

- [ ] **Operational Scripts**
  - [ ] Create Vault backup and restore scripts
  - [ ] Implement credential rotation scripts with service coordination
  - [ ] Set up certificate renewal automation with service updates
  - [ ] Create security audit and compliance checking scripts
  - [ ] Implement disaster recovery procedures
  - [ ] Set up automated security testing scripts

### 7. Security Compliance and Auditing

- [ ] **Audit and Compliance**
  - [ ] Implement comprehensive audit logging for all secret access
  - [ ] Set up compliance monitoring and reporting
  - [ ] Create security policy documentation
  - [ ] Implement access review and rotation procedures
  - [ ] Set up vulnerability scanning and assessment
  - [ ] Create incident response procedures

- [ ] **Testing and Validation**
  - [ ] Create comprehensive security test suites
  - [ ] Implement penetration testing procedures
  - [ ] Set up automated security scanning
  - [ ] Test disaster recovery and backup procedures
  - [ ] Validate credential rotation and failover scenarios
  - [ ] Create security regression testing

### 8. Documentation and Training

- [ ] **Documentation Updates**
  - [ ] Document all Vault integration procedures
  - [ ] Create operational runbooks for each service
  - [ ] Update troubleshooting guides with Vault-specific scenarios
  - [ ] Document security procedures and policies
  - [ ] Create architecture and design documentation
  - [ ] Update changelog with all security enhancements

- [ ] **Logging and Monitoring**
  - [ ] Log every action, config change, and test result to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`
  - [ ] Implement structured logging with correlation IDs
  - [ ] Set up centralized log aggregation and analysis
  - [ ] Create security dashboards and alerting
  - [ ] Monitor compliance metrics and KPIs
  - [ ] Set up automated reporting and notifications

---

## Vault Implementation Guidance

### Vault Agent Configuration Examples

#### PostgreSQL Service Vault Agent Config
```hcl
# /opt/my-secure-ha-stack/vault/agent/postgres-agent.hcl
vault {
  address = "https://vault.purebliss.app:8200"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path   = "/vault/config/role_id"
      secret_id_file_path = "/vault/config/secret_id"
    }
  }
  sink "file" {
    config = {
      path = "/vault/secrets/.token"
    }
  }
}

template {
  source      = "/vault/templates/postgres.conf.tmpl"
  destination = "/vault/secrets/postgres.conf"
  perms       = 0600
  command     = "supervisorctl restart postgres"
}
```

#### Keycloak Database Connection Template
```bash
# /opt/my-secure-ha-stack/vault/templates/keycloak-db.conf.tmpl
{{- with secret "database/creds/keycloak-role" -}}
export KC_DB_USERNAME="{{ .Data.username }}"
export KC_DB_PASSWORD="{{ .Data.password }}"
{{- end }}
export KC_DB_URL="jdbc:postgresql://postgres:5432/keycloak?sslmode=require"
```

### Dynamic Secret Engine Configuration

#### PostgreSQL Database Configuration
```bash
# Configure PostgreSQL connection in Vault
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/postgres?sslmode=require" \
    allowed_roles="keycloak-role,plane-role,grafana-role" \
    username="vault_admin" \
    password="$(vault kv get -field=admin_password secret/postgres)"

# Create role for Keycloak
vault write database/roles/keycloak-role \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE keycloak TO \"{{name}}\";" \
    default_ttl="24h" \
    max_ttl="168h"
```

### Service-Specific AppRole Policies

#### Keycloak Policy
```hcl
# /opt/my-secure-ha-stack/vault/policies/keycloak-policy.hcl
path "database/creds/keycloak-role" {
  capabilities = ["read"]
}

path "secret/data/keycloak/*" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}
```

#### Plane Policy
```hcl
# /opt/my-secure-ha-stack/vault/policies/plane-policy.hcl
path "database/creds/plane-role" {
  capabilities = ["read"]
}

path "secret/data/plane/*" {
  capabilities = ["read"]
}

path "secret/data/redis/auth" {
  capabilities = ["read"]
}
```

### Container Integration Examples

#### Enhanced Docker Compose with Vault Agent
```yaml
# Example service definition with Vault Agent sidecar
services:
  keycloak:
    image: quay.io/keycloak/keycloak:24.0.5
    depends_on:
      - keycloak-vault-agent
      - postgres
    volumes:
      - keycloak-secrets:/vault/secrets:ro
    environment:
      - KC_DB=postgres
    command: >
      bash -c "
        source /vault/secrets/keycloak-db.conf &&
        /opt/keycloak/bin/kc.sh start --optimized
      "
    networks:
      - purebliss-net

  keycloak-vault-agent:
    image: hashicorp/vault:1.17.3
    command: vault agent -config=/vault/config/agent.hcl
    volumes:
      - ./vault/agent/keycloak-agent.hcl:/vault/config/agent.hcl:ro
      - ./vault/config/keycloak-role-id:/vault/config/role_id:ro
      - ./vault/config/keycloak-secret-id:/vault/config/secret_id:ro
      - ./vault/templates:/vault/templates:ro
      - keycloak-secrets:/vault/secrets
    networks:
      - purebliss-net

volumes:
  keycloak-secrets:
    driver: tmpfs
    driver_opts:
      tmpfs:
        size: 100m
        mode: 1777
```

---

## Implementation Priority Matrix

### Phase 1: Foundation (Week 1)
1. **Vault Server Setup** - Configure TLS, AppRole, and basic secret engines
2. **PostgreSQL Dynamic Secrets** - Implement database credential rotation
3. **Basic Vault Agent** - Deploy agents for critical services

### Phase 2: Service Integration (Week 2)
1. **Keycloak Integration** - Dynamic DB credentials and admin secret management
2. **Nginx Certificate Management** - Vault-based SSL certificate deployment
3. **Redis Authentication** - Vault-managed AUTH password rotation

### Phase 3: Monitoring and Security (Week 3)
1. **Prometheus/Loki Integration** - Secure metrics and logging with Vault
2. **Plane Service Integration** - Complete application secret management
3. **CodeServer Security** - Development environment credential management

### Phase 4: Operations and Testing (Week 4)
1. **Automated Testing** - Credential rotation, failover, and security testing
2. **Documentation** - Complete operational runbooks and procedures
3. **Production Readiness** - Final security audit and compliance validation

---

## Security Best Practices Summary

### Critical Security Requirements
- **NO HARDCODED SECRETS**: All credentials must come from Vault at runtime
- **LEAST PRIVILEGE**: Each service gets only the minimum required permissions
- **CREDENTIAL ROTATION**: All secrets must rotate automatically (max 24-hour leases)
- **AUDIT LOGGING**: All secret access must be logged and monitored
- **TLS EVERYWHERE**: All communication must be encrypted in transit

### Compliance Checkpoints
- [ ] No secrets in environment variables or configuration files
- [ ] All database connections use dynamic credentials from Vault
- [ ] SSL/TLS enforced for all service communication
- [ ] Comprehensive audit logging enabled for all secret access
- [ ] Automated credential rotation verified and tested
- [ ] Security policies documented and approved
- [ ] Disaster recovery procedures tested and validated

---

## Notes

- All changes must comply with copilot-instructions.md and organizational security standards.
- Use feature branches and PRs for all enhancements.
- Validate with automated tests and CI before merging.
- Every action must be logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`

---

## Next Steps

1. **Immediate Actions**
   - Begin with Vault server setup and TLS configuration
   - Configure PostgreSQL dynamic secret engine
   - Implement basic Vault Agent for one service (start with PostgreSQL)

2. **Week 1 Deliverables**
   - Vault server fully operational with TLS
   - PostgreSQL using dynamic credentials
   - Basic monitoring and logging implemented

3. **Review and Validation**
   - Security audit of Vault configuration
   - Testing of credential rotation scenarios
   - Documentation review and approval

4. **Deployment Planning**
   - Staged rollout plan for each service
   - Rollback procedures for each phase
   - Production deployment timeline and requirements
