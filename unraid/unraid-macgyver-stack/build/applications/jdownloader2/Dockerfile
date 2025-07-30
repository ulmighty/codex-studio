# ============================================================================
# JDOWNLOADER2 - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================

FROM debian:bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Jdownloader2 - version will be updated by build script
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Jdownloader2..."

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
    && groupadd -g ${PGID} jdownloader2 \
    && useradd -u ${PUID} -g jdownloader2 -d /config -s /bin/bash jdownloader2 \
    && mkdir -p /app /config /data \
    && chown -R jdownloader2:jdownloader2 /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=jdownloader2:jdownloader2 entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5800

VOLUME ["/config", "/data"]

USER jdownloader2

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="jdownloader2-MAC" \
      org.opencontainers.image.description="Jdownloader2 for Unraid MacGyver Stack"
