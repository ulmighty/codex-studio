# ============================================================================
# LOKI - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================

FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar

# Download Loki
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Loki..."

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
    && addgroup -g ${PGID} loki \
    && adduser -u ${PUID} -G loki -D -H loki \
    && mkdir -p /app /config /data \
    && chown -R loki:loki /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=loki:loki entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3100

VOLUME ["/config", "/data"]

USER loki

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="loki-MAC" \
      org.opencontainers.image.description="Loki for Unraid MacGyver Stack"
