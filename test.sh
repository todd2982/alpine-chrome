#!/bin/sh -e

echo "# Common test"
docker container run --rm --entrypoint '' ${IMAGE_NAME:-todd2982/alpine-chrome} cat /etc/alpine-release
docker container run --rm --entrypoint '' ${IMAGE_NAME:-todd2982/alpine-chrome} chromium-browser --version
