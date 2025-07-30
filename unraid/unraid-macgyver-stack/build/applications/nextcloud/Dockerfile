# ============================================================================
# NEXTCLOUD - CUSTOM BUILD FROM PHP-FPM BASE
# ============================================================================

FROM php:8.3-fpm-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    curl \
    tar \
    git

# Download Nextcloud
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Nextcloud..."

FROM php:8.3-fpm-alpine

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install PHP extensions and dependencies
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    nginx \
    postgresql-client \
    redis \
    shadow \
    supervisor \
    tzdata \
    && docker-php-ext-install \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    pdo_pgsql \
    zip \
    && addgroup -g ${PGID} nextcloud \
    && adduser -u ${PUID} -G nextcloud -D -H nextcloud \
    && mkdir -p /app /config /data \
    && chown -R nextcloud:nextcloud /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy configs
COPY --chown=nextcloud:nextcloud nginx.conf /etc/nginx/nginx.conf
COPY --chown=nextcloud:nextcloud supervisord.conf /etc/supervisord.conf
COPY --chown=nextcloud:nextcloud entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8081

VOLUME ["/config", "/data"]

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="nextcloud-MAC" \
      org.opencontainers.image.description="Nextcloud PHP application for Unraid MacGyver Stack"
