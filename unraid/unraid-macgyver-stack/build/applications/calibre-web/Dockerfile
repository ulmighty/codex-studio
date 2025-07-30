# ============================================================================
# CALIBRE-WEB - CUSTOM BUILD
# ============================================================================
# Base: alpine:latest
# Description: Web app providing a clean interface for browsing Calibre
# ============================================================================

FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install dependencies based on base image
RUN if [ -f /etc/alpine-release ]; then         apk add --no-cache             ca-certificates             tzdata             && (addgroup -g ${PGID} calibre-web || true)             && adduser -u ${PUID} -G users -D -H calibre-web;     elif [ -f /etc/debian_version ]; then         apt-get update && apt-get install -y --no-install-recommends             ca-certificates             tzdata             && rm -rf /var/lib/apt/lists/*             && (groupadd -g ${PGID} calibre-web || true)             && useradd -u ${PUID} -g users -d /config -s /bin/bash calibre-web;     fi

# Create necessary directories
RUN mkdir -p /config /data /app     && chown -R calibre-web:users /config /data /app

# Switch to non-root user
USER calibre-web

# Expose port
EXPOSE 8083

# Volume
VOLUME ["/config", "/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3     CMD curl -f http://localhost:8083/ || exit 1

# Command (placeholder - needs actual app binary/script)
CMD ["sh", "-c", "echo 'Application calibre-web needs to be properly configured' && sleep infinity"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack"       org.opencontainers.image.title="calibre-web-MAC"       org.opencontainers.image.description="Web app providing a clean interface for browsing Calibre"
