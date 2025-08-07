Best Practices for Keycloak, Vault, PostgreSQL, and Redis in a Containerized Environment
This guide outlines best practices for deploying Keycloak, HashiCorp Vault, PostgreSQL, and Redis in a containerized environment using Docker. It includes configuration recommendations, security considerations, and troubleshooting steps to ensure a robust and secure identity and access management system.
1. System Architecture Overview

Keycloak: An open-source identity and access management solution for Single Sign-On (SSO), user federation, and API security.
HashiCorp Vault: Manages secrets (e.g., database credentials, Keycloak admin credentials) securely.
PostgreSQL: A relational database for persistent storage of Keycloak's realms, users, and sessions.
Redis: An in-memory key-value store for caching Keycloak sessions and authentication tokens to improve performance.
Containerized Environment: Docker with Docker Compose or Kubernetes for orchestration, ensuring scalability and isolation.

2. Best Practices
2.1. Keycloak Configuration

Use a Production-Ready Database: Configure Keycloak to use PostgreSQL instead of the default H2 database for production. H2 is not suitable for production due to its lack of persistence and scalability.
Enable HTTPS: Secure Keycloak with SSL/TLS using a valid certificate (e.g., from Let’s Encrypt). Open port 8443 for HTTPS traffic and configure Keycloak’s https-key-store-file and https-key-store-password.
Optimize Container Image: Use the official quay.io/keycloak/keycloak image and enable features like health and metrics endpoints and token exchange. Example command:docker run -p 127.0.0.1:8080:8080 -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=secure_password quay.io/keycloak/keycloak:latest start --hostname=localhost --http-enabled=true --db=postgres --features=token-exchange --db-url=<JDBC-URL> --db-username=<DB-USER> --db-password=<DB-PASSWORD> --https-key-store-file=<file> --https-key-store-password=<password>


Use Realms for Isolation: Create separate realms for different applications or tenants to isolate users and configurations.
Enable Multi-Factor Authentication (MFA): Configure MFA for enhanced security, especially for admin accounts.
Customize Themes: Tailor login and account management pages to match your branding using Keycloak’s theme customization features.
Caching with Redis: Use Redis for caching user sessions and authentication tokens to reduce database load and improve performance. Configure Keycloak to use Redis instead of the default Infinispan cache for distributed environments.

2.2. HashiCorp Vault Configuration

Secure Secret Storage: Store sensitive data like PostgreSQL credentials, Keycloak admin credentials, and SSL certificates in Vault. Use Vault’s dynamic secrets for database credentials to rotate them regularly.
Enable AppRole Authentication: Configure Keycloak and other services to authenticate with Vault using AppRole for secure access to secrets.
Use a Dedicated Vault Network: Run Vault in a separate Docker network to isolate it from other services, enhancing security.
Enable Audit Logging: Configure Vault’s audit logging to track access to secrets for compliance and troubleshooting.
High Availability: Deploy Vault in a high-availability mode with a backend like Consul or PostgreSQL for resilience.

2.3. PostgreSQL Configuration

Persistent Storage: Use a named Docker volume for PostgreSQL data to ensure persistence across container restarts. Example Docker Compose configuration:volumes:
  postgres_data:
    driver: local


Optimize Connection Pool: Set the initial, minimum, and maximum database connection pool sizes to the same value to avoid creating new connections dynamically, which is costly. For example, set KC_DB_POOL_INITIAL_SIZE=20, KC_DB_POOL_MIN_SIZE=20, and KC_DB_POOL_MAX_SIZE=20. Ensure the total connections (pool size × Keycloak instances) do not exceed PostgreSQL’s maximum connections (default: 100).
Database User and Privileges: Create a dedicated database user for Keycloak with minimal privileges. Example SQL:CREATE DATABASE keycloak_db;
CREATE USER keycloak_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE keycloak_db TO keycloak_user;


Enable Background Validation: Configure PostgreSQL to validate connections periodically to detect and recover from connection issues. Example configuration in Keycloak’s datasource:<validation>
  <check-valid-connection-sql>SELECT 1</check-valid-connection-sql>
  <background-validation>true</background-validation>
  <background-validation-millis>60000</background-validation-millis>
