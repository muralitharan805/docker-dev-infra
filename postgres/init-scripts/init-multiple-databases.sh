#!/bin/bash
set -e
set -u

# Function to dynamically create a database and load extensions
function setup_database() {
    local db_name=$1
    echo "===================================================="
    echo "Initializing database: '$db_name'"
    echo "===================================================="

    # 1. Create database if it does not exist
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        SELECT 'CREATE DATABASE $db_name'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db_name')\gexec
EOSQL

    # 2. Enable extensions in that specific database
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" <<-EOSQL
        CREATE EXTENSION IF NOT EXISTS vector;
        CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS postgis_topology;
EOSQL
}

# Always enable extensions on the primary default database (e.g., 'vectordb')
setup_database "$POSTGRES_DB"

# Check if there are other databases defined in the environment variable
if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
    echo "Multiple databases requested: $POSTGRES_MULTIPLE_DATABASES"
    
    # Split the comma-separated database names and process each
    for db in $(echo "$POSTGRES_MULTIPLE_DATABASES" | tr ',' ' '); do
        setup_database "$db"
    done
    echo "All databases initialized successfully!"
fi
