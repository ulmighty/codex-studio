#!/bin/bash
# ============================================================================
# UNRAID MACGYVER STACK - STATUS CHECK
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}============================================================${NC}"
echo -e "${PURPLE}UNRAID MACGYVER STACK - DEPLOYMENT STATUS${NC}"
echo -e "${PURPLE}============================================================${NC}\n"

# System Information
echo -e "${CYAN}System Information:${NC}"
echo "  Hostname: $(hostname)"
echo "  Unraid Version: $(cat /etc/unraid-version 2>/dev/null || echo "Not on Unraid")"
echo "  Docker Version: $(docker version --format '{{.Server.Version}}')"
echo "  Project Path: $PROJECT_ROOT"
echo "  Domain: $DOMAIN"
echo ""

# Network Status
echo -e "${CYAN}Networks:${NC}"
for network in "$NETWORK_NAME" "vpn-network-MAC"; do
    if docker network ls | grep -q "$network"; then
        echo -e "  ${GREEN}✓${NC} $network"
    else
        echo -e "  ${RED}✗${NC} $network"
    fi
done
echo ""

# Core Infrastructure
echo -e "${CYAN}Core Infrastructure:${NC}"
for container in vault-MAC traefik-MAC gluetun-MAC postgresql-MAC; do
    if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        local ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container" | head -n1)
        echo -e "  ${GREEN}✓${NC} $container (IP: $ip)"
    else
        echo -e "  ${RED}✗${NC} $container"
    fi
done
echo ""

# Application Status
echo -e "${CYAN}Applications:${NC}"

# Count running applications
TOTAL_APPS=33
RUNNING_APPS=$(docker ps --filter "label=net.unraid.docker.managed=dockerman" --format "{{.Names}}" | grep -c "MAC$" || echo "0")

echo "  Total: $TOTAL_APPS"
echo "  Running: $RUNNING_APPS"
echo "  Stopped: $((TOTAL_APPS - RUNNING_APPS))"
echo ""

# Certificate Status
echo -e "${CYAN}SSL Certificates:${NC}"
if [ -d "$PROJECT_ROOT/certs" ]; then
    CERT_COUNT=$(ls -1 "$PROJECT_ROOT/certs"/*.pem 2>/dev/null | grep -v key | wc -l || echo "0")
    echo "  Generated: $CERT_COUNT certificates"
    if [ -f "$PROJECT_ROOT/certs/_wildcard.${DOMAIN}.pem" ]; then
        echo -e "  ${GREEN}✓${NC} Wildcard certificate exists"
    else
        echo -e "  ${RED}✗${NC} Wildcard certificate missing"
    fi
else
    echo -e "  ${RED}✗${NC} Certificate directory not found"
fi
echo ""

# Storage Usage
echo -e "${CYAN}Storage Usage:${NC}"
if [ -d "$APPDATA_PATH" ]; then
    echo "  AppData: $(du -sh "$APPDATA_PATH" 2>/dev/null | cut -f1)"
fi
if [ -d "$DATA_PATH" ]; then
    echo "  Media: $(du -sh "$DATA_PATH" 2>/dev/null | cut -f1 || echo "N/A")"
fi
echo ""

# Quick Health Check
echo -e "${CYAN}Health Checks:${NC}"

# Vault
if docker exec vault-MAC vault status &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Vault is unsealed and ready"
else
    echo -e "  ${YELLOW}!${NC} Vault needs attention"
fi

# PostgreSQL
if docker exec postgresql-MAC pg_isready -U postgres &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} PostgreSQL is accepting connections"
else
    echo -e "  ${RED}✗${NC} PostgreSQL is not ready"
fi

# VPN
if docker exec gluetun-MAC wget -qO- https://ipinfo.io/country 2>/dev/null | grep -qv "US"; then
    echo -e "  ${GREEN}✓${NC} VPN is connected"
else
    echo -e "  ${YELLOW}!${NC} VPN connection needs checking"
fi

echo ""

# Access URLs
echo -e "${CYAN}Access URLs:${NC}"
echo "  Traefik: https://traefik.${DOMAIN}"
echo "  Vault: https://vault.${DOMAIN}"
if docker ps --format "{{.Names}}" | grep -q "^plex-MAC$"; then
    echo "  Plex: https://plex.${DOMAIN}"
fi
if docker ps --format "{{.Names}}" | grep -q "^overseerr-MAC$"; then
    echo "  Overseerr: https://overseerr.${DOMAIN}"
fi

echo -e "\n${PURPLE}============================================================${NC}"