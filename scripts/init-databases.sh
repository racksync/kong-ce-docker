#!/bin/bash
# init-databases.sh - Initialize multiple databases for Kong and Konga
# This script runs on first PostgreSQL container startup

set -e

# Create konga database and user if they don't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create konga user
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'konga') THEN
            CREATE USER konga WITH PASSWORD 'konga';
        END IF;
    END
    \$\$;

    -- Create konga database
    SELECT 'CREATE DATABASE konga OWNER konga'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'konga')\gexec

    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE konga TO konga;
EOSQL

echo "Databases initialized: kong, konga"
