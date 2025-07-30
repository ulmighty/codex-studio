# ============================================================================
# KAVITA - CUSTOM BUILD
# ============================================================================
# Base: debian:bullseye-slim
# Description: Fast, feature rich, cross platform reading server
# ============================================================================

FROM debian:bullseye-slim

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install dependencies based on base image
RUN if [ -f /etc/alpine-release ]; then         apk add --no-cache             ca-certificates             tzdata             && (addgroup -g ${PGID} kavita || true)             && adduser -u ${PUID} -G users -D -H kavita;     elif [ -f /etc/debian_version ]; then         apt-get update && apt-get install -y --no-install-recommends             ca-certificates             tzdata             && rm -rf /var/lib/apt/lists/*             && (groupadd -g ${PGID} kavita || true)             && useradd -u ${PUID} -g users -d /config -s /bin/bash kavita;     fi

# Create necessary directories
RUN mkdir -p /config /data /app     && chown -R kavita:users /config /data /app

# Switch to non-root user
USER kavita

# Expose port
EXPOSE 5000

# Volume
VOLUME ["/config", "/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3     CMD curl -f http://localhost:5000/ || exit 1

# Command (placeholder - needs actual app binary/script)
CMD ["sh", "-c", "echo 'Application kavita needs to be properly configured' && sleep infinity"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack"       org.opencontainers.image.title="kavita-MAC"       org.opencontainers.image.description="Fast, feature rich, cross platform reading server"
