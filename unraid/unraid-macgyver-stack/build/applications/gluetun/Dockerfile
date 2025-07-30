# ============================================================================
# GLUETUN - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
# Multi-stage build for Gluetun VPN client
# Base: alpine:latest
# ============================================================================

ARG GLUETUN_VERSION=v3.38.0

# Stage 1: Build Gluetun from source
FROM golang:1.21-alpine AS builder

ARG GLUETUN_VERSION

RUN apk add --no-cache \
    git \
    make \
    && git clone https://github.com/qdm12/gluetun.git /build \
    && cd /build \
    && git checkout ${GLUETUN_VERSION} \
    && go mod download \
    && CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o gluetun cmd/gluetun/main.go

# Stage 2: Final minimal image
FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    iptables \
    ip6tables \
    openvpn \
    wireguard-tools \
    bind-tools \
    tzdata \
    curl \
    jq \
    && (addgroup -g ${PGID} vpn || true) \
    && adduser -u ${PUID} -G users -D -H vpn \
    && mkdir -p /gluetun /tmp/gluetun \
    && chown -R vpn:users /gluetun /tmp/gluetun

# Copy Gluetun binary from builder
COPY --from=builder /build/gluetun /usr/local/bin/gluetun

# Copy entrypoint script
COPY --chown=vpn:vpn entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose VPN interface for other containers
EXPOSE 8888/tcp 8388/tcp 8388/udp

# Volumes
VOLUME ["/gluetun"]

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/local/bin/gluetun healthcheck || exit 1

# Run as root for network operations
USER root

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="gluetun-MAC" \
      org.opencontainers.image.description="Gluetun VPN client for Unraid MacGyver Stack" \
      org.opencontainers.image.version="${GLUETUN_VERSION}" \
      org.opencontainers.image.source="https://github.com/qdm12/gluetun"