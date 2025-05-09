FROM ghcr.io/zoobdude/alpine-chrome

USER root
RUN apk add --no-cache tini deno

USER chrome
ENTRYPOINT ["tini", "--"]
