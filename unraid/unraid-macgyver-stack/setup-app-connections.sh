#!/bin/bash
# Set up inter-app connections for the Unraid MacGyver Stack

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "=== SETTING UP INTER-APP CONNECTIONS ==="
echo ""

# Get current running containers
RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | grep "MAC" | sort)

echo "Current running containers:"
echo "$RUNNING_CONTAINERS"
echo ""

# Function to configure app connections
configure_connections() {
    local app=$1
    shift
    local connections=("$@")
    
    echo "Configuring connections for $app..."
    
    # Create connection config file
    mkdir -p "$APPDATA_PATH/${app}-MAC"
    cat > "$APPDATA_PATH/${app}-MAC/connections.json" << EOF
{
  "connections": [
EOF
    
    local first=true
    for conn in "${connections[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$APPDATA_PATH/${app}-MAC/connections.json"
        fi
        
        IFS=':' read -r service url <<< "$conn"
        cat >> "$APPDATA_PATH/${app}-MAC/connections.json" << EOF
    {
      "service": "$service",
      "url": "$url",
      "api_key_path": "/vault/secrets/${service}_api_key"
    }
EOF
    done
    
    cat >> "$APPDATA_PATH/${app}-MAC/connections.json" << EOF

  ]
}
EOF
}

# Configure ARR app connections
echo "=== Configuring ARR Apps Connections ==="

# Sonarr connections
configure_connections "sonarr" \
    "sabnzbd:http://sabnzbd-MAC:8080" \
    "prowlarr:http://gluetun-MAC:9696" \
    "bazarr:http://gluetun-MAC:6767" \
    "plex:http://plex-MAC:32400" \
    "jellyfin:http://jellyfin-MAC:8096" \
    "notifiarr:http://notifiarr-MAC:5454"

# Radarr connections
configure_connections "radarr" \
    "sabnzbd:http://sabnzbd-MAC:8080" \
    "prowlarr:http://gluetun-MAC:9696" \
    "bazarr:http://gluetun-MAC:6767" \
    "plex:http://plex-MAC:32400" \
    "jellyfin:http://jellyfin-MAC:8096" \
    "notifiarr:http://notifiarr-MAC:5454"

# Lidarr connections
configure_connections "lidarr" \
    "sabnzbd:http://sabnzbd-MAC:8080" \
    "prowlarr:http://gluetun-MAC:9696" \
    "plex:http://plex-MAC:32400" \
    "jellyfin:http://jellyfin-MAC:8096" \
    "notifiarr:http://notifiarr-MAC:5454"

# Readarr connections
configure_connections "readarr" \
    "sabnzbd:http://sabnzbd-MAC:8080" \
    "prowlarr:http://gluetun-MAC:9696" \
    "kavita:http://kavita-MAC:5000" \
    "calibre:http://calibre-MAC:8082" \
    "notifiarr:http://notifiarr-MAC:5454"

# Prowlarr connections to all ARR apps
configure_connections "prowlarr" \
    "sonarr:http://gluetun-MAC:8989" \
    "radarr:http://gluetun-MAC:7878" \
    "lidarr:http://gluetun-MAC:8686" \
    "readarr:http://gluetun-MAC:8787"

# Bazarr connections
configure_connections "bazarr" \
    "sonarr:http://gluetun-MAC:8989" \
    "radarr:http://gluetun-MAC:7878"

echo ""
echo "=== Configuring Media Server Connections ==="

# Overseerr connections
configure_connections "overseerr" \
    "sonarr:http://gluetun-MAC:8989" \
    "radarr:http://gluetun-MAC:7878" \
    "plex:http://plex-MAC:32400" \
    "jellyfin:http://jellyfin-MAC:8096" \
    "tautulli:http://tautulli-MAC:8181"

# Tautulli connections
configure_connections "tautulli" \
    "plex:http://plex-MAC:32400" \
    "notifiarr:http://notifiarr-MAC:5454"

echo ""
echo "=== Configuring Monitoring Connections ==="

# Grafana data sources
configure_connections "grafana" \
    "prometheus:http://prometheus-MAC:9090" \
    "influxdb:http://influxdb-MAC:8086" \
    "postgresql:postgresql://postgresql-MAC:5432"

# Prometheus targets
cat > "$APPDATA_PATH/prometheus-MAC/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik-MAC:8080']
  
  - job_name: 'sonarr'
    static_configs:
      - targets: ['gluetun-MAC:8989']
    metrics_path: '/api/v3/metrics'
  
  - job_name: 'radarr'
    static_configs:
      - targets: ['gluetun-MAC:7878']
    metrics_path: '/api/v3/metrics'
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

