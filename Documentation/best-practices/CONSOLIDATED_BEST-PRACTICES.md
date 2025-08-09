# Consolidated BEST PRACTICES Documentation

**Generated**: 2025-08-07 22:01:45  
**Purpose**: Consolidated documentation from multiple service-specific documents  
**Consolidation Type**: best-practices  
**Services Covered**: postgres,redis,vault/backup

## Overview

This document consolidates similar best-practices documentation from multiple services to eliminate 
duplication while preserving service-specific information and maintaining cross-references.

## Service-Specific Information


### Universal Best Practices Framework

#### Security Best Practices
- **Secrets Management**: Use Vault for all credentials and sensitive data
- **Network Security**: Implement proper network segmentation and TLS
- **Access Control**: Principle of least privilege, role-based access
- **Audit Logging**: Comprehensive logging and monitoring

#### Performance Best Practices
- **Resource Management**: Proper CPU/memory limits and requests
- **Caching Strategy**: Implement appropriate caching layers
- **Connection Pooling**: Optimize database and service connections
- **Monitoring**: Comprehensive metrics and alerting

#### Deployment Best Practices
- **Health Checks**: Comprehensive readiness and liveness probes
- **Graceful Shutdown**: Proper signal handling and cleanup
- **Rolling Updates**: Zero-downtime deployment strategies
- **Rollback Procedures**: Quick recovery mechanisms

#### Service-Specific Best Practices


### postgres Service

**Source Document**: BEST_PRACTICES.md  
**Original Location**: /opt/dev-purebliss/services/postgres/BEST_PRACTICES.md

##### Configuration Guidelines

###### Environment Variable Standards

- `POSTGRES_HOST`: Container name `purebliss-postgres`
- `POSTGRES_PORT`: Standard port `5432`
- `POSTGRES_DATA_PATH`: Must point to RAID storage (`/raid-storage/postgres/data`)
- `POSTGRES_LOG_PATH`: Must point to RAID storage (`/raid-storage/logs/postgres.log`)
- `POSTGRES_MAX_CONNECTIONS`: Tuned for expected load (default: 100)

###### RAID Storage Requirements

- Data persistence: `/raid-storage/postgres/data`
- Log files: `/raid-storage/logs/postgres.log`
- Backup location: `/raid-storage/backups/postgres`
- WAL archiving: `/raid-storage/postgres/wal`

###### Multi-Database Configuration

- `postgres`: Default administrative database
- `keycloak`: Keycloak authentication service database
- `plane`: Issue tracking service database
- `vikunja`: Task management service database

##### Performance Optimization

###### Resource Limits and Requests

```yaml
resources:
  limits:
    memory: "1Gi"
    cpu: "1000m"
  requests:
    memory: "512Mi"
    cpu: "500m"
```

###### Database Tuning

- `shared_buffers`: 25% of available memory
- `effective_cache_size`: 75% of available memory
- `work_mem`: Calculated based on max_connections
- `maintenance_work_mem`: 256MB for maintenance operations

###### Index Optimization

- Composite indexes for multi-column queries
- Partial indexes for filtered queries
- Regular ANALYZE and VACUUM operations
- Query performance monitoring

##### Security Considerations

###### Vault Integration Requirements

- Dynamic database credentials via Vault
- Service-specific database users with minimal privileges
- Regular credential rotation
- Connection pooling with secure authentication

###### Access Control Standards

- No direct superuser access for applications
- Database-specific users for each service
- Row-level security where applicable
- SSL/TLS encryption for all connections

###### Backup Security

- Encrypted backups stored on RAID
- Point-in-time recovery capability
- Regular backup validation and testing

##### Common Issues & Solutions

###### Issue: Connection Pool Exhaustion

**Symptoms:** Applications report "too many connections" errors

**Solution:**
```bash
#### Check current connections
docker exec purebliss-postgres psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

#### Identify long-running queries
docker exec purebliss-postgres psql -U postgres -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';"

#### Kill long-running queries if needed
docker exec purebliss-postgres psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '10 minutes';"
```

###### Issue: Vault Authentication Failures

**Symptoms:** Services cannot connect using dynamic credentials

