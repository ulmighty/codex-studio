# ============================================================================
# GRAFANA - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
FROM alpine:latest

ARG PUID=99
ARG PGID=100

RUN apk add --no-cache \
    ca-certificates \
    curl \
    libc6-compat \
    && (addgroup -g ${PGID} grafana || true) \
    && adduser -u ${PUID} -G users -D -H grafana

# Download and install Grafana
ARG GRAFANA_VERSION=10.2.3
RUN mkdir -p /tmp/grafana /app \
    && curl -L "https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz" \
    | tar -xz -C /tmp/grafana --strip-components=1 \
    && mv /tmp/grafana /app/grafana \
    && mkdir -p /config /var/lib/grafana \
    && chown -R grafana:users /app /config /var/lib/grafana \
    && rm -rf /tmp/grafana

USER grafana
EXPOSE 3000
VOLUME ["/config", "/var/lib/grafana"]
ENV GF_PATHS_CONFIG=/config/grafana.ini
ENV GF_PATHS_DATA=/var/lib/grafana
ENV GF_PATHS_LOGS=/config/logs
ENV GF_PATHS_PLUGINS=/var/lib/grafana/plugins
ENV GF_PATHS_PROVISIONING=/config/provisioning
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:3000/api/health || exit 1
CMD ["/app/grafana/bin/grafana-server", "--homepath", "/app/grafana", "--config", "/config/grafana.ini"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="grafana-MAC" \
      org.opencontainers.image.description="Grafana monitoring built from scratch"