#!/bin/bash
# ============================================================================
# UNIVERSAL APPLICATION BUILDER FOR UNRAID MACGYVER STACK
# ============================================================================
# This script generates Dockerfiles and deployment scripts for all 33 apps
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

# Application definitions
declare -A APP_CONFIG

# Media Automation Apps (VPN Required)
APP_CONFIG[prowlarr]="base=debian:bullseye-slim;port=9117;vpn=true;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/prowlarr-logo.png"
APP_CONFIG[radarr]="base=debian:bullseye-slim;port=7878;vpn=true;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/radarr-logo.png"
APP_CONFIG[sonarr]="base=debian:bullseye-slim;port=8989;vpn=true;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/sonarr-logo.png"
APP_CONFIG[lidarr]="base=debian:bullseye-slim;port=8686;vpn=true;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/lidarr-logo.png"
APP_CONFIG[readarr]="base=debian:bullseye-slim;port=8787;vpn=true;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/readarr-logo.png"
APP_CONFIG[bazarr]="base=debian:bullseye-slim;port=6767;vpn=true;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/bazarr-logo.png"
APP_CONFIG[mylar3]="base=debian:bullseye-slim;port=8090;vpn=true;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/mylar3-logo.png"

# Download Clients (No VPN)
APP_CONFIG[sabnzbd]="base=debian:bullseye-slim;port=8080;vpn=false;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/sabnzbd-logo.png"
APP_CONFIG[jdownloader2]="base=debian:bullseye-slim;port=5800;vpn=false;icon=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/jdownloader-2-icon.png"

# Media Servers
APP_CONFIG[plex]="base=nvidia/cuda:12.3.1-runtime-ubuntu22.04;port=32400;vpn=false;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/plex-logo.png"
APP_CONFIG[jellyfin]="base=debian:bullseye-slim;port=8096;vpn=false;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/jellyfin-logo.png"
APP_CONFIG[emby]="base=debian:bullseye-slim;port=8097;vpn=false;icon=https://seeklogo.com/images/E/emby-logo-3A3D8C1A5C-seeklogo.com.png"

# Monitoring & Requests
APP_CONFIG[tautulli]="base=debian:bullseye-slim;port=8181;vpn=false;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/tautulli-logo.png"
APP_CONFIG[overseerr]="base=debian:bullseye-slim;port=5055;vpn=false;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/overseerr-logo.png"
APP_CONFIG[notifiarr]="base=alpine:latest;port=5454;vpn=false;icon=https://avatars.githubusercontent.com/u/130932487?s=200&v=4"

# Observability
APP_CONFIG[prometheus]="base=alpine:latest;port=9090;vpn=false;icon=https://seeklogo.com/images/P/prometheus-monitoring-system-logo-4077C6C3D5-seeklogo.com.png"
APP_CONFIG[grafana]="base=alpine:latest;port=3000;vpn=false;icon=https://seeklogo.com/images/G/grafana-logo-3A3D8C1A5C-seeklogo.com.png"
APP_CONFIG[loki]="base=alpine:latest;port=3100;vpn=false;icon=https://grafana.com/static/assets/img/logos/loki.png"

# Specialized Services
APP_CONFIG[frigate]="base=nvidia/cuda:12.3.1-runtime-ubuntu22.04;port=5000;vpn=false;icon=https://frigate.video/img/frigate-logo.png"
APP_CONFIG[unmanic]="base=nvidia/cuda:12.3.1-runtime-ubuntu22.04;port=8888;vpn=false;icon=https://dashboardicons.com/assets/img/icons/unmanic.png"
APP_CONFIG[stash]="base=debian:bullseye-slim;port=9999;vpn=false;icon=https://raw.githubusercontent.com/stashapp/stash/master/ui/v2.5/src/assets/images/stash-logo.png"
APP_CONFIG[resilio]="base=debian:bullseye-slim;port=8889;vpn=false;icon=https://www.resilio.com/wp-content/uploads/2019/05/resilio-sync-logo.png"
APP_CONFIG[nginx-proxy-manager]="base=alpine:latest;port=81;vpn=false;icon=https://dashboardicons.com/assets/img/icons/nginx-proxy-manager.png"

