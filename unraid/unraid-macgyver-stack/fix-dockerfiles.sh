#!/bin/bash
# Fix all Dockerfiles to handle GID 100 (users group) conflict

set -euo pipefail

PROJECT_ROOT="/mnt/user/docker_builds/unraid-macgyver-stack"

echo "Fixing Dockerfiles to handle Unraid group conflicts..."

# Find all Dockerfiles and fix the group creation
find "$PROJECT_ROOT/build/applications" -name "Dockerfile" -exec sed -i \
    -e 's/addgroup -g ${PGID} \([a-z]*\)/\(addgroup -g ${PGID} \1 || true\)/g' \
    -e 's/adduser -u ${PUID} -G \([a-z]*\)/adduser -u ${PUID} -G users/g' \
    -e 's/chown -R \([a-z]*\):\1/chown -R \1:users/g' {} \;

echo "Dockerfiles fixed!"

# Also fix the deployment scripts to handle already initialized Vault
sed -i 's/docker exec vault-MAC vault status/docker exec vault-MAC vault status || true/g' \
    "$PROJECT_ROOT/build/scripts/deploy-vault.sh"

echo "Deployment scripts updated!"