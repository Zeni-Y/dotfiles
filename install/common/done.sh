#!/usr/bin/env bash

# chezmoi apply 完了メッセージ

# Nix の環境変数を読み込む
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

cat <<'EOF'

==========================================
  chezmoi apply completed successfully!
==========================================
EOF

# chezmoi apply 完了後、自動で fish shell に切り替え
exec fish
