# syntax=docker/dockerfile:1.7
FROM debian:bookworm-slim

# Common runtime packages for self-contained .NET binaries (ICU/SSL/zlib/Kerberos), CA, tz, curl
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates tzdata curl \
      libicu72 libssl3 zlib1g libkrb5-3 \
    ; rm -rf /var/lib/apt/lists/*

# Non-root user
ARG USER=fastbcp
ARG UID=10001
RUN useradd -m -u ${UID} -s /usr/sbin/nologin ${USER}

# Useful directories
WORKDIR /work
RUN mkdir -p /config /data && chown -R ${USER}:${USER} /config /data /work

######################################################################
# Copy the FastBCP Linux x64 binary (>= 0.28.0) renamed to "fastbcp"
# Place it at the root of the repo before building.
######################################################################
COPY --chown=${USER}:${USER} fastbcp /usr/local/bin/fastbcp

RUN chmod 0755 /usr/local/bin/fastbcp

# OCI Labels
LABEL org.opencontainers.image.title="FastBCP (CLI) - Runtime Docker Image" \
      org.opencontainers.image.description="Minimal container to run FastBCP (parallel export to files/objects)" \
      org.opencontainers.image.vendor="Architecture & Performance" \
      org.opencontainers.image.source="https://github.com/aetperf/FastBCP-Image" \
      org.opencontainers.image.licenses="Proprietary"

# Standard volumes
VOLUME ["/config", "/data", "/work"]

# Default to non-root
USER ${USER}

# ENTRYPOINT directly on the FastBCP binary
ENTRYPOINT ["/usr/local/bin/fastbcp"]

