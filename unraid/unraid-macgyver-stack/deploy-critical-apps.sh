#!/bin/bash
# Deploy critical applications for the Unraid MacGyver Stack

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "=== DEPLOYING CRITICAL APPLICATIONS ==="
echo "This will deploy the most important apps for a functional media stack"
echo ""

# Function to create and deploy an app
deploy_critical_app() {
    local app=$1
    local base_image=$2
    local port=$3
    local network="${4:-$NETWORK_NAME}"
    
    echo ">>> Deploying $app..."
    
    mkdir -p "$PROJECT_ROOT/build/applications/$app"
    cd "$PROJECT_ROOT/build/applications/$app"
    
    case "$app" in
        "jellyfin")
            cat > Dockerfile << 'EOF'
# ============================================================================
# JELLYFIN - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    ffmpeg \
    openssl \
    locales \
    tzdata \
    libfontconfig1 \
    libfreetype6 \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} jellyfin || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash jellyfin

# Install Jellyfin from official repo
RUN curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - \
    && echo "deb [arch=amd64] https://repo.jellyfin.org/ubuntu bullseye main" > /etc/apt/sources.list.d/jellyfin.list \
    && apt-get update \
    && apt-get install -y jellyfin-server jellyfin-web jellyfin-ffmpeg5 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /config /cache /media \
    && chown -R jellyfin:users /config /cache /media

USER jellyfin
EXPOSE 8096
VOLUME ["/config", "/cache", "/media"]
ENV JELLYFIN_DATA_DIR=/config
ENV JELLYFIN_CACHE_DIR=/cache
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8096/health || exit 1
CMD ["jellyfin", "--datadir", "/config", "--cachedir", "/cache", "--webdir", "/usr/share/jellyfin/web"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="jellyfin-MAC" \
      org.opencontainers.image.description="Jellyfin media server built from scratch"
EOF
            ;;
            
        "sabnzbd")
            cat > Dockerfile << 'EOF'
# ============================================================================
# SABNZBD - CUSTOM BUILD FROM DEBIAN BASE  
# ============================================================================
FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    git \
    p7zip-full \
    par2 \
    unrar-free \
    unzip \
    wget \
    curl \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} sabnzbd || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash sabnzbd

# Install SABnzbd from GitHub
RUN git clone --depth 1 --branch 4.0.3 https://github.com/sabnzbd/sabnzbd.git /app/sabnzbd \
    && cd /app/sabnzbd \
    && pip3 install --no-cache-dir -r requirements.txt \
    && mkdir -p /config /downloads/incomplete /downloads/complete \
    && chown -R sabnzbd:users /app /config /downloads