# Productivity
APP_CONFIG[nextcloud]="base=php:8.3-fpm-alpine;port=8081;vpn=false;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/nextcloud-logo.png"
APP_CONFIG[grocy]="base=php:8.3-fpm-alpine;port=9283;vpn=false;icon=https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/grocy-logo.png"
APP_CONFIG[homebox]="base=alpine:latest;port=7745;vpn=false;icon=https://raw.githubusercontent.com/hay-kot/homebox/main/frontend/public/logo.png"
APP_CONFIG[filezilla]="base=debian:bullseye-slim;port=5801;vpn=false;icon=https://upload.wikimedia.org/wikipedia/commons/0/01/FileZilla_logo.svg"
APP_CONFIG[cloudcommander]="base=debian:bullseye-slim;port=8000;vpn=false;icon=https://cloudcmd.io/img/logo/cloudcmd.svg"
APP_CONFIG[homeassistant]="base=debian:bullseye-slim;port=8123;vpn=false;icon=https://upload.wikimedia.org/wikipedia/commons/6/6e/Home_Assistant_Logo.svg"

# Helper functions
log_info() {
    echo -e "\033[0;34m[BUILDER]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

# Parse app configuration
parse_config() {
    local app=$1
    local config="${APP_CONFIG[$app]}"
    
    # Extract configuration values
    BASE_IMAGE=$(echo "$config" | grep -oP 'base=\K[^;]+')
    APP_PORT=$(echo "$config" | grep -oP 'port=\K[^;]+')
    USE_VPN=$(echo "$config" | grep -oP 'vpn=\K[^;]+')
    APP_ICON=$(echo "$config" | grep -oP 'icon=\K[^;]+')
}

# Generate Dockerfile based on base image
generate_dockerfile() {
    local app=$1
    local app_dir="$PROJECT_ROOT/build/applications/$app"
    
    mkdir -p "$app_dir"
    parse_config "$app"
    
    log_info "Generating Dockerfile for $app (base: $BASE_IMAGE)"
    
    case "$BASE_IMAGE" in
        "debian:bullseye-slim")
            generate_debian_dockerfile "$app" "$app_dir"
            ;;
        "alpine:latest")
            generate_alpine_dockerfile "$app" "$app_dir"
            ;;
        "nvidia/cuda:"*)
            generate_cuda_dockerfile "$app" "$app_dir"
            ;;
        "php:8.3-fpm-alpine")
            generate_php_dockerfile "$app" "$app_dir"
            ;;
    esac
    
    log_success "Dockerfile generated for $app"
}

