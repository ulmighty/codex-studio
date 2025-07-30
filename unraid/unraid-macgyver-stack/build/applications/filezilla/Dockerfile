# ============================================================================
# FILEZILLA - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================

FROM debian:bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Filezilla - version will be updated by build script
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Filezilla..."

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
    && groupadd -g ${PGID} filezilla \
    && useradd -u ${PUID} -g filezilla -d /config -s /bin/bash filezilla \
    && mkdir -p /app /config /data \
    && chown -R filezilla:filezilla /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=filezilla:filezilla entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5801

VOLUME ["/config", "/data"]

USER filezilla

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="filezilla-MAC" \
      org.opencontainers.image.description="Filezilla for Unraid MacGyver Stack"
