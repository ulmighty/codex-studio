# ============================================================================
# HEIMDALL - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    php \
    php-curl \
    php-dom \
    php-json \
    php-mbstring \
    php-sqlite3 \
    php-xml \
    php-zip \
    sqlite3 \
    git \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} heimdall || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash heimdall \
    && mkdir -p /app /config \
    && chown -R heimdall:users /app /config

# Install Heimdall
RUN git clone --depth 1 https://github.com/linuxserver/Heimdall.git /app/heimdall \
    && chown -R heimdall:users /app

USER heimdall
EXPOSE 8085
VOLUME ["/config"]
WORKDIR /app/heimdall
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8085/ || exit 1
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8085"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="heimdall-MAC" \
      org.opencontainers.image.description="Heimdall dashboard built from scratch"