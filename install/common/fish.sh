#!/usr/bin/env bash

# fisher プラグインマネージャのインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# mise でインストールした fish を PATH に通す
eval "$(~/.local/bin/mise activate bash)"

function main() {
    # fisher を URL から直接メモリに読み込み、fish_plugins の全プラグインをインストール
    # ファイルに保存しないため fisher 自身との競合が発生しない
    # --no-config: config.fish の再読み込みによるフォークボムを防止
    fish --no-config -c '
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
        fisher update
    '
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
