# Keycloak Break-Fix Report

**Pure Bliss Elite Standards - Service Independence & Vault Integration**
**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Executive Summary

This document provides comprehensive troubleshooting guidance for the Keycloak authentication service in the Pure Bliss development environment. It covers common issues, diagnostic procedures, resolution steps, and preventive measures to ensure reliable service operation.

## Service Overview

**Service Name:** Keycloak Authentication Service
**Container Name:** `purebliss-keycloak`
**Base Image:** `quay.io/keycloak/keycloak:24.0.5`
**Network:** `purebliss-net`
**Primary Port:** 8080
**Health Endpoint:** `/realms/master`

## Common Issues and Resolutions

### 1. Container Startup Failures

#### Symptoms
- Container fails to start or crashes immediately
- Docker health check fails
- No response from service endpoints

#### Diagnostic Commands
```bash
# Check container status
docker ps -a --filter "name=purebliss-keycloak"

# Check container logs
docker logs purebliss-keycloak --tail 50

# Check resource usage
docker stats purebliss-keycloak --no-stream

# Validate environment
docker exec purebliss-keycloak env | grep -E 'KC_|VAULT_|POSTGRES'
```

#### Root Causes
1. **Missing Environment Variables**
   - Resolution: Verify `.env` file contains all required variables
   - Prevention: Add environment validation to entrypoint script

2. **Insufficient Memory**
   - Resolution: Increase container memory limits
   - Prevention: Monitor memory usage and set appropriate limits

3. **Port Conflicts**
   - Resolution: Check for conflicting services on port 8080
   - Prevention: Use dynamic port allocation or service discovery

#### Resolution Steps
```bash
# 1. Stop and remove failed container
docker stop purebliss-keycloak
docker rm purebliss-keycloak

# 2. Verify environment configuration
cat /opt/dev-purebliss/services/keycloak/.env

# 3. Check resource availability
free -h
df -h

# 4. Restart with enhanced logging
docker run -d --name purebliss-keycloak \
  --network purebliss-net \
  --env-file /opt/dev-purebliss/services/keycloak/.env \
  keycloak:enhanced

# 5. Monitor startup process
docker logs -f purebliss-keycloak
```

### 2. Database Connection Issues

#### Symptoms
- Keycloak logs show database connection errors
- Service fails to initialize
- Authentication failures

#### Diagnostic Commands
```bash
# Test PostgreSQL connectivity from Keycloak container
docker exec purebliss-keycloak bash -c 'echo > /dev/tcp/purebliss-postgres/5432'

# Check PostgreSQL status
docker exec purebliss-postgres pg_isready -U keycloak

# Verify database exists
docker exec purebliss-postgres psql -U postgres -l | grep keycloak

# Test database authentication
docker exec purebliss-keycloak bash -c 'PGPASSWORD=$KC_DB_PASSWORD psql -h purebliss-postgres -U $KC_DB_USERNAME -d $KC_DB_NAME -c "SELECT 1;"'
```

#### Root Causes
1. **PostgreSQL Service Down**
   - Resolution: Start PostgreSQL service
   - Prevention: Add dependency checks in entrypoint

2. **Database Not Created**
   - Resolution: Create keycloak database manually
   - Prevention: Add database creation logic to entrypoint

3. **Invalid Credentials**
   - Resolution: Update credentials in Vault or environment
   - Prevention: Implement credential validation

#### Resolution Steps
```bash
# 1. Verify PostgreSQL is running
docker ps --filter "name=purebliss-postgres"

# 2. Create database if missing
docker exec purebliss-postgres createdb -U postgres keycloak

# 3. Create user if missing
docker exec purebliss-postgres psql -U postgres -c "
CREATE USER keycloak WITH PASSWORD 'keycloak_secure_password';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
"

# 4. Test connection
docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT version();"

# 5. Restart Keycloak
docker restart purebliss-keycloak
```

### 3. Vault Integration Failures

#### Symptoms
- Keycloak uses fallback credentials instead of Vault
- Authentication errors with Vault
- Missing or invalid secrets

#### Diagnostic Commands
```bash
# Check Vault connectivity
curl -s http://purebliss-vault:8200/v1/sys/health | jq .

# Verify Vault token
docker exec purebliss-keycloak bash -c 'curl -H "X-Vault-Token: $VAULT_TOKEN" http://purebliss-vault:8200/v1/auth/token/lookup-self'

# Check Keycloak secrets in Vault
docker exec purebliss-keycloak bash -c 'curl -H "X-Vault-Token: $VAULT_TOKEN" http://purebliss-vault:8200/v1/secret/data/keycloak/database'
```

