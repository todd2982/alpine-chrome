# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Alpine-chrome is a Docker image project that provides Chromium browser running in headless mode on a minimal Alpine Linux base. This is a maintained fork that continues regular builds with up-to-date Chrome versions. The project supports multiple image variants with different capabilities (Node.js, Puppeteer, Playwright, ChromeDriver, Selenoid, Deno).

## Image Architecture

The project uses a **layered build approach**:

1. **Base image** (`Dockerfile` in root): Alpine Linux + Chromium + fonts
2. **Layer 1 images**: Built FROM base
   - `with-node`: Adds Node.js, npm, yarn, build tools
   - `with-deno`: Adds Deno runtime
   - `with-chromedriver`: Adds ChromeDriver
3. **Layer 2 images**: Built FROM layer 1 (typically with-node)
   - `with-puppeteer`: Node + Puppeteer (FROM with-node)
   - `with-playwright`: Node + Playwright (FROM with-node)
   - `with-selenoid`: Selenium server implementation (FROM with-node)
   - `with-puppeteer-xvfb`: Puppeteer + Xvfb for Chrome extension testing

**Important**: When modifying Dockerfiles, understand the dependency chain. Changes to the base image affect all downstream images. Layer 2 images depend on their respective layer 1 parents.

## Build and Test Commands

### Building Images

The project uses GitHub Actions for automated builds. To build locally:

```bash
# Build base image
docker build -t todd2982/alpine-chrome:latest .

# Build variant images (from their respective directories)
docker build -t todd2982/alpine-chrome:with-node with-node/
docker build -t todd2982/alpine-chrome:with-puppeteer with-puppeteer/
```

### Testing Images

Each image variant has its own test script in its directory:

```bash
# Test base image
./test.sh

# Test variant images (sets IMAGE_NAME env var and runs tests)
cd with-puppeteer && ./test.sh
cd with-playwright && ./test.sh
cd with-chromedriver && ./test.sh
```

**Test Pattern**: All variant test scripts follow the same pattern:
1. Set `IMAGE_NAME` environment variable
2. Call parent `../test.sh` for basic tests
3. Run variant-specific tests (if any)

### GitHub Actions Workflow

The build workflow (`.github/workflows/build.yml`) has three jobs that run sequentially:
1. `build-base`: Builds the base image
2. `layer-one-images`: Builds with-node, with-deno, with-chromedriver (needs build-base)
3. `layer-two-images`: Builds with-playwright, with-puppeteer, with-selenoid (needs layer-one-images)

Each job uses the reusable action `.github/actions/build-single-container/action.yml` which:
- Builds the image
- Runs tests
- Extracts Chrome/ChromeDriver version for tagging
- Pushes to ghcr.io (only on master branch)

## Security Considerations

Chrome sandboxing requires special configuration. There are three approaches (documented in README):

1. **Best (seccomp)**: Use `--security-opt seccomp=./chrome.json`
2. **Good (SYS_ADMIN)**: Use `--cap-add=SYS_ADMIN`
3. **Acceptable (no-sandbox)**: Use `--no-sandbox` flag

The `chrome.json` file contains a seccomp profile that allows Chrome to run securely without requiring SYS_ADMIN capabilities.

**When writing examples or tests**: Prefer `--cap-add=SYS_ADMIN` over `--no-sandbox` for better security in documentation.

## Important Environment Variables

### Base Image
- `HOME=/tmp`: Required for Chromium to function properly
- `CHROME_BIN=/usr/bin/chromium-browser`: Path to Chrome binary
- `CHROME_PATH=/usr/lib/chromium/`: Chrome library path
- `CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage"`: Default flags

### Puppeteer Images
- `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1`: Don't download Chrome (use system)
- `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser`: Use Alpine's Chrome

### Playwright Images
- `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`: Don't download browsers
- `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser`: Use Alpine's Chrome

## Key Files

- `chrome.json`: Seccomp security profile for Chrome (from Jessie Frazelle)
- `local.conf`: Font configuration for proper emoji and international character rendering
- `.github/actions/build-single-container/action.yml`: Reusable build/test/push action
- Each `test.sh`: Validates the respective image works correctly

## Internationalization Support

The base image includes `font-wqy-zenhei` (from Alpine edge/community) for Asian character support. Test scripts verify rendering for:
- Chinese (Baidu)
- Japanese (Yahoo Japan)
- Korean (Naver)

## Common Development Patterns

### Adding a New Image Variant

1. Create new directory: `with-{variant}/`
2. Add `Dockerfile` (typically FROM an existing image)
3. Add `test.sh` script that sources `../test.sh` and adds variant tests
4. Update `.github/workflows/build.yml` to include in appropriate layer
5. Update README.md with new tag and usage examples

### Version Updates

Version tags are automatically extracted by GitHub Actions from:
- Chromium: `chromium-browser --version` output (regex: `Chromium ([0-9]+)\.`)
- ChromeDriver: `chromedriver --version` output (regex: `ChromeDriver ([0-9]+)\.`)

The workflow ensures Chromium and ChromeDriver major versions match for with-chromedriver builds.

## Registry

Images are published to GitHub Container Registry (ghcr.io):
- `ghcr.io/todd2982/alpine-chrome:latest`
- `ghcr.io/todd2982/alpine-chrome:{version}`
- `ghcr.io/todd2982/alpine-chrome:with-{variant}`
- `ghcr.io/todd2982/alpine-chrome:{version}-with-{variant}`

Builds only push to registry on master branch.
