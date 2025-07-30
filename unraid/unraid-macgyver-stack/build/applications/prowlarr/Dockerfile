# ============================================================================
# PROWLARR - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Prowlarr
ARG APP_VERSION=1.37.0.5076
RUN mkdir -p /tmp/prowlarr \
    && curl -L "https://github.com/Prowlarr/Prowlarr/releases/download/v${APP_VERSION}/Prowlarr.master.${APP_VERSION}.linux-core-x64.tar.gz" \
    | tar -xz -C /tmp/prowlarr --strip-components=1

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
    && (groupadd -g ${PGID} prowlarr || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash prowlarr \
    && mkdir -p /app /config /media /downloads \
    && chown -R prowlarr:users /app /config /media /downloads

COPY --from=builder /tmp/prowlarr /app/prowlarr
RUN chown -R prowlarr:users /app

EXPOSE 9696
VOLUME ["/config", "/media", "/downloads"]
USER prowlarr
ENV XDG_CONFIG_HOME=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:9696/ping || exit 1
CMD ["/app/prowlarr/Prowlarr", "-nobrowser", "-data=/config"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="prowlarr-MAC" \
      org.opencontainers.image.description="Prowlarr built from scratch"
