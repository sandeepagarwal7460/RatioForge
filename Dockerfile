# ============================================================
# BUILD
# ============================================================

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder

WORKDIR /src

COPY . .

ENV EnableWindowsTargeting=true

RUN dotnet restore Source/RatioForge.sln \
    -p:EnableWindowsTargeting=true

RUN dotnet publish Source/RatioForge/RatioForge.csproj \
    --configuration Release \
    --runtime win-x64 \
    --self-contained true \
    --output /publish \
    -p:EnableWindowsTargeting=true \
    -p:PublishSingleFile=false \
    -p:DebugType=None \
    -p:DebugSymbols=false


# ============================================================
# RUNTIME
# ============================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ENV WINEPREFIX=/wine
ENV WINEARCH=win64
ENV DISPLAY=:99

WORKDIR /app


# ============================================================
# Enable 32-bit architecture
# ============================================================

RUN dpkg --add-architecture i386


# ============================================================
# Install prerequisites for WineHQ
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        wget \
        ca-certificates \
        gnupg2 \
        software-properties-common \
        xvfb \
        x11vnc \
        novnc \
        websockify \
        xauth \
        procps \
        python3 \
        && \
    rm -rf /var/lib/apt/lists/*


# ============================================================
# WineHQ repository
# ============================================================

RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key \
        https://dl.winehq.org/wine-builds/winehq.key


RUN wget -NP /etc/apt/sources.list.d/ \
        https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources


# ============================================================
# Install current Wine stable
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        --install-recommends \
        winehq-stable \
        && \
    rm -rf /var/lib/apt/lists/*


# ============================================================
# Copy RatioForge
# ============================================================

COPY --from=builder /publish /app/RatioForge


# ============================================================
# Startup
# ============================================================

COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh


EXPOSE 10000

CMD ["/app/start.sh"]
