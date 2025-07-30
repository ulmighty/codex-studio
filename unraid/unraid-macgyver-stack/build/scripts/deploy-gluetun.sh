#!/bin/bash
# ============================================================================
# GLUETUN VPN DEPLOYMENT SCRIPT
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

GLUETUN_IMAGE="gluetun-mac:latest"
CONTAINER_NAME="gluetun-MAC"
VPN_NETWORK="vpn-network-MAC"

log_info() {
    echo -e "\033[0;34m[GLUETUN]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Build Gluetun image
build_gluetun() {
    log_info "Building Gluetun Docker image..."
    
    cd "$PROJECT_ROOT/build/applications/gluetun"
    
    docker build \
        --build-arg GLUETUN_VERSION=v3.38.0 \
        --build-arg PUID=$PUID \
        --build-arg PGID=$PGID \
        -t "$GLUETUN_IMAGE" \
        .
    
    log_success "Gluetun image built successfully"
}

# Create VPN network for dependent containers
create_vpn_network() {
    log_info "Creating VPN network..."
    
    if ! docker network inspect "$VPN_NETWORK" &> /dev/null; then
        docker network create \
            --driver bridge \
            --subnet 172.26.0.0/16 \
            --gateway 172.26.0.1 \
            --opt com.docker.network.bridge.name="br-vpn-mac" \
            "$VPN_NETWORK"
        log_success "VPN network created"
    else
        log_info "VPN network already exists"
    fi
}

# Deploy Gluetun container
deploy_gluetun() {
    log_info "Deploying Gluetun container..."
    
    # Stop and remove existing container if present
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    
    # Create necessary directories
    mkdir -p "$APPDATA_PATH/gluetun-MAC"
    
    # Set permissions
    chown -R $PUID:$PGID "$APPDATA_PATH/gluetun-MAC"
    
    # Port mappings for VPN-routed applications
    local port_mappings=(
        "-p 9117:9117"    # Prowlarr
        "-p 8989:8989"    # Sonarr
        "-p 7878:7878"    # Radarr
        "-p 8686:8686"    # Lidarr
        "-p 8787:8787"    # Readarr
        "-p 6767:6767"    # Bazarr
        "-p 8090:8090"    # Mylar3
    )
    
    # Run Gluetun container
    docker run -d \
        --name="$CONTAINER_NAME" \
        --hostname="gluetun" \
        --network="$NETWORK_NAME" \
        --restart="unless-stopped" \
        --cap-add NET_ADMIN \
        --device /dev/net/tun \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TIMEZONE" \
        -e VPN_SERVICE_PROVIDER="nordvpn" \
        -e VPN_TYPE="openvpn" \
        -e OPENVPN_USER="$NORDVPN_USERNAME" \
        -e OPENVPN_PASSWORD="$NORDVPN_PASSWORD" \
        -e SERVER_COUNTRIES="$NORDVPN_COUNTRY" \
        -e SERVER_HOSTNAMES="$NORDVPN_SERVER" \
        -e SERVER_CATEGORIES="$NORDVPN_CATEGORIES" \
        -e OPENVPN_VERSION="2.6" \
        -e OPENVPN_PROTOCOL="$NORDVPN_OPENVPN_PROTOCOL" \
        -e FIREWALL="on" \
        -e FIREWALL_VPN_INPUT_PORTS="9117,8989,7878,8686,8787,6767,8090" \
        -e FIREWALL_OUTBOUND_SUBNETS="$VPN_FIREWALL_OUTBOUND_SUBNETS" \
        -e DOT="on" \
        -e DOT_PROVIDERS="cloudflare" \
        -e BLOCK_MALICIOUS="on" \
        -e BLOCK_SURVEILLANCE="on" \
        -e BLOCK_ADS="off" \
        -e HTTPPROXY="on" \
        -e HTTPPROXY_LOG="on" \
        -e SHADOWSOCKS="on" \
        -e UPDATER_PERIOD="24h" \
        -e HEALTH_VPN_DURATION_INITIAL="30s" \
        -e HEALTH_VPN_DURATION_ADDITION="10s" \
        -e LOG_LEVEL="info" \
        ${port_mappings[@]} \
        -v "$APPDATA_PATH/gluetun-MAC:/gluetun:rw" \
        --label="net.unraid.docker.managed=dockerman" \
        --label="net.unraid.docker.icon=https://avatars.githubusercontent.com/u/48880220?s=400&v=4" \
        --label="net.unraid.docker.webui=http://[IP]:[PORT:8000]/v1/openvpn/status" \
        --label="traefik.enable=false" \
        "$GLUETUN_IMAGE"
    
    log_success "Gluetun container deployed"
}

# Test VPN connectivity
test_vpn() {
    log_info "Testing VPN connectivity..."
    
    # Wait for container to start
    sleep 10
    
    # Check VPN status
    local vpn_status=$(docker exec "$CONTAINER_NAME" wget -qO- https://ipinfo.io/json 2>/dev/null || echo "{}")
    
    if echo "$vpn_status" | jq -r '.country' | grep -qv "US\|null"; then
        log_success "VPN connected successfully"
        echo "  External IP: $(echo "$vpn_status" | jq -r '.ip')"
        echo "  Location: $(echo "$vpn_status" | jq -r '.city'), $(echo "$vpn_status" | jq -r '.country')"
    else
        log_error "VPN connection may have issues"
    fi
}

# Generate Unraid XML template
generate_xml_template() {
    log_info "Generating Unraid XML template..."
    
    cat > "$PROJECT_ROOT/xml-templates/gluetun-MAC.xml" << EOF
<?xml version="1.0"?>
<Container version="2">
  <Name>gluetun-MAC</Name>
  <Repository>gluetun-mac:latest</Repository>
  <Registry/>
  <Network>$NETWORK_NAME</Network>
  <MyIP/>
  <Shell>sh</Shell>
  <Privileged>false</Privileged>
  <Support>https://github.com/qdm12/gluetun</Support>
  <Project>https://github.com/qdm12/gluetun</Project>
  <Overview>Gluetun - VPN client for multiple providers (NordVPN configured) for Unraid MacGyver Stack</Overview>
  <Category>Network:VPN</Category>
  <WebUI/>
  <TemplateURL/>
  <Icon>https://avatars.githubusercontent.com/u/48880220?s=400&v=4</Icon>
  <ExtraParams>--cap-add NET_ADMIN --device /dev/net/tun --sysctl net.ipv6.conf.all.disable_ipv6=0</ExtraParams>
  <PostArgs/>
  <CPUset/>
  <DateInstalled>$(date +%s)</DateInstalled>
  <DonateText/>
  <DonateLink/>
  <Requires/>
  <Config Name="Prowlarr Port" Target="9117" Default="9117" Mode="tcp" Description="Prowlarr WebUI" Type="Port" Display="always" Required="true" Mask="false">9117</Config>
  <Config Name="Sonarr Port" Target="8989" Default="8989" Mode="tcp" Description="Sonarr WebUI" Type="Port" Display="always" Required="true" Mask="false">8989</Config>
  <Config Name="Radarr Port" Target="7878" Default="7878" Mode="tcp" Description="Radarr WebUI" Type="Port" Display="always" Required="true" Mask="false">7878</Config>
  <Config Name="Lidarr Port" Target="8686" Default="8686" Mode="tcp" Description="Lidarr WebUI" Type="Port" Display="always" Required="true" Mask="false">8686</Config>
  <Config Name="Readarr Port" Target="8787" Default="8787" Mode="tcp" Description="Readarr WebUI" Type="Port" Display="always" Required="true" Mask="false">8787</Config>
  <Config Name="Bazarr Port" Target="6767" Default="6767" Mode="tcp" Description="Bazarr WebUI" Type="Port" Display="always" Required="true" Mask="false">6767</Config>
  <Config Name="Mylar3 Port" Target="8090" Default="8090" Mode="tcp" Description="Mylar3 WebUI" Type="Port" Display="always" Required="true" Mask="false">8090</Config>
  <Config Name="Config" Target="/gluetun" Default="/mnt/user/appdata/gluetun-MAC" Mode="rw" Description="Configuration storage" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/gluetun-MAC</Config>
  <Config Name="VPN Provider" Target="VPN_SERVICE_PROVIDER" Default="nordvpn" Mode="" Description="VPN service provider" Type="Variable" Display="always" Required="true" Mask="false">nordvpn</Config>
  <Config Name="NordVPN Username" Target="OPENVPN_USER" Default="" Mode="" Description="NordVPN username" Type="Variable" Display="always" Required="true" Mask="false">$NORDVPN_USERNAME</Config>
  <Config Name="NordVPN Password" Target="OPENVPN_PASSWORD" Default="" Mode="" Description="NordVPN password" Type="Variable" Display="always" Required="true" Mask="true">$NORDVPN_PASSWORD</Config>
  <Config Name="Server Country" Target="SERVER_COUNTRIES" Default="United States" Mode="" Description="VPN server country" Type="Variable" Display="always" Required="false" Mask="false">$NORDVPN_COUNTRY</Config>
  <Config Name="Server Hostname" Target="SERVER_HOSTNAMES" Default="" Mode="" Description="Specific VPN server" Type="Variable" Display="advanced" Required="false" Mask="false">$NORDVPN_SERVER</Config>
  <Config Name="PUID" Target="PUID" Default="99" Mode="" Description="User ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PUID</Config>
  <Config Name="PGID" Target="PGID" Default="100" Mode="" Description="Group ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PGID</Config>
  <Config Name="Timezone" Target="TZ" Default="America/New_York" Mode="" Description="Timezone" Type="Variable" Display="advanced" Required="false" Mask="false">$TIMEZONE</Config>
</Container>
EOF
    
    log_success "XML template generated"
}

# Main execution
main() {
    log_info "Starting Gluetun deployment..."
    
    build_gluetun
    create_vpn_network
    deploy_gluetun
    test_vpn
    generate_xml_template
    
    # Display container logs
    log_info "Container logs:"
    docker logs "$CONTAINER_NAME" --tail 20
    
    log_success "Gluetun deployment complete!"
    echo "  VPN Gateway ready for dependent applications"
    echo "  Network: $VPN_NETWORK"
}

main "$@"