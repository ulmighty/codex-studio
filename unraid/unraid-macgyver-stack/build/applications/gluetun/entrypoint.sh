#!/bin/sh
# ============================================================================
# GLUETUN ENTRYPOINT SCRIPT
# ============================================================================

set -e

# Set default environment variables
export VPN_SERVICE_PROVIDER="${VPN_SERVICE_PROVIDER:-nordvpn}"
export VPN_TYPE="${VPN_TYPE:-openvpn}"
export OPENVPN_USER="${OPENVPN_USER:-$NORDVPN_USERNAME}"
export OPENVPN_PASSWORD="${OPENVPN_PASSWORD:-$NORDVPN_PASSWORD}"
export SERVER_COUNTRIES="${SERVER_COUNTRIES:-$NORDVPN_COUNTRY}"
export SERVER_HOSTNAMES="${SERVER_HOSTNAMES:-$NORDVPN_SERVER}"
export FIREWALL_OUTBOUND_SUBNETS="${FIREWALL_OUTBOUND_SUBNETS:-$VPN_FIREWALL_OUTBOUND_SUBNETS}"

# Enable port forwarding for containerized apps
export FIREWALL_VPN_INPUT_PORTS="${FIREWALL_VPN_INPUT_PORTS:-9117,8989,7878,8686,8787,6767,8191}"

# Health check configuration
export HEALTH_VPN_DURATION_INITIAL="${HEALTH_VPN_DURATION_INITIAL:-30s}"
export HEALTH_VPN_DURATION_ADDITION="${HEALTH_VPN_DURATION_ADDITION:-10s}"

# DNS configuration
export DOT="${DOT:-on}"
export DOT_PROVIDERS="${DOT_PROVIDERS:-cloudflare}"
export BLOCK_MALICIOUS="${BLOCK_MALICIOUS:-on}"
export BLOCK_SURVEILLANCE="${BLOCK_SURVEILLANCE:-on}"
export BLOCK_ADS="${BLOCK_ADS:-off}"

# Log level
export LOG_LEVEL="${LOG_LEVEL:-info}"

echo "[INFO] Starting Gluetun VPN client..."
echo "[INFO] VPN Provider: $VPN_SERVICE_PROVIDER"
echo "[INFO] Server: $SERVER_HOSTNAMES"

# Execute Gluetun
exec /usr/local/bin/gluetun "$@"