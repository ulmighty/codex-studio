# ============================================================================
# INFLUXDB - CUSTOM BUILD
# ============================================================================
# Base: alpine:latest
# Description: Time series database
# ============================================================================

FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install dependencies based on base image
RUN if [ -f /etc/alpine-release ]; then         apk add --no-cache             ca-certificates             tzdata             && (addgroup -g ${PGID} influxdb || true)             && adduser -u ${PUID} -G users -D -H influxdb;     elif [ -f /etc/debian_version ]; then         apt-get update && apt-get install -y --no-install-recommends             ca-certificates             tzdata             && rm -rf /var/lib/apt/lists/*             && (groupadd -g ${PGID} influxdb || true)             && useradd -u ${PUID} -g users -d /config -s /bin/bash influxdb;     fi

# Create necessary directories
RUN mkdir -p /config /data /app     && chown -R influxdb:users /config /data /app

# Switch to non-root user
USER influxdb

# Expose port
EXPOSE 8086

# Volume
VOLUME ["/config", "/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3     CMD curl -f http://localhost:8086/ || exit 1

# Command (placeholder - needs actual app binary/script)
CMD ["sh", "-c", "echo 'Application influxdb needs to be properly configured' && sleep infinity"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack"       org.opencontainers.image.title="influxdb-MAC"       org.opencontainers.image.description="Time series database"
