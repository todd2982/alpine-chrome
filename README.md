[![GitHub Stars](https://img.shields.io/github/stars/todd2982/alpine-chrome)](https://github.com/todd2982/alpine-chrome/) [![Docker Build Status](https://img.shields.io/github/actions/workflow/status/todd2982/alpine-chrome/build.yml)](https://github.com/todd2982/alpine-chrome/actions/workflows/build.yml)

# alpine-chrome

A minimal headless Chromium image built specifically as a **Chrome CDP sidecar for [Karakeep](https://github.com/karakeep-app/karakeep)**.

Karakeep requires a headless Chrome instance reachable via the Chrome DevTools Protocol (CDP). Chromium v112+ removed `--remote-debugging-address`, so Chrome always binds DevTools to `127.0.0.1` — unreachable from other Docker containers. This image solves that with a built-in CDP proxy that rewrites WebSocket URLs and exposes port 9222 on all interfaces.

---

## Registry

- **GitHub Container Registry:** `ghcr.io/todd2982/alpine-chrome`

---

## Usage with Karakeep

Add this as a sidecar in your `docker-compose.yml`:

```yaml
services:
  chrome:
    image: ghcr.io/todd2982/alpine-chrome:latest
    restart: unless-stopped
    cap_add:
      - SYS_ADMIN

  karakeep:
    image: ghcr.io/karakeep-app/karakeep:release
    environment:
      BROWSER_WEB_URL: http://chrome:9222
    depends_on:
      - chrome
```

> **Default behavior:** The image ships with `--no-sandbox` enabled by default (via `CHROMIUM_FLAGS`) because most Docker environments do not grant `SYS_ADMIN` or a permissive seccomp profile. If you can provide either, override `CHROMIUM_FLAGS` to remove it — see [Security](#security) below.

---

## How It Works

The entrypoint (`docker-entrypoint.sh`) does three things:

1. Starts Chromium bound to `127.0.0.1:9223` (internal only)
2. Runs a Python CDP proxy (`cdp-proxy.py`) on `0.0.0.0:9222` that:
   - Rewrites WebSocket URLs in `/json` and `/json/version` responses so CDP clients receive usable addresses
   - Transparently proxies WebSocket CDP connections
3. Monitors both processes and exits if either crashes

This is necessary because Chromium v112+ ignores `--remote-debugging-address` and always binds DevTools to localhost.

---

## Security

Chrome sandboxing requires special Docker configuration. Three options (best to worst):

The image defaults to `--no-sandbox` so it works out of the box in standard Docker environments. To use a hardened configuration, override `CHROMIUM_FLAGS` to remove `--no-sandbox` and grant Chrome the sandbox it needs:

### ✅ Best: seccomp profile

```bash
docker run -d -p 9222:9222 \
  --security-opt seccomp=$(pwd)/chrome.json \
  -e CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage" \
  ghcr.io/todd2982/alpine-chrome
```

The [`chrome.json`](chrome.json) seccomp profile (from Jessie Frazelle) lets Chrome sandbox properly without requiring `SYS_ADMIN`.

### ✅ Good: SYS_ADMIN capability

```bash
docker run -d -p 9222:9222 \
  --cap-add=SYS_ADMIN \
  -e CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage" \
  ghcr.io/todd2982/alpine-chrome
```

### ⚠️ Default (no-sandbox)

```bash
docker run -d -p 9222:9222 ghcr.io/todd2982/alpine-chrome
```

Works in standard Docker environments without any extra capabilities. Only use in trusted/isolated environments where the container is the trust boundary.

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CHROMIUM_FLAGS` | `--no-sandbox --disable-software-rasterizer --disable-dev-shm-usage` | Extra flags appended to every Chrome invocation. Override to remove `--no-sandbox` when using `SYS_ADMIN` or a seccomp profile. |
| `HOME` | `/tmp` | Required for Chromium to function |
| `CHROME_BIN` | `/usr/bin/chromium-browser` | Path to Chrome binary |
| `CHROME_PATH` | `/usr/lib/chromium/` | Chrome library path |

### Custom Chrome Flags

Override `CHROMIUM_FLAGS` to customize Chrome startup flags. For example, to enable sandbox with `SYS_ADMIN`:

```bash
docker run -d -p 9222:9222 \
  --cap-add=SYS_ADMIN \
  -e CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage" \
  ghcr.io/todd2982/alpine-chrome
```

### Override Entrypoint

If you need raw Chrome access without the CDP proxy:

```bash
docker run --rm -it --entrypoint "" ghcr.io/todd2982/alpine-chrome \
  chromium-browser --headless --no-sandbox ...
```

---

## Build

```bash
docker build -t ghcr.io/todd2982/alpine-chrome:latest .
```

### Testing

```bash
./test.sh
```

### GitHub Actions

The build workflow (`.github/workflows/build.yml`) runs on:
- Pull requests
- Weekly schedule (Thursday 04:25 UTC)
- Manual dispatch

It builds the image, runs tests, extracts the Chromium version for tagging, and pushes to GHCR on `master`.

---

## References

- [Karakeep](https://github.com/karakeep-app/karakeep) — the bookmark manager this image is built for
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)
- [Chromium command-line switches](https://peter.sh/experiments/chromium-command-line-switches/)
- [Issues](https://github.com/todd2982/alpine-chrome/issues)
