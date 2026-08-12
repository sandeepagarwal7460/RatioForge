#!/bin/bash

set -u

export DISPLAY=:99
export WINEPREFIX=/wine
export WINEARCH=win64

PORT="${PORT:-10000}"

RATIOFORGE="/app/RatioForge/RatioForge.exe"

echo "=============================================="
echo " RatioForge + Wine + noVNC"
echo "=============================================="


# ============================================================
# 1. START VIRTUAL DISPLAY
# ============================================================

echo "[1/7] Starting Xvfb..."

Xvfb :99 \
    -screen 0 1280x720x24 \
    -ac \
    +extension GLX \
    +render \
    -noreset \
    >/tmp/xvfb.log 2>&1 &

XVFB_PID=$!

sleep 3

if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "ERROR: Xvfb failed."
    cat /tmp/xvfb.log
    exit 1
fi

echo "Xvfb running: PID $XVFB_PID"


# ============================================================
# 2. INITIALIZE WINE
# ============================================================

echo "[2/7] Initializing Wine..."

wineboot --init >/tmp/wineboot.log 2>&1 || true

sleep 5

echo "Wine initialized."

wine --version || true


# ============================================================
# 3. CHECK RATIOFORGE
# ============================================================

echo "[3/7] Checking RatioForge..."

if [ ! -f "$RATIOFORGE" ]; then

    echo "ERROR: RatioForge.exe was not found."

    find /app/RatioForge -maxdepth 2 -type f

    exit 1
fi

echo "Found:"
echo "$RATIOFORGE"


# ============================================================
# 4. START RATIOFORGE SUPERVISOR
# ============================================================

start_ratioforge() {

    echo ""
    echo "=============================================="
    echo " Starting RatioForge"
    echo "=============================================="

    WINEDEBUG=+seh,+module,+loaddll wine "$RATIOFORGE" \
        >/tmp/ratioforge.log 2>&1 &

    RATIOFORGE_PID=$!

    echo "$RATIOFORGE_PID" >/tmp/ratioforge.pid

    echo "RatioForge PID: $RATIOFORGE_PID"
}


ratioforge_supervisor() {

    while true; do

        start_ratioforge

        echo "RatioForge started."

        wait "$RATIOFORGE_PID"

        EXIT_CODE=$?

        echo ""
        echo "RatioForge exited."
        echo "Exit code: $EXIT_CODE"

        echo ""
        echo "Last RatioForge output:"
        tail -100 /tmp/ratioforge.log || true

        echo ""
        echo "Restarting RatioForge in 10 seconds..."

        sleep 10

    done
}


ratioforge_supervisor &

SUPERVISOR_PID=$!


# ============================================================
# 5. CREATE VNC PASSWORD
# ============================================================

echo ""
echo "[5/7] Configuring VNC password..."

if [ -z "${VNC_PASSWORD:-}" ]; then

    echo ""
    echo "ERROR:"
    echo "VNC_PASSWORD environment variable is not set."
    echo ""
    echo "Set VNC_PASSWORD in Render Environment Variables."
    echo ""

    exit 1
fi


mkdir -p /root/.vnc

x11vnc -storepasswd \
    "$VNC_PASSWORD" \
    /root/.vnc/passwd \
    >/tmp/vnc-password.log 2>&1

chmod 600 /root/.vnc/passwd

echo "VNC password configured."


# ============================================================
# 6. START VNC SERVER
# ============================================================

echo ""
echo "[6/7] Starting x11vnc..."

x11vnc \
    -display :99 \
    -rfbport 5900 \
    -rfbauth /root/.vnc/passwd \
    -localhost \
    -forever \
    -shared \
    -noxdamage \
    -repeat \
    >/tmp/x11vnc.log 2>&1 &

X11VNC_PID=$!

sleep 3

if ! kill -0 "$X11VNC_PID" 2>/dev/null; then

    echo "ERROR: x11vnc failed."

    cat /tmp/x11vnc.log

    exit 1
fi

echo "x11vnc running: PID $X11VNC_PID"


# ============================================================
# 7. START NOVNC / WEBSOCKIFY
# ============================================================

echo ""
echo "[7/7] Starting noVNC..."

echo ""
echo "=============================================="
echo " Browser desktop available"
echo "=============================================="
echo ""
echo "Port: $PORT"
echo "VNC target: localhost:5900"
echo ""


# websockify serves the noVNC web interface and
# proxies WebSocket traffic to the local VNC server.
#
# Render forwards HTTPS/WebSocket traffic to this port.

exec websockify \
    --web=/usr/share/novnc \
    "$PORT" \
    localhost:5900
