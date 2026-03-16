#!/usr/bin/env bash
set -euo pipefail

docker run --gpus all -it --name "${USER}_container" \
    --shm-size=16g \
    -v "${HOME}:/home/${USER}/host" \
    -w "/home/${USER}" \
    "${USER}_image"
