# ============================================================================
# JELLYFIN - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Jellyfin binaries
ARG JELLYFIN_VERSION=10.8.13
RUN mkdir -p /tmp/jellyfin \
    && curl -L "https://repo.jellyfin.org/releases/server/portable/stable/combined/jellyfin_${JELLYFIN_VERSION}.tar.gz" \
    | tar -xz -C /tmp/jellyfin --strip-components=1

FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ffmpeg \
    openssl \
    locales \
    tzdata \
    libfontconfig1 \
    libfreetype6 \
    libssl1.1 \
    libicu67 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} jellyfin || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash jellyfin \
    && mkdir -p /app /config /cache /media \
    && chown -R jellyfin:users /app /config /cache /media

COPY --from=builder /tmp/jellyfin /app/jellyfin
RUN chown -R jellyfin:users /app

USER jellyfin
EXPOSE 8096
VOLUME ["/config", "/cache", "/media"]
ENV JELLYFIN_DATA_DIR=/config
ENV JELLYFIN_CACHE_DIR=/cache
ENV JELLYFIN_LOG_DIR=/config/log
ENV JELLYFIN_WEB_DIR=/app/jellyfin/jellyfin-web
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8096/health || exit 1
CMD ["/app/jellyfin/jellyfin", "--datadir", "/config", "--cachedir", "/cache"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="jellyfin-MAC" \
      org.opencontainers.image.description="Jellyfin media server built from scratch"