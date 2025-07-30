# ============================================================================
# POSTGRESQL 17 - CUSTOM BUILD FROM DEBIAN BASE
# ============================================================================
# Multi-stage build for PostgreSQL 17
# Base: debian:bullseye-slim
# ============================================================================

FROM debian:bullseye-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    ca-certificates \
    libreadline-dev \
    zlib1g-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    liblz4-dev \
    libzstd-dev \
    libicu-dev \
    pkg-config \
    bison \
    flex \
    && rm -rf /var/lib/apt/lists/*

# Download and build PostgreSQL 17
ARG PG_VERSION=17.0
RUN cd /tmp \
    && wget https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz \
    && tar -xzf postgresql-${PG_VERSION}.tar.gz \
    && cd postgresql-${PG_VERSION} \
    && ./configure \
        --prefix=/usr/local/pgsql \
        --with-openssl \
        --with-libxml \
        --with-libxslt \
        --with-lz4 \
        --with-zstd \
        --with-icu \
    && make -j$(nproc) \
    && make install \
    && cd contrib \
    && make -j$(nproc) \
    && make install

# Final stage
FROM debian:bullseye-slim

# Unraid user/group
ARG PUID=99
ARG PGID=100

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreadline8 \
    zlib1g \
    libssl1.1 \
    libxml2 \
    libxslt1.1 \
    liblz4-1 \
    libzstd1 \
    libicu67 \
    locales \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.utf8

# Copy PostgreSQL from builder
COPY --from=builder /usr/local/pgsql /usr/local/pgsql

# Add PostgreSQL to PATH
ENV PATH=/usr/local/pgsql/bin:$PATH
ENV PGDATA=/var/lib/postgresql/data

# Create postgres user with Unraid UID/GID
RUN (groupadd -g ${PGID} postgres || true) \
    && useradd -u ${PUID} -g users -d /var/lib/postgresql -s /bin/bash postgres \
    && mkdir -p /var/lib/postgresql/data /var/run/postgresql /docker-entrypoint-initdb.d \
    && chown -R postgres:users /var/lib/postgresql /var/run/postgresql

# Copy custom entrypoint
COPY --chown=postgres:postgres docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy initialization scripts
COPY --chown=postgres:postgres initdb.d/ /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Volume for data persistence
VOLUME ["/var/lib/postgresql/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD pg_isready -U postgres || exit 1

# Entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["postgres"]

# Labels
LABEL maintainer="Atlas - Unraid MacGyver Stack" \
      org.opencontainers.image.title="postgresql-MAC" \
      org.opencontainers.image.description="PostgreSQL 17 for Unraid MacGyver Stack" \
      org.opencontainers.image.version="17.0" \
      org.opencontainers.image.source="https://www.postgresql.org/"