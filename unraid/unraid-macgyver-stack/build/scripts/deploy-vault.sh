#!/bin/bash
# ============================================================================
# VAULT DEPLOYMENT SCRIPT
# ============================================================================

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

VAULT_IMAGE="vault-mac:latest"
CONTAINER_NAME="vault-MAC"
VAULT_PORT=8200

log_info() {
    echo -e "\033[0;34m[VAULT]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Build Vault image
build_vault() {
    log_info "Building Vault Docker image..."
    
    cd "$PROJECT_ROOT/build/applications/vault"
    
    docker build \
        --build-arg VAULT_VERSION=1.15.4 \
        --build-arg PUID=$PUID \
        --build-arg PGID=$PGID \
        -t "$VAULT_IMAGE" \
        .
    
    log_success "Vault image built successfully"
}

# Deploy Vault container
deploy_vault() {
    log_info "Deploying Vault container..."
    
    # Stop and remove existing container if present
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    
    # Create necessary directories
    mkdir -p "$APPDATA_PATH/vault-MAC"/{data,logs,config,file,policies,audit}
    
    # Copy configuration
    cp "$PROJECT_ROOT/build/applications/vault/config.hcl" "$APPDATA_PATH/vault-MAC/config/"
    
    # Set permissions
    chown -R $PUID:$PGID "$APPDATA_PATH/vault-MAC"
    
    # Run Vault container
    docker run -d \
        --name="$CONTAINER_NAME" \
        --hostname="vault" \
        --network="$NETWORK_NAME" \
        --restart="unless-stopped" \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TIMEZONE" \
        -e VAULT_DEV_MODE="$VAULT_DEV_MODE" \
        -e VAULT_DEV_ROOT_TOKEN_ID="$VAULT_DEV_ROOT_TOKEN_ID" \
        -e VAULT_API_ADDR="http://vault.${DOMAIN}:8200" \
        -e VAULT_LOG_LEVEL="info" \
        -p "${VAULT_PORT}:8200" \
        -v "$APPDATA_PATH/vault-MAC/data:/vault/data:rw" \
        -v "$APPDATA_PATH/vault-MAC/logs:/vault/logs:rw" \
        -v "$APPDATA_PATH/vault-MAC/config:/vault/config:rw" \
        -v "$APPDATA_PATH/vault-MAC/file:/vault/file:rw" \
        -v "$APPDATA_PATH/vault-MAC/policies:/vault/policies:ro" \
        -v "$APPDATA_PATH/vault-MAC/audit:/vault/audit:rw" \
        --cap-add IPC_LOCK \
        --label="net.unraid.docker.managed=dockerman" \
        --label="net.unraid.docker.icon=https://seeklogo.com/images/H/hashicorp-vault-logo-6A9D1F1A5C-seeklogo.com.png" \
        --label="net.unraid.docker.webui=http://[IP]:[PORT:8200]" \
        --label="traefik.enable=true" \
        --label="traefik.http.routers.vault.rule=Host(\`vault.${DOMAIN}\`)" \
        --label="traefik.http.routers.vault.entrypoints=websecure" \
        --label="traefik.http.routers.vault.tls=true" \
        --label="traefik.http.services.vault.loadbalancer.server.port=8200" \
        "$VAULT_IMAGE"
    
    log_success "Vault container deployed"
}

# Initialize Vault
initialize_vault() {
    if [ "$VAULT_DEV_MODE" = "true" ]; then
        log_info "Vault running in dev mode - skipping initialization"
        return
    fi
    
    log_info "Waiting for Vault to start..."
    sleep 5
    
    # Check if already initialized
    if docker exec "$CONTAINER_NAME" vault status 2>&1 | grep -q "Initialized.*true"; then
        log_info "Vault already initialized"
        return
    fi
    
    log_info "Initializing Vault..."
    
    # Initialize with 3 key shares, threshold of 2
    local init_output=$(docker exec "$CONTAINER_NAME" vault operator init \
        -key-shares=3 \
        -key-threshold=2 \
        -format=json)
    
    # Save initialization data
    echo "$init_output" > "$APPDATA_PATH/vault-MAC/vault-init.json"
    chmod 600 "$APPDATA_PATH/vault-MAC/vault-init.json"
    
    log_success "Vault initialized. Keys saved to vault-init.json"
    log_error "CRITICAL: Backup vault-init.json immediately and store securely!"
}

# Create initial policies and enable engines
configure_vault() {
    log_info "Configuring Vault..."
    
    local vault_addr="http://localhost:$VAULT_PORT"
    local vault_token="$VAULT_ROOT_TOKEN"
    
    # Wait for Vault to be ready
    until docker exec "$CONTAINER_NAME" vault status &>/dev/null; do
        log_info "Waiting for Vault to be ready..."
        sleep 2
    done
    
    # Enable KV v2 secrets engine
    docker exec -e VAULT_TOKEN="$vault_token" "$CONTAINER_NAME" \
        vault secrets enable -path=secret kv-v2 || true
    
    # Enable AppRole auth
    docker exec -e VAULT_TOKEN="$vault_token" "$CONTAINER_NAME" \
        vault auth enable approle || true
    
    # Create admin policy
    cat > "$APPDATA_PATH/vault-MAC/policies/admin.hcl" << 'EOF'
# Admin policy - full access
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
    
    # Create base application policy template
    cat > "$APPDATA_PATH/vault-MAC/policies/app-template.hcl" << 'EOF'
# Application policy template
path "secret/data/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/{{identity.entity.name}}/*" {
  capabilities = ["list", "read"]
}

# Allow apps to write their own API keys and URLs
path "secret/data/{{identity.entity.name}}/api_key" {
  capabilities = ["create", "update", "read"]
}

path "secret/data/{{identity.entity.name}}/url" {
  capabilities = ["create", "update", "read"]
}

# Read global secrets
path "secret/data/global/*" {
  capabilities = ["read"]
}
EOF
    
    log_success "Vault configuration complete"
}

# Generate Unraid XML template
generate_xml_template() {
    log_info "Generating Unraid XML template..."
    
    cat > "$PROJECT_ROOT/xml-templates/vault-MAC.xml" << EOF
<?xml version="1.0"?>
<Container version="2">
  <Name>vault-MAC</Name>
  <Repository>vault-mac:latest</Repository>
  <Registry/>
  <Network>$NETWORK_NAME</Network>
  <MyIP/>
  <Shell>sh</Shell>
  <Privileged>false</Privileged>
  <Support>https://github.com/hashicorp/vault</Support>
  <Project>https://www.vaultproject.io/</Project>
  <Overview>HashiCorp Vault - Centralized secrets management for Unraid MacGyver Stack</Overview>
  <Category>Security: Tools:</Category>
  <WebUI>http://[IP]:[PORT:8200]</WebUI>
  <TemplateURL/>
  <Icon>https://seeklogo.com/images/H/hashicorp-vault-logo-6A9D1F1A5C-seeklogo.com.png</Icon>
  <ExtraParams>--cap-add IPC_LOCK</ExtraParams>
  <PostArgs/>
  <CPUset/>
  <DateInstalled>$(date +%s)</DateInstalled>
  <DonateText/>
  <DonateLink/>
  <Requires/>
  <Config Name="Web UI Port" Target="8200" Default="8200" Mode="tcp" Description="Vault API/UI port" Type="Port" Display="always" Required="true" Mask="false">$VAULT_PORT</Config>
  <Config Name="AppData" Target="/vault/data" Default="/mnt/user/appdata/vault-MAC/data" Mode="rw" Description="Vault data storage" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/vault-MAC/data</Config>
  <Config Name="Logs" Target="/vault/logs" Default="/mnt/user/appdata/vault-MAC/logs" Mode="rw" Description="Vault logs" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/vault-MAC/logs</Config>
  <Config Name="Config" Target="/vault/config" Default="/mnt/user/appdata/vault-MAC/config" Mode="rw" Description="Vault configuration" Type="Path" Display="always" Required="true" Mask="false">$APPDATA_PATH/vault-MAC/config</Config>
  <Config Name="Dev Mode" Target="VAULT_DEV_MODE" Default="false" Mode="" Description="Run in development mode" Type="Variable" Display="advanced" Required="false" Mask="false">$VAULT_DEV_MODE</Config>
  <Config Name="Dev Root Token" Target="VAULT_DEV_ROOT_TOKEN_ID" Default="" Mode="" Description="Dev mode root token" Type="Variable" Display="advanced" Required="false" Mask="true">$VAULT_DEV_ROOT_TOKEN_ID</Config>
  <Config Name="PUID" Target="PUID" Default="99" Mode="" Description="User ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PUID</Config>
  <Config Name="PGID" Target="PGID" Default="100" Mode="" Description="Group ID" Type="Variable" Display="advanced" Required="false" Mask="false">$PGID</Config>
  <Config Name="Timezone" Target="TZ" Default="America/New_York" Mode="" Description="Timezone" Type="Variable" Display="advanced" Required="false" Mask="false">$TIMEZONE</Config>
</Container>
EOF
    
    log_success "XML template generated"
}

# Main execution
main() {
    log_info "Starting Vault deployment..."
    
    build_vault
    deploy_vault
    initialize_vault
    configure_vault
    generate_xml_template
    
    # Display status
    log_info "Vault Status:"
    docker exec "$CONTAINER_NAME" vault status || true
    
    log_success "Vault deployment complete!"
    echo "  Access Vault UI at: https://vault.${DOMAIN}"
    echo "  Dev Root Token: $VAULT_DEV_ROOT_TOKEN_ID"
}

main "$@"