#!/bin/sh
set -e

echo "[INFO] Starting ${app^}..."

# Execute application
exec /app/nginx-proxy-manager
