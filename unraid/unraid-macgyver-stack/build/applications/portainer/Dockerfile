# ============================================================================
# PORTAINER - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
FROM alpine:latest

ARG PUID=99
ARG PGID=100

RUN apk add --no-cache \
    ca-certificates \
    curl \
    && (addgroup -g ${PGID} portainer || true) \
    && adduser -u ${PUID} -G users -D -H portainer

# Download and install Portainer CE
ARG PORTAINER_VERSION=2.19.4
RUN mkdir -p /app \
    && curl -L "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
    | tar -xz -C /app \
    && mkdir -p /data \
    && chown -R portainer:users /app /data

USER portainer
EXPOSE 9000 8000
VOLUME ["/data"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:9000 || exit 1
CMD ["/app/portainer/portainer"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="portainer-MAC" \
      org.opencontainers.image.description="Portainer CE built from scratch"
