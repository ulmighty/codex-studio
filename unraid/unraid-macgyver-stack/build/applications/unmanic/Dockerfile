# ============================================================================
# UNMANIC - CUSTOM BUILD FROM NVIDIA CUDA BASE
# ============================================================================

FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Unmanic
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Unmanic..."

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
    && groupadd -g ${PGID} unmanic \
    && useradd -u ${PUID} -g unmanic -d /config -s /bin/bash unmanic \
    && mkdir -p /app /config /data \
    && chown -R unmanic:unmanic /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=unmanic:unmanic entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888

VOLUME ["/config", "/data"]

USER unmanic

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="unmanic-MAC" \
      org.opencontainers.image.description="Unmanic with GPU support for Unraid MacGyver Stack"