**Solution:**
1. Verify Vault PostgreSQL engine is enabled
2. Check database connection string in Vault
3. Validate PostgreSQL user permissions
4. Test credential generation manually

###### Issue: Database Performance Degradation

**Symptoms:** Slow query response times, high CPU usage

**Solution:**
```bash
#### Check database statistics
docker exec purebliss-postgres psql -U postgres -c "SELECT schemaname,tablename,n_tup_ins,n_tup_upd,n_tup_del FROM pg_stat_user_tables;"

#### Run ANALYZE on all tables
docker exec purebliss-postgres psql -U postgres -c "ANALYZE;"

#### Check for missing indexes
docker exec purebliss-postgres psql -U postgres -c "SELECT schemaname, tablename, attname, n_distinct, correlation FROM pg_stats WHERE schemaname NOT IN ('information_schema', 'pg_catalog');"
```

##### Emergency Procedures

###### Database Recovery

1. Stop all application services
2. Create emergency backup if possible
3. Restore from latest RAID backup
4. Validate data integrity
5. Restart services in dependency order

###### Data Corruption Response

1. Immediate shutdown to prevent further corruption
2. Assess extent of corruption
3. Restore from point-in-time backup
4. Validate data consistency
5. Implement preventive measures

##### Monitoring & Alerting

###### Key Metrics to Monitor

- Connection count and utilization
- Query performance and slow queries
- Database size and growth rate
- Backup success and duration
- Replication lag (if applicable)
- Cache hit ratios

###### Alert Thresholds

- Connection usage > 80%: Warning alert
- Slow query count > 10/minute: Warning alert
- Database size growth > 10%/day: Warning alert
- Backup failure: Critical alert
- CPU usage > 85%: Warning alert

###### Dashboard Configuration

- Database health overview
- Connection and query metrics
- Performance statistics
- Backup status monitoring
- Error rates and alerts

##### Database Management

###### Regular Maintenance Tasks

- Daily: Monitor logs and performance metrics
- Weekly: Run VACUUM and ANALYZE operations
- Monthly: Review and optimize slow queries
- Quarterly: Review database size and archiving needs

###### Backup Strategy

```bash
#### Daily automated backup
docker exec purebliss-postgres pg_dump -U postgres -d keycloak > /raid-storage/backups/postgres/keycloak_$(date +%Y%m%d).sql
docker exec purebliss-postgres pg_dump -U postgres -d plane > /raid-storage/backups/postgres/plane_$(date +%Y%m%d).sql
docker exec purebliss-postgres pg_dump -U postgres -d vikunja > /raid-storage/backups/postgres/vikunja_$(date +%Y%m%d).sql

#### Retention: Keep 30 daily, 12 monthly backups
find /raid-storage/backups/postgres/ -name "*.sql" -mtime +30 -delete
```

##### Integration Points

###### Services Using PostgreSQL

- Keycloak: User authentication and authorization data
- Plane: Issue tracking and project management data
- Vikunja: Task and project management data

###### Vault Integration

- Database credentials dynamically generated
- Connection pooling with rotated credentials
- Service-specific database users

##### Troubleshooting Quick Reference

```bash
#### Check PostgreSQL status
docker exec purebliss-postgres pg_isready -U postgres

#### View PostgreSQL logs
docker logs purebliss-postgres

#### Connect to specific database
docker exec -it purebliss-postgres psql -U postgres -d keycloak

#### Check database sizes
docker exec purebliss-postgres psql -U postgres -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size FROM pg_database;"

#### Monitor active connections
docker exec purebliss-postgres psql -U postgres -c "SELECT datname, usename, application_name, client_addr, state FROM pg_stat_activity WHERE state = 'active';"

#### Check replication status (if applicable)
docker exec purebliss-postgres psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```


### redis Service

**Source Document**: BEST_PRACTICES.md  
**Original Location**: /opt/dev-purebliss/services/redis/BEST_PRACTICES.md

##### Configuration Guidelines

###### Environment Variable Standards

