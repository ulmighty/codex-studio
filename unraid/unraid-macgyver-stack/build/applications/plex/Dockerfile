# ============================================================================
# PLEX - CUSTOM BUILD FROM DEBIAN BASE (SIMPLIFIED)
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Plex Media Server
ARG PLEX_VERSION=1.40.5.8854-f36c552fd
RUN mkdir -p /tmp/plex \
    && curl -L "https://downloads.plex.tv/plex-media-server-new/${PLEX_VERSION}/debian/plexmediaserver_${PLEX_VERSION}_amd64.deb" \
    -o /tmp/plex/plexmediaserver.deb

FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ffmpeg \
    tzdata \
    wget \
    xmlstarlet \
    uuid-runtime \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} plex || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash plex \
    && mkdir -p /app /config /transcode /media \
    && chown -R plex:users /app /config /transcode /media

# Install Plex from deb package
COPY --from=builder /tmp/plex/plexmediaserver.deb /tmp/
RUN dpkg -i /tmp/plexmediaserver.deb || apt-get install -f -y \
    && rm -f /tmp/plexmediaserver.deb \
    && chown -R plex:users /usr/lib/plexmediaserver

USER plex
EXPOSE 32400 3005 8324 32469 1900 32410 32412 32413 32414
VOLUME ["/config", "/transcode", "/media"]
ENV PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver
ENV PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/config
ENV PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
ENV TMPDIR=/transcode
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:32400/identity || exit 1
CMD ["/usr/lib/plexmediaserver/Plex Media Server"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="plex-MAC" \
      org.opencontainers.image.description="Plex Media Server built from scratch"