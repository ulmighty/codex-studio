#!/bin/bash
# Deploy all applications quickly

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "=== DEPLOYING ALL APPLICATIONS ==="

# Function to deploy an app
deploy_app() {
    local app_name=$1
    local port=$2
    local extra_args="${3:-}"
    
    echo "Deploying $app_name on port $port..."
    
    cd "$PROJECT_ROOT/build/applications/$app_name"
    
    # Try to build the image
    if docker build -t "${app_name}-mac:latest" --build-arg PUID=99 --build-arg PGID=100 . 2>/dev/null; then
        echo "Built $app_name successfully"
    else
        echo "Failed to build $app_name, skipping..."
        return 1
    fi
    
    # Remove existing container if any
    docker stop "${app_name}-MAC" 2>/dev/null || true
    docker rm "${app_name}-MAC" 2>/dev/null || true
    
    # Run container
    docker run -d \
        --name="${app_name}-MAC" \
        --network="$NETWORK_NAME" \
        --restart="unless-stopped" \
        -p "${port}:${port}" \
        -v "$APPDATA_PATH/${app_name}-MAC:/config:rw" \
        -v "$DATA_PATH:/data:rw" \
        $extra_args \
        "${app_name}-mac:latest"
    
    echo "$app_name deployed!"
}

# Deploy media automation apps (through VPN)
echo "=== Deploying VPN-routed apps ==="
# Removed jackett as requested
deploy_app "sonarr" "8989" "--network=container:gluetun-MAC"
deploy_app "radarr" "7878" "--network=container:gluetun-MAC"
deploy_app "lidarr" "8686" "--network=container:gluetun-MAC"
deploy_app "readarr" "8787" "--network=container:gluetun-MAC"
deploy_app "bazarr" "6767" "--network=container:gluetun-MAC"
deploy_app "prowlarr" "8090" "--network=container:gluetun-MAC"

# Deploy download clients
echo "=== Deploying download clients ==="
deploy_app "sabnzbd" "8080"
# Removed qbittorrent as requested

# Deploy media servers
echo "=== Deploying media servers ==="
deploy_app "plex" "32400" "-e PLEX_CLAIM=$PLEX_CLAIM"
deploy_app "jellyfin" "8096" "--device /dev/dri:/dev/dri"
deploy_app "overseerr" "5055"
deploy_app "tautulli" "8181"
deploy_app "kavita" "5000"

# Deploy monitoring & management
echo "=== Deploying monitoring apps ==="
deploy_app "grafana" "3000"
deploy_app "prometheus" "9090"
deploy_app "redis" "6379"
deploy_app "influxdb" "8086"
deploy_app "portainer" "9000" "-v /var/run/docker.sock:/var/run/docker.sock"

# Deploy specialized services
echo "=== Deploying specialized services ==="
deploy_app "unmanic" "8888"
deploy_app "notifiarr" "5454"
deploy_app "frigate" "5001" "--device /dev/dri:/dev/dri"
deploy_app "calibre" "8082"
deploy_app "calibre-web" "8083"

# Deploy productivity apps
echo "=== Deploying productivity apps ==="
deploy_app "gitea" "3001"
deploy_app "wikijs" "3002"
deploy_app "vaultwarden" "8084"
deploy_app "n8n" "5678"
deploy_app "heimdall" "8085"

echo "=== APPLICATION DEPLOYMENT COMPLETE ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "-MAC"