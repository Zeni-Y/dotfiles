#!/usr/bin/env bash
set -euo pipefail

# chezmoi init + apply
if [ ! -d "${HOME}/.local/share/chezmoi" ]; then
    chezmoi init --apply Zeni-Y
else
    chezmoi apply
fi

exec "$@"
