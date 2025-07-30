#!/bin/bash
# ============================================================================
# POSTGRESQL DEPLOYMENT SCRIPT
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

POSTGRES_IMAGE="postgresql-mac:latest"
CONTAINER_NAME="postgresql-MAC"
POSTGRES_PORT=5432

log_info() {
    echo -e "\033[0;34m[POSTGRES]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Build PostgreSQL image
build_postgresql() {
    log_info "Building PostgreSQL Docker image..."
    
    cd "$PROJECT_ROOT/build/applications/postgresql"
    
    docker build \
        --build-arg PG_VERSION=17.0 \
        --build-arg PUID=$PUID \
        --build-arg PGID=$PGID \
        -t "$POSTGRES_IMAGE" \
        .
    
    log_success "PostgreSQL image built successfully"
}

# Deploy PostgreSQL container
deploy_postgresql() {
    log_info "Deploying PostgreSQL container..."
    
    # Stop and remove existing container if present
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    
    # Create necessary directories
    mkdir -p "$APPDATA_PATH/postgresql-MAC"/{data,logs,backups,config}
    
    # Set permissions
    chown -R $PUID:$PGID "$APPDATA_PATH/postgresql-MAC"
    
    # Run PostgreSQL container
    docker run -d \
        --name="$CONTAINER_NAME" \
        --hostname="postgresql" \
        --network="$NETWORK_NAME" \
        --restart="unless-stopped" \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TIMEZONE" \
        -e POSTGRES_DB="$POSTGRES_DB" \
        -e POSTGRES_USER="$POSTGRES_USER" \
        -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.UTF-8" \
        -e PGDATA="/var/lib/postgresql/data/pgdata" \
        -p "${POSTGRES_PORT}:5432" \
        -v "$APPDATA_PATH/postgresql-MAC/data:/var/lib/postgresql/data:rw" \
        -v "$APPDATA_PATH/postgresql-MAC/logs:/var/log/postgresql:rw" \
        -v "$APPDATA_PATH/postgresql-MAC/backups:/backups:rw" \
        -v "$PROJECT_ROOT/build/applications/postgresql/initdb.d:/docker-entrypoint-initdb.d:ro" \
        --shm-size=256m \
        --label="net.unraid.docker.managed=dockerman" \
        --label="net.unraid.docker.icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/postgres-logo.png" \
        --label="net.unraid.docker.webui=" \
        --label="traefik.enable=false" \
        "$POSTGRES_IMAGE"
    
    log_success "PostgreSQL container deployed"
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    log_info "Waiting for PostgreSQL to be ready..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec "$CONTAINER_NAME" pg_isready -U postgres &>/dev/null; then
            log_success "PostgreSQL is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    log_error "PostgreSQL failed to start within expected time"
    return 1
}

# Store database credentials in Vault
store_credentials_in_vault() {
    log_info "Storing database credentials in Vault..."
    
    # Wait for Vault to be accessible
    local vault_addr="http://vault-MAC:8200"
    local vault_token="$VAULT_ROOT_TOKEN"
    
    # Store master credentials
    docker exec vault-MAC sh -c "
        export VAULT_TOKEN='$vault_token'
        vault kv put secret/postgresql/master \
            host='postgresql.${DOMAIN}' \
            port='5432' \
            username='$POSTGRES_USER' \
            password='$POSTGRES_PASSWORD' \
            database='$POSTGRES_DB' \
            connection_string='postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@postgresql.${DOMAIN}:5432/$POSTGRES_DB'
    " 2>/dev/null || log_warning "Could not store credentials in Vault (Vault may not be ready)"
    
    # Store application-specific credentials
    local apps=("radarr" "sonarr" "lidarr" "readarr" "prowlarr" "bazarr" "mylar3" "nextcloud")
    
    for app in "${apps[@]}"; do
        docker exec vault-MAC sh -c "
            export VAULT_TOKEN='$vault_token'
            vault kv put secret/$app/database \
                host='postgresql.${DOMAIN}' \
                port='5432' \
                username='$app' \
                password='${app}_pass_change_me' \
                database='${app}_db' \
                connection_string='postgresql://$app:${app}_pass_change_me@postgresql.${DOMAIN}:5432/${app}_db'
        " 2>/dev/null || true
    done
    
    log_success "Database credentials stored in Vault"
}

# Create backup script
create_backup_script() {
    log_info "Creating backup script..."
    
    cat > "$APPDATA_PATH/postgresql-MAC/backup-postgres.sh" << 'EOF'
#!/bin/bash
# PostgreSQL Backup Script

BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Backup all databases
docker exec postgresql-MAC pg_dumpall -U postgres | gzip > "${BACKUP_DIR}/postgres_backup_${TIMESTAMP}.sql.gz"

# Clean old backups
find "${BACKUP_DIR}" -name "postgres_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup completed: postgres_backup_${TIMESTAMP}.sql.gz"
EOF
    
    chmod +x "$APPDATA_PATH/postgresql-MAC/backup-postgres.sh"
    log_success "Backup script created"
}

# Generate Unraid XML template
generate_xml_template() {
    log_info "Generating Unraid XML template..."
    
    cat > "$PROJECT_ROOT/xml-templates/postgresql-MAC.xml" << EOF
<?xml version="1.0"?>
<Container version="2">
  <Name>postgresql-MAC</Name>
  <Repository>postgresql-mac:latest</Repository>
  <Registry/>
  <Network>$NETWORK_NAME</Network>
  <MyIP/>
  <Shell>bash</Shell>
  <Privileged>false</Privileged>
  <Support>https://www.postgresql.org/</Support>
  <Project>https://www.postgresql.org/</Project>
  <Overview>PostgreSQL 17 - Advanced relational database for Unraid MacGyver Stack</Overview>
  <Category>Database:</Category>
  <WebUI/>
  <TemplateURL/>
  <Icon>https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/postgres-logo.png</Icon>
  <ExtraParams>--shm-size=256m</ExtraParams>
  <PostArgs/>
  <CPUset/>
  <DateInstalled>$(date +%s)</DateInstalled>
  <DonateText/>
  <DonateLink/>
  <Requires/>
  <Config Name="PostgreSQL Port" Target="5432" Default="5432" Mode="tcp" Description="PostgreSQL port" Type="Port" Display="always" Required="true" Mask="false">$POSTGRES_PORT</Config>
  <Config Name="Data Directory" Target="/var/lib/postgresql/data" Default="/mnt/user/appdata/postgresql-MAC/data" Mode="rw" Description="Database storage" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/postgresql-MAC/data</Config>
  <Config Name="Backup Directory" Target="/backups" Default="/mnt/user/appdata/postgresql-MAC/backups" Mode="rw" Description="Backup storage" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/postgresql-MAC/backups</Config>
  <Config Name="Init Scripts" Target="/docker-entrypoint-initdb.d" Default="" Mode="ro" Description="Initialization scripts" Type="Path" Display="advanced" Required="false" Mask="false">$PROJECT_ROOT/build/applications/postgresql/initdb.d</Config>
  <Config Name="Database Name" Target="POSTGRES_DB" Default="macgyver_master" Mode="" Description="Default database name" Type="Variable" Display="always" Required="true" Mask="false">$POSTGRES_DB</Config>
  <Config Name="Database User" Target="POSTGRES_USER" Default="macgyver_admin" Mode="" Description="Database superuser" Type="Variable" Display="always" Required="true" Mask="false">$POSTGRES_USER</Config>
  <Config Name="Database Password" Target="POSTGRES_PASSWORD" Default="" Mode="" Description="Database password" Type="Variable" Display="always" Required="true" Mask="true">$POSTGRES_PASSWORD</Config>
  <Config Name="PGDATA" Target="PGDATA" Default="/var/lib/postgresql/data/pgdata" Mode="" Description="PostgreSQL data directory" Type="Variable" Display="advanced" Required="true" Mask="false">/var/lib/postgresql/data/pgdata</Config>
  <Config Name="PUID" Target="PUID" Default="99" Mode="" Description="User ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PUID</Config>
  <Config Name="PGID" Target="PGID" Default="100" Mode="" Description="Group ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PGID</Config>
  <Config Name="Timezone" Target="TZ" Default="America/New_York" Mode="" Description="Timezone" Type="Variable" Display="advanced" Required="false" Mask="false">$TIMEZONE</Config>
</Container>
EOF
    
    log_success "XML template generated"
}

# Main execution
main() {
    log_info "Starting PostgreSQL deployment..."
    
    build_postgresql
    deploy_postgresql
    wait_for_postgres
    store_credentials_in_vault
    create_backup_script
    generate_xml_template
    
    # Display connection info
    log_success "PostgreSQL deployment complete!"
    echo "  Host: postgresql.${DOMAIN}"
    echo "  Port: $POSTGRES_PORT"
    echo "  Database: $POSTGRES_DB"
    echo "  Username: $POSTGRES_USER"
    echo "  Connection: postgresql://$POSTGRES_USER:[password]@postgresql.${DOMAIN}:5432/$POSTGRES_DB"
}

main "$@"