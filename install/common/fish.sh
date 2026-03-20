#!/usr/bin/env bash

# fish shell のインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

FISH_VERSION="4.5.0"

function install_fish() {
    # バージョン比較で冪等性を確保
    if command -v fish &>/dev/null; then
        local current
        current="$(fish --version 2>/dev/null | sed 's/fish, version //')"
        if [ "${current}" = "${FISH_VERSION}" ]; then
            echo "fish ${FISH_VERSION} is already installed"
            return 0
        fi
        echo "fish ${current} found, upgrading to ${FISH_VERSION}..."
    fi

    if [ "$(uname)" = "Darwin" ]; then
        brew install fish
    elif [ "$(uname)" = "Linux" ]; then
        local arch
        arch="$(uname -m)"
        local url="https://github.com/fish-shell/fish-shell/releases/download/${FISH_VERSION}/fish-${FISH_VERSION}-linux-${arch}.tar.xz"

        echo "Downloading fish ${FISH_VERSION} for ${arch}..."
        mkdir -p "${HOME}/.local/bin"
        curl -fsSL "${url}" | tar -xJ -C "${HOME}/.local/bin"
        chmod +x "${HOME}/.local/bin/fish"
        echo "fish ${FISH_VERSION} installed to ~/.local/bin/fish"
    else
        echo "Unsupported OS: $(uname)"
        return 1
    fi
}

function setup_fisher() {
    # fisher プラグインマネージャをインストールし、fish_plugins からプラグインを復元
    if [ -f "${HOME}/.config/fish/fish_plugins" ]; then
        fish -c '
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            fisher update
        '
    fi
}

function main() {
    install_fish
    setup_fisher
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
