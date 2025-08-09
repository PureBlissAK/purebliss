# PostgreSQL Automation Guide

## Overview

The PostgreSQL service provides database functionality for the PureBliss development environment. It manages multiple application databases (keycloak, plane, vikunja) with independent startup capabilities and comprehensive health monitoring.

## Architecture

### Container Details

- **Container Name:** `purebliss-postgres`
- **Base Image:** `postgres:16`
- **Exposed Ports:** `5432` (PostgreSQL)
- **Dependencies:** None (fully independent)

### Key Features

1. **Independent Startup:** Starts without external dependencies
2. **Multi-Database:** Supports multiple application databases
3. **User Management:** Creates application-specific users
4. **Health Monitoring:** Built-in health checks
5. **Development Mode:** Simplified configuration for development
6. **Vault Ready:** Compatible with future Vault integration

## Configuration

### Main Configuration File

Location: `/opt/dev-purebliss/services/postgres/postgres-docker-compose-independent.yml`

Key configuration sections:

- **Environment:** Database connection settings
- **Volumes:** Data persistence and logging
- **Health Checks:** Connection monitoring
- **Security:** Container security settings

### Environment Variables

- `POSTGRES_DB`: Main database name (default: `postgres`)
- `POSTGRES_USER`: Main database user (default: `postgres`)
- `POSTGRES_PASSWORD`: Main database password
- `PGDATA`: PostgreSQL data directory

## Directory Structure

```
/opt/dev-purebliss/services/postgres/
├── postgres-docker-compose-independent.yml  # Docker Compose configuration
├── postgres-dockerfile-independent          # Container build configuration
├── entrypoint-independent.sh               # Container startup script
├── init-scripts/                           # Database initialization scripts
└── logs/                                   # Service logs
```

## Database Structure

### Created Databases

1. **postgres** - Main PostgreSQL database
2. **keycloak** - Authentication service database
3. **plane** - Issue tracking service database
4. **vikunja** - Task management database

### Created Users

1. **postgres** - Superuser for administration
2. **keycloak** - Application user for Keycloak service
3. **plane** - Application user for Plane service
4. **vikunja** - Application user for Vikunja service

### Credentials (Development Mode)

- **postgres:** `purebliss_dev_postgres_2025`
- **keycloak:** `keycloak_dev_2025`
- **plane:** `plane_dev_2025`
- **vikunja:** `vikunja_dev_2025`

## Operations

### Starting the Service

```bash
cd /opt/dev-purebliss/services/postgres
docker compose -f postgres-docker-compose-independent.yml up -d
```

### Stopping the Service

```bash
cd /opt/dev-purebliss/services/postgres
docker compose -f postgres-docker-compose-independent.yml down
```

### Health Check

```bash
# Check container status
docker ps --filter "name=purebliss-postgres"

# Test database connectivity
docker exec purebliss-postgres pg_isready -U postgres -d postgres

# List all databases
docker exec purebliss-postgres psql -U postgres -c "\l"

# List all users
docker exec purebliss-postgres psql -U postgres -c "\du"
```

### Database Access

```bash
# Connect as postgres superuser
docker exec -it purebliss-postgres psql -U postgres -d postgres

# Connect to application databases
docker exec -it purebliss-postgres psql -U keycloak -d keycloak
docker exec -it purebliss-postgres psql -U plane -d plane
docker exec -it purebliss-postgres psql -U vikunja -d vikunja
```

## Integration Points

### Service Dependencies

- **None:** PostgreSQL starts independently
- **Network:** Uses `purebliss-net` Docker network

### Services Using PostgreSQL

- **Keycloak:** Authentication service
- **Plane:** Issue tracking service
- **Vikunja:** Task management service
- **Future Services:** Any service requiring database storage

## Monitoring

### Health Endpoint

PostgreSQL health is monitored via:

