-- PostgreSQL Initialization Script for Fresh Database
-- This script creates additional databases and users for Vault integration

CREATE DATABASE vikunja;
CREATE DATABASE keycloak;
CREATE DATABASE plane;
CREATE DATABASE vault_managed;

# Create database for Grafana
CREATE DATABASE grafana;

CREATE USER vikunja WITH ENCRYPTED PASSWORD 'vikunja_password_123';
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak_password_123';
CREATE USER plane WITH ENCRYPTED PASSWORD 'plane_password_123';

# Create grafana user (no password, Vault will manage credentials)
CREATE USER grafana;

GRANT ALL PRIVILEGES ON DATABASE vikunja TO vikunja;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
GRANT ALL PRIVILEGES ON DATABASE plane TO plane;

# Grant privileges to grafana user on grafana database
GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana;

-- Grant schema permissions to keycloak user
GRANT USAGE, CREATE ON SCHEMA public TO keycloak;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO keycloak;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO keycloak;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO keycloak;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO keycloak;

-- Create a dedicated user for Vault's database secrets engine
CREATE USER vault_admin WITH ENCRYPTED PASSWORD 'vault_admin_password_123' SUPERUSER;

-- Log the initialization
\echo 'PostgreSQL initialization completed with fresh databases and users'
