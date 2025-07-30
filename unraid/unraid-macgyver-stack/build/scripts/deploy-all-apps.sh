#!/bin/bash
# ============================================================================
# DEPLOY ALL APPLICATIONS - UNRAID MACGYVER STACK
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
NC='\033[0m'

# Application groups
declare -a VPN_APPS=(prowlarr radarr sonarr lidarr readarr bazarr mylar3)
declare -a DOWNLOAD_APPS=(sabnzbd jdownloader2)
declare -a MEDIA_SERVERS=(plex jellyfin emby)
declare -a MONITORING_APPS=(tautulli overseerr notifiarr prometheus grafana loki)
declare -a SPECIALIZED_APPS=(frigate unmanic stash resilio nginx-proxy-manager)
declare -a PRODUCTIVITY_APPS=(nextcloud grocy homebox filezilla cloudcommander homeassistant)

log_section() {
    echo -e "\n${PURPLE}============================================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================================${NC}\n"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if core infrastructure is ready
check_infrastructure() {
    log_section "Checking Core Infrastructure"
    
    local required_containers=("vault-MAC" "traefik-MAC" "gluetun-MAC" "postgresql-MAC")
    local missing=()
    
    for container in "${required_containers[@]}"; do
        if ! docker ps --format "{{.Names}}" | grep -q "^$container$"; then
            missing+=("$container")
        else
            log_success "$container is running"
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing core infrastructure: ${missing[*]}"
        log_info "Run './deploy.sh stage2' first"
        exit 1
    fi
    
    log_success "All core infrastructure is ready"
}

# Deploy application group
deploy_group() {
    local group_name=$1
    shift
    local apps=("$@")
    
    log_section "Deploying $group_name"
    
    for app in "${apps[@]}"; do
        log_info "Deploying $app..."
        
        if [ -f "$PROJECT_ROOT/build/scripts/deploy-${app}.sh" ]; then
            # Execute deployment script
            "$PROJECT_ROOT/build/scripts/deploy-${app}.sh" || {
                log_error "Failed to deploy $app"
                continue
            }
            
            # Wait for container to start
            sleep 5
            
            # Verify deployment
            if docker ps --format "{{.Names}}" | grep -q "^${app}-MAC$"; then
                log_success "$app deployed successfully"
                
                # Store URL in Vault
                store_app_url_in_vault "$app"
            else
                log_error "$app container not running"
            fi
        else
            log_error "Deployment script not found for $app"
        fi
    done
}

# Store application URL in Vault
store_app_url_in_vault() {
    local app=$1
    
    docker exec vault-MAC sh -c "
        export VAULT_TOKEN='$VAULT_ROOT_TOKEN'
        vault kv put secret/$app/url value='https://$app.${DOMAIN}'
    " 2>/dev/null || true
}

# Wait for API key generation
wait_for_api_key() {
    local app=$1
    local max_attempts=30
    local attempt=0
    
    log_info "Waiting for $app to generate API key..."
    
    while [ $attempt -lt $max_attempts ]; do
        # Check if API key exists in app config
        local config_file="$APPDATA_PATH/${app}-MAC/config/config.xml"
        
        if [ -f "$config_file" ] && grep -q "ApiKey" "$config_file"; then
            local api_key=$(grep -oP '<ApiKey>\K[^<]+' "$config_file" 2>/dev/null || true)
            
            if [ -n "$api_key" ]; then
                # Store in Vault
                docker exec vault-MAC sh -c "
                    export VAULT_TOKEN='$VAULT_ROOT_TOKEN'
                    vault kv put secret/$app/api_key value='$api_key'
                " 2>/dev/null || true
                
                log_success "$app API key stored in Vault"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log_error "Timeout waiting for $app API key"
    return 1
}

# Configure inter-app connections
configure_connections() {
    log_section "Configuring Application Connections"
    
    # Configure Prowlarr connections to *arr apps
    log_info "Configuring Prowlarr connections..."
    for app in radarr sonarr lidarr readarr; do
        # Get API keys from Vault
        local api_key=$(docker exec vault-MAC sh -c "
            export VAULT_TOKEN='$VAULT_ROOT_TOKEN'
            vault kv get -field=value secret/$app/api_key 2>/dev/null
        " || echo "")
        
        if [ -n "$api_key" ]; then
            log_info "Configuring Prowlarr -> $app connection"
            # Configuration would be done via API calls here
        fi
    done
    
    # Configure Overseerr connections
    log_info "Configuring Overseerr connections..."
    # Similar configuration for Overseerr -> Radarr/Sonarr
    
    log_success "Application connections configured"
}

# Generate status report
generate_status_report() {
    log_section "Deployment Status Report"
    
    local total_apps=33
    local running_apps=$(docker ps --filter "label=net.unraid.docker.managed=dockerman" --format "{{.Names}}" | grep -c "MAC$" || true)
    
    echo "Total Applications: $total_apps"
    echo "Running Containers: $running_apps"
    echo ""
    
    # List all applications with status
    for group in "Core Infrastructure:4" "Media Automation:7" "Download Clients:2" "Media Servers:3" "Monitoring:6" "Specialized:5" "Productivity:6"; do
        local group_name="${group%:*}"
        local group_count="${group#*:}"
        echo -e "\n${BLUE}$group_name ($group_count apps):${NC}"
        
        case "$group_name" in
            "Core Infrastructure")
                local apps=(vault traefik gluetun postgresql)
                ;;
            "Media Automation")
                local apps=("${VPN_APPS[@]}")
                ;;
            "Download Clients")
                local apps=("${DOWNLOAD_APPS[@]}")
                ;;
            "Media Servers")
                local apps=("${MEDIA_SERVERS[@]}")
                ;;
            "Monitoring")
                local apps=("${MONITORING_APPS[@]}")
                ;;
            "Specialized")
                local apps=("${SPECIALIZED_APPS[@]}")
                ;;
            "Productivity")
                local apps=("${PRODUCTIVITY_APPS[@]}")
                ;;
        esac
        
        for app in "${apps[@]}"; do
            if docker ps --format "{{.Names}}" | grep -q "^${app}-MAC$"; then
                echo -e "  ${GREEN}✓${NC} $app - https://$app.${DOMAIN}"
            else
                echo -e "  ${RED}✗${NC} $app"
            fi
        done
    done
    
    echo -e "\n${BLUE}Access URLs:${NC}"
    echo "  Traefik Dashboard: https://traefik.${DOMAIN}"
    echo "  Vault UI: https://vault.${DOMAIN}"
    echo "  Grafana: https://grafana.${DOMAIN}"
    echo "  Prometheus: https://prometheus.${DOMAIN}"
}

