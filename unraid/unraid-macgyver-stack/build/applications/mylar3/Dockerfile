# ============================================================================
# MYLAR3 - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================

FROM debian:bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Mylar3 - version will be updated by build script
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Mylar3..."

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
    && groupadd -g ${PGID} mylar3 \
    && useradd -u ${PUID} -g mylar3 -d /config -s /bin/bash mylar3 \
    && mkdir -p /app /config /data \
    && chown -R mylar3:mylar3 /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=mylar3:mylar3 entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8090

VOLUME ["/config", "/data"]

USER mylar3

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="mylar3-MAC" \
      org.opencontainers.image.description="Mylar3 for Unraid MacGyver Stack"
