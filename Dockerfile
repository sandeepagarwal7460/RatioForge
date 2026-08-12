FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
        wine \
        wine32 \
        wine64 \
        xvfb \
        winbind \
        cabextract \
        && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY RatioForge.exe /app/RatioForge.exe

CMD ["xvfb-run", "--auto-servernum", "wine", "/app/RatioForge.exe"]
