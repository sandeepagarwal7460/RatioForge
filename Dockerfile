FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEPREFIX=/wine
ENV DISPLAY=:99
ENV PORT=10000

# Enable 32-bit packages because some Windows applications/dependencies
# still require them.
RUN dpkg --add-architecture i386

RUN apt-get update && apt-get install -y \
    wine64 \
    wine32 \
    winbind \
    xvfb \
    cabextract \
    wget \
    curl \
    python3 \
    python3-pip \
    procps \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
WORKDIR /app

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application files
COPY server.py .
COPY start.sh .
COPY RatioForge.exe .

RUN chmod +x /app/start.sh

# Create Wine directory
RUN mkdir -p /wine

# Initialize Wine during image build
RUN xvfb-run --auto-servernum wineboot --init || true

EXPOSE 10000

CMD ["/app/start.sh"]
