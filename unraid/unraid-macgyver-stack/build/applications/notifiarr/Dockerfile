# ============================================================================
# NOTIFIARR - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================

FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar

# Download Notifiarr
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Notifiarr..."

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
    && addgroup -g ${PGID} notifiarr \
    && adduser -u ${PUID} -G notifiarr -D -H notifiarr \
    && mkdir -p /app /config /data \
    && chown -R notifiarr:notifiarr /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=notifiarr:notifiarr entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5454

VOLUME ["/config", "/data"]

USER notifiarr

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="notifiarr-MAC" \
      org.opencontainers.image.description="Notifiarr for Unraid MacGyver Stack"
