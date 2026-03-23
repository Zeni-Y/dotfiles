#!/usr/bin/env bash

# Nix パッケージマネージャのインストール
# Determinate Systems installer を使用（flakes デフォルト有効）

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_nix() {
    if command -v nix &>/dev/null; then
        echo "Nix は既にインストールされています"
        return
    fi

    echo "Nix をインストール中..."
    curl --proto '=https' --tlsv1.2 -sSf -L \
        https://install.determinate.systems/nix | sh -s -- install --no-confirm
}

function main() {
    install_nix
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
