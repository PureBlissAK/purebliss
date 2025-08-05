# Pure Bliss Development: Comprehensive Troubleshooting & Best Practices

> **MANDATORY:** All troubleshooting steps, actions, and progress must always be logged in **/opt/my-secure-ha-stack/logs/dev-environment-setup.log**. This is a permanent requirement for all work—never skip this step.

## Service Troubleshooting Log System


**CRITICAL:** Before starting any troubleshooting, configuration, or code change, you MUST:
- Reference the troubleshooting log for the relevant service(s) to:
  - Review previous issues, solutions, and current state
  - Check the last known healthy state and healthy config location for the service
  - Confirm the current healthy config is saved and documented
- Log every troubleshooting step, action, and resolution in the central log file:
  - **/opt/my-secure-ha-stack/logs/dev-environment-setup.log**
  - This log is the authoritative record for all troubleshooting and must never be deleted or rotated out of existence.
  - All team members and scripts must append to this file for every diagnostic, fix, or configuration change.

### Log Structure
- Each service maintains its own troubleshooting log section
- Logs include: Issue, Root Cause, Solution, Prevention, Date
- Each log also tracks:
  - **Healthy State Description:** What constitutes a healthy/working state for the service
  - **Healthy Config Location:** Path(s) to the last known good configuration file(s) or backup(s)
- Reference these logs before making changes to any service
- Update logs immediately after resolving issues
- If a fix is applied, update the healthy state and healthy config location in the log to reflect the new working baseline

---

## Service-Specific Troubleshooting Logs

### 1. NGINX Service Log

#### Current Known Issues & Solutions:
- **SSL Certificate Path Issues (2025-08-03)**
  - **Issue:** Container serving self-signed certs instead of Let's Encrypt
  - **Root Cause:** Wrong cert paths in nginx.conf, stale volume mounts
  - **Solution:** Use `/mnt/raid0/nginx/certs/live/dev.purebliss.app/fullchain.pem` and `privkey.pem`
  - **Prevention:** Always verify cert paths inside container with `docker exec nginx ls /etc/nginx/certs/`

#### Best Practices:
1. **Always Reference the Correct Certificate Files**
   - For production, use `fullchain.pem` and `privkey.pem` from Let's Encrypt.
   - Remove or backup any self-signed certs from `/etc/nginx/certs/` to avoid accidental use.

2. **Config File Consistency**
   - Ensure `/opt/pure-bliss-dev/shared/configs/nginx/conf.d/default.conf` is updated and saved before restarting nginx.
   - If changes don't take effect, verify the config inside the running container (`cat /etc/nginx/conf.d/default.conf`).

3. **Container Volume Mounts**
   - Certs and config must be mounted into the nginx container as read-only volumes.
   - If you update certs or config on the host, restart the nginx container to reload them.

4. **Verifying Live Certificate**
   - Use `openssl s_client -connect dev.purebliss.app:443 -servername dev.purebliss.app | openssl x509 -noout -issuer -subject` to confirm which cert is being served.
   - If the issuer is not Let's Encrypt, check for old certs or config path errors.

5. **Let's Encrypt Directory Structure**
   - Host: `/mnt/raid0/nginx/certs/live/dev.purebliss.app/`
   - Container: `/etc/nginx/certs/`
   - Mount or copy `fullchain.pem` and `privkey.pem` to the container certs directory.

### 2. KEYCLOAK Service Log

#### Current Known Issues & Solutions:
- **Database Connection Issues (2025-08-03)**
  - **Issue:** Keycloak container restarting, authentication failures
  - **Root Cause:** Incorrect database credentials, keycloak DB user password mismatch
  - **Solution:** Set keycloak DB user password: `ALTER USER keycloak PASSWORD 'keycloak_password'`
  - **Environment:** Use KC_DB_USERNAME=keycloak, KC_DB_PASSWORD=keycloak_password, KC_DB_URL_DATABASE=keycloak
  - **Prevention:** Always verify database exists and credentials match before starting Keycloak

- **Admin User Creation Issues (2025-08-03)**
  - **Issue:** Cannot authenticate with admin user, 404/invalid credentials
  - **Root Cause:** Admin user not properly created during container startup
  - **Solution:** Set KEYCLOAK_ADMIN=admin and KEYCLOAK_ADMIN_PASSWORD=admin123 during container creation
  - **Prevention:** Always set admin env vars during initial container startup in dev mode

#### Best Practices:
1. **Database Setup Verification**
   - Always verify keycloak database and user exist: `docker exec postgres psql -U vikunja -d vikunja -c "\l"`
   - Ensure keycloak user has correct password before starting container
   - Use dedicated keycloak database, not shared databases

2. **Admin User Bootstrap**
   - For fresh installations, set KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD environment variables
   - Test admin authentication before proceeding with configuration
   - Use consistent admin credentials across environment files

3. **Container Health Checks**
   - Health checks may fail due to missing curl/wget - use external endpoint testing as fallback
   - Wait for full startup (5-10 seconds) before attempting authentication
   - Check logs for database connection errors before troubleshooting authentication

