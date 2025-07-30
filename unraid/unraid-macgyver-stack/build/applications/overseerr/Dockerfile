# ============================================================================
# OVERSEERR - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download Overseerr
ARG OVERSEERR_VERSION=1.33.2
RUN mkdir -p /tmp/overseerr \
    && curl -L "https://github.com/sct/overseerr/releases/download/v${OVERSEERR_VERSION}/overseerr-${OVERSEERR_VERSION}-linux-x64.tar.gz" \
    | tar -xz -C /tmp/overseerr --strip-components=1

FROM debian:bullseye-slim

ARG PUID=99
ARG PGID=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libicu67 \
    libssl1.1 \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && (groupadd -g ${PGID} overseerr || true) \
    && useradd -u ${PUID} -g users -d /config -s /bin/bash overseerr \
    && mkdir -p /app /config \
    && chown -R overseerr:users /app /config

COPY --from=builder /tmp/overseerr /app/overseerr
RUN chown -R overseerr:users /app

USER overseerr
EXPOSE 5055
VOLUME ["/config"]
ENV CONFIG_DIRECTORY=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:5055/api/v1/status || exit 1
CMD ["/app/overseerr/overseerr"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="overseerr-MAC" \
      org.opencontainers.image.description="Overseerr request manager built from scratch"