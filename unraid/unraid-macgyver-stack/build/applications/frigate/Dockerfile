# ============================================================================
# FRIGATE - CUSTOM BUILD FROM NVIDIA CUDA BASE
# ============================================================================

FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Frigate
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Frigate..."

FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ffmpeg \
    libgomp1 \
    python3 \
    python3-pip \
    tzdata \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g ${PGID} frigate \
    && useradd -u ${PUID} -g frigate -d /config -s /bin/bash frigate \
    && mkdir -p /app /config /data \
    && chown -R frigate:frigate /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=frigate:frigate entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000

VOLUME ["/config", "/data"]

USER frigate

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="frigate-MAC" \
      org.opencontainers.image.description="Frigate with GPU support for Unraid MacGyver Stack"
