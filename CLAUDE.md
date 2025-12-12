# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

alpine-chrome is a Docker image project that provides headless Chromium browser running on Alpine Linux. This is a maintained fork of the original jlandure/alpine-chrome project, continuing regular builds with updated Chrome versions.

**Registry**: Images are published to GitHub Container Registry at `ghcr.io/todd2982/alpine-chrome`

## Repository Structure

The repository follows a layered Docker image architecture:

1. **Base image** (`./Dockerfile`): Core Alpine + Chromium setup
2. **Layer one images** (`with-node/`, `with-deno/`, `with-chromedriver/`): Add runtime environments
3. **Layer two images** (`with-puppeteer/`, `with-playwright/`, `with-selenoid/`): Add automation frameworks

Each variant directory contains:
- `Dockerfile` - Image definition
- `test.sh` - Validation script that runs during build

## Build System

### GitHub Actions Workflow

The build process (`.github/workflows/build.yml`) orchestrates image builds:

- **Trigger**: Weekly on Thursdays at 4:25 AM UTC, on PRs, and manual dispatch
- **Build order**: base → layer-one-images → layer-two-images
- **Platforms**: linux/amd64, linux/arm64
- **Testing**: Each image is tested before pushing
- **Tagging**: Images are tagged with both variant names (`with-node`) and version numbers (e.g., `100-with-node`)

### Custom Build Action

The `.github/actions/build-single-container/action.yml` handles individual image builds:

1. Sets folder based on tag (`latest` → `.`, others → folder name)
2. Builds image with `docker` driver
3. Runs `test.sh` in the variant directory
4. Extracts Chromium version and creates versioned tags
5. Pushes to GHCR (only on master branch)

### Building Images Locally

```bash
# Build base image
docker build -t todd2982/alpine-chrome .

# Build variant (e.g., with-node)
docker build -t todd2982/alpine-chrome:with-node with-node/

# Run tests for base image
IMAGE_NAME=todd2982/alpine-chrome ./test.sh

# Run tests for variant
IMAGE_NAME=todd2982/alpine-chrome:with-node with-node/test.sh
```

## Security Considerations

Chrome sandboxing requires one of three approaches when running containers:

1. **`--no-sandbox` flag**: Simplest but least secure, use only with trusted sites
2. **`--cap-add=SYS_ADMIN`**: Enables sandboxing but grants broad privileges
3. **seccomp profile** (recommended): Use `chrome.json` with `--security-opt seccomp=$(pwd)/chrome.json`

The `chrome.json` file is a comprehensive seccomp profile from Jessie Frazelle's dotfiles.

## Key Docker Image Details

### Base Image Configuration

- **Base OS**: Alpine Linux (currently 3.23)
- **User**: Runs as non-root `chrome` user
- **Working directory**: `/usr/src/app`
- **Entrypoint**: `chromium-browser --headless` with flags from `CHROMIUM_FLAGS`
- **Environment**:
  - `HOME=/tmp` - Required for Chromium setup
  - `CHROME_BIN=/usr/bin/chromium-browser`
  - `CHROME_PATH=/usr/lib/chromium/`
  - `CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage"`

### Font Support

- Base fonts: `ttf-freefont`
- Emoji support: `font-noto-emoji`
- Asian character support: `font-wqy-zenhei` (from edge/community repo)
- Configuration: `local.conf` sets up font fallback for emoji rendering

### Image Variants

- **with-node**: Adds Node.js, npm, yarn, build tools (gcc, g++, python3, git, make)
- **with-puppeteer**: Extends with-node, adds Puppeteer (skips Chromium download, uses system Chromium)
- **with-playwright**: Extends with-node, adds Playwright (skips browser download, uses system Chromium)
- **with-chromedriver**: Adds chromium-chromedriver, exposes port 9515
- **with-selenoid**: Selenium server with Chrome and chromedriver
- **with-deno**: Adds Deno runtime
- **with-puppeteer-xvfb**: Puppeteer with Xvfb for Chrome extension testing

## Testing

All variants must pass their respective `test.sh` script:
- Base test checks Alpine version and Chromium version
- Variant tests may include additional checks specific to their tooling

## Important Environment Variables for Variants

When building automation images:
- `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1` - Prevents Puppeteer from downloading its own Chromium
- `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser` - Points to system Chromium
- `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` - Prevents Playwright from downloading browsers
- `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser` - Points to system Chromium

## Common Commands

### Run Chromium Commands

```bash
# Print DOM
docker run --rm ghcr.io/todd2982/alpine-chrome --no-sandbox --dump-dom https://example.com

# Generate PDF
docker run --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --no-sandbox --print-to-pdf https://example.com

# Take screenshot
docker run --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --no-sandbox --screenshot https://example.com

# Run with devtools
docker run -d -p 9222:9222 ghcr.io/todd2982/alpine-chrome --no-sandbox --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 https://example.com
```

### Run with Automation Frameworks

```bash
# Puppeteer
docker run --rm -v $(pwd)/src:/usr/src/app/src --cap-add=SYS_ADMIN ghcr.io/todd2982/alpine-chrome:with-puppeteer node src/script.js

# Playwright
docker run --rm -v $(pwd)/test:/usr/src/app/test --cap-add=SYS_ADMIN ghcr.io/todd2982/alpine-chrome:with-playwright node test/test.js

# Selenoid
docker run --rm --cap-add=SYS_ADMIN -p 4444:4444 ghcr.io/todd2982/alpine-chrome:with-selenoid
```

### Override Defaults

```bash
# Override CHROMIUM_FLAGS
docker run --rm --env CHROMIUM_FLAGS="--other-flag" ghcr.io/todd2982/alpine-chrome

# Override entrypoint completely
docker run --rm --entrypoint "" ghcr.io/todd2982/alpine-chrome chromium-browser --version

# Run as root
docker run --rm --entrypoint "" --user root ghcr.io/todd2982/alpine-chrome sh
```

## Version Management

- Chromium version is auto-detected during builds and used for tagging
- Tags follow pattern: `{chromium-major-version}` for base, `{chromium-major-version}-{variant}` for variants
- The `latest` tag and variant tags (e.g., `with-node`) always point to most recent build

## Adding New Variants

To add a new variant:
1. Create a new directory `with-{name}/`
2. Add a `Dockerfile` that builds from `ghcr.io/todd2982/alpine-chrome` or a layer-one variant
3. Add a `test.sh` script that validates the image
4. Update `.github/workflows/build.yml` to include the variant in the appropriate layer
5. Document usage in `README.md`
