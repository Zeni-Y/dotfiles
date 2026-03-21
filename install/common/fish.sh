#!/usr/bin/env bash

# fisher プラグインマネージャのインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# mise でインストールした fish を PATH に通す
eval "$(~/.local/bin/mise activate bash)"

function setup_login_shell() {
    local fish_path
    fish_path="$HOME/.local/share/mise/shims/fish"

    # /etc/shells に未登録なら追加
    if ! grep -qxF "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # ログインシェルを fish に変更
    sudo chsh -s "$fish_path" "$USER"
}

function main() {
    # fisher プラグインのインストール/更新
    # --no-config: config.fish の再読み込みによるフォークボムを防止
    fish --no-config -c '
        # 既存の fisher がある場合、全プラグインを削除して競合を回避
        if test -f ~/.config/fish/functions/fisher.fish
            source ~/.config/fish/functions/fisher.fish
            fisher remove (fisher list)
        end
        # fisher を URL から直接メモリに読み込み、fish_plugins から全プラグインをインストール
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
        fisher update
    '

    setup_login_shell
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
