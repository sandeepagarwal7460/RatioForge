#!/bin/bash

set -u

echo "=========================================="
echo " RatioForge - Render 24/7 Service"
echo "=========================================="

export DISPLAY=:99
export WINEPREFIX=/wine
export WINEARCH=win64

PORT="${PORT:-10000}"

RATIOFORGE="/app/RatioForge/RatioForge.exe"


# ============================================================
# START VIRTUAL DISPLAY
# ============================================================

echo "[1] Starting Xvfb..."

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

echo "Xvfb running."


# ============================================================
# INITIALIZE WINE
# ============================================================

echo "[2] Initializing Wine..."

wineboot --init >/tmp/wineboot.log 2>&1 || true

sleep 5

echo "Wine initialized."

wine --version || true


# ============================================================
# CHECK RATIOFORGE
# ============================================================

echo "[3] Checking RatioForge..."

if [ ! -f "$RATIOFORGE" ]; then

    echo "ERROR: RatioForge.exe does not exist."

    echo ""
    echo "Contents of /app/RatioForge:"
    find /app/RatioForge -maxdepth 2 -type f

    exit 1
fi

echo "Found:"
echo "$RATIOFORGE"


# ============================================================
# START RATIOFORGE FUNCTION
# ============================================================

start_ratioforge() {

    echo ""
    echo "=========================================="
    echo " Starting RatioForge"
    echo "=========================================="

    wine "$RATIOFORGE" \
        >/tmp/ratioforge.log 2>&1 &

    RATIOFORGE_PID=$!

    echo "$RATIOFORGE_PID" >/tmp/ratioforge.pid

    echo "RatioForge PID: $RATIOFORGE_PID"

}


# ============================================================
# RATIOFORGE SUPERVISOR
# ============================================================

supervisor() {

    while true; do

        start_ratioforge

        echo ""
        echo "RatioForge started."

        # Wait until RatioForge exits.
        wait "$RATIOFORGE_PID"

        EXIT_CODE=$?

        echo ""
        echo "=========================================="
        echo " RatioForge stopped"
        echo " Exit code: $EXIT_CODE"
        echo "=========================================="

        echo ""
        echo "Last RatioForge log:"
        tail -100 /tmp/ratioforge.log || true

        echo ""
        echo "Restarting RatioForge in 10 seconds..."

        sleep 10

    done
}


# ============================================================
# START SUPERVISOR
# ============================================================

supervisor &
SUPERVISOR_PID=$!


# ============================================================
# HTTP SERVER
# ============================================================

echo ""
echo "=========================================="
echo " Starting HTTP health server"
echo "=========================================="

python3 - "$PORT" <<'PY'

import sys
import os
from http.server import BaseHTTPRequestHandler
from http.server import HTTPServer

PORT = int(sys.argv[1])


class Handler(BaseHTTPRequestHandler):

    def do_GET(self):

        if self.path == "/":

            body = b"RatioForge service is running\n"

            self.send_response(200)

            self.send_header(
                "Content-Type",
                "text/plain"
            )

            self.send_header(
                "Content-Length",
                str(len(body))
            )

            self.end_headers()

            self.wfile.write(body)

            return


        if self.path == "/health":

            body = b'{"status":"healthy"}\n'

            self.send_response(200)

            self.send_header(
                "Content-Type",
                "application/json"
            )

            self.send_header(
                "Content-Length",
                str(len(body))
            )

            self.end_headers()

            self.wfile.write(body)

            return


        if self.path == "/status":

            running = False

            try:

                with open("/tmp/ratioforge.pid", "r") as f:
                    pid = int(f.read().strip())

                os.kill(pid, 0)

                running = True

            except Exception:

                running = False


            if running:

                body = b'{"ratioforge":"running"}\n'

            else:

                body = b'{"ratioforge":"restarting"}\n'


            self.send_response(200)

            self.send_header(
                "Content-Type",
                "application/json"
            )

            self.send_header(
                "Content-Length",
                str(len(body))
            )

            self.end_headers()

            self.wfile.write(body)

            return


        body = b'{"error":"not found"}\n'

        self.send_response(404)

        self.send_header(
            "Content-Type",
            "application/json"
        )

        self.send_header(
            "Content-Length",
            str(len(body))
        )

        self.end_headers()

        self.wfile.write(body)


    def log_message(self, format, *args):

        print(
            "[HTTP]",
            format % args,
            flush=True
        )


server = HTTPServer(
    ("0.0.0.0", PORT),
    Handler
)

print(
    f"Health server listening on 0.0.0.0:{PORT}",
    flush=True
)

server.serve_forever()

PY
