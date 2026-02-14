# syntax=docker/dockerfile:1.7
FROM debian:trixie-slim

# Common runtime packages for self-contained .NET binaries (ICU/SSL/zlib/Kerberos), CA, tz, curl
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates tzdata curl \
      passwd \
      libicu76 \
      libssl3 zlib1g libkrb5-3 \
    ; rm -rf /var/lib/apt/lists/*

# Non-root user
ARG USER=fastbcp
ARG UID=10001
RUN set -eux; \
    useradd -m -u ${UID} -s /usr/sbin/nologin ${USER}

# Useful directories
WORKDIR /work
RUN mkdir -p /config /data /logs /airflow/xcom \
 && chown -R ${USER}:${USER} /config /data /work /logs /airflow/xcom

# Copy the FastBCP Linux x64 binary (downloaded by CI at repo root)
COPY --chown=${USER}:${USER} FastBCP /usr/local/bin/FastBCP
RUN chmod 0755 /usr/local/bin/FastBCP

# OCI Labels
LABEL org.opencontainers.image.title="FastBCP (CLI) - Runtime Docker Image" \
      org.opencontainers.image.description="Minimal container to run FastBCP (parallel export to files/objects)" \
      org.opencontainers.image.vendor="Architecture & Performance" \
      org.opencontainers.image.source="https://github.com/aetperf/FastBCP-Image" \
      org.opencontainers.image.licenses="Proprietary"

VOLUME ["/config", "/data", "/work", "/logs"]

USER ${USER}
ENTRYPOINT ["/usr/local/bin/FastBCP"]
