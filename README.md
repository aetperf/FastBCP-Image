# FastBCP - Docker Image (Linux x64) – v0.28.0+

Minimal, production‑ready container image to run **FastBCP** (parallel export CLI). This setup targets **FastBCP ≥ 0.28.0**, which supports passing the license **inline** via `--license "<content>"` 

> **Binary required for custom build**  
> The FastBCP binary is **not** distributed in this repository. Request the **Linux x64** build here:  
> https://www.arpe.io/get-your-fastbcp-trial/  
> unzip and place it at the repository root (next to the `Dockerfile`), then build your own custom image.

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
- **FastBCP Linux x64 ≥ 0.28.0** binary (for build only)
- Optional: `FastBCP_Settings.json` to mount/copy into `/config` for custom logging settings

## Get the binary (for build only)
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

## License
Since 0.28.0, pass the **license content directly** via `--license "…"`. Several 

## Prebuilt image on dockerhub
You can also use a prebuilt image on DockerHub that already include the binary. You must provide your own license at runtime.
- dockerhub versions/releases are aligned with the fastbcp versions/releases.

```bash
docker pull aetp/fastbcp:latest
```
or 
```bash
docker pull aetp/fastbcp:v0.28.3
```

# Usage

the docker image use as entrypoint the fastbcp binary, so you can run it directly with parameters like defined in the [FastBCP documentation](https://aetperf.github.io/FastBCP-Documentation/).

You can get the **command line help** using this 

```bash
docker run --rm aetp/fastbcp:latest
```

You can get the **version** using this 

```bash
docker run --rm aetp/fastbcp:latest --version
```

## Samples

- **Export from sql server to parquet on S3**:

```bash  
export licenseContent = cat ./FastBCP.lic
docker run --rm  \
-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
-e AWS_REGION=${AWS_REGION} \
aetp/fastbcp:latest \
--connectiontype "mssql" \
--server "host.docker.internal,1433" \
--user "FastUser" \
--password "FastPassword" \
--database "tpch_test" \
--query "SELECT * FROM dbo.orders where year(o_orderdate)=1998" \
--fileoutput "orders.parquet" \
--directory "s3://aetpftoutput/dockertest/" \
--paralleldegree 12 \
--parallelmethod "Ntile" \
--distributekeycolumn "o_orderkey" \
--merge false \
--license $licenseContent 
```


**Good practice**: prefer `--env-file`, Docker/Compose/Kubernetes secrets, or managed identities for cloud credentials. Avoid leaving the license content in shell history.

## Volumes
- `/work`   – working directory (container `WORKDIR`)
- `/config` – optional configuration directory (e.g. to store `FastBCP_Settings.json` for custom logging)
- `/data`   – target source/exports
- `/logs`   – logs directory (ensure that `FastBCP_Settings.json` is configured to write logs to this directory)


## Other Examples

> The exact parameters depend on your source and target settings. The snippets below illustrate the call pattern from Docker in a **linux shell**.

### 1) Export from sql server to csv /data using a filtered query as source and Ntile method as parallelism
```bash
export licenseContent = cat ./FastBCP.lic
docker run --rm \
aetp/fastbcp:latest \
--connectiontype "mssql" \
--server "host.docker.internal,1433" \
--user "FastUser" \
--password "FastPassword" \
--database "tpch_test" \
--query "SELECT * FROM dbo.orders where year(o_orderdate)=1998" \
--fileoutput "orders.csv" \
--directory "/data/orders/csv" \
--delimiter "|" \
--decimalseparator "." \
--dateformat "yyyy-MM-dd HH:mm:ss" \
--paralleldegree 12 \
--parallelmethod "Ntile" \
--distributekeycolumn "o_orderkey" \
--merge false \
--license $licenseContent 
```

### 2) PostgreSQL → partitioned Parquet to adls using a filtered query as source and Ctid method as parallelism
```bash
export licenseContent = $(cat ./FastBCP.lic)
export adlscontainer = "aetpadlseu"

docker run --rm  \
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
--query "SELECT * FROM tpch_10.orders where o_orderdate >= '1998-01-01' and o_orderdate < '1999-01-01'" \
--fileoutput "orders.parquet" \
--directory "abfss://${adlscontainer}.dfs.core.windows.net/fastbcpoutput/testdfs/orders" \
--paralleldegree -2 \
--parallelmethod "Ctid" \
--license $licenseContent 
```

### 3) Oracle (oraodp) → partitioned Parquet to gcs using table only as source and Rowid method as parallelism auto (-2)
```bash
export licenseContent = $(cat ./FastBCP.lic)
export gcsbucket = "aetp-gcs-bucket"

// get GCP credentials JSON content from file, then copy to env var
export GOOGLE_APPLICATION_CREDENTIALS_JSON=$(cat ./gcp-credentials.json)

docker run --rm \
-e GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS_JSON} \
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
--license $licenseContent 
```

## Configuring FastBCP Logging with Custom Settings

*Available starting from version **v0.28.3***

FastBCP supports **custom logging configuration** through an external Serilog settings file in JSON format.
This allows you to control **how and where logs are written** — to the console, to files, or dynamically per run.

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
          "keyPropertyName": "TraceId",
          "defaultKey": "no-trace",
          "to": [
            {
              "Name": "File",
              "Args": {
                "path": "/logs/log-{{LogTimestamp}}-{{TraceId}}.json",
                "formatter": "Serilog.Formatting.Compact.CompactJsonFormatter, Serilog.Formatting.Compact",
                "rollingInterval": "Infinite",
                "shared": false,
                "encoding": "utf-8",
                "retainedFileCountLimit": 100
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

### Available Variables for Path or Filename Formatting

You can use the following placeholders to dynamically generate log file names or directories:

| Variable Name      | Description                                  |
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

The Docker image declares several volumes to organize data and configuration:

```dockerfile
VOLUME ["/config", "/data", "/work", "/logs"]
```

Your Serilog configuration file (for example, `FastBCP_Settings_Logs_To_Files.json`) must be placed in `/config`,
either by mounting a local directory or by using a Docker named volume.

Example:

```bash
docker run --rm \
  -v D:\FastBCP\config:/config \
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
  --merge false 
```

If the `--settingsfile` argument is not provided, FastBCP will use its built-in default logging configuration.

---

### Volume Configuration and Access Modes

| Volume Path | Description                                                         | Access Mode           | Typical Usage                                   |
| ----------- | ------------------------------------------------------------------- | --------------------- | ----------------------------------------------- |
| `/config`   | Contains user-provided configuration files (e.g., Serilog settings) | Read-Only / Read-Many | Shared across multiple containers; not modified |
| `/data`     | Input/output data directory                                         | Read-Many/Write-Many       | Stores imported or exported data files          |
| `/work`     | Temporary working directory                                         | Read-Many/Write-Many       | Used internally for temporary processing        |
| `/logs`     | Log output directory (per-run or aggregated logs)                   | Read-Many/Write-Many       | Stores runtime and execution logs               |



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
- **Missing `libicu`/`libssl`/`zlib`/`krb5`** → the image includes `libicu72`, `libssl3`, `zlib1g`, `libkrb5-3`. If your build requires additional libs, add them via `apt`.
- **Permission denied** writing under `/data` → ensure the host directory permissions match the container UID (`10001`).
- **DB host not reachable** → on Linux, use `--add-host=host.docker.internal:host-gateway` or the Compose `extra_hosts` equivalent.

## Notes
- This image **does** embed the proprietary binary. you must provide a valid license (or request trial license) in order to work. **Do not share your private license outside your company**
- OCI labels are set for traceability (source, vendor, license).