</validation>



2.4. Redis Configuration

Use Official Redis Image: Pull the official redis image from Docker Hub for reliability and updates.
Enable Persistence: Configure Redis to use RDB (Redis Database) snapshots for persistence to save data across restarts. Example command:docker run --name redis-cache -d redis redis-server --save 60 1 --loglevel warning


Run in Detached Mode: Run Redis in the background using the -d flag to keep it running independently of the terminal.
Secure Redis: Use Redis AUTH with a strong password and configure TLS for secure communication in production.
Dedicated Network: Place Redis in a dedicated Docker network to isolate it from other services.

2.5. Docker Compose Setup

Unified Configuration: Use a single docker-compose.yml file to manage Keycloak, Vault, PostgreSQL, and Redis for simplified deployment and dependency management.
Custom Network: Create a custom bridge network for secure communication between containers. Example:networks:
  keycloak_network:
    driver: bridge


Environment Variables: Use environment variables for sensitive data and retrieve them from Vault to avoid hardcoding secrets in the Docker Compose file.
Health Checks: Implement health checks for each service to ensure containers are running correctly. Example for Keycloak:healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3



2.6. Security Best Practices

Least Privilege Principle: Assign minimal permissions to users and services accessing Vault, PostgreSQL, and Redis.
Rotate Credentials: Use Vault’s dynamic secrets to rotate database and Keycloak admin credentials regularly.
Network Isolation: Use Docker networks to isolate services and restrict access to only necessary ports (e.g., 8080 for Keycloak, 5432 for PostgreSQL, 6379 for Redis, 8200 for Vault).
Firewall Rules: Configure firewall rules (e.g., ufw) to allow only required ports. Example:sudo ufw allow 8443
sudo ufw enable


Backup and Recovery: Regularly back up PostgreSQL and Vault data. For PostgreSQL, use pg_dump for backups and test restoration procedures.

3. Troubleshooting Steps and Procedures
3.1. Keycloak Issues

Problem: Keycloak Fails to Start with "Failed to add user" Error

Cause: Duplicate admin username in the master realm.
Solution: Check the KEYCLOAK_ADMIN environment variable. Ensure it’s unique or reset the admin user via the Keycloak Admin Console or by deleting the master realm data in PostgreSQL and restarting.
Procedure:
Check logs: docker logs keycloak_container_id
Verify KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD environment variables.
If necessary, drop the master realm in PostgreSQL:DROP SCHEMA keycloak CASCADE;


Restart Keycloak: docker-compose restart keycloak




Problem: Keycloak Loses Data on Restart

Cause: Incorrect volume mapping for PostgreSQL.
Solution: Ensure the PostgreSQL volume is correctly mapped to /var/lib/postgresql/data. Example Docker Compose:volumes:
  - postgres_data:/var/lib/postgresql/data


Procedure:
Inspect volume mappings: docker inspect postgres_container_id
Correct the volume path in docker-compose.yml.
Restart the stack: docker-compose up -d




Problem: Slow Performance

Cause: Inefficient database connection pool or lack of caching.
Solution: Optimize the database connection pool (see PostgreSQL section) and enable Redis caching.
Procedure:
Configure Redis in Keycloak’s configuration file or environment variables.
Verify Redis connection: docker exec redis_container_id redis-cli ping
Monitor Keycloak performance using metrics endpoints: http://localhost:8080/metrics





3.2. Vault Issues

Problem: Vault Authentication Fails

Cause: Incorrect AppRole credentials or misconfigured Vault policies.
Solution: Verify AppRole credentials and policies in Vault.
Procedure:
Check Vault logs: docker logs vault_container_id
Verify AppRole setup: vault read auth/approle/role/my-role
Update policies if needed: vault policy write my-policy policy.hcl
Test authentication: vault write auth/approle/login role_id=<role_id> secret_id=<secret_id>




Problem: Secrets Not Accessible

