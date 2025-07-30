# ============================================================================
# BAZARR - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    python3 \
    python3-pip \
    python3-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    gcc \
    musl-dev \
    git \
    ffmpeg \
    unrar-free \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} bazarr || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash bazarr \
    && mkdir -p /app /config /media \
    && chown -R bazarr:users /app /config /media

# Install Bazarr from source
RUN git clone https://github.com/morpheus65535/bazarr.git /app/bazarr \
    && cd /app/bazarr \
    && pip3 install --no-cache-dir -r requirements.txt \
    && chown -R bazarr:users /app

USER bazarr
EXPOSE 6767
VOLUME ["/config", "/media"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:6767/api/v1/system/health || exit 1
CMD ["python3", "/app/bazarr/bazarr.py", "--no-update", "--config", "/config"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="bazarr-MAC" \
      org.opencontainers.image.description="Bazarr subtitle manager built from scratch"
