# PostgreSQL Container - Scaffolding Documentation

**Container Status**: ✅ COMPLETED
**Scaffolding Phase**: 2 of 10
**Dependencies**: Vault (Container 1)
**Ready for Integration**: Yes

## Container Overview

- **Image**: postgres:16-alpine
- **Container Name**: purebliss-postgresql-scaffolding
- **Port**: 5432
- **Database**: purebliss_dev
- **Network**: purebliss-scaffolding

## Setup Instructions

1. **Start PostgreSQL**:
   ```bash
   cd /opt/dev-purebliss/scaffolding/postgresql
   ./setup-postgresql.sh
   ```

2. **Test Restart**:
   ```bash
   ./test-postgresql-restart.sh
   ```

3. **Health Check**:
   ```bash
   /opt/dev-purebliss/scaffolding/scripts/health-check.sh purebliss-postgresql-scaffolding 5432
   ```

## Container Configuration

### Docker Compose Configuration
- File: `docker-compose.postgresql.yml`
- Health checks enabled with 30s intervals
- Data persistence via named volume
- Exposed on port 5432

### Environment Variables
- `POSTGRES_DB=purebliss_dev`
- `POSTGRES_USER=postgres`
- `POSTGRES_PASSWORD=purebliss-postgres-password`
- `PGDATA=/var/lib/postgresql/data/pgdata`

### Database Schema
- **purebliss_app**: Main application schema
- **purebliss_config**: Configuration schema
- **purebliss_logs**: Logging schema
- **Health Check Table**: `purebliss_app.health_check`

## Health Validation

### Health Check Commands
- **Docker Health**: `pg_isready -U postgres -d purebliss_dev`
- **Connectivity**: `psql -U postgres -d purebliss_dev -c "SELECT 1"`

### Validation Tests Passed
- ✅ Container starts successfully
- ✅ Database initialization complete
- ✅ Container survives restart
- ✅ Data persistence confirmed
- ✅ Network connectivity to Vault
- ✅ No critical errors in logs

## Database Access

### Connection Details
- **Host**: localhost (or container name for inter-container)
- **Port**: 5432
- **Database**: purebliss_dev
- **Username**: postgres
- **Password**: purebliss-postgres-password

### Read-Only Monitoring User
- **Username**: purebliss_monitor
- **Password**: monitor-readonly-password
- **Permissions**: SELECT on all schemas

## Vault Integration Ready

### Database Secrets Engine
PostgreSQL is ready for Vault database secrets engine integration:

```bash
# Enable database secrets engine in Vault
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='purebliss-root-token'

vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/purebliss-postgresql \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@purebliss-postgresql-scaffolding:5432/purebliss_dev?sslmode=disable" \
    allowed_roles="purebliss-role" \
    username="postgres" \
    password="purebliss-postgres-password"
```

## Usage for Next Container

### PostgreSQL Integration for Redis
When setting up the next container (Redis), PostgreSQL can provide:

- **Configuration Storage**: Store Redis configurations
- **Session Data Backup**: Backup Redis session data
- **Monitoring Data**: Store Redis metrics and logs
- **Container Coordination**: Share startup/health status

## Troubleshooting

### Common Issues
1. **Port 5432 already in use**: Stop other PostgreSQL instances
2. **Database won't initialize**: Check init scripts in `/init` directory
3. **Health check fails**: Wait 60 seconds for full initialization
4. **Data not persisting**: Check volume mount `postgresql_data`

### Quick Commands
```bash
# Check container status
docker ps | grep postgresql

# View logs
docker logs purebliss-postgresql-scaffolding

# Connect to database
docker exec -it purebliss-postgresql-scaffolding psql -U postgres -d purebliss_dev

# Check schemas
docker exec purebliss-postgresql-scaffolding psql -U postgres -d purebliss_dev -c "\dn"

# Restart container
docker restart purebliss-postgresql-scaffolding

# Stop container
docker-compose -f docker-compose.postgresql.yml down
```

### Data Volume Management
```bash
# Backup database
docker exec purebliss-postgresql-scaffolding pg_dump -U postgres purebliss_dev > backup.sql

# Restore database
docker exec -i purebliss-postgresql-scaffolding psql -U postgres purebliss_dev < backup.sql

# Check volume
docker volume inspect purebliss-postgresql-scaffolding-data
```

## Scaffolding Handoff

✅ **PostgreSQL Container COMPLETE**
✅ **Ready for Redis Integration**
✅ **All health validations passed**
✅ **Documentation complete**
✅ **Vault integration prepared**

**Next Container**: Redis (Container 3 of 10)

