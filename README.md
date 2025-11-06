# FastBCP - Docker Image (Linux x64) – v0.28.0+

Minimal, production‑ready container image to run **FastBCP** (parallel export CLI). This setup targets **FastBCP ≥ 0.28.0**, which supports passing the license **inline** via `--license "<content>"` — no entrypoint script or license file is required.

> ⚠️ **Binary required**  
> The FastBCP binary is **not** distributed in this repository. Request the **Linux x64** build here:  
> 👉 https://www.arpe.io/get-your-fastbcp-trial/  
> Rename it to `fastbcp`, place it at the repository root (next to the `Dockerfile`), then build the image.

## Table of contents
- [Prerequisites](#prerequisites)
- [Get the binary](#get-the-binary)
- [Build](#build)
- [Run FastBCP](#run-fastbcp)
- [License (≥ 0.28.0)](#license--0280)
- [Volumes](#volumes)
- [Examples](#examples)
- [Docker Compose](#docker-compose)
- [Performance & networking](#performance--networking)
- [Security tips](#security-tips)
- [Troubleshooting](#troubleshooting)
- [Notes](#notes)

---

## Prerequisites
- Docker 24+ (or Podman)
- **FastBCP Linux x64 ≥ 0.28.0** binary
- Optional: `FastBCP_Settings.json` to mount/copy into `/config`

## Get the binary
1. Request a trial: https://www.arpe.io/get-your-fastbcp-trial/
2. Rename the downloaded file to `fastbcp` and ensure it is executable if testing locally:
   ```bash
   chmod +x fastbcp
   ```
3. Place it at the **repository root** (beside `Dockerfile`).

## Build
```bash
docker build -t fastbcp:latest .
docker run --rm fastbcp:latest --version
```

## Run FastBCP
This container has `ENTRYPOINT` set to the `fastbcp` binary. Any arguments you pass to `docker run` are forwarded to FastBCP.
```bash
docker run --rm fastbcp:latest --help
```

## License (≥ 0.28.0)
Since 0.28.0, pass the **license content directly** via `--license "…"`. Several safe patterns:

- **Environment variable + substitution** (recommended):
  ```bash
  export FASTBCP_LICENSE_CONTENT="$(cat ./licence.txt)"
  docker run --rm fastbcp:latest     --license "${FASTBCP_LICENSE_CONTENT}" --version
  ```

- **Inline substitution**:
  ```bash
  docker run --rm fastbcp:latest     --license "$(cat ./licence.txt)" --version
  ```

- **Mounted file** (alternative):
  ```bash
  docker run --rm -v "$PWD/config:/config" fastbcp:latest     --license "$(cat /config/FastBCP.lic)" --version
  ```

> 🔐 **Good practice**: prefer `--env-file`, Docker/Compose/Kubernetes secrets, or managed identities for cloud credentials. Avoid leaving the license content in shell history.

## Volumes
- `/work`   – working directory (container `WORKDIR`)
- `/config` – optional configuration (e.g., `FastBCP_Settings.json`)
- `/data`   – target source/exports

## Examples

> The exact parameters depend on your source and target settings. The snippets below illustrate the call pattern from Docker.

### 1) SQL Server → local CSV
```bash
docker run --rm   --add-host=host.docker.internal:host-gateway   -v "$PWD/data:/data"   -e FASTBCP_LICENSE_CONTENT="$(cat ./licence.txt)"   fastbcp:latest     --license "${FASTBCP_LICENSE_CONTENT}"     export       --source "mssql://user:*****@host.docker.internal:1433/DbName?encrypt=true&trustServerCertificate=true"       --query  "SELECT * FROM dbo.BigTable"       --out    "/data/bigtable.csv"       --format csv --delimiter ";" --header
```

### 2) PostgreSQL → partitioned Parquet (local)
```bash
docker run --rm   --add-host=host.docker.internal:host-gateway   -v "$PWD/data:/data"   -e FASTBCP_LICENSE_CONTENT="$(cat ./licence.txt)"   fastbcp:latest     --license "${FASTBCP_LICENSE_CONTENT}"     export       --source "postgres://user:*****@host.docker.internal:5432/db"       --table  public.lineitem       --out    "/data/lineitem_{part}.parquet"       --format parquet --parallel 16 --files 16
```

### 3) Export → S3
```bash
docker run --rm   -e AWS_ACCESS_KEY_ID=AKIA...   -e AWS_SECRET_ACCESS_KEY=****   -e AWS_REGION=eu-west-1   -e FASTBCP_LICENSE_CONTENT="$(cat ./licence.txt)"   fastbcp:latest     --license "${FASTBCP_LICENSE_CONTENT}"     export       --source "postgres://user:*****@db:5432/app"       --query  "SELECT * FROM public.events"       --out    "s3://my-bucket/exports/events_{part}.parquet"       --format parquet --parallel 32
```

## Docker Compose
```yaml
services:
  fastbcp:
    image: fastbcp:latest
    container_name: fastbcp
    environment:
      FASTBCP_LICENSE_CONTENT: ${FASTBCP_LICENSE_CONTENT:-}
      # AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
      # AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
      # AWS_REGION: eu-west-1
    volumes:
      - ./config:/config
      - ./data:/data
    # On Linux, to reach a database listening on the Docker host:
    extra_hosts:
      - "host.docker.internal:host-gateway"
    command: ["--help"]
```
```bash
docker compose up --build fastbcp
```

## Performance & networking
- Place `/data` on fast storage (NVMe) when exporting large datasets.
- Tune `--parallel` according to CPU and I/O throughput.
- To reach a DB on the local host from Linux, add `--add-host=host.docker.internal:host-gateway` (or the `extra_hosts` entry in Compose).
- For high‑bandwidth object‑store targets (S3/ADLS/GCS), ensure consistent MTU settings end‑to‑end; consider jumbo frames where appropriate.

## Security tips
- Never commit your license or cloud credentials to source control.
- Prefer Docker/Compose/Kubernetes **secrets** or environment files (`--env-file`) and managed identities (IAM Role / IRSA / Workload Identity / Managed Identity).

## Troubleshooting
- **Exec format error** → ensure the binary is Linux x64 and executable (`chmod +x fastbcp`).
- **Missing `libicu`/`libssl`/`zlib`/`krb5`** → the image includes `libicu72`, `libssl3`, `zlib1g`, `libkrb5-3`. If your build requires additional libs, add them via `apt`.
- **Permission denied** writing under `/data` → ensure the host directory permissions match the container UID (`10001`).
- **DB host not reachable** → on Linux, use `--add-host=host.docker.internal:host-gateway` or the Compose `extra_hosts` equivalent.

## Notes
- This image **does not** embed the proprietary binary. You must provide it (trial or licensed).
- OCI labels are set for traceability (source, vendor, license).
