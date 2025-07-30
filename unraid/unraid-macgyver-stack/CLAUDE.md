# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Unraid MacGyver Stack is a comprehensive Docker-based application platform built from only 4 base images, designed for native Unraid integration. It implements 31+ applications with advanced VPN segmentation, centralized secrets management, and SSL termination.

## Core Architecture

### Base Image Strategy
All applications are built from exactly 4 base images:
- `debian:bullseye-slim` - For complex applications requiring full Linux environment
- `alpine:latest` - For lightweight services and infrastructure components  
- `nvidia/cuda:12.3.1-runtime-ubuntu22.04` - For GPU-accelerated applications
- `php:8.3-fpm-alpine` - For PHP-based web applications

### Network Architecture
- **Primary Network**: `macgyver-network-MAC` (172.25.0.0/16) for direct internet access
- **VPN Network**: Privacy-sensitive applications use `--network=container:gluetun-MAC` 
- **SSL Termination**: Traefik handles SSL with wildcard certificates for `*.ulmighty.local`

### Security Model
- **Vault Integration**: HashiCorp Vault manages all secrets with bidirectional flow
- **User Context**: All containers run as PUID=99, PGID=100 (Unraid standard)
- **Network Isolation**: VPN gateway (Gluetun) isolates indexer applications

## Key Commands

### Build System
```bash
# Build all applications from scratch
./build-all-from-scratch.sh

# Build specific application
docker build -t <app>-mac:latest ./build/applications/<app>/

# Deploy infrastructure first (required order)
./deploy-infrastructure.sh
./deploy-applications.sh
```

### Container Management
```bash
# Check network connectivity and VPN status
./scripts/check-network-status.sh

# View logs for VPN-routed containers
docker logs gluetun-MAC  # Check VPN status first
docker logs <app>-MAC

# Monitor container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### SSL and Certificates
```bash
# Generate local SSL certificates
mkcert -install
mkcert "*.ulmighty.local" localhost 127.0.0.1 ::1

# Deploy certificates to Traefik
cp ./*.pem /mnt/user/appdata/traefik-MAC/certificates/
```

## Application Categories & Deployment

### Infrastructure (Deploy First)
1. **vault-MAC** - Secrets management (Port 8200)
2. **traefik-MAC** - SSL termination/reverse proxy (Ports 80, 443, 8079)
3. **gluetun-MAC** - VPN gateway for privacy applications
4. **postgresql-MAC** - Centralized database (Port 5432)

### VPN-Routed Applications (Privacy-Critical)
Applications that use `--network=container:gluetun-MAC`:
- **prowlarr-MAC** - Indexer management
- **sonarr-MAC** - TV series automation  
- **radarr-MAC** - Movie automation
- **bazarr-MAC** - Subtitle management
- **sabnzbd-MAC** - Usenet downloader

### Direct Network Applications
Management and media serving applications on `macgyver-network-MAC`:
- **portainer-MAC** - Container management (Port 9001)
- **grafana-MAC** - Analytics dashboard (Port 3001)
- **tautulli-MAC** - Plex statistics (Port 8181)

## Configuration Patterns

### Dockerfile Template System
The build system uses template functions for consistency:
```bash
# Standard application build pattern
FROM debian:bullseye-slim AS builder
# Download and build application
FROM debian:bullseye-slim
# Runtime configuration with Unraid user/group setup
```

### XML Template Structure
Unraid integration requires specific XML template format:
```xml
<Container version="2">
  <Name>app-MAC</Name>
  <Repository>app-mac:latest</Repository>
  <Network>macgyver-network-MAC</Network>
  <Icon>https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/svg/app.svg</Icon>
  <!-- Environment, ports, volumes -->
</Container>
```

### Environment Variables
Standard environment variables for all containers:
- `PUID=99` - Unraid user ID
- `PGID=100` - Unraid group ID  
- `TZ=America/Chicago` - Timezone
- Application-specific variables for API keys, database connections

## Port Management

### Reserved Ports
- **8080, 8443** - Unraid GUI (HTTP/HTTPS)
- **80, 443** - Traefik public SSL termination
- **8079** - Traefik dashboard

### Application Port Ranges
- **8000-8099** - Infrastructure and management
- **8200-8299** - Security and databases
- **8900-8999** - Media management applications
- **9000-9099** - Monitoring and analytics

## VPN Integration

### Gluetun Configuration
Key environment variables:
- `VPN_SERVICE_PROVIDER=surfshark`
- `OPENVPN_USER` and `OPENVPN_PASSWORD` from Vault
- `FIREWALL_OUTBOUND_SUBNETS=172.25.0.0/16` - Allow local network

### VPN-Dependent Deployments
Applications using VPN must wait for Gluetun readiness:
```bash
# Check VPN status before deploying dependent containers  
docker exec gluetun-MAC sh -c 'curl -s ifconfig.me' || echo "VPN not ready"
```

## Vault Integration

### Secret Storage Patterns
- API keys stored as `secret/data/<application>/config`
- Database credentials in `secret/data/databases/<service>`
- VPN credentials in `secret/data/vpn/gluetun`

### Vault Agent Sidecar
Some applications use Vault Agent for automatic secret injection:
```bash
# Template for secret injection
vault kv put secret/<app>/config api_key="generated_key_value"
```

## Troubleshooting

### Common Issues
1. **VPN Connectivity**: Check Gluetun logs and test external IP
2. **Port Conflicts**: Verify no overlap with Unraid ports 8080/8443
3. **SSL Issues**: Ensure certificates exist in Traefik volume
4. **Container Startup**: Check user permissions (PUID/PGID) and volume ownership

### Debugging Commands
```bash
# Test VPN routing
docker exec gluetun-MAC curl -s ifconfig.me

# Check Vault connectivity  
docker exec vault-MAC vault status

# View Traefik routes
docker exec traefik-MAC cat /etc/traefik/dynamic/routes.yml

# Monitor container logs
docker logs --follow <container>-MAC
```

## Development Workflow

### Adding New Applications
1. Create Dockerfile in `build/applications/<app>/`
2. Build image: `docker build -t <app>-mac:latest ./build/applications/<app>/`
3. Create XML template in `templates/<app>-MAC.xml`
4. Copy template to `/boot/config/plugins/dockerMan/templates-user/`
5. Deploy via Unraid Docker tab or direct Docker command

### SSL Certificate Management
- Certificates auto-renew via Traefik Let's Encrypt integration
- Local development uses mkcert for `*.ulmighty.local` domain
- Production requires valid domain and DNS configuration

This architecture provides a secure, scalable, and maintainable platform for self-hosted applications with enterprise-grade secret management and network isolation.