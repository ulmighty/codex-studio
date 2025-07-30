# ============================================================================
# READARR - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Readarr
ARG APP_VERSION=0.4.18.2805
RUN mkdir -p /tmp/readarr \
    && curl -L "https://github.com/Readarr/Readarr/releases/download/v${APP_VERSION}/Readarr.develop.${APP_VERSION}.linux-core-x64.tar.gz" \
    | tar -xz -C /tmp/readarr --strip-components=1

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
    && (groupadd -g ${PGID} readarr || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash readarr \
    && mkdir -p /app /config /media /downloads \
    && chown -R readarr:users /app /config /media /downloads

COPY --from=builder /tmp/readarr /app/readarr
RUN chown -R readarr:users /app

EXPOSE 8787
VOLUME ["/config", "/media", "/downloads"]
USER readarr
ENV XDG_CONFIG_HOME=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8787/ping || exit 1
CMD ["/app/readarr/Readarr", "-nobrowser", "-data=/config"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="readarr-MAC" \
      org.opencontainers.image.description="Readarr built from scratch"
