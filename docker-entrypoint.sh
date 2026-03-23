#!/bin/sh
# docker-entrypoint.sh
#
# Modern Chromium (v112+) ignores --remote-debugging-address and always binds
# DevTools to 127.0.0.1 for security reasons. This script works around that by:
#   1. Starting Chromium on an internal loopback port (9223)
#   2. Running cdp-proxy.py which listens on 0.0.0.0:9222 and:
#      - Rewrites WebSocket URLs in /json and /json/version responses so
#        CDP clients (e.g. Karakeep) receive usable addresses
#      - Transparently proxies WebSocket connections for CDP traffic
#
# Environment variables:
#   CHROME_INTERNAL_PORT  Internal port Chrome listens on (default: 9223)
#   CHROME_EXTERNAL_PORT  External port the proxy exposes  (default: 9222)
#   CHROMIUM_FLAGS        Extra flags appended to every Chrome invocation

set -e

INTERNAL_PORT="${CHROME_INTERNAL_PORT:-9223}"
EXTERNAL_PORT="${CHROME_EXTERNAL_PORT:-9222}"

# Start chromium on the internal loopback port.
# $CHROMIUM_FLAGS lets users inject extra flags without overriding the CMD.
# shellcheck disable=SC2086
chromium-browser "$@" ${CHROMIUM_FLAGS} --remote-debugging-port="$INTERNAL_PORT" &
CHROME_PID=$!

# Kill both processes when we exit
cleanup() {
  kill "$CHROME_PID" "$PROXY_PID" 2>/dev/null || true
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

echo "[entrypoint] Chrome ready. Starting CDP proxy on 0.0.0.0:$EXTERNAL_PORT -> 127.0.0.1:$INTERNAL_PORT"

# Start the CDP proxy (rewrites WS URLs in JSON responses)
python3 /usr/local/bin/cdp-proxy.py &
PROXY_PID=$!

# Monitor both processes; restart container if either dies
while true; do
  if ! kill -0 "$CHROME_PID" 2>/dev/null; then
    echo "[entrypoint] Chrome process died unexpectedly" >&2
    exit 1
  fi
  if ! kill -0 "$PROXY_PID" 2>/dev/null; then
    echo "[entrypoint] CDP proxy process died unexpectedly" >&2
    exit 1
  fi
  sleep 5
done
