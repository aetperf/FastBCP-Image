FROM ubuntu:22.04

RUN apt-get update && apt-get install -y curl unzip libicu70 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /airflow/xcom

RUN chmod -R 777 /airflow/xcom

WORKDIR /app

RUN curl -L -o FastBCP.zip "https://aetpshared.s3.eu-west-1.amazonaws.com/FastBCP/trial/FastBCP-linux-x64.zip" \
    && unzip FastBCP.zip \
    && rm FastBCP.zip

COPY FastBCP_Settings.json /app/

RUN chmod +x ./FastBCP

ENTRYPOINT ["./FastBCP"]
