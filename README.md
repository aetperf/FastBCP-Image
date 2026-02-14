# FastBCP Docker Image

Minimal, production‑ready container image to run **[FastBCP](https://www.arpe.io/fastbcp)** (parallel export CLI), a high-performance bulk copy utility designed for data integration and automation workflows.

This setup targets **FastBCP ≥ 0.28.0**, which supports passing the license **inline** via `--license "<content>"`.

## Image Overview

* **Base image:** `debian:trixie-slim`
* **Entrypoint:** `/usr/local/bin/FastBCP`
* **Repository:** [https://github.com/aetperf/FastBCP-Image](https://github.com/aetperf/FastBCP-Image)
* **DockerHub:** [aetp/fastbcp](https://hub.docker.com/r/aetp/fastbcp)
* **Published automatically** via GitHub Actions for each new release and weekly security updates

> **For custom builds**  
> The FastBCP binary is **not** distributed in this repository. Request the **Linux x64** build here:  
> https://fastbcp.arpe.io/start/  
> Unzip and place it at the repository root (next to the `Dockerfile`), then build your own custom image.


## Table of contents

### Building Your Own Image
* [Prerequisites](#prerequisites)
* [Get the binary](#get-the-binary-for-build-only)
* [Build](#build)
* [Run FastBCP](#run-fastbcp)

### Using the Prebuilt Image from DockerHub
* [Prebuilt image on DockerHub](#prebuilt-image-on-dockerhub)
* [Usage](#usage)
* [Examples](#examples)

### Configuration & Advanced Usage
* [Volumes](#volumes)
* [Configuring FastBCP Logging](#configuring-fastbcp-logging-with-custom-settings)
* [Performance & networking](#performance--networking)
* [Security tips](#security-tips)

### Reference
* [Troubleshooting](#troubleshooting)
* [Notes](#notes)

---

## Prerequisites
- Docker 24+ (or Podman)
- **FastBCP Linux x64 ≥ 0.28.0** binary (for build only)
- Optional: `FastBCP_Settings.json` to mount/copy into `/config` for custom logging settings

## Get the binary (for build only)
1. Request a trial: https://fastbcp.arpe.io
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

## Prebuilt image on DockerHub

You can use a prebuilt image from DockerHub that already includes the FastBCP binary. You must provide your own license at runtime.

**DockerHub repository:** [aetp/fastbcp](https://hub.docker.com/r/aetp/fastbcp)

### Available tags
- **Version-specific tags** are aligned with FastBCP releases (e.g., `v0.28.3`)
- **`latest`** tag always points to the most recent FastBCP version

### Automatic updates
- **New releases:** Images are automatically built when new FastBCP versions are released
- **Security updates:** The **latest version of each minor branch** (e.g., latest v0.27.x, v0.28.x, v0.29.x) is automatically rebuilt weekly (every Monday) with the latest base image and security patches
  - This ensures that all actively used versions remain secure without breaking compatibility
  - Example: If you use `v0.28.8` (latest of 0.28.x branch), it gets security updates even after `v0.29.0` is released

### Pull the image

```bash
# Latest version
docker pull aetp/fastbcp:latest

# Specific version
docker pull aetp/fastbcp:v0.28.3
```

### Run FastBCP directly

```bash
# Get help
docker run --rm aetp/fastbcp:latest

# Check version
docker run --rm aetp/fastbcp:latest --version
```

# Usage

The Docker image uses the FastBCP binary as its entrypoint, so you can run it directly with parameters as defined in the [FastBCP documentation](https://fastbcp.arpe.io/docs/latest/).

### Basic commands

```bash
# Get command line help
docker run --rm aetp/fastbcp:latest

# Check version
docker run --rm aetp/fastbcp:latest --version
```

### License requirement

Since version 0.28.0, pass the **license content directly** via `--license "…"`.

```bash
export licenseContent=$(cat ./FastBCP.lic)

# Use $licenseContent in your docker run commands
docker run --rm aetp/fastbcp:latest \
  --license "$licenseContent" \
  [other parameters...]
```

**Best practice:** Prefer `--env-file`, Docker/Compose/Kubernetes secrets, or managed identities for cloud credentials. Avoid leaving the license content in shell history.

## Examples

> The exact parameters depend on your source and target settings. The snippets below illustrate the call pattern from Docker in a **Linux shell**.

### 1) SQL Server → Parquet on S3

```bash  
export licenseContent=$(cat ./FastBCP.lic)

docker run --rm \
-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
-e AWS_REGION=${AWS_REGION} \
aetp/fastbcp:latest \
--connectiontype "mssql" \
--server "host.docker.internal,1433" \
--user "FastUser" \
--password "FastPassword" \
--database "tpch_test" \
--query "SELECT * FROM dbo.orders WHERE year(o_orderdate)=1998" \
--fileoutput "orders.parquet" \
--directory "s3://aetpftoutput/dockertest/" \
--paralleldegree 12 \
--parallelmethod "Ntile" \
--distributekeycolumn "o_orderkey" \
--merge false \
--license "$licenseContent"
```

### 2) SQL Server → CSV with custom logging

```bash
export licenseContent=$(cat ./FastBCP.lic)

docker run --rm \
-v fastbcp-config:/config \
-v fastbcp-data:/data \
-v fastbcp-logs:/logs \
aetp/fastbcp:latest \
--settingsfile "/config/FastBCP_Settings_Logs_To_Files.json" \
--connectiontype "mssql" \
--server "host.docker.internal,1433" \
--user "FastUser" \
--password "FastPassword" \
--database "tpch_test" \
--query "SELECT * FROM dbo.orders WHERE year(o_orderdate)=1998" \
--fileoutput "orders.csv" \
--directory "/data/orders/csv" \
--delimiter "|" \
--decimalseparator "." \
--dateformat "yyyy-MM-dd HH:mm:ss" \
--paralleldegree 12 \
--parallelmethod "Ntile" \
--distributekeycolumn "o_orderkey" \
--merge false \
--license "$licenseContent"
```

### 3) PostgreSQL → Parquet on Azure Data Lake Storage (ADLS)

```bash
export licenseContent=$(cat ./FastBCP.lic)
export adlscontainer="aetpadlseu"

docker run --rm \
-e AZURE_CLIENT_ID=${AZURE_CLIENT_ID} \
-e AZURE_TENANT_ID=${AZURE_TENANT_ID} \
-e AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET} \
aetp/fastbcp:latest \
--connectiontype "pgcopy" \
--server "host.docker.internal:15432" \
--user "FastUser" \
--password "FastPassword" \
--database "tpch" \
--sourceschema "tpch_10" \
--sourcetable "orders" \
--query "SELECT * FROM tpch_10.orders WHERE o_orderdate >= '1998-01-01' AND o_orderdate < '1999-01-01'" \
--fileoutput "orders.parquet" \
--directory "abfss://${adlscontainer}.dfs.core.windows.net/fastbcpoutput/testdfs/orders" \
--paralleldegree -2 \
--parallelmethod "Ctid" \
--license "$licenseContent"
```

### 4) Oracle → Parquet on Google Cloud Storage (GCS)

```bash
export licenseContent=$(cat ./FastBCP.lic)
export gcsbucket="aetp-gcs-bucket"
export GOOGLE_APPLICATION_CREDENTIALS_JSON=$(cat ./gcp-credentials.json)

docker run --rm \
-e GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS_JSON}" \
aetp/fastbcp:latest \
--connectiontype "oraodp" \
--server "host.docker.internal:1521/FREEPDB1" \
--user "TPCH_IN" \
--password "TPCH_IN" \
--database "FREEPDB1" \
--sourceschema "TPCH_IN" \
--sourcetable "ORDERS" \
--fileoutput "orders.parquet" \
--directory "gs://${gcsbucket}/fastbcpoutput/testgs/orders" \
--parallelmethod "Rowid" \
--paralleldegree -2 \
--license "$licenseContent"
```

## Volumes

The Docker image declares several volumes to organize data and configuration:

```dockerfile
VOLUME ["/config", "/data", "/work", "/logs"]
```

### Volume configuration and access modes

| Volume Path | Description                                                         | Access Mode               | Typical Usage                                   |
| ----------- | ------------------------------------------------------------------- | ------------------------- | ----------------------------------------------- |
| `/config`   | Contains user-provided configuration files (e.g., Serilog settings) | **Read-only / Read-many** | Shared across multiple containers; not modified |
| `/data`     | Input/output data directory                                         | **Read-many/Write-many**  | Stores imported or exported data files          |
| `/work`     | Temporary working directory (container `WORKDIR`)                   | **Read-many/Write-many**  | Used internally for temporary processing        |
| `/logs`     | Log output directory (per-run or aggregated logs)                   | **Read-many/Write-many**  | Stores runtime and execution logs               |

## Configuring FastBCP Logging with Custom Settings

*Available starting from version **v0.28.3***

FastBCP supports **custom logging configuration** through an external Serilog settings file in JSON format.
This allows you to control **how and where logs are written** — to the console, to files, or dynamically per run.

You can download an example logging settings file directly from GitHub:  
**[FastBCP_Settings_Logs_To_Files.json](https://raw.githubusercontent.com/aetperf/FastBCP-Image/main/FastBCP_Settings_Logs_To_Files.json)**

Custom settings files must be **mounted into the container** under the `/config` directory.


---

### Example: Logging to Console, Airflow, and Dynamic Log Files

The following configuration is recommended for most production or Airflow environments.
It writes:

* Logs to the console for real-time visibility
* Run summary logs to `/airflow/xcom/return.json` for Airflow integration
* Per-run logs under `/logs`, automatically named with `{LogTimestamp}` and `{TraceId}`

```json
{
  "Serilog": {
    "Using": [
      "Serilog.Sinks.Console",
      "Serilog.Sinks.File",
      "Serilog.Enrichers.Environment",
      "Serilog.Enrichers.Thread",
      "Serilog.Enrichers.Process",
      "Serilog.Enrichers.Context",
      "Serilog.Formatting.Compact"
    ],
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "outputTemplate": "{Timestamp:yyyy-MM-ddTHH:mm:ss.fff zzz} -|- {Application} -|- {runid} -|- {Level:u12} -|- {fulltargetname} -|- {Message}{NewLine}{Exception}",
          "theme": "Serilog.Sinks.SystemConsole.Themes.ConsoleTheme::None, Serilog.Sinks.Console",
          "applyThemeToRedirectedOutput": false
        }
      },
      {
        "Name": "File",
        "Args": {
          "path": "/airflow/xcom/return.json",
          "formatter": "Serilog.Formatting.Compact.CompactJsonFormatter, Serilog.Formatting.Compact"
        }
      },
      {
        "Name": "Map",
        "Args": {
          "to": [
            {
              "Name": "File",
              "Args": {
                "path": "/logs/{logdate}/{sourcedatabase}/log-{filename}-{LogTimestamp}-{TraceId}.json",
                "formatter": "Serilog.Formatting.Compact.CompactJsonFormatter, Serilog.Formatting.Compact",
                "rollingInterval": "Infinite",
                "shared": false,
                "encoding": "utf-8"
              }
            }
          ]
        }
      }
    ],
    "Enrich": [
      "FromLogContext",
      "WithMachineName",
      "WithProcessId",
      "WithThreadId"
    ],
    "Properties": {
      "Application": "FastBCP"
    }
  }
}
```

Important notes:

* If a target directory (such as `/logs` or `/airflow/xcom`) does not exist, FastBCP automatically creates it.
* The file `/airflow/xcom/return.json` is designed to provide run summaries compatible with Airflow’s XCom mechanism.

---

### Available Tokens for Path or Filename Formatting

You can use the following placeholders to dynamically generate log file names or directories:

| Token Name      | Description                                  |
| ------------------ | -------------------------------------------- |
| `{logdate}`        | Current date in `yyyy-MM-dd` format          |
| `{logtimestamp}`   | Full timestamp of the log entry              |
| `{sourcedatabase}` | Name of the source database                  |
| `{sourceschema}`   | Name of the source schema                    |
| `{sourcetable}`    | Name of the source table                     |
| `{filename}`       | Name of the file being processed             |
| `{runid}`          | Run identifier provided in the command line  |
| `{traceid}`        | Unique trace identifier generated at runtime |

---

### Mounting a Custom Settings File

Your Serilog configuration file (for example, `FastBCP_Settings_Logs_To_Files.json`) must be placed in `/config`,
either by mounting a local directory or by using a Docker named volume.

Example with named volumes:

```bash
# First, copy your config file to a volume location
cp ~/FastBCP_Settings_Logs_To_Files.json /volumes/fastbcp-config/

# Then run FastBCP with mounted volumes
docker run --rm \
-v fastbcp-config:/config \
-v fastbcp-data:/data \
-v fastbcp-logs:/logs \
aetp/fastbcp:latest \
--settingsfile "/config/FastBCP_Settings_Logs_To_Files.json" \
--connectiontype "mssql" \
--server "host.docker.internal,1433" \
--user "FastUser" \
--password "FastPassword" \
--database "tpch_test" \
--query "SELECT * FROM dbo.orders" \
--fileoutput "orders.csv" \
--directory "/data" \
--paralleldegree 12 \
--parallelmethod "Ntile" \
--distributekeycolumn "o_orderkey" \
--merge false \
--license "$licenseContent"
```

If the `--settingsfile` argument is not provided, FastBCP will use its built-in default logging configuration.

---

## Performance & networking
- Place `/data` on fast storage (NVMe) when exporting large datasets locally.
- Tune `--parallel` according to CPU and I/O throughput.
- To reach a DB on the local host from Linux, add `--add-host=host.docker.internal:host-gateway` (or the `extra_hosts` entry in Compose).
- For high‑bandwidth object‑store targets (S3/ADLS/GCS), ensure consistent MTU settings end‑to‑end; consider jumbo frames where appropriate and if possible a dedicated endpoint.

## Security tips
- Never commit your license or cloud credentials to source control.
- Prefer Docker/Compose/Kubernetes **secrets** or environment files (`--env-file`) and managed identities (IAM Role / IRSA / Workload Identity / Managed Identity).
- FastBCP will try classic method to authenticate to cloud object stores (default profile, IAM Role, Env) if no explicit credentials are provided.

## Troubleshooting
- **Exec format error** → ensure the binary is Linux x64 and executable (`chmod +x fastbcp`).
- **Missing `libicu`/`libssl`/`zlib`/`krb5`** → the image includes `libicu76`, `libssl3`, `zlib1g`, `libkrb5-3`. If your build requires additional libs, add them via `apt`.
- **Permission denied** writing under `/data` → ensure the host directory permissions match the container UID (`10001`).
- **DB host not reachable** → on Linux, use `--add-host=host.docker.internal:host-gateway` or the Compose `extra_hosts` equivalent.

## Notes
- This image **embeds the proprietary FastBCP binary**. You must provide a valid license (or request a trial license) for the tool to work. **Do not share your private license outside your organization.**
- OCI labels are set for traceability (source, vendor, license).
- **Security maintenance:** The latest version of each minor branch (e.g., v0.27.x, v0.28.x, v0.29.x) is automatically rebuilt weekly with security patches, ensuring long-term security without forcing upgrades to newer minor versions.
- For questions or support, visit [FastBCP documentation](https://fastbcp.arpe.io/docs/latest/) or contact [ARPE.IO](https://www.arpe.io/).
