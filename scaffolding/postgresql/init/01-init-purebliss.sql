-- PostgreSQL Initialization Script for PureBliss Development
-- This script runs on container first startup

-- Create development schemas
CREATE SCHEMA IF NOT EXISTS purebliss_app;
CREATE SCHEMA IF NOT EXISTS purebliss_config;
CREATE SCHEMA IF NOT EXISTS purebliss_logs;

-- Create a test table to validate setup
CREATE TABLE IF NOT EXISTS purebliss_app.health_check (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'healthy',
    message TEXT
);

-- Insert initial health check record
INSERT INTO purebliss_app.health_check (message)
VALUES ('PostgreSQL initialized successfully for PureBliss scaffolding');

-- Create read-only user for monitoring

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'purebliss_monitor') THEN
        CREATE ROLE purebliss_monitor LOGIN PASSWORD 'monitor-readonly-password';
    END IF;
END$$;

GRANT CONNECT ON DATABASE purebliss_dev TO purebliss_monitor;
GRANT USAGE ON SCHEMA purebliss_app, purebliss_config, purebliss_logs TO purebliss_monitor;
GRANT SELECT ON ALL TABLES IN SCHEMA purebliss_app, purebliss_config, purebliss_logs TO purebliss_monitor;

-- Grant permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA purebliss_app, purebliss_config, purebliss_logs
GRANT SELECT ON TABLES TO purebliss_monitor;

-- Log successful initialization
\echo 'PureBliss PostgreSQL scaffolding initialization complete'
