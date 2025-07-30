#!/bin/sh
# ============================================================================
# VAULT ENTRYPOINT SCRIPT
# ============================================================================

set -e

# If running in dev mode, skip most initialization
if [ "${VAULT_DEV_MODE}" = "true" ]; then
    echo "[INFO] Starting Vault in development mode..."
    exec vault server -dev \
        -dev-root-token-id="${VAULT_DEV_ROOT_TOKEN_ID}" \
        -dev-listen-address="0.0.0.0:8200"
fi

# Production mode startup
echo "[INFO] Starting Vault in production mode..."

# Check for configuration file
if [ ! -f "/vault/config/config.hcl" ]; then
    echo "[ERROR] No configuration file found at /vault/config/config.hcl"
    exit 1
fi

# Start Vault server
exec vault server -config=/vault/config/config.hcl