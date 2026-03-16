#!/usr/bin/env bash
set -euo pipefail

# chezmoi init + apply（初回のみ age パスフレーズ入力が必要）
if [ ! -d "${HOME}/.local/share/chezmoi" ]; then
    chezmoi init --apply Zeni-Y
else
    chezmoi apply
fi

exec "$@"
