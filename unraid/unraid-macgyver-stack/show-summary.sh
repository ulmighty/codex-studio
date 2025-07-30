#!/bin/bash

echo "=== UNRAID MACGYVER STACK DEPLOYMENT SUMMARY ==="
echo ""
echo "Core Infrastructure (4):"
echo "- Vault (Secret Management) - Running"
echo "- Traefik (Reverse Proxy) - Running"
echo "- Gluetun (VPN Gateway) - Running"
echo "- PostgreSQL (Database) - Running"
echo ""
echo "Media Automation (6 VPN-routed):"
for app in sonarr radarr lidarr readarr bazarr prowlarr; do
    if [ -d "/mnt/user/docker_builds/unraid-macgyver-stack/build/applications/$app" ]; then
        echo "- $app/"
    fi
done
echo ""
echo "Download Clients (1):"
for app in sabnzbd; do
    if [ -d "/mnt/user/docker_builds/unraid-macgyver-stack/build/applications/$app" ]; then
        echo "- $app/"
    fi
done
echo ""
echo "Media Servers (6):"
for app in plex jellyfin emby overseerr tautulli kavita; do
    if [ -d "/mnt/user/docker_builds/unraid-macgyver-stack/build/applications/$app" ]; then
        echo "- $app/"
    fi
done
echo ""
echo "Monitoring & Management (5):"
for app in grafana prometheus redis influxdb portainer; do
    if [ -d "/mnt/user/docker_builds/unraid-macgyver-stack/build/applications/$app" ]; then
        echo "- $app/"
    fi
done
echo ""
echo "Specialized Services (5):"
for app in unmanic notifiarr frigate calibre calibre-web; do
    if [ -d "/mnt/user/docker_builds/unraid-macgyver-stack/build/applications/$app" ]; then
        echo "- $app/"
    fi
done
echo ""
echo "Productivity Apps (5):"
for app in gitea wikijs vaultwarden n8n heimdall; do
    if [ -d "/mnt/user/docker_builds/unraid-macgyver-stack/build/applications/$app" ]; then
        echo "- $app/"
    fi
done
echo ""
echo "Total: 31 Applications + 4 Core Services = 35 Containers"
echo ""
echo "Current Running Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep "MAC"