- `REDIS_HOST`: Container name `purebliss-redis`
- `REDIS_PORT`: Standard port `6379`
- `REDIS_DATA_PATH`: Must point to RAID storage (`/raid-storage/redis/data`)
- `REDIS_LOG_PATH`: Must point to RAID storage (`/raid-storage/logs/redis.log`)
- `REDIS_AOF_ENABLED`: Always `true` for data persistence
- `REDIS_DEFAULT_TTL`: Default time-to-live for cached data (3600 seconds)

###### RAID Storage Requirements

- Data persistence: `/raid-storage/redis/data`
- AOF files: `/raid-storage/redis/data/appendonly.aof`
- Log files: `/raid-storage/logs/redis.log`
- Backup location: `/raid-storage/backups/redis`

###### Persistence Configuration

- AOF (Append Only File) enabled for durability
- RDB snapshots for backup purposes
- Memory optimization with appropriate eviction policies
- Regular AOF rewrite for space efficiency

##### Performance Optimization

###### Resource Limits and Requests

```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "256Mi"
    cpu: "250m"
```

###### Memory Management

- `maxmemory`: Set to 80% of container memory limit
- `maxmemory-policy`: `allkeys-lru` for general caching
- Monitor memory usage and fragmentation
- Regular memory optimization and cleanup

###### Caching Strategies

- Set appropriate TTL for different data types
- Use Redis data structures efficiently (sets, hashes, lists)
- Implement cache warming for critical data
- Monitor cache hit ratios and optimize accordingly

##### Security Considerations

###### Vault Integration Requirements

- Authentication tokens stored and rotated via Vault
- Redis AUTH password managed by Vault
- Service-specific access controls where possible
- Encrypted connections for sensitive data

###### Access Control Standards

- Redis AUTH enabled for all connections
- Network isolation within Docker network
- No direct external access (proxied through services)
- Connection limits to prevent abuse

###### Data Security

- Sensitive data encrypted before storage in Redis
- Regular security audits of cached data
- Automatic expiration of sensitive tokens
- Monitoring for unusual access patterns

##### Common Issues & Solutions

###### Issue: Memory Usage High

**Symptoms:** Redis reports high memory usage, OOM errors

**Solution:**

```bash
#### Check memory usage
docker exec purebliss-redis redis-cli INFO memory

#### Check largest keys
docker exec purebliss-redis redis-cli --bigkeys

#### Monitor memory fragmentation
docker exec purebliss-redis redis-cli INFO memory | grep fragmentation

#### Clean expired keys manually if needed
docker exec purebliss-redis redis-cli FLUSHDB
```

###### Issue: AOF Corruption

**Symptoms:** Redis fails to start, AOF loading errors

**Solution:**

```bash
#### Check AOF integrity
docker exec purebliss-redis redis-check-aof /data/appendonly.aof

#### Repair AOF if possible
docker exec purebliss-redis redis-check-aof --fix /data/appendonly.aof

#### Restore from backup if repair fails
docker stop purebliss-redis
cp /raid-storage/backups/redis/latest/appendonly.aof /raid-storage/redis/data/
docker start purebliss-redis
```

###### Issue: Connection Pool Exhaustion

**Symptoms:** Applications report connection timeouts

**Solution:**

```bash
#### Check connected clients
docker exec purebliss-redis redis-cli INFO clients

#### Monitor connection patterns
docker exec purebliss-redis redis-cli CLIENT LIST

#### Set connection limits if needed
docker exec purebliss-redis redis-cli CONFIG SET maxclients 1000
```

##### Emergency Procedures

###### Redis Recovery

1. Stop Redis container safely
2. Backup current AOF and RDB files
3. Restore from latest RAID backup
4. Validate data integrity
5. Restart Redis and verify operation

###### Data Loss Response

1. Assess scope of data loss
2. Stop applications using Redis
3. Restore from point-in-time backup
4. Rebuild cache from primary data sources
5. Resume applications with monitoring

##### Monitoring & Alerting

###### Key Metrics to Monitor

- Memory usage and fragmentation
- Connected clients and connection rate
- Cache hit/miss ratios
- AOF and RDB file sizes
- Command execution times
- Evicted keys count

###### Alert Thresholds

- Memory usage > 80%: Warning alert
- Memory fragmentation > 1.5: Warning alert
- Connected clients > 90% of max: Warning alert
- Cache hit ratio < 80%: Warning alert
- AOF file size growth > 50% daily: Warning alert

