FROM ghcr.io/todd2982/alpine-chrome

USER root
# Upgrade first so chromium-chromedriver version matches installed chromium packages
RUN apk upgrade --no-cache --available && apk add --no-cache chromium-chromedriver
USER chrome
EXPOSE 9515
ENTRYPOINT ["chromedriver","--allowed-ips=","--allowed-origins=*"]
