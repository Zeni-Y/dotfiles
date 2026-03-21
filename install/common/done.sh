#!/usr/bin/env bash

# chezmoi apply 完了メッセージ

cat <<'EOF'

==========================================
  chezmoi apply completed successfully!
==========================================
EOF

# chezmoi apply 完了後、自動で fish shell に切り替え
exec ~/.local/bin/mise x -- fish
