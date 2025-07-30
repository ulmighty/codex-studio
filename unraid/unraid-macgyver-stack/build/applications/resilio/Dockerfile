# ============================================================================
# RESILIO - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================

FROM debian:bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Resilio - version will be updated by build script
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Resilio..."

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
    && groupadd -g ${PGID} resilio \
    && useradd -u ${PUID} -g resilio -d /config -s /bin/bash resilio \
    && mkdir -p /app /config /data \
    && chown -R resilio:resilio /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=resilio:resilio entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8889

VOLUME ["/config", "/data"]

USER resilio

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="resilio-MAC" \
      org.opencontainers.image.description="Resilio for Unraid MacGyver Stack"
