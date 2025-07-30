#!/bin/bash
# Create missing applications

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

# Missing apps: jackett, qbittorrent, kavita, redis, influxdb, portainer, calibre, calibre-web, gitea, wikijs, vaultwarden, n8n, heimdall

# Create app directory structure
create_app() {
    local app_name=$1
    local base_image=$2
    local port=$3
    local description=$4
    
    echo "Creating $app_name..."
    
    mkdir -p "$PROJECT_ROOT/build/applications/$app_name"
    
    # Create Dockerfile
    cat > "$PROJECT_ROOT/build/applications/$app_name/Dockerfile" << EOF
# ============================================================================
# ${app_name^^} - CUSTOM BUILD
# ============================================================================
# Base: $base_image
# Description: $description
# ============================================================================

FROM $base_image

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install dependencies based on base image
RUN if [ -f /etc/alpine-release ]; then \
        apk add --no-cache \
            ca-certificates \
            tzdata \
            && (addgroup -g \${PGID} ${app_name} || true) \
            && adduser -u \${PUID} -G users -D -H ${app_name}; \
    elif [ -f /etc/debian_version ]; then \
        apt-get update && apt-get install -y --no-install-recommends \
            ca-certificates \
            tzdata \
            && rm -rf /var/lib/apt/lists/* \
            && (groupadd -g \${PGID} ${app_name} || true) \
            && useradd -u \${PUID} -g users -d /config -s /bin/bash ${app_name}; \
    fi

# Create necessary directories
RUN mkdir -p /config /data /app \
    && chown -R ${app_name}:users /config /data /app

# Switch to non-root user
USER ${app_name}

# Expose port
EXPOSE $port

# Volume
VOLUME ["/config", "/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:$port/ || exit 1

# Command (placeholder - needs actual app binary/script)
CMD ["sh", "-c", "echo 'Application ${app_name} needs to be properly configured' && sleep infinity"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="${app_name}-MAC" \
      org.opencontainers.image.description="$description"
EOF

    echo "Created $app_name"
}

# Create missing applications
create_app "jackett" "alpine:latest" "9117" "API Support for your favorite torrent trackers"
create_app "qbittorrent" "alpine:latest" "8081" "qBittorrent BitTorrent client"
create_app "kavita" "debian:bullseye-slim" "5000" "Fast, feature rich, cross platform reading server"
create_app "redis" "alpine:latest" "6379" "In-memory data structure store"
create_app "influxdb" "alpine:latest" "8086" "Time series database"
create_app "portainer" "alpine:latest" "9000" "Docker management GUI"
create_app "calibre" "debian:bullseye-slim" "8082" "Ebook management application"
create_app "calibre-web" "alpine:latest" "8083" "Web app providing a clean interface for browsing Calibre"
create_app "gitea" "alpine:latest" "3001" "Git with a cup of tea - self-hosted Git service"
create_app "wikijs" "debian:bullseye-slim" "3002" "Modern and powerful wiki app"
create_app "vaultwarden" "alpine:latest" "8084" "Unofficial Bitwarden compatible server"
create_app "n8n" "debian:bullseye-slim" "5678" "Workflow automation tool"
create_app "heimdall" "php:8.3-fpm-alpine" "8085" "Application dashboard and launcher"

echo "All missing applications created!"