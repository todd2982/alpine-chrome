FROM alpine:3.23

# Installs latest Chromium package.
# socat is used to forward 0.0.0.0:9222 -> 127.0.0.1:9223 because modern
# Chromium (v112+) removed support for --remote-debugging-address and always
# binds DevTools to 127.0.0.1, making it unreachable from other Docker containers.
RUN apk upgrade --no-cache --available \
    && apk add --no-cache \
      gcompat \
      glib \
      nss \
      libxcb \
      libgcc \
      chromium \
      chromium-swiftshader \
      ttf-freefont \
      font-noto-emoji \
      socat \
      wget \
    && apk add --no-cache \
      --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
      font-wqy-zenhei

COPY local.conf /etc/fonts/local.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Add Chrome as a user
RUN mkdir -p /usr/src/app \
    && adduser -D chrome \
    && chown -R chrome:chrome /usr/src/app \
    && chmod +x /usr/local/bin/docker-entrypoint.sh
# Run Chrome as non-privileged
USER chrome
WORKDIR /usr/src/app

ENV HOME=/tmp \
    CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/

# Autorun chrome headless with socat port-forward so Chrome is reachable from
# other Docker containers (Chromium v112+ ignores --remote-debugging-address).
# The entrypoint starts Chrome on 127.0.0.1:9223 then exposes 0.0.0.0:9222.
ENV CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage"
EXPOSE 9222
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--headless", "--disable-gpu", "--no-sandbox", "--disable-dev-shm-usage", "--hide-scrollbars"]
