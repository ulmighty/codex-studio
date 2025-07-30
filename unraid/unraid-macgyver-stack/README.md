# Unraid MacGyver Stack

A complete, automated 33-application deployment stack for Unraid with enterprise-grade security, centralized secrets management, and full automation.

## Overview

The Unraid MacGyver Stack provides:
- **33 applications** across media automation, monitoring, and productivity
- **Custom Docker images** built from only 4 base images (no pre-built app images)
- **Vault-centric secrets management** with bidirectional flow
- **Automatic SSL/TLS** for all services via Traefik
- **VPN protection** for indexer applications via Gluetun
- **Native Unraid integration** with XML templates

## Architecture

### Base Images Strategy
- `debian:bullseye-slim` - 18 apps (*arr suite, download clients, etc.)
- `alpine:latest` - 8 apps (Traefik, Prometheus, Grafana, etc.)
- `nvidia/cuda:12.3.1-runtime-ubuntu22.04` - 3 apps (Plex, Frigate, Unmanic)
- `php:8.3-fpm-alpine` - 4 apps (Nextcloud, Grocy, etc.)

### Core Infrastructure
1. **Vault** - Centralized secrets management
2. **Traefik** - Reverse proxy with automatic SSL
3. **Gluetun** - VPN gateway (NordVPN)
4. **PostgreSQL 17** - Centralized database

## Quick Start

### Prerequisites
- Unraid 7.0+
- Docker with Compose v2.39+
- 16GB+ RAM recommended
- SSD for appdata

### Installation

1. Clone to your Unraid server:
```bash
cd /mnt/user/docker_builds
git clone https://github.com/yourusername/unraid-macgyver-stack.git
cd unraid-macgyver-stack
```

2. Configure environment:
```bash
# Edit .env file with your settings
nano .env
```

3. Deploy everything:
```bash
./deploy.sh all
```

Or deploy stage by stage:
```bash
./deploy.sh stage1  # Research and analysis
./deploy.sh stage2  # Core infrastructure
./deploy.sh stage3  # Prepare applications
./deploy.sh stage4  # Deploy all apps
./deploy.sh stage5  # Configure integrations
```

## Application List

### Media Automation (VPN Protected)
- Prowlarr - Indexer management
- Radarr - Movie automation
- Sonarr - TV automation  
- Lidarr - Music automation
- Readarr - Book automation
- Bazarr - Subtitle automation
- Mylar3 - Comic automation

### Download Clients
- SABnzbd - Usenet downloader
- JDownloader2 - Direct downloads

### Media Servers
- Plex - Primary media server (GPU)
- Jellyfin - Open source alternative
- Emby - Alternative media server

### Monitoring & Analytics
- Prometheus - Metrics collection
- Grafana - Visualization
- Loki - Log aggregation
- Tautulli - Plex analytics
- Overseerr - Request management
- Notifiarr - Notifications

### Specialized Services
- Frigate - AI NVR (GPU)
- Unmanic - Transcoding (GPU)
- Stash - Media organization
- Resilio Sync - P2P sync
- Nginx Proxy Manager - Alternative proxy

### Productivity
- Nextcloud - Self-hosted cloud
- Grocy - Inventory management
- Homebox - Home inventory
- FileZilla - FTP client
- CloudCommander - File manager
- Home Assistant - Home automation

## Key Features

### Vault Integration
- All secrets stored in Vault
- Applications retrieve credentials FROM Vault
- Applications store API keys INTO Vault
- Automatic service discovery

### Security
- Non-root containers (PUID=99, PGID=100)
- Minimal attack surface
- Network isolation
- VPN protection for indexers

### Automation
- Zero manual configuration
- Automatic port assignment
- Service discovery via Vault
- SSL certificates via mkcert

## Access URLs

After deployment, access services at:
- `https://vault.ulmighty.local` - Vault UI
- `https://traefik.ulmighty.local` - Traefik dashboard
- `https://radarr.ulmighty.local` - Radarr
- `https://plex.ulmighty.local` - Plex
- etc.

## Troubleshooting

### Check deployment status:
```bash
./build/scripts/deploy-all-apps.sh status
```

### View container logs:
```bash
docker logs <container-name>-MAC
```

### Rebuild specific app:
```bash
./build/scripts/deploy-<appname>.sh
```

## Contributing

Pull requests welcome! Please follow the existing patterns:
- Custom Dockerfiles only (no pre-built images)
- Vault integration for all secrets
- Unraid XML template generation
- Comprehensive automation

## License

MIT License - See LICENSE file for details

## Credits

Created by Atlas - Expert Unraid & Docker Solutions Architect