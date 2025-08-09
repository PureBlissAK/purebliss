# Pure Bliss Redis Service

This directory contains the Dockerfile and Docker Compose configuration for the Redis microservice, managed as part of the Pure Bliss core infrastructure.

## Features
- Redis 7 (alpine base image)
- Healthcheck for container orchestration
- Consistent container naming: `purebliss-redis`
- Exposed on port 6379
- Connected to `purebliss-net` Docker network
- Labeled for observability (Prometheus, Loki, etc.)
- Optional: mount custom `redis.conf` or persistent data/logs

## Usage

### Build and Start Redis

```bash
cd /opt/dev-purebliss/services/redis
# Build the image
docker build -t purebliss-redis:latest .
# Start the service
# (from parent orchestrator or directly)
docker-compose -f redis-docker-compose.yml up -d
```

### Health Check

```bash
docker inspect --format='{{.State.Health.Status}}' purebliss-redis
```

### Logs

```bash
docker logs purebliss-redis
```

## Vault Integration
- Redis is automatically onboarded to Vault for dynamic secrets by the orchestrator script (`start-all-services.sh`).
- See `/opt/dev-purebliss/start-all-services.sh` for details.

## Customization
- To use a custom `redis.conf`, uncomment the relevant lines in the Dockerfile and Compose file.
- For persistent data, set `REDIS_DATA_PATH` and `REDIS_LOG_PATH` as environment variables and uncomment the volumes section.

## Observability
- Service and role labels are set for monitoring and logging.

---

For troubleshooting, see the central log: `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.
