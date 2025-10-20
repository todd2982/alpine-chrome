FROM ghcr.io/todd2982/alpine-chrome

USER root
RUN apk add --no-cache \
      tini make gcc g++ python3 git nodejs npm yarn
USER chrome
ENTRYPOINT ["tini", "--"]
