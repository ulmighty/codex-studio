# ============================================================================
# TRAEFIK - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
# Multi-stage build for Traefik reverse proxy
# Base: alpine:latest
# ============================================================================

ARG TRAEFIK_VERSION=3.0.0

# Stage 1: Download and verify Traefik binary
FROM alpine:latest AS downloader

ARG TRAEFIK_VERSION
ARG TARGETARCH

RUN apk add --no-cache \
    curl \
    tar \
    && cd /tmp \
    && curl -sSL "https://github.com/traefik/traefik/releases/download/v${TRAEFIK_VERSION}/traefik_v${TRAEFIK_VERSION}_linux_${TARGETARCH}.tar.gz" -o traefik.tar.gz \
    && tar -xzf traefik.tar.gz \
    && chmod +x traefik \
    && mv traefik /usr/local/bin/

# Stage 2: Final minimal image
FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    wget \
    && ((addgroup -g ${PGID} traefik || true) || true) \
    && adduser -u ${PUID} -G users -D -H traefik \
    && mkdir -p /etc/traefik /var/log/traefik /certificates \
    && chown -R traefik:users /etc/traefik /var/log/traefik /certificates

# Copy Traefik binary from downloader
COPY --from=downloader /usr/local/bin/traefik /usr/local/bin/traefik

# Copy configuration files
COPY --chown=traefik:traefik traefik.yml /etc/traefik/traefik.yml
COPY --chown=traefik:traefik dynamic/ /etc/traefik/dynamic/

# Expose ports
EXPOSE 80 443 8080

# Volumes
VOLUME ["/etc/traefik", "/certificates", "/var/log/traefik"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost:8080/ping || exit 1

# Switch to non-root user
USER traefik

# Command
CMD ["traefik"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="traefik-MAC" \
      org.opencontainers.image.description="Traefik reverse proxy for Unraid MacGyver Stack" \
      org.opencontainers.image.version="${TRAEFIK_VERSION}" \
      org.opencontainers.image.source="https://github.com/traefik/traefik"