#!/usr/bin/env bash
set -euo pipefail

docker build \
    --build-arg USERNAME="$USER" \
    --build-arg USER_UID="$(id -u)" \
    --build-arg USER_GID="$(id -g)" \
    ./ -t "${USER}_image"
