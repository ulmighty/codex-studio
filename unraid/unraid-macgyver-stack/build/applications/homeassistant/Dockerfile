# ============================================================================
# HOMEASSISTANT - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================

FROM debian:bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Homeassistant - version will be updated by build script
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Homeassistant..."

FROM debian:bullseye-slim

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libicu67 \
    libssl1.1 \
    mediainfo \
    python3 \
    sqlite3 \
    tzdata \
    unrar \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g ${PGID} homeassistant \
    && useradd -u ${PUID} -g homeassistant -d /config -s /bin/bash homeassistant \
    && mkdir -p /app /config /data \
    && chown -R homeassistant:homeassistant /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=homeassistant:homeassistant entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8123

VOLUME ["/config", "/data"]

USER homeassistant

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="homeassistant-MAC" \
      org.opencontainers.image.description="Homeassistant for Unraid MacGyver Stack"