- **Command:** `pg_isready -U postgres -d postgres -h localhost -p 5432`
- **Interval:** 15 seconds
- **Timeout:** 10 seconds
- **Retries:** 5
- **Start Period:** 30 seconds

### Log Monitoring

```bash
# Follow container logs
docker logs -f purebliss-postgres

# Check PostgreSQL logs within container
docker exec purebliss-postgres tail -f /var/log/postgresql/postgresql.log

# Check application logs
tail -f /opt/my-secure-ha-stack/logs/dev-environment-setup.log | grep POSTGRES
```

### Performance Monitoring

```bash
# Check active connections
docker exec purebliss-postgres psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Check database sizes
docker exec purebliss-postgres psql -U postgres -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"

# Check table activity
docker exec purebliss-postgres psql -U postgres -d keycloak -c "SELECT schemaname,tablename,n_tup_ins,n_tup_upd,n_tup_del FROM pg_stat_user_tables;"
```

## Security Considerations

### Development Mode

- Uses static passwords for development
- All databases accessible within Docker network
- No encryption in transit (suitable for development)

### Production Recommendations

- Implement Vault integration for dynamic passwords
- Enable SSL/TLS for all connections
- Implement connection pooling
- Enable audit logging
- Regular backup strategy

## Troubleshooting

### Common Issues

1. **Container Won't Start**
   - Check available disk space: `df -h`
   - Verify network exists: `docker network ls | grep purebliss-net`
   - Check port availability: `netstat -tlnp | grep 5432`

2. **Database Connection Issues**
   - Verify container is healthy: `docker ps --filter "name=purebliss-postgres"`
   - Test connectivity: `docker exec purebliss-postgres pg_isready -U postgres`
   - Check logs: `docker logs purebliss-postgres`

3. **Application Can't Connect**
   - Verify user exists: `docker exec purebliss-postgres psql -U postgres -c "\du"`
   - Test application credentials: `docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT version();"`
   - Check network connectivity from application container

### Log Analysis

```bash
# Check for connection errors
docker logs purebliss-postgres 2>&1 | grep -i "connection\|error\|failed"

# Monitor active queries
docker exec purebliss-postgres psql -U postgres -c "SELECT query FROM pg_stat_activity WHERE state = 'active';"

# Check for authentication issues
docker logs purebliss-postgres 2>&1 | grep -i "authentication\|password"
```

## Backup and Recovery

### Data Backup

```bash
# Backup all databases
docker exec purebliss-postgres pg_dumpall -U postgres > /opt/my-secure-ha-stack/backups/postgres-all-$(date +%Y%m%d_%H%M%S).sql

# Backup specific database
docker exec purebliss-postgres pg_dump -U postgres keycloak > /opt/my-secure-ha-stack/backups/keycloak-$(date +%Y%m%d_%H%M%S).sql
```

### Data Recovery

```bash
# Restore all databases
docker exec -i purebliss-postgres psql -U postgres < /opt/my-secure-ha-stack/backups/postgres-all-backup.sql

# Restore specific database
docker exec -i purebliss-postgres psql -U postgres -d keycloak < /opt/my-secure-ha-stack/backups/keycloak-backup.sql
```

## Maintenance

### Regular Tasks

1. **Check Database Sizes**
2. **Monitor Connection Counts**
3. **Review Query Performance**
4. **Update Statistics**
5. **Backup Verification**

### Update Procedure

1. Backup current data
2. Update Docker image version
3. Rebuild container: `docker compose build`
4. Restart service: `docker compose up -d`
5. Verify all applications can connect

## Development Notes

### Current Status

- ✅ Independent startup working
- ✅ All application databases created
- ✅ All application users configured
- ✅ Health checks passing
- ✅ Connection testing successful
- ✅ Container independence achieved

### Future Enhancements

- Integrate with Vault for dynamic password management
- Add connection pooling (PgBouncer)
- Implement SSL/TLS certificates
- Add automated backup scheduling
- Performance monitoring dashboards