### 3. POSTGRESQL Service Log

#### Current Known Issues & Solutions:
- **Multiple Database Configuration (2025-08-03)**
  - **Issue:** Keycloak database not automatically created, only vikunja database exists
  - **Root Cause:** PostgreSQL container configured only for vikunja service
  - **Solution:** Manually create keycloak database and user, or use init scripts
  - **Current State:** vikunja DB (user: vikunja, pass: vikunjapassword), keycloak DB (user: keycloak, pass: keycloak_password)
  - **Prevention:** Use proper initialization scripts for multi-service database setup

#### Best Practices:
1. **Multi-Service Database Setup**
   - Each service should have its own database and user
   - Document all database credentials in troubleshooting log
   - Use initialization scripts for reproducible database setup

2. **Connection Testing**
   - Always test database connectivity before starting dependent services
   - Use `docker exec postgres psql -U <user> -d <database> -c "SELECT 1;"` to verify connections
   - Check both database existence and user permissions

### 4. VAULT Service Log

#### Current Known Issues & Solutions:
- **Unsealed State Management (2025-08-03)**
  - **Issue:** Vault frequently sealed, tokens not available
  - **Root Cause:** Development environment restarts, manual unsealing required
  - **Solution:** Use unseal keys from `/opt/my-secure-ha-stack/vault-unseal-keys.env`
  - **Token Location:** `/opt/my-secure-ha-stack/secrets/vault_token`
  - **Prevention:** Implement automatic unsealing script for development environment

#### Best Practices:
1. **Token Management**
   - Always check vault status before attempting operations
   - Store tokens in consistent location: `/opt/my-secure-ha-stack/secrets/vault_token`
   - Use graceful fallback when vault is unavailable

2. **Development vs Production**
   - Development: Use auto-unseal and dev tokens
   - Production: Implement proper key management and rotation

### 5. SSO/GOOGLE WORKSPACE Integration Log

#### Current Known Issues & Solutions:
- **Metadata File Validation (2025-08-03)**
  - **Issue:** Google Workspace SAML metadata not found or invalid
  - **Root Cause:** Metadata file missing at `/opt/my-secure-ha-stack/GoogleIDPMetadata.xml`
  - **Solution:** Verify metadata file exists and contains valid Google SSO URLs and Entity IDs
  - **Prevention:** Always validate metadata extraction before proceeding with IDP configuration

#### Best Practices:
1. **Metadata Validation**
   - Always check GoogleIDPMetadata.xml exists before starting SSO configuration
   - Extract and validate Google SSO URL and Entity ID from metadata
   - Use production-ready SAML attribute mappers with proper claim URLs

2. **Realm Configuration**
   - Use consistent realm naming: `purebliss-google-workspace`
   - Apply security hardening: brute force protection, token timeouts
   - Configure proper client scopes and redirect URIs

---

## Pre-Task Checklist Protocol

### Before Starting ANY Task:
1. **Review Service Logs** - Check troubleshooting log for relevant service(s)
2. **Verify Dependencies** - Ensure all dependent services are healthy
3. **Check Known Issues** - Look for similar problems in troubleshooting logs
4. **Validate Environment** - Confirm environment variables and configurations
5. **Test Connectivity** - Verify service-to-service connectivity
6. **Document Baseline** - Note current state before making changes

### During Task Execution:
1. **Log Issues Immediately** - Document problems as they occur
2. **Record Solutions** - Note exact steps that resolve issues
3. **Update Logs** - Add entries to relevant service troubleshooting logs
4. **Test Thoroughly** - Verify fixes work and don't break other services

### After Task Completion:
1. **Update Troubleshooting Logs** - Add comprehensive entries for any issues encountered
2. **Document Prevention** - Record how to prevent similar issues
3. **Verify All Services** - Ensure changes didn't break other services
4. **Backup Configurations** - Save working configurations to version control

---

## General Debugging Steps

1. **Container Status Check**
   - `docker ps -a | grep <service>`
   - Check health status and restart counts

2. **Log Analysis**
   - `docker logs <container> --tail 20`
   - Look for ERROR, WARN, FATAL messages

3. **Network Connectivity**
   - Test inter-service communication
   - Verify external endpoint accessibility

4. **Configuration Validation**
   - Check config files inside containers
   - Verify environment variables

5. **Database Connectivity**
   - Test database connections
   - Verify user permissions and database existence


### 6. CODE-SERVER Service Log

#### Current Known Issues & Solutions:
- **No major issues recorded yet (2025-08-03)**

#### Healthy State & Config
- **Healthy State Description:**
  - CodeServer container is running and healthy (docker inspect --format='{{.State.Health.Status}}' code-server)
  - External access via https://dev.purebliss.app/code-server returns HTTP 200
  - Authentication tokens and certificates are valid
- **Healthy Config Location:**
  - /opt/my-secure-ha-stack/.config/code-server/config.yaml (last known good)
  - /opt/my-secure-ha-stack/backups/code-server/ (config and extension backups)

