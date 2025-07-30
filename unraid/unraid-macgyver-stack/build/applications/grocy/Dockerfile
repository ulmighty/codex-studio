# ============================================================================
# GROCY - CUSTOM BUILD FROM PHP-FPM BASE
# ============================================================================

FROM php:8.3-fpm-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    curl \
    tar \
    git

# Download Grocy
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Grocy..."

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
    && addgroup -g ${PGID} grocy \
    && adduser -u ${PUID} -G grocy -D -H grocy \
    && mkdir -p /app /config /data \
    && chown -R grocy:grocy /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy configs
COPY --chown=grocy:grocy nginx.conf /etc/nginx/nginx.conf
COPY --chown=grocy:grocy supervisord.conf /etc/supervisord.conf
COPY --chown=grocy:grocy entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9283

VOLUME ["/config", "/data"]

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="grocy-MAC" \
      org.opencontainers.image.description="Grocy PHP application for Unraid MacGyver Stack"