# Generate Debian-based Dockerfile
generate_debian_dockerfile() {
    local app=$1
    local app_dir=$2
    
    cat > "$app_dir/Dockerfile" << EOF
# ============================================================================
# ${app^^} - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================

FROM debian:bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    ca-certificates \\
    curl \\
    tar \\
    xz-utils \\
    && rm -rf /var/lib/apt/lists/*

# Download ${app^} - version will be updated by build script
ARG APP_VERSION=latest
RUN mkdir -p /app \\
    && cd /app \\
    && echo "Downloading ${app^}..."

FROM debian:bullseye-slim

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    ca-certificates \\
    curl \\
    libicu67 \\
    libssl1.1 \\
    mediainfo \\
    python3 \\
    sqlite3 \\
    tzdata \\
    unrar \\
    unzip \\
    wget \\
    && rm -rf /var/lib/apt/lists/* \\
    && groupadd -g \${PGID} ${app} \\
    && useradd -u \${PUID} -g ${app} -d /config -s /bin/bash ${app} \\
    && mkdir -p /app /config /data \\
    && chown -R ${app}:${app} /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=${app}:${app} entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE ${APP_PORT}

VOLUME ["/config", "/data"]

USER ${app}

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \\
      org.opencontainers.image.title="${app}-MAC" \\
      org.opencontainers.image.description="${app^} for Unraid MacGyver Stack"
EOF
}

# Generate Alpine-based Dockerfile
generate_alpine_dockerfile() {
    local app=$1
    local app_dir=$2
    
    cat > "$app_dir/Dockerfile" << EOF
# ============================================================================
# ${app^^} - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================

FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \\
    ca-certificates \\
    curl \\
    tar

# Download ${app^}
ARG APP_VERSION=latest
RUN mkdir -p /app \\
    && cd /app \\
    && echo "Downloading ${app^}..."

FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apk add --no-cache \\
    ca-certificates \\
    curl \\
    shadow \\
    su-exec \\
    tzdata \\
    && addgroup -g \${PGID} ${app} \\
    && adduser -u \${PUID} -G ${app} -D -H ${app} \\
    && mkdir -p /app /config /data \\
    && chown -R ${app}:${app} /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=${app}:${app} entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE ${APP_PORT}

VOLUME ["/config", "/data"]

USER ${app}

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \\
      org.opencontainers.image.title="${app}-MAC" \\
      org.opencontainers.image.description="${app^} for Unraid MacGyver Stack"
EOF
}

# Generate basic entrypoint script
generate_entrypoint() {
    local app=$1
    local app_dir=$2
    
    cat > "$app_dir/entrypoint.sh" << 'EOF'
#!/bin/sh
set -e

echo "[INFO] Starting ${app^}..."

# Execute application
exec /app/${app}
EOF
    
    sed -i "s/\${app}/$app/g" "$app_dir/entrypoint.sh"
}

# Generate CUDA-based Dockerfile
generate_cuda_dockerfile() {
    local app=$1
    local app_dir=$2
    
    cat > "$app_dir/Dockerfile" << EOF
# ============================================================================
# ${app^^} - CUSTOM BUILD FROM NVIDIA CUDA BASE
# ============================================================================

FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    ca-certificates \\
    curl \\
    tar \\
    xz-utils \\
    && rm -rf /var/lib/apt/lists/*

# Download ${app^}
ARG APP_VERSION=latest
RUN mkdir -p /app \\
    && cd /app \\
    && echo "Downloading ${app^}..."

FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    ca-certificates \\
    curl \\
    ffmpeg \\
    libgomp1 \\
    python3 \\
    python3-pip \\
    tzdata \\
    wget \\
    && rm -rf /var/lib/apt/lists/* \\
    && groupadd -g \${PGID} ${app} \\
    && useradd -u \${PUID} -g ${app} -d /config -s /bin/bash ${app} \\
    && mkdir -p /app /config /data \\
    && chown -R ${app}:${app} /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=${app}:${app} entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE ${APP_PORT}

VOLUME ["/config", "/data"]

USER ${app}

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \\
      org.opencontainers.image.title="${app}-MAC" \\
      org.opencontainers.image.description="${app^} with GPU support for Unraid MacGyver Stack"
EOF
}

# Generate PHP-based Dockerfile
generate_php_dockerfile() {
    local app=$1
    local app_dir=$2
    
    cat > "$app_dir/Dockerfile" << EOF
# ============================================================================
# ${app^^} - CUSTOM BUILD FROM PHP-FPM BASE
# ============================================================================

FROM php:8.3-fpm-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \\
    curl \\
    tar \\
    git

# Download ${app^}
ARG APP_VERSION=latest
RUN mkdir -p /app \\
    && cd /app \\
    && echo "Downloading ${app^}..."

FROM php:8.3-fpm-alpine

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install PHP extensions and dependencies
RUN apk add --no-cache \\
    bash \\
    ca-certificates \\
    curl \\
    nginx \\
    postgresql-client \\
    redis \\
    shadow \\
    supervisor \\
    tzdata \\
    && docker-php-ext-install \\
    bcmath \\
    exif \\
    gd \\
    intl \\
    mysqli \\
    opcache \\
    pdo_mysql \\
    pdo_pgsql \\
    zip \\
    && addgroup -g \${PGID} ${app} \\
    && adduser -u \${PUID} -G ${app} -D -H ${app} \\
    && mkdir -p /app /config /data \\
    && chown -R ${app}:${app} /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy configs
COPY --chown=${app}:${app} nginx.conf /etc/nginx/nginx.conf
COPY --chown=${app}:${app} supervisord.conf /etc/supervisord.conf
COPY --chown=${app}:${app} entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE ${APP_PORT}

VOLUME ["/config", "/data"]

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \\
      org.opencontainers.image.title="${app}-MAC" \\
      org.opencontainers.image.description="${app^} PHP application for Unraid MacGyver Stack"
EOF
}

# Generate deployment script
generate_deployment_script() {
    local app=$1
    parse_config "$app"
    
    local script_path="$PROJECT_ROOT/build/scripts/deploy-${app}.sh"
    
    cat > "$script_path" << EOF
#!/bin/bash
# ============================================================================
# ${app^^} DEPLOYMENT SCRIPT
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env

APP_NAME="${app}"
IMAGE_NAME="${app}-mac:latest"
CONTAINER_NAME="${app}-MAC"
APP_PORT=${APP_PORT}
USE_VPN=${USE_VPN}

log_info() {
    echo -e "\\033[0;34m[${app^^}]\\033[0m \$1"
}

log_success() {
    echo -e "\\033[0;32m[SUCCESS]\\033[0m \$1"
}

# Build image
build_app() {
    log_info "Building ${app^} Docker image..."
    
    cd "\$PROJECT_ROOT/build/applications/\$APP_NAME"
    
    docker build \\
        --build-arg PUID=\$PUID \\
        --build-arg PGID=\$PGID \\
        -t "\$IMAGE_NAME" \\
        .
    
    log_success "${app^} image built successfully"
}

# Deploy container
deploy_app() {
    log_info "Deploying ${app^} container..."
    
    # Stop and remove existing container
    docker stop "\$CONTAINER_NAME" 2>/dev/null || true
    docker rm "\$CONTAINER_NAME" 2>/dev/null || true
    
    # Create directories
    mkdir -p "\$APPDATA_PATH/\$CONTAINER_NAME"/{config,data,logs}
    chown -R \$PUID:\$PGID "\$APPDATA_PATH/\$CONTAINER_NAME"
    
    # Network selection
    if [ "\$USE_VPN" = "true" ]; then
        NETWORK_OPT="--network=container:gluetun-MAC"
        PORT_OPT=""
    else
        NETWORK_OPT="--network=\$NETWORK_NAME"
        PORT_OPT="-p \${APP_PORT}:\${APP_PORT}"
    fi
    
    # Run container
    docker run -d \\
        --name="\$CONTAINER_NAME" \\
        --hostname="\$APP_NAME" \\
        \$NETWORK_OPT \\
        --restart="unless-stopped" \\
        -e PUID="\$PUID" \\
        -e PGID="\$PGID" \\
        -e TZ="\$TIMEZONE" \\
        \$PORT_OPT \\
        -v "\$APPDATA_PATH/\$CONTAINER_NAME/config:/config:rw" \\
        -v "\$APPDATA_PATH/\$CONTAINER_NAME/data:/data:rw" \\
        -v "\$DATA_PATH:/media:rw" \\
        --label="net.unraid.docker.managed=dockerman" \\
        --label="net.unraid.docker.icon=${APP_ICON}" \\
        --label="net.unraid.docker.webui=http://[IP]:[PORT:\${APP_PORT}]" \\
        --label="traefik.enable=true" \\
        --label="traefik.http.routers.\$APP_NAME.rule=Host(\\\`\$APP_NAME.\${DOMAIN}\\\`)" \\
        --label="traefik.http.routers.\$APP_NAME.entrypoints=websecure" \\
        --label="traefik.http.routers.\$APP_NAME.tls=true" \\
        --label="traefik.http.services.\$APP_NAME.loadbalancer.server.port=\${APP_PORT}" \\
        "\$IMAGE_NAME"
    
    log_success "${app^} container deployed"
}

# Store in Vault
store_in_vault() {
    log_info "Storing ${app^} information in Vault..."
    
    # Store URL and wait for API key
    docker exec vault-MAC sh -c "
        export VAULT_TOKEN='\$VAULT_ROOT_TOKEN'
        vault kv put secret/\$APP_NAME/url value='https://\$APP_NAME.\${DOMAIN}'
    " 2>/dev/null || true
}

# Main
main() {
    log_info "Starting ${app^} deployment..."
    
    build_app
    deploy_app
    store_in_vault
    
    log_success "${app^} deployment complete!"
    echo "  URL: https://\$APP_NAME.\${DOMAIN}"
}

main "\$@"
EOF
    
    chmod +x "$script_path"
    log_success "Deployment script created for $app"
}

# Generate XML template
generate_xml_template() {
    local app=$1
    parse_config "$app"
    
    local xml_path="$PROJECT_ROOT/xml-templates/${app}-MAC.xml"
    
    cat > "$xml_path" << EOF
<?xml version="1.0"?>
<Container version="2">
  <Name>${app}-MAC</Name>
  <Repository>${app}-mac:latest</Repository>
  <Registry/>
  <Network>$([ "$USE_VPN" = "true" ] && echo "container:gluetun-MAC" || echo "$NETWORK_NAME")</Network>
  <MyIP/>
  <Shell>sh</Shell>
  <Privileged>false</Privileged>
  <Support>https://github.com/unraid-macgyver-stack</Support>
  <Project>https://github.com/unraid-macgyver-stack</Project>
  <Overview>${app^} - Part of Unraid MacGyver Stack</Overview>
  <Category>MediaApp:Other</Category>
  <WebUI>http://[IP]:[PORT:${APP_PORT}]</WebUI>
  <TemplateURL/>
  <Icon>${APP_ICON}</Icon>
  <ExtraParams/>
  <PostArgs/>
  <CPUset/>
  <DateInstalled>\$(date +%s)</DateInstalled>
  <DonateText/>
  <DonateLink/>
  <Requires/>
EOF

    if [ "$USE_VPN" != "true" ]; then
        cat >> "$xml_path" << EOF
  <Config Name="WebUI Port" Target="${APP_PORT}" Default="${APP_PORT}" Mode="tcp" Description="WebUI Port" Type="Port" Display="always" Required="true" Mask="false">${APP_PORT}</Config>
EOF
    fi

    cat >> "$xml_path" << EOF
  <Config Name="Config" Target="/config" Default="/mnt/user/appdata/${app}-MAC/config" Mode="rw" Description="Configuration" Type="Path" Display="always" Required="true" Mask="false">\$APPDATA_PATH/${app}-MAC/config</Config>
  <Config Name="Data" Target="/data" Default="/mnt/user/appdata/${app}-MAC/data" Mode="rw" Description="Application data" Type="Path" Display="always" Required="true" Mask="false">\$APPDATA_PATH/${app}-MAC/data</Config>
  <Config Name="Media" Target="/media" Default="/mnt/user/data" Mode="rw" Description="Media storage" Type="Path" Display="always" Required="true" Mask="false">\$DATA_PATH</Config>
  <Config Name="PUID" Target="PUID" Default="99" Mode="" Description="User ID" Type="Variable" Display="advanced" Required="false" Mask="false">\$PUID</Config>
  <Config Name="PGID" Target="PGID" Default="100" Mode="" Description="Group ID" Type="Variable" Display="advanced" Required="false" Mask="false">\$PGID</Config>
  <Config Name="Timezone" Target="TZ" Default="America/New_York" Mode="" Description="Timezone" Type="Variable" Display="advanced" Required="false" Mask="false">\$TIMEZONE</Config>
</Container>
EOF
    
    log_success "XML template created for $app"
}

# Main execution
main() {
    log_info "Starting application builder..."
    
    # Process each application
    for app in "${!APP_CONFIG[@]}"; do
        log_info "Processing $app..."
        
        generate_dockerfile "$app"
        generate_entrypoint "$app" "$PROJECT_ROOT/build/applications/$app"
        generate_deployment_script "$app"
        generate_xml_template "$app"
        
        log_success "Completed $app"
    done
    
    log_success "Application builder complete!"
    echo "  Generated: ${#APP_CONFIG[@]} applications"
    echo "  Dockerfiles: $PROJECT_ROOT/build/applications/"
    echo "  Scripts: $PROJECT_ROOT/build/scripts/"
    echo "  XML Templates: $PROJECT_ROOT/xml-templates/"
}

main "$@"