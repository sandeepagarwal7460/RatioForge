#!/bin/bash

set -u

export DISPLAY=:99
export WINEPREFIX=/wine
export WINEARCH=win64

PORT="${PORT:-10000}"
RATIOFORGE="/app/RatioForge/RatioForge.exe"

echo "=============================================="
echo " RatioForge + Wine 11 + Xvfb + noVNC"
echo "=============================================="
echo "PORT: $PORT"
echo "DISPLAY: $DISPLAY"
echo "WINEPREFIX: $WINEPREFIX"
echo ""


# ============================================================
# 1. START XVFB
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
    echo ""
    cat /tmp/xvfb.log || true
    exit 1
fi

echo "Xvfb PID: $XVFB_PID"
echo "Xvfb started successfully."


# ============================================================
# 2. INITIALIZE WINE
# ============================================================

echo ""
echo "=============================================="
echo " [2/7] Initializing Wine"
echo "=============================================="

wine --version || true

echo ""
echo "Starting Wine prefix initialization..."
echo "Timeout: 30 seconds"

timeout 30s wineboot --init >/tmp/wineboot.log 2>&1
WINEBOOT_EXIT=$?

echo ""
echo "wineboot exit code: $WINEBOOT_EXIT"

if [ "$WINEBOOT_EXIT" -eq 124 ]; then

    echo ""
    echo "WARNING: wineboot timed out after 30 seconds."

    echo ""
    echo "Wineboot log:"
    cat /tmp/wineboot.log || true

    echo ""
    echo "Continuing startup anyway."

elif [ "$WINEBOOT_EXIT" -ne 0 ]; then

    echo ""
    echo "WARNING: wineboot returned an error."

    echo ""
    echo "Wineboot log:"
    cat /tmp/wineboot.log || true

    echo ""
    echo "Continuing startup anyway."

else

    echo ""
    echo "Wine initialized successfully."

fi

sleep 3


# ============================================================
# 3. CHECK RATIOFORGE
# ============================================================

echo ""
echo "=============================================="
echo " [3/7] Checking RatioForge"
echo "=============================================="

if [ ! -f "$RATIOFORGE" ]; then

    echo ""
    echo "ERROR: RatioForge.exe was not found."

    echo ""
    echo "Contents of /app/RatioForge:"

    find /app/RatioForge \
        -maxdepth 2 \
        -type f \
        -print

    exit 1
fi

echo "RatioForge found:"
echo "$RATIOFORGE"

echo ""
echo "RatioForge file information:"

ls -lh "$RATIOFORGE"


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

    WINEDEBUG=+seh,+pid,+tid,+module,+loaddll \
    wine "$RATIOFORGE" \
        >/tmp/ratioforge.log 2>&1 &

    RATIOFORGE_PID=$!

    echo "$RATIOFORGE_PID" >/tmp/ratioforge.pid

    echo "RatioForge PID: $RATIOFORGE_PID"
    echo "RatioForge started."

}


ratioforge_supervisor() {

    while true; do

        start_ratioforge

        echo ""
        echo "Waiting 10 seconds for RatioForge startup..."

        sleep 10


        if kill -0 "$RATIOFORGE_PID" 2>/dev/null; then

            echo ""
            echo "RatioForge process is running."

        else

            echo ""
            echo "WARNING: RatioForge exited during startup."

            echo ""
            echo "=============================================="
            echo " RatioForge / Wine LOG"
            echo "=============================================="

            cat /tmp/ratioforge.log || true

            echo ""
            echo "=============================================="
            echo " End RatioForge / Wine LOG"
            echo "=============================================="

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


# Start RatioForge supervisor in background.

ratioforge_supervisor &

SUPERVISOR_PID=$!

echo ""
echo "RatioForge supervisor PID: $SUPERVISOR_PID"


# ============================================================
# 5. CONFIGURE VNC PASSWORD
# ============================================================

echo ""
echo "=============================================="
echo " [5/7] Configuring VNC"
echo "=============================================="


if [ -z "${VNC_PASSWORD:-}" ]; then

    echo ""
    echo "ERROR: VNC_PASSWORD is not configured."
    echo ""
    echo "Add VNC_PASSWORD to:"
    echo ""
    echo "Render → ratioforge → Environment"
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

    echo ""
    echo "ERROR: x11vnc failed to start."

    echo ""
    echo "x11vnc log:"
    cat /tmp/x11vnc.log || true

    exit 1

fi

echo "x11vnc PID: $X11VNC_PID"
echo "x11vnc started successfully."


# ============================================================
# 7. START NOVNC
# ============================================================

echo ""
echo "=============================================="
echo " [7/7] Starting noVNC"
echo "=============================================="

echo ""
echo "=============================================="
echo " Browser desktop available"
echo "=============================================="

echo ""
echo "Port: $PORT"
echo "VNC target: localhost:5900"
echo "Web root: /usr/share/novnc"
echo ""

echo "Starting websockify..."
echo ""


exec websockify \
    --web=/usr/share/novnc \
    "$PORT" \
    localhost:5900
