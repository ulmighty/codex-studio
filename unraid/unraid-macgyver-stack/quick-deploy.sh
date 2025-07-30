#!/bin/bash
# Quick deployment script for core infrastructure

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "=== QUICK DEPLOY - Core Infrastructure ==="

# 1. Deploy Traefik
echo "Deploying Traefik..."
cd $PROJECT_ROOT/build/applications/traefik
docker build -t traefik-mac:latest . && \
docker run -d \
    --name="traefik-MAC" \
    --network="$NETWORK_NAME" \
    --restart="unless-stopped" \
    -p 80:80 \
    -p 443:443 \
    -p 8079:8080 \
    -v "$APPDATA_PATH/traefik-MAC/config/traefik.yml:/etc/traefik/traefik.yml:ro" \
    -v "$APPDATA_PATH/traefik-MAC/dynamic:/etc/traefik/dynamic:ro" \
    -v "$PROJECT_ROOT/certs:/certificates:ro" \
    -v "/var/run/docker.sock:/var/run/docker.sock:ro" \
    traefik-mac:latest

# 2. Deploy Gluetun
echo "Deploying Gluetun..."
cd $PROJECT_ROOT/build/applications/gluetun
docker build -t gluetun-mac:latest . && \
docker run -d \
    --name="gluetun-MAC" \
    --network="$NETWORK_NAME" \
    --restart="unless-stopped" \
    --cap-add NET_ADMIN \
    --device /dev/net/tun \
    -e VPN_SERVICE_PROVIDER="nordvpn" \
    -e OPENVPN_USER="$NORDVPN_USERNAME" \
    -e OPENVPN_PASSWORD="$NORDVPN_PASSWORD" \
    -e SERVER_COUNTRIES="$NORDVPN_COUNTRY" \
    -p 9117:9117 \
    -p 8989:8989 \
    -p 7878:7878 \
    -p 8686:8686 \
    -p 8787:8787 \
    -p 6767:6767 \
    -p 8090:8090 \
    gluetun-mac:latest

# 3. Deploy PostgreSQL
echo "Deploying PostgreSQL..."
cd $PROJECT_ROOT/build/applications/postgresql
docker build -t postgresql-mac:latest . && \
docker run -d \
    --name="postgresql-MAC" \
    --network="$NETWORK_NAME" \
    --restart="unless-stopped" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -p 5432:5432 \
    -v "$APPDATA_PATH/postgresql-MAC/data:/var/lib/postgresql/data:rw" \
    postgresql-mac:latest

echo "=== Core Infrastructure Deployed ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"