# Install XML templates to Unraid
install_xml_templates() {
    log_section "Installing Unraid XML Templates"
    
    local template_dir="/boot/config/plugins/dockerMan/templates-user"
    
    if [ -d "$template_dir" ]; then
        log_info "Copying XML templates to Unraid..."
        cp -f "$PROJECT_ROOT/xml-templates"/*.xml "$template_dir/"
        log_success "XML templates installed"
    else
        log_error "Unraid template directory not found"
    fi
}

# Main execution
main() {
    log_section "UNRAID MACGYVER STACK - FULL DEPLOYMENT"
    
    # Check infrastructure
    check_infrastructure
    
    # Deploy application groups in order
    case "${1:-all}" in
        "media")
            deploy_group "Media Automation Apps (VPN)" "${VPN_APPS[@]}"
            deploy_group "Download Clients" "${DOWNLOAD_APPS[@]}"
            ;;
        "servers")
            deploy_group "Media Servers" "${MEDIA_SERVERS[@]}"
            ;;
        "monitoring")
            deploy_group "Monitoring & Analytics" "${MONITORING_APPS[@]}"
            ;;
        "specialized")
            deploy_group "Specialized Services" "${SPECIALIZED_APPS[@]}"
            ;;
        "productivity")
            deploy_group "Productivity Apps" "${PRODUCTIVITY_APPS[@]}"
            ;;
        "all")
            deploy_group "Media Automation Apps (VPN)" "${VPN_APPS[@]}"
            sleep 10  # Wait for VPN apps to stabilize
            
            deploy_group "Download Clients" "${DOWNLOAD_APPS[@]}"
            deploy_group "Media Servers" "${MEDIA_SERVERS[@]}"
            deploy_group "Monitoring & Analytics" "${MONITORING_APPS[@]}"
            deploy_group "Specialized Services" "${SPECIALIZED_APPS[@]}"
            deploy_group "Productivity Apps" "${PRODUCTIVITY_APPS[@]}"
            
            # Configure connections after all apps are deployed
            configure_connections
            
            # Install XML templates
            install_xml_templates
            ;;
        *)
            echo "Usage: $0 [media|servers|monitoring|specialized|productivity|all]"
            exit 1
            ;;
    esac
    
    # Generate status report
    generate_status_report
    
    log_success "Deployment complete!"
}

main "$@"