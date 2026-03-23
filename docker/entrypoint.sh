#!/usr/bin/env bash
set -euo pipefail

# chezmoi init + apply
if [ ! -d "${HOME}/.local/share/chezmoi" ]; then
    chezmoi init --apply Zeni-Y
else
    chezmoi apply
fi

# SSH サーバー起動（特権ポート 22 のため sudo が必要）
sudo service ssh start

exec "$@"
