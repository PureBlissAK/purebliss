# syntax=docker/dockerfile:1
FROM redis:7-alpine

# Install required packages for Vault integration
RUN apk add --no-cache curl jq bash

# Install Vault CLI for secret retrieval
RUN wget -O- https://releases.hashicorp.com/vault/1.17.3/vault_1.17.3_linux_amd64.zip | \
    unzip - && \
    mv vault /usr/local/bin/ && \
    chmod +x /usr/local/bin/vault && \
    rm -f vault_1.17.3_linux_amd64.zip

# Copy entrypoint script with all Vault logic
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


# Create Redis user and directories if not present
RUN id -u redis >/dev/null 2>&1 || adduser -D -s /bin/sh -u 999 -G redis redis; \
    mkdir -p /data /usr/local/etc/redis; \
    chown -R redis:redis /data /usr/local/etc/redis


USER redis

# Healthcheck for Docker Compose
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
  CMD redis-cli ping | grep -q PONG || exit 1

# Expose default Redis port
EXPOSE 6379

# Use custom entrypoint for Vault integration
ENTRYPOINT ["/entrypoint.sh"]
CMD []
