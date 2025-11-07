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
docker pull aetp/fastbcp:v0.28.1
```

# Usage

the docker image use as entrypoint the fastbcp binary, so you can run it directly with parameters like defined in the [FastBCP documentation](https://aetperf.github.io/FastBCP-Documentation/).

You can get the **command line help** using this 

```bash
docker run --rm fastbcp:latest
```

You can get the **version** using this 

```bash
docker run --rm fastbcp:latest --version
```

## Samples

- **Export from sql server to parquet on S3**:

```bash  
export licenseContent = cat ./FastBCP.lic
docker run --rm \
-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
-e AWS_REGION=${AWS_REGION} \
fastbcp:latest \
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

## Other Examples

> The exact parameters depend on your source and target settings. The snippets below illustrate the call pattern from Docker in a **linux shell**.

### 1) Export from sql server to csv /data using a filtered query as source and Ntile method as parallelism
```bash
export licenseContent = cat ./FastBCP.lic
docker run --rm \
fastbcp:latest \
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

docker run --rm \
-e AZURE_CLIENT_ID=${AZURE_CLIENT_ID} \
-e AZURE_TENANT_ID=${AZURE_TENANT_ID} \
-e AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET} \
fastbcp:latest \
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
fastbcp:latest \
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
--license $licenseContent 
```




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
