FROM alpine:3.23

# Installs Chromium and a minimal set of dependencies.
# A Python CDP proxy (cdp-proxy.py) is used to expose 0.0.0.0:9222 -> 127.0.0.1:9223
# because Chromium v112+ removed --remote-debugging-address and always binds DevTools
# to 127.0.0.1, making it unreachable from other Docker containers.
# The proxy rewrites WebSocket URLs in /json* responses so CDP clients (e.g. Karakeep)
# receive usable addresses instead of the internal 127.0.0.1:9223 addresses.
RUN apk upgrade --no-cache --available \
    && apk add --no-cache \
      gcompat \
      glib \
      nss \
      libxcb \
      libgcc \
      chromium \
      ttf-freefont \
      python3 \
      wget

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY cdp-proxy.py /usr/local/bin/cdp-proxy.py

# Add Chrome as a user
RUN mkdir -p /usr/src/app \
    && adduser -D chrome \
    && chown -R chrome:chrome /usr/src/app \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/cdp-proxy.py

# Run Chrome as non-privileged
USER chrome
WORKDIR /usr/src/app

ENV HOME=/tmp \
    CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/

# The entrypoint starts Chrome on 127.0.0.1:9223 then runs a CDP proxy that
# listens on 0.0.0.0:9222, rewrites WebSocket URLs in /json* responses, and
# transparently proxies WebSocket connections for CDP clients (e.g. Karakeep).
# Chromium v112+ ignores --remote-debugging-address, hence the proxy approach.
#
# Security: prefer --cap-add=SYS_ADMIN or a seccomp profile over --no-sandbox.
# See README for usage examples.
ENV CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage"
EXPOSE 9222
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--headless", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage", "--hide-scrollbars"]