###### Dashboard Configuration

- Redis health overview
- Memory and performance metrics
- Connection statistics
- Cache performance metrics
- Error rates and slow operations

##### Cache Management

###### TTL Best Practices

- Session data: 30 minutes - 2 hours
- API responses: 5-15 minutes
- Static configuration: 24 hours
- User preferences: 1 hour
- Temporary tokens: Based on token lifetime

###### Data Structure Usage

```bash
#### Efficient patterns
#### Use hashes for structured data
HSET user:123 name "John" email "john@example.com"

#### Use sets for unique collections
SADD tags:article:456 "redis" "caching" "performance"

#### Use sorted sets for rankings
ZADD leaderboard 100 "player1" 95 "player2"

#### Use lists for queues
LPUSH queue:tasks "task1" "task2"
```

##### Integration Points

###### Services Using Redis

- Keycloak: Session storage and user state caching
- Plane: API response caching and temporary data
- Vikunja: Task caching and user session management
- Nginx: Rate limiting and temporary storage

###### Vault Integration

- Redis AUTH password rotation
- Connection credential management
- Security token storage and rotation

##### Troubleshooting Quick Reference

```bash
#### Check Redis status
docker exec purebliss-redis redis-cli ping

#### Monitor Redis performance
docker exec purebliss-redis redis-cli INFO stats

#### Check memory usage
docker exec purebliss-redis redis-cli INFO memory

#### Monitor slow operations
docker exec purebliss-redis redis-cli SLOWLOG GET 10

#### Check connected clients
docker exec purebliss-redis redis-cli CLIENT LIST

#### Monitor key expiration
docker exec purebliss-redis redis-cli INFO keyspace

#### Check persistence status
docker exec purebliss-redis redis-cli LASTSAVE

#### Manual AOF rewrite
docker exec purebliss-redis redis-cli BGREWRITEAOF

#### Backup current data
docker exec purebliss-redis redis-cli BGSAVE
```

##### Development vs Production

###### Development Mode

- Reduced memory limits for local development
- Less aggressive persistence settings
- DEBUG logging enabled
- Manual cache warming acceptable

###### Production Mode

- Optimized memory and persistence settings
- Regular automated backups
- Comprehensive monitoring and alerting
- High availability clustering (if required)

##### Performance Tuning

###### Redis Configuration Optimization

```conf
#### Memory optimization
maxmemory 400mb
maxmemory-policy allkeys-lru

#### Persistence optimization
save 900 1
save 300 10
save 60 10000

#### AOF configuration
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

#### Network optimization
tcp-keepalive 300
timeout 0
```

###### Client Connection Optimization

- Use connection pooling in applications
- Implement proper connection lifecycle management
- Monitor and tune connection limits
- Use pipelining for bulk operations when appropriate


### vault Service

**Source Document**: BEST_PRACTICES.md  
**Original Location**: /opt/dev-purebliss/services/vault/backup/BEST_PRACTICES.md

##### Configuration Guidelines

###### Environment Variable Standards
- `VAULT_ADDR`: Must use HTTPS in production, HTTP only for development mode
- `VAULT_DEV_MODE`: Set to `true` only for development, `false` for production
- `VAULT_DATA_PATH`: Must point to RAID storage (`/raid-storage/vault/data`)
- `VAULT_LOG_PATH`: Must point to RAID storage (`/raid-storage/logs/vault.log`)

###### RAID Storage Requirements
- Data persistence: `/raid-storage/vault/data`
- Log files: `/raid-storage/logs/vault.log`
- TLS certificates: `/raid-storage/vault/tls`
- Backup location: `/raid-storage/backups/vault`

###### Security Configuration
- TLS always enabled except in development mode
- Auto-unseal disabled in development (manual unseal required)
- Root token stored securely and rotated regularly
- Audit logging enabled for all production deployments

##### Performance Optimization

###### Resource Limits and Requests
```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "256Mi"
    cpu: "250m"
```

###### Storage Backend
- File storage backend for development
- High-performance storage required for RAID array
- Regular backup and recovery testing