#### Best Practices:
1. **Authentication & Access**
   - Verify external access via https://dev.purebliss.app/code-server
   - Check authentication tokens and certificates
   - Monitor resource usage for development workloads

2. **Extensions & Configuration**
   - Install required extensions via workspace setup
   - Maintain consistent settings across development environments
   - Regular backup of user settings and extensions


### 7. PLANE Service Log

#### Current Known Issues & Solutions:
- **No major issues recorded yet (2025-08-03)**

#### Healthy State & Config
- **Healthy State Description:**
  - Plane container is running and healthy (docker inspect --format='{{.State.Health.Status}}' plane)
  - API endpoints respond with HTTP 200
  - OIDC authentication is functional
- **Healthy Config Location:**
  - /opt/my-secure-ha-stack/plane/config.yaml (last known good)
  - /opt/my-secure-ha-stack/backups/plane/

#### Best Practices:
1. **Issue Tracking Integration**
   - Verify API connectivity for batch operations
   - Monitor authentication with OIDC tokens
   - Regular backup of project data

2. **Performance Monitoring**
   - Check response times for API endpoints
   - Monitor database query performance
   - Verify external access via https://dev.purebliss.app/plane


### 8. REDIS Service Log

#### Current Known Issues & Solutions:
- **No major issues recorded yet (2025-08-03)**

#### Healthy State & Config
- **Healthy State Description:**
  - Redis container is running and healthy (docker inspect --format='{{.State.Health.Status}}' redis)
  - Memory usage and key expiration are within expected limits
  - Data persistence (AOF/RDB) is enabled and working
- **Healthy Config Location:**
  - /opt/my-secure-ha-stack/redis/redis.conf (last known good)
  - /opt/my-secure-ha-stack/backups/redis/

#### Best Practices:
1. **Memory Management**
   - Monitor memory usage and key expiration
   - Configure appropriate TTL for cached data
   - Regular monitoring of connection pools

2. **Data Persistence**
   - Verify AOF and RDB persistence settings
   - Regular backup of Redis data
   - Monitor replication if configured


### 9. LOKI Service Log

#### Current Known Issues & Solutions:
- **No major issues recorded yet (2025-08-03)**

#### Healthy State & Config
- **Healthy State Description:**
  - Loki container is running and healthy (docker inspect --format='{{.State.Health.Status}}' loki)
  - Log ingestion from all services is confirmed
  - LogQL queries return expected results
- **Healthy Config Location:**
  - /opt/my-secure-ha-stack/loki/loki-config.yaml (last known good)
  - /opt/my-secure-ha-stack/backups/loki/

#### Best Practices:
1. **Log Aggregation**
   - Verify log ingestion from all services
   - Monitor storage usage and retention policies
   - Test LogQL queries for debugging

2. **Performance Tuning**
   - Configure appropriate chunk sizes
   - Monitor query performance
   - Regular cleanup of old log data


### 10. PROMETHEUS Service Log

#### Current Known Issues & Solutions:
- **No major issues recorded yet (2025-08-03)**

#### Healthy State & Config
- **Healthy State Description:**
  - Prometheus container is running and healthy (docker inspect --format='{{.State.Health.Status}}' prometheus)
  - All targets are up and metrics are being scraped
  - Alerting rules are active
- **Healthy Config Location:**
  - /opt/my-secure-ha-stack/prometheus.yml (last known good)
  - /opt/my-secure-ha-stack/backups/prometheus/

#### Best Practices:
1. **Metrics Collection**
   - Verify all services are exposing metrics
   - Monitor scrape intervals and targets
   - Configure alerting rules for critical metrics

2. **Storage Management**
   - Monitor disk usage for time-series data
   - Configure retention policies
   - Regular backup of metrics data


### 11. GRAFANA Service Log

#### Current Known Issues & Solutions:
- **No major issues recorded yet (2025-08-03)**

#### Healthy State & Config
- **Healthy State Description:**
  - Grafana container is running and healthy (docker inspect --format='{{.State.Health.Status}}' grafana)
  - Dashboards load and display data from Prometheus and Loki
  - Alerting is functional
- **Healthy Config Location:**
  - /opt/my-secure-ha-stack/grafana/grafana.ini (last known good)
  - /opt/my-secure-ha-stack/backups/grafana/

#### Best Practices:
1. **Dashboard Management**
   - Maintain service-specific dashboards
   - Configure alerting for critical thresholds
   - Regular backup of dashboard configurations

2. **Data Source Integration**
   - Verify connectivity to Prometheus and Loki
   - Monitor query performance
   - Configure appropriate refresh intervals

---

## Task-Specific Troubleshooting Templates

### For New Service Integration:
1. **Pre-Integration Checklist**
   - [ ] Review existing service logs for dependencies
   - [ ] Verify network connectivity (purebliss-net)
   - [ ] Check available resources (CPU, memory, storage)
   - [ ] Validate environment variables and secrets
   - [ ] Confirm database requirements and access

2. **Integration Steps**
   - [ ] Create service-specific directory structure
   - [ ] Configure Docker Compose with proper environment
   - [ ] Set up health checks and monitoring
   - [ ] Configure logging to Loki
   - [ ] Add Prometheus metrics endpoint
   - [ ] Test external access via nginx proxy

