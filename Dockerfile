# ============================================================
# BUILD STAGE
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
# Install basic packages
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        wget \
        curl \
        ca-certificates \
        gnupg2 \
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
# Add WineHQ repository
# ============================================================

RUN mkdir -pm755 /etc/apt/keyrings

RUN wget -O /etc/apt/keyrings/winehq-archive.key \
    https://dl.winehq.org/wine-builds/winehq.key

RUN wget -NP /etc/apt/sources.list.d/ \
    https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources


# ============================================================
# Install Wine Stable
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
# Create temporary display for Wine setup
# ============================================================

RUN Xvfb :99 \
        -screen 0 1280x720x24 \
        -ac \
        >/tmp/build-xvfb.log 2>&1 & \
    XVFB_PID=$! && \
    sleep 3 && \
    wineboot --init || true


# ============================================================
# Install Wine Mono
# ============================================================

RUN wget -O /tmp/wine-mono.msi \
    https://dl.winehq.org/wine/wine-mono/10.2.0/wine-mono-10.2.0-x86.msi


RUN Xvfb :99 \
        -screen 0 1280x720x24 \
        -ac \
        >/tmp/mono-xvfb.log 2>&1 & \
    XVFB_PID=$! && \
    sleep 3 && \
    wine msiexec /i /tmp/wine-mono.msi /qn || true


RUN rm -f /tmp/wine-mono.msi


# ============================================================
# Verify Wine
# ============================================================

RUN wine --version


# ============================================================
# Startup script
# ============================================================

COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh


# ============================================================
# Render
# ============================================================

EXPOSE 10000

CMD ["/app/start.sh"]
