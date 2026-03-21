#!/usr/bin/env bash

# fisher プラグインマネージャのインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly FUNCTIONS_DIR="${HOME}/.config/fish/functions"
readonly FISHER_URL="https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish"

# mise でインストールした fish を PATH に通す
eval "$(~/.local/bin/mise activate bash)"

function install_fisher() {
    mkdir -p "${FUNCTIONS_DIR}"

    echo "Downloading fisher.fish..."
    curl -sL "${FISHER_URL}" -o "${FUNCTIONS_DIR}/fisher.fish"

    # fisher 自身を正式にインストール（fish_plugins との整合性を確保）
    # curl でファイルを置いただけでは fisher update 時に競合エラーになる
    fish --no-config -c '
        source ~/.config/fish/functions/fisher.fish
        fisher install jorgebucaran/fisher
    '
}

function setup_plugins() {
    # fisher.fish を直接 source してプラグインを復元
    # --no-config: config.fish の再読み込みによるフォークボムを防止
    if [ -f "${HOME}/.config/fish/fish_plugins" ]; then
        fish --no-config -c '
            source ~/.config/fish/functions/fisher.fish
            fisher update
        '
    fi
}

function main() {
    install_fisher
    setup_plugins
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