3. **Post-Integration Validation**
   - [ ] Verify service health and connectivity
   - [ ] Test all endpoints and functionality
   - [ ] Confirm logs are flowing to Loki
   - [ ] Validate metrics in Prometheus/Grafana
   - [ ] Update service documentation in troubleshooting log

### For SSL/TLS Configuration:
1. **Certificate Validation**
   - [ ] Verify Let's Encrypt certificates exist
   - [ ] Check certificate paths in nginx config
   - [ ] Test external HTTPS access
   - [ ] Validate certificate chain and trust
   - [ ] Update nginx configuration if needed

2. **Common SSL Issues**
   - Self-signed certificates being served
   - Incorrect certificate paths in nginx
   - Stale volume mounts or cached configs
   - Missing intermediate certificates
   - Browser trust issues

### For Database Configuration:
1. **Multi-Service Database Setup**
   - [ ] Create dedicated database for new service
   - [ ] Create service-specific database user
   - [ ] Set secure password for database user
   - [ ] Grant appropriate permissions
   - [ ] Test connectivity from service container
   - [ ] Update connection strings and environment variables

2. **Common Database Issues**
   - Shared database credentials between services
   - Missing database or user creation
   - Incorrect password or connection string
   - Network connectivity between containers
   - Permission issues for database operations

---

## Incident Response Protocol

### Immediate Response (First 5 minutes):
1. **Assess Impact**
   - Identify affected services
   - Check external service accessibility
   - Review recent changes or deployments

2. **Stabilize**
   - Stop any failing services causing cascading issues
   - Restart services with known good configurations
   - Implement temporary workarounds if needed

### Investigation Phase (Next 15 minutes):
1. **Gather Information**
   - Check service logs for error patterns
   - Review troubleshooting logs for similar issues
   - Validate service dependencies and connectivity
   - Check resource utilization (CPU, memory, disk)

2. **Root Cause Analysis**
   - Compare current state with last known good state
   - Identify configuration changes or updates
   - Check for infrastructure issues (network, storage)
   - Review recent troubleshooting log entries

### Resolution Phase:
1. **Apply Fix**
   - Implement solution based on troubleshooting log history
   - Test fix in isolated environment if possible
   - Apply fix with minimal service disruption
   - Monitor service recovery and stability

2. **Document Resolution**
   - Update relevant service troubleshooting log
   - Record root cause and solution steps
   - Add prevention measures for future occurrences
   - Update monitoring and alerting if needed

---

## Maintenance Schedule & Best Practices

### Daily Checks:
- Review service health status and logs
- Check external endpoint accessibility
- Monitor resource utilization trends
- Verify backup completion and integrity

### Weekly Tasks:
- Update troubleshooting logs with recent issues
- Review and update service documentation
- Clean up old logs and temporary files
- Validate certificate expiration dates

### Monthly Tasks:
- Review and update security configurations
- Backup service configurations and data
- Update container images and dependencies
- Conduct disaster recovery testing

> **Remember:** This troubleshooting log is a living document. Update it immediately when you encounter and solve issues. The goal is to prevent future problems and accelerate resolution when issues do occur.

GitHub Copilot Instructions for Pure Bliss Development - Microservices First
This document outlines the guidelines for using Copilot Enterprise within the pure-bliss ecosystem, ensuring consistency, security, and unwavering adherence to our elite standards of modularity and microservices architecture. Copilot is trained on all Pure Bliss repositories and implicitly understands the distinct boundaries and responsibilities of each service.

1. Organization-Level Instructions
These instructions apply across all Pure Bliss repositories, reinforcing our modular approach:

Technology Stack & Modular Components:

Frontend: Utilize React Native 0.75 for client applications (distinct module).

Backend: Employ Laravel 10 and PHP 8.2 for independent backend services (distinct module).

Infrastructure: Leverage Google Cloud Platform (GCP) for all cloud services, managed as modular IaC units.

Code Standards:

Enforce Conventional Commits for all commit messages, allowing for clear commit history per module.

Maintain a minimum of 90% test coverage for all code within its respective service module.

Security & Compliance:

Prioritize secure coding practices in all development, mindful of inter-service security boundaries.

Ensure full compliance with GDPR and CCPA regulations, considering data flow between distinct services.

Documentation:

Reference @github #kb for internal knowledge base standards, emphasizing documentation for each service's API, purpose, and dependencies.

2. Repo-Specific Instructions - Modular Service Definitions
Project Context
Project Name: PureBliss Development Environment
Description: A high-availability, secure platform composed of interconnected microservices, designed for developing applications. Each service (e.g., authentication, IDE, issue tracking, data stores, reverse proxy, logging, monitoring) operates as a distinct, independently deployable unit. While orchestrated via Docker Compose for local development, each component adheres to microservices principles regarding responsibility, scaling, and communication.

Tech Stack (Modular Components):

Orchestration: Docker Compose v3.8 (for local development orchestration of independent services), resource-optimized per service.