#### Root Causes
1. **Vault Service Down**
   - Resolution: Start Vault service and ensure it's unsealed
   - Prevention: Add Vault health checks to monitoring

2. **Invalid Token**
   - Resolution: Generate new token or use root token
   - Prevention: Implement token refresh mechanism

3. **Missing Secrets**
   - Resolution: Create required secrets in Vault
   - Prevention: Add secret initialization to setup script

#### Resolution Steps
```bash
# 1. Check Vault status
docker ps --filter "name=purebliss-vault"
curl http://purebliss-vault:8200/v1/sys/health

# 2. Unseal Vault if needed
source /opt/my-secure-ha-stack/vault-unseal-keys.env
for key in $UNSEAL_KEY_1 $UNSEAL_KEY_2 $UNSEAL_KEY_3; do
  curl -X PUT -d "{\"key\":\"$key\"}" http://purebliss-vault:8200/v1/sys/unseal
done

# 3. Create missing secrets
export VAULT_TOKEN=$(grep "Initial Root Token:" /opt/my-secure-ha-stack/vault-init-output.txt | awk '{print $NF}')

curl -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
  -d '{"data":{"username":"keycloak","password":"keycloak_secure_password","database":"keycloak","host":"purebliss-postgres","port":"5432"}}' \
  http://purebliss-vault:8200/v1/secret/data/keycloak/database

# 4. Restart Keycloak with valid token
docker restart purebliss-keycloak
```

### 4. Health Check Failures

#### Symptoms
- Health endpoint returns 404 or 500 errors
- Container health status shows unhealthy
- Service appears running but health checks fail

#### Diagnostic Commands
```bash
# Test health endpoints manually
curl -v http://localhost:8080/realms/master
curl -v http://localhost:8080/auth/realms/master
curl -v http://localhost:8080/health

# Check Keycloak process
docker exec purebliss-keycloak ps aux | grep keycloak

# Verify port binding
docker exec purebliss-keycloak netstat -tlnp | grep 8080
```

#### Root Causes
1. **Keycloak 24+ Endpoint Changes**
   - Resolution: Use `/realms/master` instead of `/auth/realms/master`
   - Prevention: Update all health check scripts to use correct endpoints

2. **Service Not Fully Initialized**
   - Resolution: Wait for complete startup before health checks
   - Prevention: Increase health check start period

3. **Network Connectivity Issues**
   - Resolution: Verify container network configuration
   - Prevention: Add network validation to startup process

#### Resolution Steps
```bash
# 1. Update health check endpoint in all scripts
sed -i 's|/auth/realms/master|/realms/master|g' /opt/dev-purebliss/validate-container-health.sh

# 2. Wait for service initialization
timeout 300 bash -c 'until curl -f http://localhost:8080/realms/master; do sleep 10; done'

# 3. Verify network connectivity
docker network inspect purebliss-net | grep purebliss-keycloak

# 4. Test health endpoint
curl -f http://localhost:8080/realms/master && echo "Health OK"
```

### 5. Redis Caching Issues

#### Symptoms
- Slow response times
- Session management problems
- Cache-related errors in logs

#### Diagnostic Commands
```bash
# Test Redis connectivity
docker exec purebliss-keycloak bash -c 'echo > /dev/tcp/purebliss-redis/6379'

# Check Redis status
docker exec purebliss-redis redis-cli ping

# Monitor Redis performance
docker exec purebliss-redis redis-cli --latency-history -i 1
```

#### Root Causes
1. **Redis Service Down**
   - Resolution: Start Redis service
   - Prevention: Add Redis health checks to monitoring

2. **Cache Configuration Issues**
   - Resolution: Update Keycloak cache configuration
   - Prevention: Validate cache settings during startup

#### Resolution Steps
```bash
# 1. Verify Redis is running
docker ps --filter "name=purebliss-redis"

# 2. Test Redis connectivity
docker exec purebliss-redis redis-cli ping

# 3. Restart Redis if needed
docker restart purebliss-redis

# 4. Restart Keycloak to re-establish cache connection
docker restart purebliss-keycloak
```

### 6. SSL/TLS Configuration Issues

#### Symptoms
- HTTPS endpoints not working
- Certificate errors
- Secure connections failing

#### Diagnostic Commands
```bash
# Check certificate validity
openssl s_client -connect dev.purebliss.app:443 -servername dev.purebliss.app

# Verify nginx SSL configuration
docker exec purebliss-nginx nginx -t

# Check Vault PKI status
curl http://purebliss-vault:8200/v1/pki/ca/pem
```

