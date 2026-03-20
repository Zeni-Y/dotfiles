#!/usr/bin/env bash

# fish shell のセットアップ（mise でインストール済みの fish に対して fisher を設定）

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function setup_fisher() {
    # fisher プラグインマネージャをインストールし、fish_plugins からプラグインを復元
    # --no-config: config.fish の再読み込みによるフォークボムを防止
    if [ -f "${HOME}/.config/fish/fish_plugins" ]; then
        fish --no-config -c '
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            fisher update
        '
    fi
}

function main() {
    setup_fisher
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
