#!/usr/bin/env bash

# Intel Mac (darwin/amd64) 専用の Homebrew パッケージインストール
# mise の aqua/ubi バックエンドが darwin/amd64 に非対応のツールを管理する

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Intel Mac 専用パッケージ（aqua レジストリが darwin/amd64 非対応のもの）
BREW_PACKAGES=(
    fd
)

function install_brew_packages() {
    for pkg in "${BREW_PACKAGES[@]}"; do
        if brew list --formula "${pkg}" >/dev/null 2>&1; then
            echo "${pkg} は既にインストール済みです"
        else
            brew install "${pkg}"
        fi
    done
}

function main() {
    if [ "$(uname)" != "Darwin" ] || [ "$(uname -m)" != "x86_64" ]; then
        return 0
    fi
    install_brew_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
