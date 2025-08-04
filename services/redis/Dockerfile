# syntax=docker/dockerfile:1
FROM redis:7-alpine

# Optional: Copy custom redis.conf if present
# COPY redis.conf /usr/local/etc/redis/redis.conf

# Healthcheck for Docker Compose
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD redis-cli ping | grep -q PONG || exit 1

# Expose default Redis port
EXPOSE 6379

# Default command (can be overridden by docker-compose)
CMD ["redis-server"]
