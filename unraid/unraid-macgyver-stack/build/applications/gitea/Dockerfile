# ============================================================================
# GITEA - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
FROM alpine:latest AS builder

RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar

# Download Gitea
ARG GITEA_VERSION=1.22.6
RUN mkdir -p /tmp/gitea \
    && curl -L "https://github.com/go-gitea/gitea/releases/download/v${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64" \
    -o /tmp/gitea/gitea \
    && chmod +x /tmp/gitea/gitea

FROM alpine:latest

ARG PUID=99
ARG PGID=100

RUN apk add --no-cache \
    ca-certificates \
    curl \
    git \
    openssh \
    tzdata \
    bash \
    && (addgroup -g ${PGID} gitea || true) \
    && adduser -u ${PUID} -G users -D -H gitea \
    && mkdir -p /app /data /config \
    && chown -R gitea:users /app /data /config

COPY --from=builder /tmp/gitea/gitea /app/gitea
RUN chown gitea:users /app/gitea

USER gitea
EXPOSE 3001 22
VOLUME ["/data", "/config"]
ENV GITEA_WORK_DIR=/data
ENV GITEA_CUSTOM=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3001/ || exit 1
CMD ["/app/gitea", "web", "--port", "3001"]

LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="gitea-MAC" \
      org.opencontainers.image.description="Gitea Git service built from scratch"