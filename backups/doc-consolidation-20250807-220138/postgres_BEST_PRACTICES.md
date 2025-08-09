# PostgreSQL Service Best Practices

## Configuration Guidelines

### Environment Variable Standards

- `POSTGRES_HOST`: Container name `purebliss-postgres`
- `POSTGRES_PORT`: Standard port `5432`
- `POSTGRES_DATA_PATH`: Must point to RAID storage (`/raid-storage/postgres/data`)
- `POSTGRES_LOG_PATH`: Must point to RAID storage (`/raid-storage/logs/postgres.log`)
- `POSTGRES_MAX_CONNECTIONS`: Tuned for expected load (default: 100)

### RAID Storage Requirements

- Data persistence: `/raid-storage/postgres/data`
- Log files: `/raid-storage/logs/postgres.log`
- Backup location: `/raid-storage/backups/postgres`
- WAL archiving: `/raid-storage/postgres/wal`

### Multi-Database Configuration

- `postgres`: Default administrative database
- `keycloak`: Keycloak authentication service database
- `plane`: Issue tracking service database
- `vikunja`: Task management service database

## Performance Optimization

### Resource Limits and Requests

```yaml
resources:
  limits:
    memory: "1Gi"
    cpu: "1000m"
  requests:
    memory: "512Mi"
    cpu: "500m"
```

### Database Tuning

- `shared_buffers`: 25% of available memory
- `effective_cache_size`: 75% of available memory
- `work_mem`: Calculated based on max_connections
- `maintenance_work_mem`: 256MB for maintenance operations

### Index Optimization

- Composite indexes for multi-column queries
- Partial indexes for filtered queries
- Regular ANALYZE and VACUUM operations
- Query performance monitoring

## Security Considerations

### Vault Integration Requirements

- Dynamic database credentials via Vault
- Service-specific database users with minimal privileges
- Regular credential rotation
- Connection pooling with secure authentication

### Access Control Standards

- No direct superuser access for applications
- Database-specific users for each service
- Row-level security where applicable
- SSL/TLS encryption for all connections

### Backup Security

- Encrypted backups stored on RAID
- Point-in-time recovery capability
- Regular backup validation and testing

## Common Issues & Solutions

### Issue: Connection Pool Exhaustion

**Symptoms:** Applications report "too many connections" errors

**Solution:**
```bash
# Check current connections
docker exec purebliss-postgres psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Identify long-running queries
docker exec purebliss-postgres psql -U postgres -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';"

# Kill long-running queries if needed
docker exec purebliss-postgres psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '10 minutes';"
```

### Issue: Vault Authentication Failures

**Symptoms:** Services cannot connect using dynamic credentials

**Solution:**
1. Verify Vault PostgreSQL engine is enabled
2. Check database connection string in Vault
3. Validate PostgreSQL user permissions
4. Test credential generation manually

### Issue: Database Performance Degradation

**Symptoms:** Slow query response times, high CPU usage

**Solution:**
```bash
# Check database statistics
docker exec purebliss-postgres psql -U postgres -c "SELECT schemaname,tablename,n_tup_ins,n_tup_upd,n_tup_del FROM pg_stat_user_tables;"

# Run ANALYZE on all tables
docker exec purebliss-postgres psql -U postgres -c "ANALYZE;"

# Check for missing indexes
docker exec purebliss-postgres psql -U postgres -c "SELECT schemaname, tablename, attname, n_distinct, correlation FROM pg_stats WHERE schemaname NOT IN ('information_schema', 'pg_catalog');"
```

## Emergency Procedures

### Database Recovery

1. Stop all application services
2. Create emergency backup if possible
3. Restore from latest RAID backup
4. Validate data integrity
5. Restart services in dependency order

### Data Corruption Response

1. Immediate shutdown to prevent further corruption
2. Assess extent of corruption
3. Restore from point-in-time backup
4. Validate data consistency
5. Implement preventive measures

## Monitoring & Alerting

### Key Metrics to Monitor

- Connection count and utilization
- Query performance and slow queries
- Database size and growth rate
- Backup success and duration
- Replication lag (if applicable)
- Cache hit ratios

### Alert Thresholds

- Connection usage > 80%: Warning alert
- Slow query count > 10/minute: Warning alert
- Database size growth > 10%/day: Warning alert
- Backup failure: Critical alert
- CPU usage > 85%: Warning alert

### Dashboard Configuration

- Database health overview
- Connection and query metrics
- Performance statistics
- Backup status monitoring
- Error rates and alerts

## Database Management

### Regular Maintenance Tasks

- Daily: Monitor logs and performance metrics
- Weekly: Run VACUUM and ANALYZE operations
- Monthly: Review and optimize slow queries
- Quarterly: Review database size and archiving needs

### Backup Strategy

```bash
# Daily automated backup
docker exec purebliss-postgres pg_dump -U postgres -d keycloak > /raid-storage/backups/postgres/keycloak_$(date +%Y%m%d).sql
docker exec purebliss-postgres pg_dump -U postgres -d plane > /raid-storage/backups/postgres/plane_$(date +%Y%m%d).sql
docker exec purebliss-postgres pg_dump -U postgres -d vikunja > /raid-storage/backups/postgres/vikunja_$(date +%Y%m%d).sql

# Retention: Keep 30 daily, 12 monthly backups
find /raid-storage/backups/postgres/ -name "*.sql" -mtime +30 -delete
```

## Integration Points

### Services Using PostgreSQL

- Keycloak: User authentication and authorization data
- Plane: Issue tracking and project management data
- Vikunja: Task and project management data

### Vault Integration

- Database credentials dynamically generated
- Connection pooling with rotated credentials
- Service-specific database users

## Troubleshooting Quick Reference

```bash
# Check PostgreSQL status
docker exec purebliss-postgres pg_isready -U postgres

# View PostgreSQL logs
docker logs purebliss-postgres

# Connect to specific database
docker exec -it purebliss-postgres psql -U postgres -d keycloak

# Check database sizes
docker exec purebliss-postgres psql -U postgres -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size FROM pg_database;"

# Monitor active connections
docker exec purebliss-postgres psql -U postgres -c "SELECT datname, usename, application_name, client_addr, state FROM pg_stat_activity WHERE state = 'active';"

# Check replication status (if applicable)
docker exec purebliss-postgres psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```