USER sabnzbd
EXPOSE 8081
VOLUME ["/config", "/downloads"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8081/api?mode=version || exit 1
CMD ["python3", "/app/sabnzbd/SABnzbd.py", "-f", "/config", "-s", "0.0.0.0:8081", "-b", "0"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="sabnzbd-MAC" \
      org.opencontainers.image.description="SABnzbd newsreader built from scratch"
EOF
            ;;
            
        "grafana")
            cat > Dockerfile << 'EOF'
# ============================================================================
# GRAFANA - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
FROM alpine:latest

ARG PUID=99
ARG PGID=100

RUN apk add --no-cache \
    ca-certificates \
    curl \
    libc6-compat \
    && (addgroup -g ${PGID} grafana || true) \
    && adduser -u ${PUID} -G users -D -H grafana

# Download and install Grafana
ARG GRAFANA_VERSION=10.2.3
RUN mkdir -p /tmp/grafana \
    && curl -L "https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz" \
    | tar -xz -C /tmp --strip-components=1 \
    && mv /tmp /app/grafana \
    && mkdir -p /config /var/lib/grafana \
    && chown -R grafana:users /app /config /var/lib/grafana

USER grafana
EXPOSE 3000
VOLUME ["/config", "/var/lib/grafana"]
ENV GF_PATHS_CONFIG=/config/grafana.ini
ENV GF_PATHS_DATA=/var/lib/grafana
ENV GF_PATHS_LOGS=/config/logs
ENV GF_PATHS_PLUGINS=/var/lib/grafana/plugins
ENV GF_PATHS_PROVISIONING=/config/provisioning
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:3000/api/health || exit 1
CMD ["/app/grafana/bin/grafana-server", "--homepath", "/app/grafana", "--config", "/config/grafana.ini"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="grafana-MAC" \
      org.opencontainers.image.description="Grafana monitoring built from scratch"
EOF
            ;;
            
        "prometheus")
            cat > Dockerfile << 'EOF'
# ============================================================================
# PROMETHEUS - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
FROM alpine:latest

ARG PUID=99
ARG PGID=100

RUN apk add --no-cache \
    ca-certificates \
    curl \
    && (addgroup -g ${PGID} prometheus || true) \
    && adduser -u ${PUID} -G users -D -H prometheus

# Download and install Prometheus
ARG PROMETHEUS_VERSION=2.48.1
RUN mkdir -p /tmp/prometheus \
    && curl -L "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" \
    | tar -xz -C /tmp --strip-components=1 \
    && mv /tmp /app/prometheus \
    && mkdir -p /config /data \
    && chown -R prometheus:users /app /config /data

# Copy config if exists
COPY --chown=prometheus:users prometheus.yml /config/prometheus.yml || echo "No config file provided"

USER prometheus
EXPOSE 9090
VOLUME ["/config", "/data"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:9090/-/healthy || exit 1
CMD ["/app/prometheus/prometheus", "--config.file=/config/prometheus.yml", "--storage.tsdb.path=/data", "--web.console.libraries=/app/prometheus/console_libraries", "--web.console.templates=/app/prometheus/consoles"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="prometheus-MAC" \
      org.opencontainers.image.description="Prometheus monitoring built from scratch"
EOF
            ;;
            
        "portainer")
            cat > Dockerfile << 'EOF'
# ============================================================================
# PORTAINER - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
FROM alpine:latest

ARG PUID=99
ARG PGID=100

RUN apk add --no-cache \
    ca-certificates \
    curl \
    && (addgroup -g ${PGID} portainer || true) \
    && adduser -u ${PUID} -G users -D -H portainer

# Download and install Portainer CE
ARG PORTAINER_VERSION=2.19.4
RUN mkdir -p /app \
    && curl -L "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
    | tar -xz -C /app \
    && mkdir -p /data \
    && chown -R portainer:users /app /data

USER portainer
EXPOSE 9000 8000
VOLUME ["/data"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:9000 || exit 1
CMD ["/app/portainer/portainer"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="portainer-MAC" \
      org.opencontainers.image.description="Portainer CE built from scratch"
EOF
            ;;
    esac
    
    # Build the image
    echo "Building ${app}-mac:latest..."
    if docker build -t "${app}-mac:latest" --build-arg PUID=99 --build-arg PGID=100 .; then
        echo "✓ Build successful"
        
        # Stop and remove existing
        docker stop "${app}-MAC" 2>/dev/null || true
        docker rm "${app}-MAC" 2>/dev/null || true
        
        # Deploy based on app
        case "$app" in
            "jellyfin")
                docker run -d \
                    --name="${app}-MAC" \
                    --network="$NETWORK_NAME" \
                    --restart="unless-stopped" \
                    -e PUID=99 \
                    -e PGID=100 \
                    -e TZ="$TIMEZONE" \
                    -p 8096:8096 \
                    -v "$APPDATA_PATH/${app}-MAC:/config:rw" \
                    -v "$DATA_PATH/media:/media:rw" \
                    -v "$APPDATA_PATH/${app}-MAC/cache:/cache:rw" \
                    --device /dev/dri:/dev/dri \
                    "${app}-mac:latest"
                ;;
            "sabnzbd")
                docker run -d \
                    --name="${app}-MAC" \
                    --network="$NETWORK_NAME" \
                    --restart="unless-stopped" \
                    -e PUID=99 \
                    -e PGID=100 \
                    -e TZ="$TIMEZONE" \
                    -p 8081:8081 \
                    -v "$APPDATA_PATH/${app}-MAC:/config:rw" \
                    -v "$DATA_PATH/downloads:/downloads:rw" \
                    "${app}-mac:latest"
                ;;
            "grafana")
                # Create initial config
                mkdir -p "$APPDATA_PATH/${app}-MAC"
                cat > "$APPDATA_PATH/${app}-MAC/grafana.ini" << EOFINI
[server]
protocol = http
http_port = 3000
root_url = https://grafana.ulmighty.local

[security]
admin_user = admin
admin_password = ${GRAFANA_ADMIN_PASSWORD:-admin}

[users]
allow_sign_up = false

[auth.anonymous]
enabled = false

[log]
mode = console file
level = info
EOFINI
                chown -R 99:100 "$APPDATA_PATH/${app}-MAC"
                
                docker run -d \
                    --name="${app}-MAC" \
                    --network="$NETWORK_NAME" \
                    --restart="unless-stopped" \
                    -e PUID=99 \
                    -e PGID=100 \
                    -e TZ="$TIMEZONE" \
                    -p 3000:3000 \
                    -v "$APPDATA_PATH/${app}-MAC:/config:rw" \
                    -v "$APPDATA_PATH/${app}-MAC/data:/var/lib/grafana:rw" \
                    "${app}-mac:latest"
                ;;
            "prometheus")
                docker run -d \
                    --name="${app}-MAC" \
                    --network="$NETWORK_NAME" \
                    --restart="unless-stopped" \
                    -e PUID=99 \
                    -e PGID=100 \
                    -e TZ="$TIMEZONE" \
                    -p 9090:9090 \
                    -v "$APPDATA_PATH/${app}-MAC:/config:rw" \
                    -v "$APPDATA_PATH/${app}-MAC/data:/data:rw" \
                    "${app}-mac:latest"
                ;;
            "portainer")
                docker run -d \
                    --name="${app}-MAC" \
                    --network="$NETWORK_NAME" \
                    --restart="unless-stopped" \
                    -e PUID=99 \
                    -e PGID=100 \
                    -e TZ="$TIMEZONE" \
                    -p 9000:9000 \
                    -p 8000:8000 \
                    -v "$APPDATA_PATH/${app}-MAC:/data:rw" \
                    -v "/var/run/docker.sock:/var/run/docker.sock:ro" \
                    "${app}-mac:latest"
                ;;
        esac
        
        echo "✓ $app deployed!"
    else
        echo "✗ Build failed for $app"
    fi
    
    echo ""
}

# Deploy critical apps
# deploy_critical_app "jellyfin" "debian:bullseye-slim" "8096"  # Removed per user request
deploy_critical_app "sabnzbd" "debian:bullseye-slim" "8081"
deploy_critical_app "grafana" "alpine:latest" "3000"
deploy_critical_app "prometheus" "alpine:latest" "9090"
deploy_critical_app "portainer" "alpine:latest" "9000"

echo "=== CRITICAL APPS DEPLOYMENT COMPLETE ==="
echo ""
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep "MAC" | sort