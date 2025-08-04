-- PostgreSQL Initialization Script for Fresh Database
-- This script creates additional databases and users for Vault integration

-- Create databases for different services
CREATE DATABASE vikunja;
CREATE DATABASE keycloak;
CREATE DATABASE plane;
CREATE DATABASE vault_managed;

-- Create service-specific users with limited privileges
CREATE USER vikunja WITH ENCRYPTED PASSWORD 'vikunja_password_123';
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak_password_123';
CREATE USER plane WITH ENCRYPTED PASSWORD 'plane_password_123';

-- Grant privileges to service users on their respective databases
GRANT ALL PRIVILEGES ON DATABASE vikunja TO vikunja;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
GRANT ALL PRIVILEGES ON DATABASE plane TO plane;

-- Create a dedicated user for Vault's database secrets engine
CREATE USER vault_admin WITH ENCRYPTED PASSWORD 'vault_admin_password_123' SUPERUSER;

-- Log the initialization
\echo 'PostgreSQL initialization completed with fresh databases and users'
