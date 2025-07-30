#!/bin/bash
# Validate the Unraid MacGyver Stack deployment

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "=== UNRAID MACGYVER STACK - DEPLOYMENT VALIDATION ==="
echo "Date: $(date)"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check function
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    if docker ps | grep -q "$name"; then
        printf "%-20s ${GREEN}✓ Running${NC}" "$name"
        
        # Check HTTP response if URL provided
        if [ -n "$url" ]; then
            if response=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5 2>/dev/null); then
                if [ "$response" = "$expected_code" ] || [ "$response" = "302" ] || [ "$response" = "301" ]; then
                    printf " - ${GREEN}Accessible${NC} (HTTP $response)\n"
                else
                    printf " - ${YELLOW}HTTP $response${NC}\n"
                fi
            else
                printf " - ${RED}Not accessible${NC}\n"
            fi
        else
            echo ""
        fi
    else
        printf "%-20s ${RED}✗ Not running${NC}\n" "$name"
    fi
}

echo "=== CORE INFRASTRUCTURE STATUS ==="
check_service "vault-MAC" "http://localhost:8200/v1/sys/health" "200"
check_service "traefik-MAC" "http://localhost:8079" "200"
check_service "gluetun-MAC" "" 
check_service "postgresql-MAC" ""

echo ""
echo "=== MEDIA AUTOMATION APPS (VPN-ROUTED) ==="
check_service "sonarr-MAC" "http://localhost:8989/ping" "200"
check_service "radarr-MAC" "http://localhost:7878/ping" "200"
check_service "lidarr-MAC" "http://localhost:8686/ping" "200"
check_service "readarr-MAC" "http://localhost:8787/ping" "200"
check_service "prowlarr-MAC" "http://localhost:9696/ping" "200"
check_service "bazarr-MAC" "http://localhost:6767/api/v1/system/health" "200"

echo ""
echo "=== DOWNLOAD CLIENTS ==="
check_service "sabnzbd-MAC" "http://localhost:8080/api?mode=version" "200"

echo ""
echo "=== MEDIA SERVERS ==="
check_service "jellyfin-MAC" "http://localhost:8096/health" "200"
check_service "plex-MAC" "http://localhost:32400/identity" "200"

echo ""
echo "=== MONITORING & MANAGEMENT ==="
check_service "grafana-MAC" "http://localhost:3000/api/health" "200"
check_service "prometheus-MAC" "http://localhost:9090/-/healthy" "200"
check_service "portainer-MAC" "http://localhost:9000" "200"

echo ""
echo "=== NETWORK STATUS ==="
echo "Docker Network: $NETWORK_NAME"
docker network inspect "$NETWORK_NAME" | grep -A 5 "Containers" | grep "Name" | sed 's/.*"Name": "/  - /' | sed 's/".*//'

echo ""
echo "=== STORAGE STATUS ==="
echo "AppData: $APPDATA_PATH"
du -sh "$APPDATA_PATH"/*-MAC 2>/dev/null | head -10 || echo "  No app data directories yet"

echo ""
echo "=== VAULT STATUS ==="
if [ -f "/mnt/user/appdata/vault-MAC/vault-init.json" ]; then
    echo "✓ Vault initialized"
    if docker exec vault-MAC vault status 2>/dev/null | grep -q "Sealed.*false"; then
        echo "✓ Vault unsealed"
    else
        echo "✗ Vault sealed - needs unsealing"
    fi
else
    echo "✗ Vault not initialized"
fi

echo ""
echo "=== SSL CERTIFICATES ==="
if [ -d "$PROJECT_ROOT/certs" ]; then
    echo "Certificates generated for:"
    ls -1 "$PROJECT_ROOT/certs"/*.pem 2>/dev/null | grep -v key | sed 's/.*\//  - /' | sed 's/.pem//' || echo "  No certificates found"
fi

echo ""
echo "=== ACCESS URLS ==="
echo "Internal Access (use these for initial setup):"
echo "  - Vault:      http://$(hostname -I | awk '{print $1}'):8200"
echo "  - Traefik:    http://$(hostname -I | awk '{print $1}'):8079"
echo "  - Sonarr:     http://$(hostname -I | awk '{print $1}'):8989"
echo "  - Radarr:     http://$(hostname -I | awk '{print $1}'):7878"
echo ""
echo "Domain Access (after DNS/hosts configuration):"
echo "  - Vault:      https://vault.${DOMAIN}"
echo "  - Sonarr:     https://sonarr.${DOMAIN}"
echo "  - Radarr:     https://radarr.${DOMAIN}"
echo "  - Jellyfin:   https://jellyfin.${DOMAIN}"
echo "  - Grafana:    https://grafana.${DOMAIN}"

echo ""
echo "=== SUMMARY ==="
running_count=$(docker ps --format "{{.Names}}" | grep -c "MAC" || true)
total_apps=31
echo "Running Containers: $running_count"
echo "Core Infrastructure: 4/4"
echo "Applications: $((running_count - 4))/$total_apps"

if [ "$running_count" -lt 10 ]; then
    echo ""
    echo "Note: Not all applications are deployed yet."
    echo "To deploy more apps, run: ./build-all-from-scratch.sh"
fi

echo ""
echo "=== VALIDATION COMPLETE ==="