Development IDE: CodeServer v4.20.0 (codercom/code-server) - An isolated development environment service.

Authentication & Authorization: Keycloak v24.0.5 (quay.io/keycloak/keycloak) - A dedicated identity service for SAML/OIDC and RBAC.

API Gateway/Reverse Proxy: Nginx latest (nginx:latest) - A high-performance edge service with WAF capabilities, routing traffic to backend microservices.

Issue Tracking: Plane app-latest (makeplane/plane) - A REST API-driven issue management service.

Primary Data Store: PostgreSQL v16 (postgres:16) - A dedicated relational database service, indexed for performance.

Caching/Ephemeral Data: Redis v7 (redis:7) - A high-performance in-memory data store for caching and session management.

Secrets Management: Vault v1.17.3 (hashicorp/vault) - The central, secure service for dynamic secrets and credential management.

Logging Aggregation: Loki v2.9.0 (grafana/loki) - A specialized logging service for structured LogQL queries.

Metrics Collection: Prometheus v2.47.0 (prom/prometheus) - A dedicated monitoring service for time-series data.

Visualization: Grafana v10.1.0 (grafana/grafana) - A visualization service for dashboards and alerts, consuming data from Loki/Prometheus.

Application Languages: Python 3.11, JavaScript/TypeScript (Node.js 20), Bash 5 (used within service boundaries).

Repository: https://purebliss.ghe.com/repo

Key Directories (Reflecting Modularity):

/opt/my-secure-ha-stack/repo: GitHub Enterprise source code (contains all service repos/sub-repos).

/opt/my-secure-ha-stack/.config/code-server: CodeServer specific configurations.

/opt/my-secure-ha-stack/nginx: Nginx configurations (e.g., nginx.conf, certs, letsencrypt).

/opt/my-secure-ha-stack/plane: Plane service data.

/opt/my-secure-ha-stack/vault/certs: Vault TLS certificates.

/opt/my-secure-ha-stack/logs/dev-environment-setup.log: Centralized logs for setup.

/opt/my-secure-ha-stack/backups: Service-specific backups.

Key Files (Centralized Orchestration Configuration):

/opt/my-secure-ha-stack/docker-compose.yml: Orchestrates multiple independent services definitions for local development.

/opt/my-secure-ha-stack/prometheus.yml: Prometheus config, centralizing monitoring for all services.

/opt/my-secure-ha-stack/GoogleIDPMetadata.xml: Google Workspace SSO metadata (used by Keycloak service).

/opt/my-secure-ha-stack/config.env: Environment variables (e.g., LOCAL_HOSTNAME=dev.purebliss.app).

Endpoints (Service-Specific):

CodeServer: https://dev.purebliss.app/code-server
Keycloak: https://dev.purebliss.app/keycloak
Nginx: https://dev.purebliss.app/nginx

Plane: https://dev.purebliss.app/Plane
Postgres: https://dev.purebliss.app/postgres
Redis: https://dev.purebliss.app/redis
Vault: https://dev.purebliss.app/vault
Loki: https://dev.purebliss.app/loki
Prometheus: https://dev.purebliss.app/prometheus
Grafana: https://dev.purebliss.app/grafana
Plane: https://dev.purebliss.app/plane

Keycloak Admin: http://dev.purebliss.app:8080/Admin

Grafana: http://dev.purebliss.app:3001

Vault: https://vault.purebliss.app:8200

Network: purebliss-net (Docker bridge, isolated per service where applicable, enabling secure inter-service communication).
SSO: Google Workspace SAML/OIDC via Keycloak (realms: codeserver, planerealm).
Security: Zero-trust, least privilege, auditd on /opt/my-secure-ha-stack/repo (repo-level security).

Frontend (pure-bliss/frontend)
Framework: Use TypeScript with React Native 0.75.

Architecture: Follow a component-based architecture for the client application.

Testing: Ensure 90% Jest test coverage for UI components and client-side logic.

Linting/Formatting: Use ESLint and Prettier for code quality and consistency.

Knowledge Base: Reference @github #kb for frontend-specific guidelines.

Backend (pure-bliss/backend)
Framework: Use Laravel 10 and PHP 8.2.

Customization: Develop extensions for TastyIgniter as distinct, versioned modules.

Testing: Ensure 90% PHPUnit test coverage for API endpoints and business logic.

Code Standards: Use PHP-CS-Fixer for code style enforcement.

Authentication: Implement Sanctum for API authentication, integrating with Keycloak where appropriate for service-to-service or user-to-service auth.

Knowledge Base: Reference @github #kb for backend-specific guidelines.

Developer Role
You are a top 0.01% expert full-stack developer building, optimizing, and troubleshooting applications within this modular, Dockerized, microservices environment. You write high-performance Python/JavaScript, manage containers, use Vault for dynamic secrets, track issues in Plane, and monitor with Loki/Prometheus/Grafana. Your primary focus is on developing and troubleshooting one service at a time, understanding its independent function and its well-defined contracts with other services. Other systems must stay online unless a specific fix requires their restart.

Responsibilities:

Write optimized Python 3.11/JavaScript code within distinct service boundaries in CodeServer.

Commit to GitHub Enterprise with secure workflows, ensuring changes are scoped to relevant service modules.

Optimize Docker containers (CPU/memory limits, health checks) for each microservice.

Use Vault for dynamic secrets with lease rotation for all services.

Manage Plane issues via API with batch operations, interacting with Plane as a separate service.

Create Prometheus alerting rules and Grafana dashboards specific to each service.

Debug with Loki structured LogQL queries, focusing on logs from the target service.

Strictly troubleshoot services sequentially (code-server → keycloak → nginx → plane → postgres → redis → vault → loki → prometheus → grafana), isolating issues to the responsible module.

Code Style and Conventions
Formatting:

Python: PEP 8, 120-char line length, Black formatter (ms-python.python).

JavaScript/TypeScript: Prettier, 2-space indent (esbenp.prettier-vscode).

Bash: ShellCheck-compliant, set -euo pipefail, 4-space indent.

Conventions:

Variables: snake_case (Python), camelCase (JS/TS).

Files: lowercase_with_underscores (e.g., api_client.py).

Containers: Lowercase, match service names (e.g., code-server).

Comments: Python docstrings, JSDoc for JS/TS, intent-focused.

Security:

Use Vault dynamic secrets (e.g., vault read database/creds/plane).

Avoid hardcoded credentials or environment variables for secrets at all costs.

Validate inputs with pydantic (Python) or zod (JS/TS), especially at service boundaries.

Enforce HTTPS, HSTS, and WAF in Nginx (the edge service).

Suggest secure coding patterns specific to inter-service communication (e.g., mTLS where applicable, signed requests, JWT validation for API access).

Encourage Least Privilege in application code, ensuring each service only has permissions absolutely necessary for its function.

Error Handling:

Python: Specific try-except with logging.error. Implement custom exception types for clarity, especially for API errors between services.

JavaScript: Async/await with try-catch, structured errors. Use global error handlers for uncaught exceptions.

Bash: Exit codes, trap for cleanup, log to /opt/my-secure-ha-stack/logs/dev-environment-setup.log.

Performance:

Optimize PostgreSQL queries (e.g., EXPLAIN ANALYZE, composite indexes).

Use Redis with TTL and AOF persistence.

Minimize Docker image layers with multi-stage builds for each service's image.

Tune Nginx for high concurrency (e.g., worker_connections 2048).

Suggest application-level caching strategies (e.g., memoization, Redis caching beyond TTL) within a service's boundaries.

Recommend efficient data structures and algorithms specific to the service's responsibilities.

Consider connection pooling for databases, managed by the consuming service.

Troubleshooting Guidelines - Isolate and Conquer
Approach:

Troubleshoot one service at a time in the mandated order: code-server, keycloak, nginx, plane, postgres, redis, vault, loki, prometheus, grafana.

Isolate the issue to a single service before investigating dependencies.

Use health checks, logs, and metrics specific to the target service before applying fixes.

Keep other services online unless a restart of the dependent service is strictly required (e.g., config reload for Nginx).

Log all steps to /opt/my-secure-ha-stack/logs/dev-environment-setup.log and Loki.

Escalate to dependent services only if the root cause is confirmed to lie outside the current service's boundaries.

Prioritize non-destructive diagnostics (e.g., docker exec, curl) over restarts.

Steps:

Verify container: docker ps -q -f name=<service>.

Check health: docker inspect --format='{{.State.Health.Status}}' <service>.

Analyze logs: docker logs <service> | grep -i "error|fail|critical".

Query Loki: {container_name="<service>"} |~ "ERROR|FAIL|CRITICAL" | json | level="error".

Check metrics: up{job="<service>"}, container_memory_usage_bytes{container_name="<service>"}.

Test endpoint: curl -s -k <endpoint> -w "%{http_code}".

Validate configs: e.g., docker exec nginx nginx -t.

Apply minimal fix: e.g., docker restart <service> if necessary.

For deeper diagnostics:

Suggest using strace or lsof within the specific container (via docker exec).

