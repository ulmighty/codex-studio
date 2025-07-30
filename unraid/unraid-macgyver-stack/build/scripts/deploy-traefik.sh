#!/bin/bash
# ============================================================================
# TRAEFIK DEPLOYMENT SCRIPT
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

TRAEFIK_IMAGE="traefik-mac:latest"
CONTAINER_NAME="traefik-MAC"

log_info() {
    echo -e "\033[0;34m[TRAEFIK]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Build Traefik image
build_traefik() {
    log_info "Building Traefik Docker image..."
    
    cd "$PROJECT_ROOT/build/applications/traefik"
    
    docker build \
        --build-arg TRAEFIK_VERSION=3.0.0 \
        --build-arg PUID=$PUID \
        --build-arg PGID=$PGID \
        -t "$TRAEFIK_IMAGE" \
        .
    
    log_success "Traefik image built successfully"
}

# Generate hashed password for dashboard
generate_dashboard_auth() {
    log_info "Generating dashboard authentication..."
    
    # Generate bcrypt hash for password
    local hashed_pass=$(docker run --rm httpd:alpine htpasswd -nbB "$TRAEFIK_DASHBOARD_USER" "$TRAEFIK_DASHBOARD_PASSWORD" | sed -e s/\\$/\\$\\$/g)
    
    # Update middleware configuration
    sed -i "s|admin:\$2y\$10\$YourHashedPasswordHere|${hashed_pass}|" \
        "$PROJECT_ROOT/build/applications/traefik/dynamic/middlewares.yml"
    
    log_success "Dashboard authentication configured"
}

# Deploy Traefik container
deploy_traefik() {
    log_info "Deploying Traefik container..."
    
    # Stop and remove existing container if present
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    
    # Create necessary directories
    mkdir -p "$APPDATA_PATH/traefik-MAC"/{config,logs,certificates,dynamic}
    
    # Copy configuration files
    cp "$PROJECT_ROOT/build/applications/traefik/traefik.yml" "$APPDATA_PATH/traefik-MAC/config/"
    cp -r "$PROJECT_ROOT/build/applications/traefik/dynamic"/* "$APPDATA_PATH/traefik-MAC/dynamic/"
    
    # Copy certificates
    if [ -d "$PROJECT_ROOT/certs" ]; then
        cp -r "$PROJECT_ROOT/certs"/* "$APPDATA_PATH/traefik-MAC/certificates/"
    fi
    
    # Create certificate configuration for local certs
    cat > "$APPDATA_PATH/traefik-MAC/dynamic/tls.yml" << EOF
tls:
  certificates:
    - certFile: /certificates/_wildcard.${DOMAIN}.pem
      keyFile: /certificates/_wildcard.${DOMAIN}-key.pem
  stores:
    default:
      defaultCertificate:
        certFile: /certificates/_wildcard.${DOMAIN}.pem
        keyFile: /certificates/_wildcard.${DOMAIN}-key.pem
EOF
    
    # Set permissions
    chown -R $PUID:$PGID "$APPDATA_PATH/traefik-MAC"
    chmod 600 "$APPDATA_PATH/traefik-MAC/certificates"/*-key.pem 2>/dev/null || true
    
    # Run Traefik container
    docker run -d \
        --name="$CONTAINER_NAME" \
        --hostname="traefik" \
        --network="$NETWORK_NAME" \
        --restart="unless-stopped" \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TIMEZONE" \
        -p "${TRAEFIK_HTTP_PORT}:80" \
        -p "${TRAEFIK_HTTPS_PORT}:443" \
        -p "${TRAEFIK_DASHBOARD_PORT}:8080" \
        -v "$APPDATA_PATH/traefik-MAC/config/traefik.yml:/etc/traefik/traefik.yml:ro" \
        -v "$APPDATA_PATH/traefik-MAC/dynamic:/etc/traefik/dynamic:ro" \
        -v "$APPDATA_PATH/traefik-MAC/logs:/var/log/traefik:rw" \
        -v "$APPDATA_PATH/traefik-MAC/certificates:/certificates:ro" \
        -v "/var/run/docker.sock:/var/run/docker.sock:ro" \
        --label="net.unraid.docker.managed=dockerman" \
        --label="net.unraid.docker.icon=https://raw.githubusercontent.com/traefik/traefik/master/docs/content/assets/img/traefik.logo.png" \
        --label="net.unraid.docker.webui=http://[IP]:[PORT:8079]" \
        --label="traefik.enable=true" \
        --label="traefik.http.routers.traefik.rule=Host(\`traefik.${DOMAIN}\`)" \
        --label="traefik.http.routers.traefik.entrypoints=websecure" \
        --label="traefik.http.routers.traefik.tls=true" \
        --label="traefik.http.routers.traefik.service=api@internal" \
        --label="traefik.http.routers.traefik.middlewares=auth-basic@file" \
        "$TRAEFIK_IMAGE"
    
    log_success "Traefik container deployed"
}

# Generate Unraid XML template
generate_xml_template() {
    log_info "Generating Unraid XML template..."
    
    cat > "$PROJECT_ROOT/xml-templates/traefik-MAC.xml" << EOF
<?xml version="1.0"?>
<Container version="2">
  <Name>traefik-MAC</Name>
  <Repository>traefik-mac:latest</Repository>
  <Registry/>
  <Network>$NETWORK_NAME</Network>
  <MyIP/>
  <Shell>sh</Shell>
  <Privileged>false</Privileged>
  <Support>https://doc.traefik.io/traefik/</Support>
  <Project>https://traefik.io/</Project>
  <Overview>Traefik - Modern reverse proxy and load balancer for Unraid MacGyver Stack</Overview>
  <Category>Network:Web Network:Proxy</Category>
  <WebUI>http://[IP]:[PORT:8079]</WebUI>
  <TemplateURL/>
  <Icon>https://raw.githubusercontent.com/traefik/traefik/master/docs/content/assets/img/traefik.logo.png</Icon>
  <ExtraParams/>
  <PostArgs/>
  <CPUset/>
  <DateInstalled>$(date +%s)</DateInstalled>
  <DonateText/>
  <DonateLink/>
  <Requires/>
  <Config Name="HTTP Port" Target="80" Default="80" Mode="tcp" Description="HTTP entry point" Type="Port" Display="always" Required="true" Mask="false">$TRAEFIK_HTTP_PORT</Config>
  <Config Name="HTTPS Port" Target="443" Default="443" Mode="tcp" Description="HTTPS entry point" Type="Port" Display="always" Required="true" Mask="false">$TRAEFIK_HTTPS_PORT</Config>
  <Config Name="Dashboard Port" Target="8080" Default="8079" Mode="tcp" Description="Traefik dashboard port" Type="Port" Display="always" Required="true" Mask="false">$TRAEFIK_DASHBOARD_PORT</Config>
  <Config Name="Configuration" Target="/etc/traefik/traefik.yml" Default="/mnt/user/appdata/traefik-MAC/config/traefik.yml" Mode="ro" Description="Static configuration" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/traefik-MAC/config/traefik.yml</Config>
  <Config Name="Dynamic Config" Target="/etc/traefik/dynamic" Default="/mnt/user/appdata/traefik-MAC/dynamic" Mode="ro" Description="Dynamic configuration" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/traefik-MAC/dynamic</Config>
  <Config Name="Logs" Target="/var/log/traefik" Default="/mnt/user/appdata/traefik-MAC/logs" Mode="rw" Description="Log files" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/traefik-MAC/logs</Config>
  <Config Name="Certificates" Target="/certificates" Default="/mnt/user/appdata/traefik-MAC/certificates" Mode="ro" Description="TLS certificates" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/traefik-MAC/certificates</Config>
  <Config Name="Docker Socket" Target="/var/run/docker.sock" Default="/var/run/docker.sock" Mode="ro" Description="Docker socket for provider" Type="Path" Display="advanced" Required="true" Mask="false">/var/run/docker.sock</Config>
  <Config Name="PUID" Target="PUID" Default="99" Mode="" Description="User ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PUID</Config>
  <Config Name="PGID" Target="PGID" Default="100" Mode="" Description="Group ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PGID</Config>
  <Config Name="Timezone" Target="TZ" Default="America/New_York" Mode="" Description="Timezone" Type="Variable" Display="advanced" Required="false" Mask="false">$TIMEZONE</Config>
</Container>
EOF
    
    log_success "XML template generated"
}

# Main execution
main() {
    log_info "Starting Traefik deployment..."
    
    build_traefik
    generate_dashboard_auth
    deploy_traefik
    generate_xml_template
    
    # Display status
    log_info "Waiting for Traefik to start..."
    sleep 5
    
    docker logs "$CONTAINER_NAME" --tail 20
    
    log_success "Traefik deployment complete!"
    echo "  Dashboard: https://traefik.${DOMAIN}"
    echo "  Username: $TRAEFIK_DASHBOARD_USER"
    echo "  Password: [configured in .env]"
}

main "$@"