###### Caching Strategies
- In-memory secret caching with appropriate TTL
- PKI certificate caching for SSL/TLS operations

##### Security Considerations

###### Vault Integration Requirements
- AppRole authentication for service-to-service communication
- Dynamic database credentials for PostgreSQL
- PKI engine for certificate management
- Secret engines properly configured with appropriate policies

###### TLS/SSL Configuration
- TLS 1.3 minimum for all communications
- Valid certificates from internal PKI or Let's Encrypt
- Certificate rotation automation implemented

###### Access Control Standards
- Least privilege principle for all policies
- Service-specific AppRoles with minimal required permissions
- Regular policy auditing and cleanup

##### Common Issues & Solutions

###### Issue: Vault Sealed State
**Symptoms:** Vault returns 503 errors, services cannot authenticate
**Solution:**
```bash
#### Check seal status
vault status
#### Unseal if needed (development mode)
vault operator unseal ${VAULT_UNSEAL_KEY_1}
vault operator unseal ${VAULT_UNSEAL_KEY_2}
vault operator unseal ${VAULT_UNSEAL_KEY_3}
```

###### Issue: AppRole Authentication Failures
**Symptoms:** Services report 403 errors from Vault
**Solution:**
1. Verify AppRole exists and is enabled
2. Check policy assignments
3. Validate role_id and secret_id

###### Issue: PKI Certificate Issues
**Symptoms:** SSL/TLS errors in services
**Solution:**
1. Check PKI engine health
2. Verify certificate validity
3. Regenerate certificates if expired

##### Emergency Procedures

###### Vault Recovery
1. Stop all dependent services
2. Restore Vault data from RAID backup
3. Initialize and unseal Vault
4. Verify all secrets and engines
5. Restart dependent services

###### Security Incident Response
1. Immediately seal Vault if compromise suspected
2. Rotate all AppRole credentials
3. Audit all access logs
4. Generate new root token if needed

##### Monitoring & Alerting

###### Key Metrics to Monitor
- Vault seal status (should always be unsealed)
- Authentication success/failure rates
- Secret engine health
- Storage backend performance
- Memory and CPU utilization

###### Alert Thresholds
- Vault sealed state: Immediate critical alert
- Authentication failure rate > 5%: Warning alert
- Storage usage > 80%: Warning alert
- Memory usage > 90%: Critical alert

###### Dashboard Configuration
- Vault health overview
- Authentication metrics
- Secret engine utilization
- Performance metrics
- Error rates and response times

##### Development vs Production

###### Development Mode
- Single node deployment
- HTTP listener for local access
- File storage backend
- Manual unsealing acceptable
- Simplified logging

###### Production Mode
- High availability cluster
- HTTPS only with valid certificates
- Auto-unseal with cloud KMS
- Comprehensive audit logging
- Monitoring and alerting required

##### Integration Points

###### Services Dependent on Vault
- PostgreSQL (dynamic database credentials)
- Redis (authentication tokens)
- Keycloak (configuration secrets)
- Nginx (TLS certificates)
- All application services (API keys, passwords)

###### Backup Dependencies
- RAID storage availability
- Automated backup scripts
- Recovery testing procedures

##### Troubleshooting Quick Reference

```bash
#### Check Vault status
docker exec purebliss-vault vault status

#### View Vault logs
docker logs purebliss-vault

#### Test AppRole authentication
vault write auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID"

#### List enabled engines
vault secrets list

#### Check policy assignments
vault policy list
vault policy read <policy-name>
```


## Related Documentation

- [Consolidated Automation Guide](../automation/CONSOLIDATED_AUTOMATION.md)
- [Consolidated Troubleshooting Guide](../troubleshooting/CONSOLIDATED_TROUBLESHOOTING.md)
- [Consolidated Best Practices](../best-practices/CONSOLIDATED_BEST_PRACTICES.md)
- [Consolidated Integration Guide](../integration/CONSOLIDATED_INTEGRATION.md)

## Service-Specific References

- [postgres Documentation](../services/postgres/)
- [redis Documentation](../services/redis/)
- [vault Documentation](../services/vault/)

---
*This consolidated documentation is automatically maintained. For service-specific details, 
refer to the individual service documentation directories.*
