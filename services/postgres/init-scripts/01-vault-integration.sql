-- Pure Bliss PostgreSQL Vault Integration Setup
-- This script runs during PostgreSQL initialization
-- Ensures all databases and users are properly configured for Vault integration

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create a function to log initialization steps
CREATE OR REPLACE FUNCTION log_init_step(step_name TEXT) RETURNS VOID AS $$
BEGIN
    RAISE NOTICE 'VAULT_INIT: %', step_name;
END;
$$ LANGUAGE plpgsql;

-- Log the start of Vault integration setup
SELECT log_init_step('Starting PostgreSQL Vault integration setup');

-- This script will be completed by the vault-entrypoint.sh
-- The actual user and database creation happens in the entrypoint script
-- after secrets are fetched from Vault

SELECT log_init_step('PostgreSQL Vault integration initialization complete');
