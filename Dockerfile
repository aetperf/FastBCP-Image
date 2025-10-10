FROM ubuntu:22.04

# Installer curl, unzip et libicu (version 70 sur Jammy)
RUN apt-get update && apt-get install -y curl unzip libicu70 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Télécharger et extraire FastBCP
RUN curl -L -o FastBCP.zip "https://aetpshared.s3.eu-west-1.amazonaws.com/FastBCP/trial/FastBCP-linux-x64.zip" \
    && unzip FastBCP.zip \
    && rm FastBCP.zip

RUN chmod +x ./FastBCP

ENTRYPOINT ["./FastBCP"]
