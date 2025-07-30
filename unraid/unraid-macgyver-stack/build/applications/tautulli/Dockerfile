# ============================================================================
# TAUTULLI - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    python3 \
    python3-pip \
    python3-setuptools \
    git \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} tautulli || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash tautulli \
    && mkdir -p /app /config \
    && chown -R tautulli:users /app /config

# Install Tautulli from GitHub
RUN git clone --depth 1 https://github.com/Tautulli/Tautulli.git /app/tautulli \
    && chown -R tautulli:users /app

USER tautulli
EXPOSE 8181
VOLUME ["/config"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8181/status || exit 1
CMD ["python3", "/app/tautulli/Tautulli.py", "--config", "/config", "--datadir", "/config", "--port", "8181", "--nolaunch"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="tautulli-MAC" \
      org.opencontainers.image.description="Tautulli Plex analytics built from scratch"