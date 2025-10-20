FROM ghcr.io/todd2982/alpine-chrome

USER root
RUN apk add --no-cache tini deno

USER chrome
ENTRYPOINT ["tini", "--"]
