#!/usr/bin/env bash
# ============================================================================
# POSTGRESQL ENTRYPOINT SCRIPT
# ============================================================================

set -Eeo pipefail

# If running as root, switch to postgres user
if [ "$1" = 'postgres' ] && [ "$(id -u)" = '0' ]; then
    exec gosu postgres "$BASH_SOURCE" "$@"
fi

# Setup data directory
if [ "$1" = 'postgres' ]; then
    mkdir -p "$PGDATA"
    chmod 700 "$PGDATA"
    chown -R postgres:postgres "$PGDATA"
    
    # Look for existing data directory
    if [ ! -s "$PGDATA/PG_VERSION" ]; then
        echo "[INFO] Initializing database..."
        
        eval 'initdb --username=postgres --pwfile=<(echo "$POSTGRES_PASSWORD") '"$POSTGRES_INITDB_ARGS"
        
        # Internal start for setup
        pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start
        
        # Create default database if specified
        if [ -n "$POSTGRES_DB" ] && [ "$POSTGRES_DB" != 'postgres' ]; then
            echo "[INFO] Creating database: $POSTGRES_DB"
            createdb -U postgres "$POSTGRES_DB"
        fi
        
        # Create additional user if specified
        if [ -n "$POSTGRES_USER" ] && [ "$POSTGRES_USER" != 'postgres' ]; then
            echo "[INFO] Creating user: $POSTGRES_USER"
            psql -U postgres -c "CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';"
        fi
        
        # Run initialization scripts
        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sh)
                    echo "[INFO] Running $f"
                    . "$f"
                    ;;
                *.sql)
                    echo "[INFO] Running $f"
                    psql -U postgres -f "$f"
                    ;;
                *.sql.gz)
                    echo "[INFO] Running $f"
                    gunzip -c "$f" | psql -U postgres
                    ;;
                *)
                    echo "[INFO] Ignoring $f"
                    ;;
            esac
        done
        
        pg_ctl -D "$PGDATA" -m fast -w stop
        
        echo "[INFO] Database initialization complete"
    fi
    
    # Configure PostgreSQL
    cat >> "$PGDATA/postgresql.conf" <<-EOF
		
		# Performance Tuning for Unraid
		shared_buffers = 256MB
		effective_cache_size = 1GB
		maintenance_work_mem = 64MB
		checkpoint_completion_target = 0.9
		wal_buffers = 16MB
		default_statistics_target = 100
		random_page_cost = 1.1
		effective_io_concurrency = 200
		work_mem = 4MB
		min_wal_size = 1GB
		max_wal_size = 4GB
		
		# Logging
		log_destination = 'stderr'
		logging_collector = on
		log_directory = 'log'
		log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
		log_file_mode = 0600
		log_truncate_on_rotation = on
		log_rotation_age = 1d
		log_rotation_size = 100MB
		log_line_prefix = '%t [%p-%l] %u@%d '
		log_checkpoints = on
		log_connections = on
		log_disconnections = on
		log_lock_waits = on
		log_temp_files = 0
		log_autovacuum_min_duration = 0
		log_error_verbosity = default
		
		# Connection settings
		listen_addresses = '*'
		max_connections = 200
		
		# Enable extensions
		shared_preload_libraries = 'pg_stat_statements'
		pg_stat_statements.track = all
	EOF
    
    # Configure authentication
    cat >> "$PGDATA/pg_hba.conf" <<-EOF
		
		# Allow connections from Docker network
		host    all             all             172.25.0.0/16            scram-sha-256
		host    all             all             172.26.0.0/16            scram-sha-256
		host    all             all             172.17.0.0/16            scram-sha-256
	EOF
fi

exec "$@"