#!/bin/bash
# ============================================================================
# MKCERT CERTIFICATE GENERATION FOR UNRAID MACGYVER STACK
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env

PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"
CERT_DIR="$PROJECT_ROOT/certs"
MKCERT_VERSION="v1.4.4"

log_info() {
    echo -e "\033[0;34m[CERT]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Install mkcert if not present
install_mkcert() {
    if ! command -v mkcert &> /dev/null; then
        log_info "Installing mkcert..."
        
        # Download mkcert binary
        curl -L "https://github.com/FiloSottile/mkcert/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-linux-amd64" \
            -o /usr/local/bin/mkcert
        
        chmod +x /usr/local/bin/mkcert
        log_success "mkcert installed"
    else
        log_info "mkcert already installed"
    fi
}

# Generate certificates
generate_certificates() {
    mkdir -p "$CERT_DIR"
    cd "$CERT_DIR"
    
    # Install CA into system trust stores
    log_info "Installing mkcert CA..."
    mkcert -install
    
    # Copy CA certificate for container use
    cp "$(mkcert -CAROOT)/rootCA.pem" "$CERT_DIR/rootCA.pem"
    cp "$(mkcert -CAROOT)/rootCA-key.pem" "$CERT_DIR/rootCA-key.pem"
    
    # Generate wildcard certificate
    log_info "Generating wildcard certificate for *.${DOMAIN}..."
    mkcert -cert-file "_wildcard.${DOMAIN}.pem" \
           -key-file "_wildcard.${DOMAIN}-key.pem" \
           "*.${DOMAIN}" "${DOMAIN}" "localhost" "127.0.0.1" "::1"
    
    # Generate app-specific certificates
    local apps=(
        "vault" "traefik" "grafana" "prometheus" "loki"
        "prowlarr" "radarr" "sonarr" "lidarr" "readarr" "bazarr" "mylar3"
        "sabnzbd" "jdownloader2"
        "plex" "jellyfin" "emby"
        "tautulli" "overseerr" "notifiarr"
        "frigate" "unmanic" "stash" "resilio" "nginx-proxy-manager"
        "nextcloud" "grocy" "homebox" "filezilla" "cloudcommander" "homeassistant"
    )
    
    for app in "${apps[@]}"; do
        log_info "Generating certificate for ${app}.${DOMAIN}..."
        mkcert -cert-file "${app}.${DOMAIN}.pem" \
               -key-file "${app}.${DOMAIN}-key.pem" \
               "${app}.${DOMAIN}"
    done
    
    # Set permissions for Unraid
    chown -R 99:100 "$CERT_DIR"
    chmod -R 644 "$CERT_DIR"/*.pem
    chmod 600 "$CERT_DIR"/*-key.pem
    
    log_success "All certificates generated successfully"
}

# Create certificate configuration for Traefik
create_traefik_config() {
    cat > "$CERT_DIR/traefik-certs.yml" << EOF
tls:
  certificates:
    - certFile: /certs/_wildcard.${DOMAIN}.pem
      keyFile: /certs/_wildcard.${DOMAIN}-key.pem
      stores:
        - default
  stores:
    default:
      defaultCertificate:
        certFile: /certs/_wildcard.${DOMAIN}.pem
        keyFile: /certs/_wildcard.${DOMAIN}-key.pem
EOF
    
    log_success "Traefik certificate configuration created"
}

# Main execution
main() {
    log_info "Starting certificate generation..."
    
    install_mkcert
    generate_certificates
    create_traefik_config
    
    # Display certificate information
    log_info "Certificate Summary:"
    echo "  CA Certificate: $CERT_DIR/rootCA.pem"
    echo "  Wildcard Cert: $CERT_DIR/_wildcard.${DOMAIN}.pem"
    echo "  Total Certificates: $(ls -1 "$CERT_DIR"/*.pem | grep -v key | wc -l)"
    
    log_success "Certificate generation complete!"
}

main "$@"