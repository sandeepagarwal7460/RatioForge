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

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ENV WINEPREFIX=/wine
ENV WINEARCH=win64
ENV DISPLAY=:99

WORKDIR /app

RUN dpkg --add-architecture i386

RUN apt-get update && \
    apt-get install -y \
        wine64 \
        wine32 \
        winbind \
        xvfb \
        xauth \
        ca-certificates \
        procps \
        python3 \
        && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /publish /app/RatioForge

COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

EXPOSE 10000

CMD ["/app/start.sh"]
