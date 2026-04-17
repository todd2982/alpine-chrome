# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`alpine-chrome` is a minimal headless Chromium Docker image built as a **Chrome CDP sidecar for [Karakeep](https://github.com/karakeep-app/karakeep)**. It solves a specific problem: Chromium v112+ removed `--remote-debugging-address` and always binds DevTools to `127.0.0.1`, making it unreachable from other Docker containers. This image works around that with a built-in Python CDP proxy.

This is **not** a general-purpose multi-variant headless Chrome project. There is one image, one Dockerfile, one purpose.

## Image Architecture

Single-image build — no variants, no layering:

- **`Dockerfile`** (root): Alpine Linux + Chromium + minimal font support + Python3 + CDP proxy
- **`docker-entrypoint.sh`**: Starts Chromium on `127.0.0.1:9223`, then runs the CDP proxy
- **`cdp-proxy.py`**: Python CDP proxy on `0.0.0.0:9222` — rewrites WebSocket URLs in `/json*` responses and transparently proxies WebSocket connections

## Build Commands

```bash
# Build
docker build -t ghcr.io/todd2982/alpine-chrome:latest .

# Test
./test.sh
```

## GitHub Actions Workflow

The build workflow (`.github/workflows/build.yml`) has a single `build-base` job using the reusable action `.github/actions/build-single-container/action.yml`. It:
1. Builds the image
2. Runs `./test.sh`
3. Extracts the Chromium version for tagging
4. Pushes to `ghcr.io` on master branch (multi-arch: amd64 + arm64)

Triggers: pull requests, weekly Thursday 04:25 UTC schedule, manual dispatch.

## Security Considerations

Chrome sandboxing requires special Docker config. Three options (best to worst):

1. **Best (seccomp):** `--security-opt seccomp=./chrome.json`
2. **Good (SYS_ADMIN):** `--cap-add=SYS_ADMIN`
3. **Acceptable (no-sandbox):** Set `CHROMIUM_FLAGS` to include `--no-sandbox`

`chrome.json` is a seccomp profile from Jessie Frazelle. Prefer cap-add or seccomp over no-sandbox in examples.

## Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `CHROMIUM_FLAGS` | `--no-sandbox --disable-software-rasterizer --disable-dev-shm-usage` | Extra flags for Chrome. `--no-sandbox` is on by default so the image works without `SYS_ADMIN`/seccomp; override to remove it in hardened setups. |
| `HOME` | `/tmp` | Required for Chromium |
| `CHROME_BIN` | `/usr/bin/chromium-browser` | Chrome binary path |
| `CHROME_PATH` | `/usr/lib/chromium/` | Chrome library path |

## Key Files

- `Dockerfile`: Single image build
- `docker-entrypoint.sh`: Process supervisor — starts Chrome + CDP proxy
- `cdp-proxy.py`: CDP proxy that rewrites WebSocket URLs for external accessibility
- `chrome.json`: Seccomp security profile for Chrome
- `test.sh`: Validates the image works
- `.github/actions/build-single-container/action.yml`: Build/test/push action used by the CI workflow

## What This Is NOT

- Not a multi-variant project — the upstream `jlandure/alpine-chrome` layered variants (`with-node`, `with-puppeteer`, `with-playwright`, `with-chromedriver`, `with-selenoid`, etc.) are not present in this fork and exist only in git history prior to their removal
- Not a general-purpose headless Chrome for Puppeteer/Playwright/Selenium workflows
- Not intended to replace the original `jlandure/alpine-chrome` project

## Registry

Images publish to GitHub Container Registry:
- `ghcr.io/todd2982/alpine-chrome:latest`
- `ghcr.io/todd2982/alpine-chrome:{chromium-major-version}`

Builds push only on master branch.
