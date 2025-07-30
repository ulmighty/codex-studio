#!/bin/bash
# Configure Vault integration for all applications

set -euo pipefail

source /mnt/user/docker_builds/unraid-macgyver-stack/.env
PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "=== CONFIGURING VAULT INTEGRATION ==="
echo "This will set up:"
echo "1. Vault policies for each application"
echo "2. AppRoles for authentication"
echo "3. Secret paths for API keys and credentials"
echo "4. Bidirectional secret flow (read and write)"
echo ""

# Get Vault root token
VAULT_TOKEN=$(cat /mnt/user/appdata/vault-MAC/vault-init.json | grep -o '"root_token":"[^"]*' | cut -d'"' -f4)
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN

echo "Using Vault at: $VAULT_ADDR"

# Function to create app policy
create_app_policy() {
    local app_name=$1
    local policy_name="${app_name}-policy"
    
    echo "Creating policy for $app_name..."
    
    # Create policy file
    cat > "/tmp/${policy_name}.hcl" << EOF
# Policy for ${app_name}
path "secret/data/apps/${app_name}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/apps/${app_name}/*" {
  capabilities = ["list", "read"]
}

# Allow writing runtime data back to Vault
path "secret/data/runtime/${app_name}/*" {
  capabilities = ["create", "read", "update", "delete"]
}

# Allow reading shared secrets
path "secret/data/shared/*" {
  capabilities = ["read"]
}

# Allow reading database credentials
path "database/creds/${app_name}-db" {
  capabilities = ["read"]
}
EOF

    # Write policy to Vault
    docker exec vault-MAC vault policy write "$policy_name" "/tmp/${policy_name}.hcl"
}

# Function to create AppRole
create_app_role() {
    local app_name=$1
    local role_name="${app_name}-role"
    
    echo "Creating AppRole for $app_name..."
    
    # Enable AppRole auth if not already enabled
    docker exec vault-MAC vault auth list | grep -q "approle/" || \
        docker exec vault-MAC vault auth enable approle
    
    # Create role
    docker exec vault-MAC vault write "auth/approle/role/${role_name}" \
        token_policies="${app_name}-policy" \
        token_num_uses=0 \
        token_ttl=24h \
        token_max_ttl=720h \
        secret_id_ttl=0 \
        secret_id_num_uses=0
    
    # Get role ID
    ROLE_ID=$(docker exec vault-MAC vault read -field=role_id "auth/approle/role/${role_name}/role-id")
    
    # Get secret ID
    SECRET_ID=$(docker exec vault-MAC vault write -field=secret_id -f "auth/approle/role/${role_name}/secret-id")
    
    # Save credentials for the app
    mkdir -p "$APPDATA_PATH/${app_name}-MAC/vault"
    echo "$ROLE_ID" > "$APPDATA_PATH/${app_name}-MAC/vault/role-id"
    echo "$SECRET_ID" > "$APPDATA_PATH/${app_name}-MAC/vault/secret-id"
    
    echo "AppRole created for $app_name (Role ID: ${ROLE_ID:0:8}...)"
}

# Function to populate initial secrets
populate_app_secrets() {
    local app_name=$1
    
    echo "Populating secrets for $app_name..."
    
    case "$app_name" in
        "sonarr"|"radarr"|"lidarr"|"readarr"|"prowlarr")
            # ARR app secrets
            docker exec vault-MAC vault kv put "secret/apps/${app_name}/config" \
                api_key="$(openssl rand -hex 16)" \
                url_base="/${app_name}" \
                postgres_connection="Host=postgresql-MAC;Port=5432;Database=${app_name};Username=${app_name};Password=$(openssl rand -hex 12)"
            ;;
            
        "bazarr")
            docker exec vault-MAC vault kv put "secret/apps/${app_name}/config" \
                api_key="$(openssl rand -hex 16)" \
                sonarr_api_key="@secret/apps/sonarr/config:api_key" \
                radarr_api_key="@secret/apps/radarr/config:api_key"
            ;;
            
        "sabnzbd")
            docker exec vault-MAC vault kv put "secret/apps/${app_name}/config" \
                api_key="$(openssl rand -hex 16)" \
                nzb_key="$(openssl rand -hex 16)" \
                download_dir="/downloads/complete" \
                incomplete_dir="/downloads/incomplete"
            ;;
            
        "jellyfin"|"plex")
            docker exec vault-MAC vault kv put "secret/apps/${app_name}/config" \
                server_token="$(openssl rand -hex 32)" \
                transcode_hw="nvidia" \
                library_paths="/media/movies,/media/tv,/media/music"
            ;;
            
        "grafana")
            docker exec vault-MAC vault kv put "secret/apps/${app_name}/config" \
                admin_user="admin" \
                admin_password="$(openssl rand -base64 12)" \
                secret_key="$(openssl rand -hex 16)" \
                prometheus_url="http://prometheus-MAC:9090" \
                influxdb_url="http://influxdb-MAC:8086"
            ;;
            
        "notifiarr")
            docker exec vault-MAC vault kv put "secret/apps/${app_name}/config" \
                api_key="${NOTIFIARR_API_KEY:-$(openssl rand -hex 32)}" \
                discord_webhook="${DISCORD_WEBHOOK_URL:-}" \
                integration_keys="@secret/apps/*/config:api_key"
            ;;
    esac
}

