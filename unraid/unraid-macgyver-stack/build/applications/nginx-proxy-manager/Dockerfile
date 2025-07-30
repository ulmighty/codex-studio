# ============================================================================
# NGINX-PROXY-MANAGER - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================

FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar

# Download Nginx-proxy-manager
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Nginx-proxy-manager..."

FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    shadow \
    su-exec \
    tzdata \
    && addgroup -g ${PGID} nginx-proxy-manager \
    && adduser -u ${PUID} -G nginx-proxy-manager -D -H nginx-proxy-manager \
    && mkdir -p /app /config /data \
    && chown -R nginx-proxy-manager:nginx-proxy-manager /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=nginx-proxy-manager:nginx-proxy-manager entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 81

VOLUME ["/config", "/data"]

USER nginx-proxy-manager

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="nginx-proxy-manager-MAC" \
      org.opencontainers.image.description="Nginx-proxy-manager for Unraid MacGyver Stack"
