-- ============================================================================
-- CREATE APPLICATION DATABASES
-- ============================================================================

-- Create databases for each application that needs one
CREATE DATABASE IF NOT EXISTS radarr_db;
CREATE DATABASE IF NOT EXISTS sonarr_db;
CREATE DATABASE IF NOT EXISTS lidarr_db;
CREATE DATABASE IF NOT EXISTS readarr_db;
CREATE DATABASE IF NOT EXISTS prowlarr_db;
CREATE DATABASE IF NOT EXISTS bazarr_db;
CREATE DATABASE IF NOT EXISTS mylar3_db;
CREATE DATABASE IF NOT EXISTS overseerr_db;
CREATE DATABASE IF NOT EXISTS tautulli_db;
CREATE DATABASE IF NOT EXISTS nextcloud_db;
CREATE DATABASE IF NOT EXISTS grocy_db;
CREATE DATABASE IF NOT EXISTS homebox_db;
CREATE DATABASE IF NOT EXISTS homeassistant_db;
CREATE DATABASE IF NOT EXISTS frigate_db;
CREATE DATABASE IF NOT EXISTS stash_db;

-- Create application users with appropriate permissions
DO $$
BEGIN
    -- Create users if they don't exist
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'radarr') THEN
        CREATE USER radarr WITH PASSWORD 'radarr_pass_change_me';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'sonarr') THEN
        CREATE USER sonarr WITH PASSWORD 'sonarr_pass_change_me';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'nextcloud') THEN
        CREATE USER nextcloud WITH PASSWORD 'nextcloud_pass_change_me';
    END IF;
    
    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE radarr_db TO radarr;
    GRANT ALL PRIVILEGES ON DATABASE sonarr_db TO sonarr;
    GRANT ALL PRIVILEGES ON DATABASE nextcloud_db TO nextcloud;
    
    -- Create read-only monitoring user
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'prometheus') THEN
        CREATE USER prometheus WITH PASSWORD 'prometheus_pass_change_me';
        GRANT pg_monitor TO prometheus;
    END IF;
END $$;

-- Enable extensions
\c radarr_db
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

\c sonarr_db
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

\c nextcloud_db
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Return to default database
\c postgres

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'Application databases created successfully';
END $$;