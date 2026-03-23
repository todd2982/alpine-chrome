#!/bin/sh
# docker-entrypoint.sh
#
# Modern Chromium (v112+) ignores --remote-debugging-address and always binds
# DevTools to 127.0.0.1 for security reasons. This script works around that by:
#   1. Starting Chromium on an internal loopback port (9223)
#   2. Using socat to forward 0.0.0.0:9222 → 127.0.0.1:9223
#
# This allows other containers on the Docker network to reach Chrome via port 9222.

set -e

INTERNAL_PORT="${CHROME_INTERNAL_PORT:-9223}"
EXTERNAL_PORT="${CHROME_EXTERNAL_PORT:-9222}"

# Start chromium on the internal loopback port.
# Pass all extra args through (entrypoint already includes --headless via CMD).
chromium-browser "$@" --remote-debugging-port="$INTERNAL_PORT" &
CHROME_PID=$!

# Ensure Chrome dies if socat exits, and vice versa
cleanup() {
  kill "$CHROME_PID" 2>/dev/null || true
}
trap cleanup EXIT TERM INT

# Wait for Chrome DevTools to become available
echo "[entrypoint] Waiting for Chrome DevTools on 127.0.0.1:$INTERNAL_PORT..."
WAIT=0
until wget -q -O /dev/null "http://127.0.0.1:$INTERNAL_PORT/json/version" 2>/dev/null; do
  if ! kill -0 "$CHROME_PID" 2>/dev/null; then
    echo "[entrypoint] Chrome process exited unexpectedly" >&2
    exit 1
  fi
  WAIT=$((WAIT + 1))
  if [ "$WAIT" -gt 60 ]; then
    echo "[entrypoint] Timed out waiting for Chrome" >&2
    exit 1
  fi
  sleep 0.5
done

echo "[entrypoint] Chrome ready. Forwarding 0.0.0.0:$EXTERNAL_PORT -> 127.0.0.1:$INTERNAL_PORT"

# Forward external port to internal port so other containers can reach Chrome
exec socat TCP-LISTEN:"$EXTERNAL_PORT",fork,bind=0.0.0.0,reuseaddr TCP:127.0.0.1:"$INTERNAL_PORT"
