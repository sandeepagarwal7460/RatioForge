#!/bin/bash

set -u

export DISPLAY=:99
export WINEPREFIX=/wine
export WINEARCH=win64

PORT="${PORT:-10000}"
RATIOFORGE="/app/RatioForge/RatioForge.exe"

echo "=============================================="
echo " RatioForge + Wine + Xvfb + noVNC"
echo "=============================================="
echo "PORT: $PORT"
echo "DISPLAY: $DISPLAY"
echo ""


# ============================================================
# 1. START Xvfb
# ============================================================

echo "=============================================="
echo " [1/7] Starting Xvfb"
echo "=============================================="

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
    echo "ERROR: Xvfb failed to start."
    cat /tmp/xvfb.log || true
    exit 1
fi

echo "Xvfb PID: $XVFB_PID"
echo "Xvfb started."


# ============================================================
# 2. INITIALIZE WINE
# ============================================================

echo ""
echo "=============================================="
echo " [2/7] Initializing Wine"
echo "=============================================="

wine --version || true

wineboot --init >/tmp/wineboot.log 2>&1 || true

sleep 5

echo "Wine initialized."


# ============================================================
# 3. CHECK RATIOFORGE
# ============================================================

echo ""
echo "=============================================="
echo " [3/7] Checking RatioForge"
echo "=============================================="

if [ ! -f "$RATIOFORGE" ]; then

    echo "ERROR: RatioForge.exe was not found."

    echo ""
    echo "Files in /app/RatioForge:"
    find /app/RatioForge -maxdepth 2 -type f -print

    exit 1
fi

echo "RatioForge found:"
echo "$RATIOFORGE"


# ============================================================
# 4. RATIOFORGE SUPERVISOR
# ============================================================

echo ""
echo "=============================================="
echo " [4/7] Starting RatioForge supervisor"
echo "=============================================="


start_ratioforge() {

    echo ""
    echo "----------------------------------------------"
    echo " Starting RatioForge"
    echo "----------------------------------------------"

    rm -f /tmp/ratioforge.log
    rm -f /tmp/ratioforge.pid

    # Detailed Wine diagnostics.
    #
    # This intentionally produces more output than normal.
    # We need it to diagnose the crash.
    WINEDEBUG=+seh,+pid,+tid,+module,+loaddll \
    wine "$RATIOFORGE" \
        >/tmp/ratioforge.log 2>&1 &

    RATIOFORGE_PID=$!

    echo "$RATIOFORGE_PID" >/tmp/ratioforge.pid

    echo "RatioForge PID: $RATIOFORGE_PID"
    echo "RatioForge started."

    # Give the application a moment to initialize.
    sleep 8
}


ratioforge_supervisor() {

    while true; do

        start_ratioforge

        echo ""
        echo "Checking RatioForge process..."

        if kill -0 "$RATIOFORGE_PID" 2>/dev/null; then
            echo "RatioForge process is running."
        else
            echo "RatioForge already exited."
        fi


        # ----------------------------------------------------
        # Monitor RatioForge
        # ----------------------------------------------------

        while kill -0 "$RATIOFORGE_PID" 2>/dev/null; do

            sleep 5

        done


        echo ""
        echo "=============================================="
        echo " RatioForge PROCESS EXITED"
        echo "=============================================="

        echo ""
        echo "RatioForge PID:"
        echo "$RATIOFORGE_PID"

        echo ""
        echo "=============================================="
        echo " RatioForge / Wine LOG"
        echo "=============================================="

        if [ -f /tmp/ratioforge.log ]; then
            cat /tmp/ratioforge.log
        else
            echo "No RatioForge log found."
        fi

        echo ""
        echo "=============================================="
        echo " End RatioForge / Wine LOG"
        echo "=============================================="

        echo ""
        echo "Restarting RatioForge in 10 seconds..."

        sleep 10

    done
}


# Run supervisor in background.
ratioforge_supervisor &

SUPERVISOR_PID=$!

echo "RatioForge supervisor PID: $SUPERVISOR_PID"


# ============================================================
# 5. VNC PASSWORD
# ============================================================

echo ""
echo "=============================================="
echo " [5/7] Configuring VNC"
echo "=============================================="


if [ -z "${VNC_PASSWORD:-}" ]; then

    echo ""
    echo "ERROR: VNC_PASSWORD is not configured."
    echo ""
    echo "Add VNC_PASSWORD in:"
    echo "Render → Service → Environment"
    echo ""

    exit 1

fi


mkdir -p /root/.vnc

x11vnc \
    -storepasswd \
    "$VNC_PASSWORD" \
    /root/.vnc/passwd \
    >/tmp/vnc-password.log 2>&1

chmod 600 /root/.vnc/passwd

echo "VNC password configured."


# ============================================================
# 6. START x11vnc
# ============================================================

echo ""
echo "=============================================="
echo " [6/7] Starting x11vnc"
echo "=============================================="


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

    echo "ERROR: x11vnc failed to start."

    cat /tmp/x11vnc.log || true

    exit 1

fi

echo "x11vnc PID: $X11VNC_PID"
echo "x11vnc started."


# ============================================================
# 7. START noVNC
# ============================================================

echo ""
echo "=============================================="
echo " [7/7] Starting noVNC"
echo "=============================================="

echo ""
echo "Browser desktop available"
echo ""
echo "Port: $PORT"
echo "VNC target: localhost:5900"
echo ""
echo "WebSocket server settings:"
echo ""
echo "- Listen on :$PORT"
echo "- Web root: /usr/share/novnc"
echo "- VNC target: localhost:5900"
echo ""

exec websockify \
    --web=/usr/share/novnc \
    "$PORT" \
    localhost:5900
