# Redis Service Best Practices

## Configuration Guidelines

### Environment Variable Standards

- `REDIS_HOST`: Container name `purebliss-redis`
- `REDIS_PORT`: Standard port `6379`
- `REDIS_DATA_PATH`: Must point to RAID storage (`/raid-storage/redis/data`)
- `REDIS_LOG_PATH`: Must point to RAID storage (`/raid-storage/logs/redis.log`)
- `REDIS_AOF_ENABLED`: Always `true` for data persistence
- `REDIS_DEFAULT_TTL`: Default time-to-live for cached data (3600 seconds)

### RAID Storage Requirements

- Data persistence: `/raid-storage/redis/data`
- AOF files: `/raid-storage/redis/data/appendonly.aof`
- Log files: `/raid-storage/logs/redis.log`
- Backup location: `/raid-storage/backups/redis`

### Persistence Configuration

- AOF (Append Only File) enabled for durability
- RDB snapshots for backup purposes
- Memory optimization with appropriate eviction policies
- Regular AOF rewrite for space efficiency

## Performance Optimization

### Resource Limits and Requests

```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "256Mi"
    cpu: "250m"
```

### Memory Management

- `maxmemory`: Set to 80% of container memory limit
- `maxmemory-policy`: `allkeys-lru` for general caching
- Monitor memory usage and fragmentation
- Regular memory optimization and cleanup

### Caching Strategies

- Set appropriate TTL for different data types
- Use Redis data structures efficiently (sets, hashes, lists)
- Implement cache warming for critical data
- Monitor cache hit ratios and optimize accordingly

## Security Considerations

### Vault Integration Requirements

- Authentication tokens stored and rotated via Vault
- Redis AUTH password managed by Vault
- Service-specific access controls where possible
- Encrypted connections for sensitive data

### Access Control Standards

- Redis AUTH enabled for all connections
- Network isolation within Docker network
- No direct external access (proxied through services)
- Connection limits to prevent abuse

### Data Security

- Sensitive data encrypted before storage in Redis
- Regular security audits of cached data
- Automatic expiration of sensitive tokens
- Monitoring for unusual access patterns

## Common Issues & Solutions

### Issue: Memory Usage High

**Symptoms:** Redis reports high memory usage, OOM errors

**Solution:**

```bash
# Check memory usage
docker exec purebliss-redis redis-cli INFO memory

# Check largest keys
docker exec purebliss-redis redis-cli --bigkeys

# Monitor memory fragmentation
docker exec purebliss-redis redis-cli INFO memory | grep fragmentation

# Clean expired keys manually if needed
docker exec purebliss-redis redis-cli FLUSHDB
```

### Issue: AOF Corruption

**Symptoms:** Redis fails to start, AOF loading errors

**Solution:**

```bash
# Check AOF integrity
docker exec purebliss-redis redis-check-aof /data/appendonly.aof

# Repair AOF if possible
docker exec purebliss-redis redis-check-aof --fix /data/appendonly.aof

# Restore from backup if repair fails
docker stop purebliss-redis
cp /raid-storage/backups/redis/latest/appendonly.aof /raid-storage/redis/data/
docker start purebliss-redis
```

### Issue: Connection Pool Exhaustion

**Symptoms:** Applications report connection timeouts

**Solution:**

```bash
# Check connected clients
docker exec purebliss-redis redis-cli INFO clients

# Monitor connection patterns
docker exec purebliss-redis redis-cli CLIENT LIST

# Set connection limits if needed
docker exec purebliss-redis redis-cli CONFIG SET maxclients 1000
```

## Emergency Procedures

### Redis Recovery

1. Stop Redis container safely
2. Backup current AOF and RDB files
3. Restore from latest RAID backup
4. Validate data integrity
5. Restart Redis and verify operation

### Data Loss Response

1. Assess scope of data loss
2. Stop applications using Redis
3. Restore from point-in-time backup
4. Rebuild cache from primary data sources
5. Resume applications with monitoring

## Monitoring & Alerting

### Key Metrics to Monitor

- Memory usage and fragmentation
- Connected clients and connection rate
- Cache hit/miss ratios
- AOF and RDB file sizes
- Command execution times
- Evicted keys count

### Alert Thresholds

- Memory usage > 80%: Warning alert
- Memory fragmentation > 1.5: Warning alert
- Connected clients > 90% of max: Warning alert
- Cache hit ratio < 80%: Warning alert
- AOF file size growth > 50% daily: Warning alert

### Dashboard Configuration

- Redis health overview
- Memory and performance metrics
- Connection statistics
- Cache performance metrics
- Error rates and slow operations

## Cache Management

### TTL Best Practices

- Session data: 30 minutes - 2 hours
- API responses: 5-15 minutes
- Static configuration: 24 hours
- User preferences: 1 hour
- Temporary tokens: Based on token lifetime

### Data Structure Usage

```bash
# Efficient patterns
# Use hashes for structured data
HSET user:123 name "John" email "john@example.com"

# Use sets for unique collections
SADD tags:article:456 "redis" "caching" "performance"

# Use sorted sets for rankings
ZADD leaderboard 100 "player1" 95 "player2"

# Use lists for queues
LPUSH queue:tasks "task1" "task2"
```

## Integration Points

### Services Using Redis

- Keycloak: Session storage and user state caching
- Plane: API response caching and temporary data
- Vikunja: Task caching and user session management
- Nginx: Rate limiting and temporary storage

### Vault Integration

- Redis AUTH password rotation
- Connection credential management
- Security token storage and rotation

## Troubleshooting Quick Reference

```bash
# Check Redis status
docker exec purebliss-redis redis-cli ping

# Monitor Redis performance
docker exec purebliss-redis redis-cli INFO stats

# Check memory usage
docker exec purebliss-redis redis-cli INFO memory

# Monitor slow operations
docker exec purebliss-redis redis-cli SLOWLOG GET 10

# Check connected clients
docker exec purebliss-redis redis-cli CLIENT LIST

# Monitor key expiration
docker exec purebliss-redis redis-cli INFO keyspace

# Check persistence status
docker exec purebliss-redis redis-cli LASTSAVE

# Manual AOF rewrite
docker exec purebliss-redis redis-cli BGREWRITEAOF

# Backup current data
docker exec purebliss-redis redis-cli BGSAVE
```

## Development vs Production

### Development Mode

- Reduced memory limits for local development
- Less aggressive persistence settings
- DEBUG logging enabled
- Manual cache warming acceptable

### Production Mode

- Optimized memory and persistence settings
- Regular automated backups
- Comprehensive monitoring and alerting
- High availability clustering (if required)

## Performance Tuning

### Redis Configuration Optimization

```conf
# Memory optimization
maxmemory 400mb
maxmemory-policy allkeys-lru

# Persistence optimization
save 900 1
save 300 10
save 60 10000

# AOF configuration
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Network optimization
tcp-keepalive 300
timeout 0
```

### Client Connection Optimization

- Use connection pooling in applications
- Implement proper connection lifecycle management
- Monitor and tune connection limits
- Use pipelining for bulk operations when appropriate
