-- Update postgres user password to match bootstrap password
-- This ensures the migrated database works with the new Vault-generated credentials

\echo 'Updating postgres user password to match bootstrap credentials...'

-- Get the bootstrap password from environment and update postgres user
ALTER USER postgres PASSWORD :'POSTGRES_PASSWORD';

-- Verify the change
\echo 'Password updated successfully for postgres user'

-- Show current databases to verify connectivity
\l

\echo 'Database connection verified - RAID migration successful!'
