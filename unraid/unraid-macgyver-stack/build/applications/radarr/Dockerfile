# ============================================================================
# RADARR - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Radarr
ARG APP_VERSION=5.26.2.10099
RUN mkdir -p /tmp/radarr \
    && curl -L "https://github.com/Radarr/Radarr/releases/download/v${APP_VERSION}/Radarr.master.${APP_VERSION}.linux-core-x64.tar.gz" \
    | tar -xz -C /tmp/radarr --strip-components=1

FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libicu67 \
    libssl1.1 \
    mediainfo \
    python3 \
    sqlite3 \
    tzdata \
    unrar-free \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} radarr || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash radarr \
    && mkdir -p /app /config /media /downloads \
    && chown -R radarr:users /app /config /media /downloads

COPY --from=builder /tmp/radarr /app/radarr
RUN chown -R radarr:users /app

EXPOSE 7878
VOLUME ["/config", "/media", "/downloads"]
USER radarr
ENV XDG_CONFIG_HOME=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:7878/ping || exit 1
CMD ["/app/radarr/Radarr", "-nobrowser", "-data=/config"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="radarr-MAC" \
      org.opencontainers.image.description="Radarr built from scratch"
