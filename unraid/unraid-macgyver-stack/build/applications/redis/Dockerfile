# ============================================================================
# REDIS - CUSTOM BUILD
# ============================================================================
# Base: alpine:latest
# Description: In-memory data structure store
# ============================================================================

FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install dependencies based on base image
RUN if [ -f /etc/alpine-release ]; then         apk add --no-cache             ca-certificates             tzdata             && (addgroup -g ${PGID} redis || true)             && adduser -u ${PUID} -G users -D -H redis;     elif [ -f /etc/debian_version ]; then         apt-get update && apt-get install -y --no-install-recommends             ca-certificates             tzdata             && rm -rf /var/lib/apt/lists/*             && (groupadd -g ${PGID} redis || true)             && useradd -u ${PUID} -g users -d /config -s /bin/bash redis;     fi

# Create necessary directories
RUN mkdir -p /config /data /app     && chown -R redis:users /config /data /app

# Switch to non-root user
USER redis

# Expose port
EXPOSE 6379

# Volume
VOLUME ["/config", "/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3     CMD curl -f http://localhost:6379/ || exit 1

# Command (placeholder - needs actual app binary/script)
CMD ["sh", "-c", "echo 'Application redis needs to be properly configured' && sleep infinity"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack"       org.opencontainers.image.title="redis-MAC"       org.opencontainers.image.description="In-memory data structure store"