# Enable KV v2 secrets engine
echo "Enabling KV v2 secrets engine..."
docker exec vault-MAC vault secrets list | grep -q "secret/" || \
    docker exec vault-MAC vault secrets enable -version=2 -path=secret kv

# Create shared secrets
echo "Creating shared secrets..."
docker exec vault-MAC vault kv put secret/shared/nordvpn \
    username="$NORDVPN_USERNAME" \
    password="$NORDVPN_PASSWORD" \
    server="$NORDVPN_SERVER"

docker exec vault-MAC vault kv put secret/shared/postgres \
    host="postgresql-MAC" \
    port="5432" \
    admin_user="$POSTGRES_USER" \
    admin_password="$POSTGRES_PASSWORD"

docker exec vault-MAC vault kv put secret/shared/traefik \
    dashboard_user="$TRAEFIK_DASHBOARD_USER" \
    dashboard_password="$TRAEFIK_DASHBOARD_PASSWORD"

# Configure each application
APPS=(
    "sonarr" "radarr" "lidarr" "readarr" "prowlarr" "bazarr"
    "sabnzbd" "jellyfin" "plex" "overseerr" "tautulli" "kavita"
    "grafana" "prometheus" "redis" "influxdb" "portainer"
    "unmanic" "notifiarr" "frigate" "calibre" "calibre-web"
    "gitea" "wikijs" "vaultwarden" "n8n" "heimdall"
)

for app in "${APPS[@]}"; do
    echo ""
    echo "=== Configuring $app ==="
    create_app_policy "$app"
    create_app_role "$app"
    populate_app_secrets "$app"
done

# Create Vault Agent configuration for each app
echo ""
echo "Creating Vault Agent configurations..."

for app in "${APPS[@]}"; do
    cat > "$APPDATA_PATH/${app}-MAC/vault/agent.hcl" << EOF
exit_after_auth = false
pid_file = "/tmp/vault-agent.pid"

vault {
  address = "http://vault-MAC:8200"
}

auto_auth {
  method {
    type = "approle"
    
    config {
      role_id_file_path = "/vault/role-id"
      secret_id_file_path = "/vault/secret-id"
    }
  }
  
  sink {
    type = "file"
    config {
      path = "/vault/token"
    }
  }
}

template {
  source = "/vault/config.tmpl"
  destination = "/config/vault-secrets.env"
}

template {
  source = "/vault/runtime.tmpl"
  destination = "/vault/runtime-data.json"
  perms = "0600"
  
  # Write runtime data back to Vault every 5 minutes
  exec {
    command = ["sh", "-c", "cat /vault/runtime-data.json | vault kv put -format=json secret/runtime/${app}/status -"]
    timeout = "30s"
  }
}
EOF
done

echo ""
echo "=== VAULT INTEGRATION COMPLETE ==="
echo ""
echo "Each application now has:"
echo "✓ Vault policy for secret access"
echo "✓ AppRole authentication configured"
echo "✓ Initial secrets populated"
echo "✓ Vault Agent configuration for runtime integration"
echo ""
echo "Applications can now:"
echo "- Read their configuration from Vault"
echo "- Write runtime data back to Vault"
echo "- Access shared secrets"
echo "- Integrate with other services via Vault"