Cause: Network isolation or incorrect secret path.
Solution: Ensure the Docker network allows communication between Keycloak/PostgreSQL and Vault, and verify the secret path.
Procedure:
Check network configuration: docker network inspect keycloak_network
Verify secret path: vault kv get secret/my-secret
Update Vault client configuration in Keycloak/PostgreSQL.





3.3. PostgreSQL Issues

Problem: Connection Errors

Cause: Incorrect JDBC URL, username, or password.
Solution: Verify database connection details in Keycloak’s configuration.
Procedure:
Check Keycloak logs: docker logs keycloak_container_id
Test PostgreSQL connection: docker exec postgres_container_id psql -U keycloak_user -d keycloak_db -c "SELECT 1"
Update db-url, db-username, and db-password in Keycloak’s environment variables.




Problem: Database Reinitializes on Restart

Cause: Incorrect volume configuration or permissions.
Solution: Ensure the volume is mounted correctly and has proper permissions.
Procedure:
Verify volume path: docker inspect postgres_container_id
Check permissions: ls -l /path/to/postgres_data
Fix permissions if needed: chmod -R 700 /path/to/postgres_data
Restart PostgreSQL: docker-compose restart postgres





3.4. Redis Issues

Problem: Redis Connection Fails

Cause: Incorrect host/port or authentication issues.
Solution: Verify Redis host, port, and password in Keycloak’s configuration.
Procedure:
Check Redis logs: docker logs redis_container_id
Test connection: docker exec redis_container_id redis-cli -h localhost -p 6379 -a <password> ping
Update Keycloak’s Redis configuration if needed.




Problem: Data Loss on Restart

Cause: Persistence not enabled.
Solution: Enable RDB snapshots or AOF (Append-Only File) persistence.
Procedure:
Update Redis command: docker run --name redis-cache -d redis redis-server --save 60 1 --loglevel warning
Verify data persistence: docker exec redis_container_id redis-cli SAVE
Check data directory: docker inspect redis_container_id





4. Example Docker Compose Configuration
Below is an example docker-compose.yml file integrating Keycloak, Vault, PostgreSQL, and Redis with best practices applied.
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    environment:
      - KC_BOOTSTRAP_ADMIN_USERNAME=admin
      - KC_BOOTSTRAP_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
      - KC_DB=postgres
      - KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak_db
      - KC_DB_USERNAME=keycloak_user
      - KC_DB_PASSWORD=${POSTGRES_PASSWORD}
      - KC_CACHE=redis
      - KC_CACHE_HOST=redis
      - KC_CACHE_PORT=6379
      - KC_CACHE_PASSWORD=${REDIS_PASSWORD}
      - KC_HTTPS_KEY_STORE_FILE=/opt/keycloak.keystore
      - KC_HTTPS_KEY_STORE_PASSWORD=${KEYSTORE_PASSWORD}
    ports:
      - "8080:8080"
      - "8443:8443"
    depends_on:
      - postgres
      - redis
    networks:
      - keycloak_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    volumes:
      - ./keycloak.keystore:/opt/keycloak.keystore

  vault:
    image: vault:latest
    environment:
      - VAULT_DEV_ROOT_TOKEN_ID=my-root-token
    ports:
      - "8200:8200"
    cap_add:
      - IPC_LOCK
    networks:
      - keycloak_network
    healthcheck:
      test: ["CMD", "vault", "status"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:latest
    environment:
      - POSTGRES_DB=keycloak_db
      - POSTGRES_USER=keycloak_user
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - keycloak_network
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "keycloak_user"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:latest
    command: redis-server --save 60 1 --loglevel warning --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - keycloak_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  keycloak_network:
    driver: bridge

4.1. Environment Variables

Store sensitive values like KEYCLOAK_ADMIN_PASSWORD, POSTGRES_PASSWORD, REDIS_PASSWORD, and KEYSTORE_PASSWORD in Vault and retrieve them at runtime using a Vault client or environment variable injection.

5. Monitoring and Logging

Keycloak: Enable metrics endpoints (/metrics) and integrate with
