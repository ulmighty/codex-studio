# ============================================================================
# LIDARR - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Lidarr
ARG APP_VERSION=2.0.7.3849
RUN mkdir -p /tmp/lidarr \
    && curl -L "https://github.com/Lidarr/Lidarr/releases/download/v${APP_VERSION}/Lidarr.main.${APP_VERSION}.linux-x64.tar.gz" \
    | tar -xz -C /tmp/lidarr --strip-components=1

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
    && (groupadd -g ${PGID} lidarr || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash lidarr \
    && mkdir -p /app /config /media /downloads \
    && chown -R lidarr:users /app /config /media /downloads

COPY --from=builder /tmp/lidarr /app/lidarr
RUN chown -R lidarr:users /app

EXPOSE 8686
VOLUME ["/config", "/media", "/downloads"]
USER lidarr
ENV XDG_CONFIG_HOME=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8686/ping || exit 1
CMD ["/app/lidarr/Lidarr", "-nobrowser", "-data=/config"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="lidarr-MAC" \
      org.opencontainers.image.description="Lidarr built from scratch"
