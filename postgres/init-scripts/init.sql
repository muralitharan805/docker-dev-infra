-- -- 1. Enable extensions on the default database ('vectordb')
-- CREATE EXTENSION IF NOT EXISTS vector;
-- CREATE EXTENSION IF NOT EXISTS postgis;
-- CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- -- 2. Dynamically create 'civicpath' database if it doesn't already exist
-- SELECT 'CREATE DATABASE civicpath'
-- WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'civicpath')\gexec

-- -- 3. Connect to the 'civicpath' database
-- \c civicpath

-- -- 4. Enable extensions on 'civicpath' database
-- CREATE EXTENSION IF NOT EXISTS vector;
-- CREATE EXTENSION IF NOT EXISTS postgis;
-- CREATE EXTENSION IF NOT EXISTS postgis_topology;

