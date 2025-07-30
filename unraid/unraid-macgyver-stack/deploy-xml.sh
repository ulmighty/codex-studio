#!/bin/bash
# ============================================================================
# UNRAID MACGYVER STACK - XML TEMPLATE DEPLOYMENT
# ============================================================================
# Deploy containers using Unraid XML templates (no Docker Compose)
# All containers built from scratch using only 4 base images
# ============================================================================

echo "🚀 UNRAID MACGYVER STACK - XML DEPLOYMENT STARTING"
echo "=================================================="

# Ensure network exists
echo "📡 Creating MacGyver network..."
docker network create macgyver-network-MAC --driver bridge 2>/dev/null || echo "Network already exists"

# Ensure required directories exist
echo "📁 Creating required directories..."
mkdir -p /mnt/user/appdata/{vault-MAC,traefik-MAC,sonarr-MAC,radarr-MAC,prowlarr-MAC,grafana-MAC,portainer-MAC}
mkdir -p /mnt/user/media/{tv,movies,music,books}
mkdir -p /mnt/user/downloads

# Set proper ownership
echo "🔒 Setting directory permissions..."
chown -R 99:100 /mnt/user/appdata/vault-MAC /mnt/user/appdata/traefik-MAC /mnt/user/appdata/sonarr-MAC /mnt/user/appdata/radarr-MAC /mnt/user/appdata/prowlarr-MAC /mnt/user/appdata/grafana-MAC /mnt/user/appdata/portainer-MAC 2>/dev/null || echo "Permission setting attempted"

echo ""
echo "✅ DEPLOYMENT PREPARATION COMPLETE"
echo ""
echo "📋 NEXT STEPS:"
echo "1. Go to Unraid Docker tab"
echo "2. Click 'Add Container'"
echo "3. Select from Template dropdown:"
echo "   - vault-MAC (Deploy first - Core infrastructure)"
echo "   - traefik-MAC (Deploy second - Reverse proxy)"
echo "   - sonarr-MAC (Media management)"
echo "   - radarr-MAC (Movie management)"
echo "   - prowlarr-MAC (Indexer management)"
echo "   - grafana-MAC (Monitoring)"
echo "   - portainer-MAC (Container management)"
echo ""
echo "🎯 ALL TEMPLATES READY FOR UNRAID DOCKER TAB DEPLOYMENT!"
echo "🌎 Timezone: America/Chicago"
echo "🔧 Network: macgyver-network-MAC"
echo "📦 All built from 4 base images only"
echo ""