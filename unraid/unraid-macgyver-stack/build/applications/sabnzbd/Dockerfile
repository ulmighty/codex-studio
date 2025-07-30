# ============================================================================
# SABNZBD - CUSTOM BUILD FROM DEBIAN BASE  
# ============================================================================
FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    git \
    p7zip-full \
    par2 \
    unrar-free \
    unzip \
    wget \
    curl \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} sabnzbd || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash sabnzbd

# Install SABnzbd from GitHub
RUN git clone --depth 1 --branch 4.0.3 https://github.com/sabnzbd/sabnzbd.git /app/sabnzbd \
    && cd /app/sabnzbd \
    && pip3 install --no-cache-dir -r requirements.txt \
    && mkdir -p /config /downloads/incomplete /downloads/complete \
    && chown -R sabnzbd:users /app /config /downloads

USER sabnzbd
EXPOSE 8081
VOLUME ["/config", "/downloads"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8081/api?mode=version || exit 1
CMD ["python3", "/app/sabnzbd/SABnzbd.py", "-f", "/config", "-s", "0.0.0.0:8081", "-b", "0"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="sabnzbd-MAC" \
      org.opencontainers.image.description="SABnzbd newsreader built from scratch"
