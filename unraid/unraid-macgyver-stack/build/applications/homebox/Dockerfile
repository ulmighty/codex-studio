# ============================================================================
# HOMEBOX - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================

FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar

# Download Homebox
ARG APP_VERSION=latest
RUN mkdir -p /app \
    && cd /app \
    && echo "Downloading Homebox..."

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
    && addgroup -g ${PGID} homebox \
    && adduser -u ${PUID} -G homebox -D -H homebox \
    && mkdir -p /app /config /data \
    && chown -R homebox:homebox /app /config /data

# Copy application
COPY --from=builder /app /app

# Copy entrypoint
COPY --chown=homebox:homebox entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7745

VOLUME ["/config", "/data"]

USER homebox

ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="homebox-MAC" \
      org.opencontainers.image.description="Homebox for Unraid MacGyver Stack"
