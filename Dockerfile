# ============================================
# Stage 1: Build RatioForge from source
# ============================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder

WORKDIR /src

# Copy the entire repository
COPY . .

# Linux containers need this property to build
# Windows-targeted .NET projects.
ENV EnableWindowsTargeting=true

# Restore
RUN dotnet restore Source/RatioForge.sln \
    -p:EnableWindowsTargeting=true

# Publish the Windows x64 application.
# Self-contained means the Windows .NET runtime is included.
RUN dotnet publish Source/RatioForge/RatioForge.csproj \
    --configuration Release \
    --runtime win-x64 \
    --self-contained true \
    --output /publish \
    -p:EnableWindowsTargeting=true \
    -p:PublishSingleFile=false


# ============================================
# Stage 2: Linux + Wine runtime
# ============================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ENV WINEPREFIX=/wine
ENV DISPLAY=:99
ENV PORT=10000

# Enable 32-bit architecture
RUN dpkg --add-architecture i386

# Install Wine + virtual display
RUN apt-get update && \
    apt-get install -y \
        wine64 \
        wine32 \
        winbind \
        xvfb \
        ca-certificates \
        curl \
        python3 \
        && \
    rm -rf /var/lib/apt/lists/*

# Application directory
WORKDIR /app

# Copy the compiled Windows application
FROM builder AS published

# Return to runtime image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEPREFIX=/wine
ENV DISPLAY=:99
ENV PORT=10000

RUN dpkg --add-architecture i386

RUN apt-get update && \
    apt-get install -y \
        wine64 \
        wine32 \
        winbind \
        xvfb \
        ca-certificates \
        curl \
        python3 \
        && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy compiled RatioForge from builder
COPY --from=builder /publish /app/RatioForge

# Copy our startup script
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

# Render expects the application to listen on this port.
EXPOSE 10000

CMD ["/app/start.sh"]
