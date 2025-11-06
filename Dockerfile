FROM ubuntu:22.04

RUN apt-get update && apt-get install -y libicu70 && rm -rf /var/lib/apt/lists/*

# Airflow XCom
RUN mkdir -p /airflow/xcom

WORKDIR /app

COPY app/ /app/
COPY FastBCP_Settings.json /app/

RUN chmod +x ./FastBCP

ENTRYPOINT ["./FastBCP"]
