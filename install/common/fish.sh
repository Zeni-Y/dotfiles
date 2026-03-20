#!/usr/bin/env bash

# fish shell のインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_fish() {
    if command -v fish &>/dev/null; then
        echo "fish is already installed"
        return 0
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID}" in
            ubuntu|debian)
                sudo apt-get update -qq
                sudo apt-get install -y -qq fish
                ;;
            *)
                echo "Unsupported distro: ${ID}"
                return 1
                ;;
        esac
    elif [ "$(uname)" = "Darwin" ]; then
        brew install fish
    else
        echo "Unsupported OS"
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
