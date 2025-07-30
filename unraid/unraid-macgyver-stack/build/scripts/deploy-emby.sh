#!/bin/bash
# ============================================================================
# EMBY DEPLOYMENT SCRIPT
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env

APP_NAME="emby"
IMAGE_NAME="emby-mac:latest"
CONTAINER_NAME="emby-MAC"
APP_PORT=8097
USE_VPN=false

log_info() {
    echo -e "\033[0;34m[EMBY]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

# Build image
build_app() {
    log_info "Building Emby Docker image..."
    
    cd "$PROJECT_ROOT/build/applications/$APP_NAME"
    
    docker build \
        --build-arg PUID=$PUID \
        --build-arg PGID=$PGID \
        -t "$IMAGE_NAME" \
        .
    
    log_success "Emby image built successfully"
}

# Deploy container
deploy_app() {
    log_info "Deploying Emby container..."
    
    # Stop and remove existing container
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    
    # Create directories
    mkdir -p "$APPDATA_PATH/$CONTAINER_NAME"/{config,data,logs}
    chown -R $PUID:$PGID "$APPDATA_PATH/$CONTAINER_NAME"
    
    # Network selection
    if [ "$USE_VPN" = "true" ]; then
        NETWORK_OPT="--network=container:gluetun-MAC"
        PORT_OPT=""
    else
        NETWORK_OPT="--network=$NETWORK_NAME"
        PORT_OPT="-p ${APP_PORT}:${APP_PORT}"
    fi
    
    # Run container
    docker run -d \
        --name="$CONTAINER_NAME" \
        --hostname="$APP_NAME" \
        $NETWORK_OPT \
        --restart="unless-stopped" \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TIMEZONE" \
        $PORT_OPT \
        -v "$APPDATA_PATH/$CONTAINER_NAME/config:/config:rw" \
        -v "$APPDATA_PATH/$CONTAINER_NAME/data:/data:rw" \
        -v "$DATA_PATH:/media:rw" \
        --label="net.unraid.docker.managed=dockerman" \
        --label="net.unraid.docker.icon=https://seeklogo.com/images/E/emby-logo-3A3D8C1A5C-seeklogo.com.png" \
        --label="net.unraid.docker.webui=http://[IP]:[PORT:${APP_PORT}]" \
        --label="traefik.enable=true" \
        --label="traefik.http.routers.$APP_NAME.rule=Host(\`$APP_NAME.${DOMAIN}\`)" \
        --label="traefik.http.routers.$APP_NAME.entrypoints=websecure" \
        --label="traefik.http.routers.$APP_NAME.tls=true" \
        --label="traefik.http.services.$APP_NAME.loadbalancer.server.port=${APP_PORT}" \
        "$IMAGE_NAME"
    
    log_success "Emby container deployed"
}

# Store in Vault
store_in_vault() {
    log_info "Storing Emby information in Vault..."
    
    # Store URL and wait for API key
    docker exec vault-MAC sh -c "
        export VAULT_TOKEN='$VAULT_ROOT_TOKEN'
        vault kv put secret/$APP_NAME/url value='https://$APP_NAME.${DOMAIN}'
    " 2>/dev/null || true
}

# Main
main() {
    log_info "Starting Emby deployment..."
    
    build_app
    deploy_app
    store_in_vault
    
    log_success "Emby deployment complete!"
    echo "  URL: https://$APP_NAME.${DOMAIN}"
}

main "$@"
