#!/bin/bash
# Deploy all applications with proper error handling

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "=== DEPLOYING ALL APPLICATIONS ==="
echo "Starting at: $(date)"

# Track deployment status
DEPLOYED=0
FAILED=0
FAILED_APPS=""

# Function to deploy an app
deploy_app() {
    local app_name=$1
    local port=$2
    local extra_args="${3:-}"
    
    echo ""
    echo ">>> Deploying $app_name on port $port..."
    
    cd "$PROJECT_ROOT/build/applications/$app_name" 2>/dev/null || {
        echo "ERROR: Application directory not found for $app_name"
        FAILED=$((FAILED + 1))
        FAILED_APPS="$FAILED_APPS $app_name"
        return 1
    }
    
    # Stop and remove existing container if any
    docker stop "${app_name}-MAC" 2>/dev/null || true
    docker rm "${app_name}-MAC" 2>/dev/null || true
    
    # For now, use pre-built images from popular sources to speed up deployment
    # This is temporary until custom builds are properly configured
    case "$app_name" in
        "sonarr") IMAGE="lscr.io/linuxserver/sonarr:latest" ;;
        "radarr") IMAGE="lscr.io/linuxserver/radarr:latest" ;;
        "lidarr") IMAGE="lscr.io/linuxserver/lidarr:latest" ;;
        "readarr") IMAGE="lscr.io/linuxserver/readarr:develop" ;;
        "bazarr") IMAGE="lscr.io/linuxserver/bazarr:latest" ;;
        "prowlarr") IMAGE="lscr.io/linuxserver/prowlarr:latest" ;;
        "sabnzbd") IMAGE="lscr.io/linuxserver/sabnzbd:latest" ;;
        "plex") IMAGE="lscr.io/linuxserver/plex:latest" ;;
        "jellyfin") IMAGE="jellyfin/jellyfin:latest" ;;
        "overseerr") IMAGE="lscr.io/linuxserver/overseerr:latest" ;;
        "tautulli") IMAGE="lscr.io/linuxserver/tautulli:latest" ;;
        "kavita") IMAGE="kizaing/kavita:latest" ;;
        "grafana") IMAGE="grafana/grafana:latest" ;;
        "prometheus") IMAGE="prom/prometheus:latest" ;;
        "redis") IMAGE="redis:alpine" ;;
        "influxdb") IMAGE="influxdb:latest" ;;
        "portainer") IMAGE="portainer/portainer-ce:latest" ;;
        "unmanic") IMAGE="josh5/unmanic:latest" ;;
        "notifiarr") IMAGE="golift/notifiarr:latest" ;;
        "frigate") IMAGE="ghcr.io/blakeblackshear/frigate:stable" ;;
        "calibre") IMAGE="lscr.io/linuxserver/calibre:latest" ;;
        "calibre-web") IMAGE="lscr.io/linuxserver/calibre-web:latest" ;;
        "gitea") IMAGE="gitea/gitea:latest" ;;
        "wikijs") IMAGE="ghcr.io/requarks/wiki:2" ;;
        "vaultwarden") IMAGE="vaultwarden/server:latest" ;;
        "n8n") IMAGE="n8nio/n8n:latest" ;;
        "heimdall") IMAGE="lscr.io/linuxserver/heimdall:latest" ;;
        *) 
            echo "WARNING: No pre-built image defined for $app_name, skipping..."
            FAILED=$((FAILED + 1))
            FAILED_APPS="$FAILED_APPS $app_name"
            return 1
            ;;
    esac
    
    # Pull the image
    echo "Pulling image: $IMAGE"
    docker pull "$IMAGE" || {
        echo "ERROR: Failed to pull image for $app_name"
        FAILED=$((FAILED + 1))
        FAILED_APPS="$FAILED_APPS $app_name"
        return 1
    }
    
    # Run container with common settings
    docker run -d \
        --name="${app_name}-MAC" \
        --restart="unless-stopped" \
        -e PUID=99 \
        -e PGID=100 \
        -e TZ="$TIMEZONE" \
        -v "$APPDATA_PATH/${app_name}-MAC:/config:rw" \
        $extra_args \
        "$IMAGE" || {
            echo "ERROR: Failed to start container for $app_name"
            FAILED=$((FAILED + 1))
            FAILED_APPS="$FAILED_APPS $app_name"
            return 1
        }
    
    echo "✓ $app_name deployed successfully!"
    DEPLOYED=$((DEPLOYED + 1))
    return 0
}