#### Root Causes
1. **Missing SSL Certificates**
   - Resolution: Generate certificates using Vault PKI
   - Prevention: Implement automated certificate provisioning

2. **Nginx Configuration Issues**
   - Resolution: Update nginx SSL configuration
   - Prevention: Validate nginx configuration before reload

#### Resolution Steps
```bash
# 1. Generate SSL certificate from Vault
export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
curl -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
  -d '{"common_name":"dev.purebliss.app","ttl":"8760h"}' \
  http://purebliss-vault:8200/v1/pki/issue/server

# 2. Update nginx configuration
docker exec purebliss-nginx nginx -s reload

# 3. Test HTTPS connectivity
curl -k https://dev.purebliss.app/auth/realms/master
```

## Preventive Measures

### Monitoring Setup

```bash
# Add Keycloak monitoring to Prometheus
cat >> /opt/my-secure-ha-stack/prometheus.yml << EOF
  - job_name: 'keycloak'
    static_configs:
      - targets: ['purebliss-keycloak:8080']
    metrics_path: '/metrics'
EOF
```

### Automated Health Checks

```bash
# Regular health validation
0 */1 * * * /opt/dev-purebliss/validate-container-health.sh keycloak scheduled-check
```

### Log Monitoring

```bash
# Monitor for errors
tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log | grep -i "keycloak.*error"
```

## Performance Optimization

### Memory Tuning

```bash
# Optimize JVM memory settings
export JAVA_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC"
```

### Database Connection Pooling

```bash
# Optimize database connections
export KC_DB_POOL_INITIAL_SIZE=10
export KC_DB_POOL_MIN_SIZE=5
export KC_DB_POOL_MAX_SIZE=50
```

### Cache Optimization

```bash
# Configure Redis cache settings
export REDIS_MAX_MEMORY=512mb
export REDIS_EVICTION_POLICY=allkeys-lru
```

## Emergency Procedures

### Service Recovery

```bash
#!/bin/bash
# Emergency Keycloak recovery script

echo "Starting emergency Keycloak recovery..."

# 1. Stop failed service
docker stop purebliss-keycloak

# 2. Check dependencies
/opt/dev-purebliss/validate-container-health.sh postgres emergency-check
/opt/dev-purebliss/validate-container-health.sh redis emergency-check
/opt/dev-purebliss/validate-container-health.sh vault emergency-check

# 3. Start with fallback configuration
docker run -d --name purebliss-keycloak-emergency \
  --network purebliss-net \
  -e KC_DB_USERNAME=keycloak \
  -e KC_DB_PASSWORD=keycloak_secure_password \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin123 \
  keycloak:enhanced

# 4. Validate emergency service
timeout 300 bash -c 'until curl -f http://localhost:8080/realms/master; do sleep 10; done'

echo "Emergency recovery completed"
```

### Data Backup

```bash
# Backup Keycloak database
docker exec purebliss-postgres pg_dump -U keycloak keycloak > /opt/backups/keycloak-$(date +%Y%m%d-%H%M%S).sql
```

### Configuration Restore

```bash
# Restore configuration from backup
docker cp /opt/backups/keycloak-config.json purebliss-keycloak:/opt/keycloak/conf/
docker restart purebliss-keycloak
```

## Security Considerations

### Access Control

- Ensure admin console is only accessible via HTTPS
- Implement strong password policies
- Enable multi-factor authentication where possible

### Secrets Management

- Never hardcode credentials in container images
- Use Vault for all sensitive configuration
- Rotate credentials regularly

### Network Security

- Isolate Keycloak traffic using Docker networks
- Implement proper firewall rules
- Use SSL/TLS for all communications

## Support Escalation

### Level 1: Automated Recovery
- Health check failures trigger automatic restart
- Basic connectivity issues resolved by retry logic
- Performance issues addressed by resource scaling

### Level 2: Manual Intervention
- Complex configuration issues requiring expert knowledge
- Database corruption or data loss scenarios
- Security incidents requiring immediate response

### Level 3: Expert Support
- Critical security vulnerabilities
- Major version upgrades
- Architectural changes requiring design review

## Contact Information

**Primary Support:** Pure Bliss Development Team
**Security Contact:** Vault and Secrets Management Team
**Emergency Escalation:** Operations Team (24/7)

## Documentation References

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Vault Integration Guide](/opt/dev-purebliss/services/keycloak/AUTOMATION_GUIDE.md)
- [Pure Bliss Standards](/opt/.github/copilot-instructions.md)

---

**Last Updated:** $(date '+%Y-%m-%d %H:%M:%S')
**Version:** 1.0.0
**Compliance:** Pure Bliss Elite Standards
