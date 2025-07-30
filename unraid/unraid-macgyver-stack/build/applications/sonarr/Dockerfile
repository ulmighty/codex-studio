# ============================================================================
# SONARR - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Sonarr
ARG APP_VERSION=4.0.11.2680
RUN mkdir -p /tmp/sonarr \
    && curl -L "https://github.com/Sonarr/Sonarr/releases/download/v${APP_VERSION}/Sonarr.main.${APP_VERSION}.linux-x64.tar.gz" \
    | tar -xz -C /tmp/sonarr --strip-components=1

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
    && (groupadd -g ${PGID} sonarr || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash sonarr \
    && mkdir -p /app /config /media /downloads \
    && chown -R sonarr:users /app /config /media /downloads

COPY --from=builder /tmp/sonarr /app/sonarr
RUN chown -R sonarr:users /app

EXPOSE 8989
VOLUME ["/config", "/media", "/downloads"]
USER sonarr
ENV XDG_CONFIG_HOME=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8989/ping || exit 1
CMD ["/app/sonarr/Sonarr", "-nobrowser", "-data=/config"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="sonarr-MAC" \
      org.opencontainers.image.description="Sonarr built from scratch"