# Deploy media automation apps (through VPN)
echo ""
echo "=== STAGE 1: Deploying VPN-routed apps ==="
for app in sonarr radarr lidarr readarr bazarr prowlarr; do
    deploy_app "$app" "8989" "--network=container:gluetun-MAC" || true
done

# Deploy download clients
echo ""
echo "=== STAGE 2: Deploying download clients ==="
deploy_app "sabnzbd" "8080" "-p 8080:8080 --network=$NETWORK_NAME -v $DATA_PATH/downloads:/downloads" || true

# Deploy media servers
echo ""
echo "=== STAGE 3: Deploying media servers ==="
deploy_app "plex" "32400" "--network=$NETWORK_NAME -p 32400:32400 -v $DATA_PATH/media:/media --device /dev/dri:/dev/dri" || true
deploy_app "jellyfin" "8096" "--network=$NETWORK_NAME -p 8096:8096 -v $DATA_PATH/media:/media --device /dev/dri:/dev/dri" || true
deploy_app "overseerr" "5055" "--network=$NETWORK_NAME -p 5055:5055" || true
deploy_app "tautulli" "8181" "--network=$NETWORK_NAME -p 8181:8181" || true
deploy_app "kavita" "5000" "--network=$NETWORK_NAME -p 5000:5000 -v $DATA_PATH/books:/books" || true

# Deploy monitoring & management
echo ""
echo "=== STAGE 4: Deploying monitoring apps ==="
deploy_app "grafana" "3000" "--network=$NETWORK_NAME -p 3000:3000" || true
deploy_app "prometheus" "9090" "--network=$NETWORK_NAME -p 9090:9090" || true
deploy_app "redis" "6379" "--network=$NETWORK_NAME -p 6379:6379" || true
deploy_app "influxdb" "8086" "--network=$NETWORK_NAME -p 8086:8086" || true
deploy_app "portainer" "9000" "--network=$NETWORK_NAME -p 9000:9000 -p 8000:8000 -v /var/run/docker.sock:/var/run/docker.sock" || true

# Deploy specialized services
echo ""
echo "=== STAGE 5: Deploying specialized services ==="
deploy_app "unmanic" "8888" "--network=$NETWORK_NAME -p 8888:8888 -v $DATA_PATH/media:/library --device /dev/dri:/dev/dri" || true
deploy_app "notifiarr" "5454" "--network=$NETWORK_NAME -p 5454:5454" || true
deploy_app "frigate" "5001" "--network=$NETWORK_NAME -p 5001:5000 -p 8554:8554 -p 8555:8555/tcp -p 8555:8555/udp --shm-size=256m --device /dev/dri:/dev/dri -v /dev/bus/usb:/dev/bus/usb" || true
deploy_app "calibre" "8082" "--network=$NETWORK_NAME -p 8082:8080 -p 8083:8081 -v $DATA_PATH/books:/books" || true
deploy_app "calibre-web" "8083" "--network=$NETWORK_NAME -p 8084:8083 -v $DATA_PATH/books:/books" || true

# Deploy productivity apps
echo ""
echo "=== STAGE 6: Deploying productivity apps ==="
deploy_app "gitea" "3001" "--network=$NETWORK_NAME -p 3001:3000 -p 2222:22" || true
deploy_app "wikijs" "3002" "--network=$NETWORK_NAME -p 3002:3000" || true
deploy_app "vaultwarden" "8085" "--network=$NETWORK_NAME -p 8085:80" || true
deploy_app "n8n" "5678" "--network=$NETWORK_NAME -p 5678:5678" || true
deploy_app "heimdall" "8086" "--network=$NETWORK_NAME -p 8086:80 -p 8443:443" || true

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "Deployed: $DEPLOYED applications"
echo "Failed: $FAILED applications"
if [ $FAILED -gt 0 ]; then
    echo "Failed apps:$FAILED_APPS"
fi
echo "Completed at: $(date)"
echo ""
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "MAC" | sort