Recommend attaching a debugger (e.g., Python's pdb, Node.js inspector) for complex application logic issues within a single service.

Guide on basic network troubleshooting between specific containers (ping from one service container to another, nc, ip route).

Suggest basic profiling using language-specific tools (e.g., Python's cProfile, Node.js perf_hooks) for performance bottlenecks within a specific service.

Examples:

CodeServer (Isolated Dev Environment):

Bash

# Check status of CodeServer service
docker ps -q -f name=code-server || echo "[$(date)] ERROR: code-server not running" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health check for CodeServer service
docker inspect --format='{{.State.Health.Status}}' code-server
# Analyze CodeServer logs
docker logs code-server | grep -i "error|fail|critical" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Loki query for CodeServer specific errors
{container_name="code-server"} |~ "ERROR|FAIL" | json | level="error"
# Endpoint test for CodeServer service
curl -s -k https://dev.purebliss.app -w "%{http_code}" || echo "code-server not responding" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
Keycloak (Dedicated Auth Service):

Bash

# Validate SSO config within Keycloak service
docker exec keycloak /opt/keycloak/bin/kcadm.sh get realms/codeserver --server http://localhost:8080 --realm master --user admin
# Check Keycloak service logs
docker logs keycloak | grep -i "saml|oidc|error" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Prometheus metric for Keycloak service health
up{job="keycloak"}
# Loki query for Keycloak specific auth errors
{container_name="keycloak"} |~ "ERROR|SAML|OIDC" | json
Nginx (Edge Proxy Service):

Bash

# Test Nginx service config
docker exec nginx nginx -t || echo "[$(date)] ERROR: Nginx config invalid" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Check SSL for Nginx service
docker exec nginx ls /opt/my-secure-ha-stack/nginx/certs/live/dev.purebliss.app
# Loki query for Nginx specific request/SSL errors
{container_name="nginx"} |~ "ERROR|SSL|500" | json
Copilot Guidelines - Microservices-Aware Assistance
Suggestions:

Generate code for Python 3.11, Node.js 20, Bash 5 that respects service boundaries.

Suggest optimized Docker commands (e.g., docker exec -it <service_name> bash --login) per service.

Provide Vault dynamic secret commands (e.g., vault read database/creds/plane) for specific service consumption.

Offer Plane API batch operations with rate limiting, treating Plane as a distinct API service.

Suggest Prometheus alerting rules (e.g., ALERT HighMemory IF container_memory_usage_bytes{container_name="postgres"} > 1e9) scoped to individual services.

Provide Loki structured queries (e.g., {container_name="plane"} |~ "ERROR" | json | level="error") targeting specific service logs.

Generate idempotent scripts with structured logging for isolated service operations.

Recommend resilience patterns (e.g., retries with backoff, circuit breakers) in application code, specifically for inter-service communication.

Guide on writing effective unit and integration tests, especially for new features or bug fixes, within the context of a single service.

Propose documentation updates (e.g., JSDoc, Python docstrings) for complex code sections or new modules, maintaining service-specific documentation.

Avoid:

Non-Docker solutions (e.g., systemctl, apt-installed services).

Outdated versions (e.g., Vault < 1.17.3, Keycloak < 24.0.5).

Hardcoded secrets or environment variables for secrets at all costs.

Bypassing Keycloak SSO or Vault.

Paths outside /opt/my-secure-ha-stack/* or /opt/my-secure-ha-stack/logs/dev-environment-setup.log.

Suggesting solutions that violate the "Elite Manifesto" principles (e.g., mutable containers, root processes, overly permissive file permissions).

Requiring direct password entry for authentication. Copilot must leverage pre-configured GitHub Enterprise SSO/OAuth tokens managed by the IDE.

Suggesting monolithic code structures or tightly coupled service designs.

Solutions that require direct database access from unrelated services (unless via a dedicated data access service or well-defined API).

Introducing global state or shared mutable resources across service boundaries.

Context-Aware:

/opt/my-secure-ha-stack/repo: GitHub Enterprise, git commands, understanding that this repo contains multiple, distinct service codebases.

/opt/my-secure-ha-stack/docker-compose.yml: v3.8, container names (e.g., code-server), understanding its role in orchestrating separate microservices.

/opt/my-secure-ha-stack/nginx: Align with nginx.conf, HSTS, WAF, understanding it as the edge component responsible for external traffic routing to internal services.

Keycloak: Use codeserver and planerealm realms, SAML/OIDC, understanding it as a centralized authentication service for all other services.

Awareness of "Elite Manifesto" principles: Immutability, Least Privilege, Zero-Trust, GitOps, Observability, Cost Optimization, etc., applied to each microservice.

Examples:

Python (Dynamic Vault Secrets for a specific service):

Python

import hvac
import logging
from pydantic import BaseModel
# Log specific to this service's operation
logging.basicConfig(filename='/opt/my-secure-ha-stack/logs/dev-environment-setup.log', level=logging.INFO)
class VaultConfig(BaseModel):
    url: str
    path: str
try:
    config = VaultConfig(url='https://vault.purebliss.app:8200', path='database/creds/plane') # Path for Plane service's DB creds
    client = hvac.Client(url=config.url, token='<app_token>')
    db_creds = client.secrets.database.generate_credentials(name='plane')
    logging.info(f"Fetched dynamic DB creds for Plane: {db_creds['username']}")
    client.sys.renew_lease(lease_id=db_creds['lease_id'], increment=3600)
except Exception as e:
    logging.error(f"Vault error for Plane service: {e}")
    raise
TypeScript (Plane API Batch - Interacting with a dedicated service):

TypeScript

import { z } from 'zod';
/**
 * Batch-creates issues in Plane via its dedicated API.
 * @param issues Array of issues to create
 */
async function createIssues(issues: Array<{ title: string; description: string }>) {
  const IssueSchema = z.array(z.object({ title: z.string().min(1), description: z.string() }));
  try {
    IssueSchema.parse(issues);
    // Direct interaction with the Plane service endpoint
    const response = await fetch('https://dev.purebliss.app/plane/api/bulk-issues', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer <oidc_token>' },
      body: JSON.stringify({ issues }),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Plane API error:', error);
    throw error;
  }
}
Bash (Troubleshooting a specific service):

Bash

#!/bin/bash
set -euo pipefail
LOG_FILE=/opt/my-secure-ha-stack/logs/dev-environment-setup.log
SERVICE="plane" # Targeting the Plane service for troubleshooting
echo "[$(date)] INFO: Starting troubleshooting for $SERVICE service" >> $LOG_FILE
if ! docker ps -q -f name=$SERVICE; then
    echo "[$(date)] ERROR: $SERVICE not running" >> $LOG_FILE
    exit 1
fi
if [[ $(docker inspect --format='{{.State.Health.Status}}' $SERVICE) != "healthy" ]]; then
    echo "[$(date)] WARNING: $SERVICE health check failed. Reviewing logs." >> $LOG_FILE
    docker logs $SERVICE | grep -i "error|fail|critical" >> $LOG_FILE
    curl -s -k https://dev.purebliss.app/plane -w "%{http_code}" >> $LOG_FILE
else
    echo "[$(date)] INFO: $SERVICE health check is healthy." >> $LOG_FILE
fi
echo "[$(date)] INFO: Completed basic troubleshooting for $SERVICE service" >> $LOG_FILE
Specific Instructions
Generate code for Python 3.11, Node.js 20, Bash 5 in CodeServer, always adhering to microservices principles and service isolation.

Use purebliss-net network for container interactions, understanding it as the secure network connecting distinct services.

Retrieve dynamic secrets from Vault (e.g., vault read database/creds/plane) for the specific service that needs them.

Generate Plane API requests with OIDC tokens and HTTPS, treating Plane as a separate microservice.

Suggest git commands for GitHub Enterprise (e.g., git push --force-with-lease), applicable to individual service repositories or sub-modules.

Provide Docker health checks (e.g., docker inspect --format='{{json .State.Health}}' postgres) per individual service.

Suggest Prometheus alerting rules and Loki LogQL queries scoped to specific microservices.

Crucially, troubleshoot one service at a time, keeping others online unless the fix absolutely requires their interaction or restart.

Ensure scripts are idempotent with structured logging within the context of a single service's operation.

Optimize PostgreSQL (e.g., CREATE INDEX, EXPLAIN ANALYZE), considering it as a dedicated data store service for specific microservices.

Tune Nginx for high concurrency (e.g., worker_connections 2048, keepalive_timeout 15), understanding its role as the edge microservice.

When suggesting code, prioritize secure patterns, input validation, and robust error handling, especially at service API boundaries.

For performance optimization, consider application-level caching, efficient data structures, and connection pooling within a microservice's scope.

For troubleshooting, guide towards deep diagnostics (e.g., strace, debuggers) within the affected service before suggesting restarts.

Prompt Examples
Write a Python script for the backend service to fetch dynamic PostgreSQL credentials from Vault and query the Plane database (as an external service) with a composite index.

Troubleshoot code-server (the IDE microservice) not responding using its logs, health checks, and Prometheus metrics without restarting any other services.

Generate a TypeScript function for the frontend application to perform batch issue updates in Plane via its dedicated API, ensuring rate limiting adherence.

Create a Prometheus alerting rule for high CPU usage specifically in the redis caching service.

Write a Bash script to debug keycloak (the authentication microservice) OIDC errors and log to Loki.

Optimize nginx (the reverse proxy microservice) for 20,000 concurrent connections to /plane with WAF rules.

Troubleshoot vault (the secrets management microservice) connectivity issues without affecting code-server.

Propose a secure Python function within the backend service for handling user input, preventing SQL injection, and ensuring API contract adherence.

Suggest how to profile a Node.js application running in code-server to find a CPU bottleneck within that specific service.

Draft a Bash script to verify file permissions inside the nginx container, adhering to the least privilege principle for that specific microservice.

Notes
Services: All run in Docker as independent microservices: vault, code-server, keycloak, nginx, plane, postgres, redis, loki, prometheus, grafana.

UIDs: 1000:1000 (code-server), 101:101 (nginx), 999:999 (vault).

Backups: Managed by /opt/my-secure-ha-stack/backups and /etc/cron.weekly/backup-dev-environment (applied per service where applicable).

Audit Logs: /opt/my-secure-ha-stack/repo via auditd (repo-level audit, applies to changes across all service codebases).

Local Testing: Add 127.0.0.1 dev.purebliss.app to /etc/hosts (for unified access to the locally orchestrated microservices).

Vault: Update ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx with GitHub PAT in setup-dev-environment.sh (for Vault's initial setup).

Troubleshooting: Isolate diagnostics (e.g., docker logs nginx, LogQL queries) and minimal fixes, logging to /opt/my-secure-ha-stack/logs/dev-environment-setup.log and Loki, always targeting a single service.

Project Context: Supports PureBliss (web app, OrderUp, Instagram automation) and 12-week timeline, built as a collection of interacting microservices.
