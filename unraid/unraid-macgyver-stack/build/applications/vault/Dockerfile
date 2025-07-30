# ============================================================================
# VAULT - CUSTOM BUILD FROM ALPINE BASE
# ============================================================================
# Multi-stage build for HashiCorp Vault
# Base: alpine:latest
# ============================================================================

ARG VAULT_VERSION=1.15.4

# Stage 1: Download and verify Vault binary
FROM alpine:latest AS downloader

ARG VAULT_VERSION
ARG TARGETARCH

RUN apk add --no-cache \
    curl \
    gnupg \
    && cd /tmp \
    && curl -sSL "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip" -o vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip \
    && curl -sSL "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS" -o SHA256SUMS \
    && curl -sSL "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig" -o SHA256SUMS.sig \
    && wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import \
    && gpg --verify SHA256SUMS.sig SHA256SUMS \
    && grep "vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip" SHA256SUMS | sha256sum -c \
    && unzip vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip \
    && chmod +x vault \
    && mv vault /usr/local/bin/

# Stage 2: Final minimal image
FROM alpine:latest

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    libcap \
    su-exec \
    dumb-init \
    tzdata \
    && ((addgroup -g ${PGID} vault || true) || true) \
    && adduser -u ${PUID} -G users -D -H vault \
    && mkdir -p /vault/data /vault/config /vault/logs /vault/file \
    && chown -R vault:users /vault

# Copy Vault binary from downloader
COPY --from=downloader /usr/local/bin/vault /usr/local/bin/vault

# Add IPC_LOCK capability for memory locking
RUN setcap cap_ipc_lock=+ep /usr/local/bin/vault

# Copy custom entrypoint
COPY --chown=vault:vault entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy default configuration
COPY --chown=vault:vault config.hcl /vault/config/config.hcl

# Expose API port
EXPOSE 8200

# Volume for persistent data
VOLUME ["/vault/data", "/vault/logs"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD VAULT_ADDR=http://127.0.0.1:8200 vault status -format=json | grep -q '"initialized":true' || exit 1

# Switch to non-root user
USER vault

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="vault-MAC" \
      org.opencontainers.image.description="HashiCorp Vault for Unraid MacGyver Stack" \
      org.opencontainers.image.version="${VAULT_VERSION}" \
      org.opencontainers.image.source="https://github.com/hashicorp/vault"