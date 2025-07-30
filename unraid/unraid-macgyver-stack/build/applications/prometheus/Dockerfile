# ============================================================================
# PROMETHEUS - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
FROM alpine:latest

ARG PUID=99
ARG PGID=100

RUN apk add --no-cache \
    ca-certificates \
    curl \
    && (addgroup -g ${PGID} prometheus || true) \
    && adduser -u ${PUID} -G users -D -H prometheus

# Download and install Prometheus
ARG PROMETHEUS_VERSION=2.48.1
RUN mkdir -p /tmp/prometheus /app \
    && curl -L "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" \
    | tar -xz -C /tmp/prometheus --strip-components=1 \
    && mv /tmp/prometheus /app/prometheus \
    && mkdir -p /config /data \
    && chown -R prometheus:users /app /config /data \
    && rm -rf /tmp/prometheus

# Create default config
RUN echo 'global:' > /config/prometheus.yml && \
    echo '  scrape_interval: 15s' >> /config/prometheus.yml && \
    echo '  evaluation_interval: 15s' >> /config/prometheus.yml && \
    echo '' >> /config/prometheus.yml && \
    echo 'scrape_configs:' >> /config/prometheus.yml && \
    echo '  - job_name: "prometheus"' >> /config/prometheus.yml && \
    echo '    static_configs:' >> /config/prometheus.yml && \
    echo '      - targets: ["localhost:9090"]' >> /config/prometheus.yml && \
    chown prometheus:users /config/prometheus.yml

USER prometheus
EXPOSE 9090
VOLUME ["/config", "/data"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:9090/-/healthy || exit 1
CMD ["/app/prometheus/prometheus", "--config.file=/config/prometheus.yml", "--storage.tsdb.path=/data", "--web.console.libraries=/app/prometheus/console_libraries", "--web.console.templates=/app/prometheus/consoles"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="prometheus-MAC" \
      org.opencontainers.image.description="Prometheus monitoring built from scratch"