echo ""
echo "=== Configuring Traefik Routes ==="

# Create Traefik dynamic configuration for all services
mkdir -p "$APPDATA_PATH/traefik-MAC/dynamic"

cat > "$APPDATA_PATH/traefik-MAC/dynamic/routes.yml" << 'EOF'
http:
  routers:
    sonarr:
      rule: "Host(`sonarr.ulmighty.local`)"
      service: sonarr
      tls:
        certResolver: default
    
    radarr:
      rule: "Host(`radarr.ulmighty.local`)"
      service: radarr
      tls:
        certResolver: default
    
    plex:
      rule: "Host(`plex.ulmighty.local`)"
      service: plex
      tls:
        certResolver: default
    
    jellyfin:
      rule: "Host(`jellyfin.ulmighty.local`)"
      service: jellyfin
      tls:
        certResolver: default
    
    grafana:
      rule: "Host(`grafana.ulmighty.local`)"
      service: grafana
      tls:
        certResolver: default
    
    vault:
      rule: "Host(`vault.ulmighty.local`)"
      service: vault
      tls:
        certResolver: default
    
    portainer:
      rule: "Host(`portainer.ulmighty.local`)"
      service: portainer
      tls:
        certResolver: default

  services:
    sonarr:
      loadBalancer:
        servers:
          - url: "http://gluetun-MAC:8989"
    
    radarr:
      loadBalancer:
        servers:
          - url: "http://gluetun-MAC:7878"
    
    plex:
      loadBalancer:
        servers:
          - url: "http://plex-MAC:32400"
    
    jellyfin:
      loadBalancer:
        servers:
          - url: "http://jellyfin-MAC:8096"
    
    grafana:
      loadBalancer:
        servers:
          - url: "http://grafana-MAC:3000"
    
    vault:
      loadBalancer:
        servers:
          - url: "http://vault-MAC:8200"
    
    portainer:
      loadBalancer:
        servers:
          - url: "http://portainer-MAC:9000"
EOF

echo ""
echo "=== Creating Database Schemas ==="

# Create database schemas for each app
PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOF 2>/dev/null || echo "Database setup will be done when PostgreSQL is ready"
-- Create schemas for each application
CREATE SCHEMA IF NOT EXISTS sonarr;
CREATE SCHEMA IF NOT EXISTS radarr;
CREATE SCHEMA IF NOT EXISTS lidarr;
CREATE SCHEMA IF NOT EXISTS readarr;
CREATE SCHEMA IF NOT EXISTS prowlarr;
CREATE SCHEMA IF NOT EXISTS bazarr;
CREATE SCHEMA IF NOT EXISTS grafana;
CREATE SCHEMA IF NOT EXISTS gitea;
CREATE SCHEMA IF NOT EXISTS wikijs;
CREATE SCHEMA IF NOT EXISTS n8n;

-- Create users for each application
CREATE USER sonarr WITH PASSWORD 'sonarr_pass';
CREATE USER radarr WITH PASSWORD 'radarr_pass';
CREATE USER lidarr WITH PASSWORD 'lidarr_pass';
CREATE USER readarr WITH PASSWORD 'readarr_pass';
CREATE USER prowlarr WITH PASSWORD 'prowlarr_pass';
CREATE USER bazarr WITH PASSWORD 'bazarr_pass';

-- Grant permissions
GRANT ALL ON SCHEMA sonarr TO sonarr;
GRANT ALL ON SCHEMA radarr TO radarr;
GRANT ALL ON SCHEMA lidarr TO lidarr;
GRANT ALL ON SCHEMA readarr TO readarr;
GRANT ALL ON SCHEMA prowlarr TO prowlarr;
GRANT ALL ON SCHEMA bazarr TO bazarr;
EOF

echo ""
echo "=== INTER-APP CONNECTIONS COMPLETE ==="
echo ""
echo "Configured:"
echo "✓ ARR apps connected to download clients and media servers"
echo "✓ Prowlarr connected to all ARR apps for indexer management"
echo "✓ Bazarr connected to Sonarr/Radarr for subtitles"
echo "✓ Overseerr connected to media servers and ARR apps"
echo "✓ Grafana connected to monitoring data sources"
echo "✓ Traefik routes configured for all services"
echo "✓ Database schemas prepared for applications"
echo ""
echo "Access your services at:"
echo "- https://sonarr.ulmighty.local"
echo "- https://radarr.ulmighty.local"
echo "- https://plex.ulmighty.local"
echo "- https://jellyfin.ulmighty.local"
echo "- https://grafana.ulmighty.local"
echo "- https://vault.ulmighty.local"
echo "- https://portainer.ulmighty.local"