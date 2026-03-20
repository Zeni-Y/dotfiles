#!/usr/bin/env bash

# keychain のインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

KEYCHAIN_VERSION="2.9.8"

function install_keychain() {
    # バージョン比較で冪等性を確保
    if command -v keychain &>/dev/null; then
        local current
        # keychain --version は stderr に出力する
        current="$(keychain --version 2>&1 | head -1 | awk '{print $NF}')"
        if [ "${current}" = "${KEYCHAIN_VERSION}" ]; then
            echo "keychain ${KEYCHAIN_VERSION} is already installed"
            return 0
        fi
        echo "keychain ${current} found, upgrading to ${KEYCHAIN_VERSION}..."
    fi

    if [ "$(uname)" = "Darwin" ]; then
        brew install keychain
    elif [ "$(uname)" = "Linux" ]; then
        local url="https://github.com/danielrobbins/keychain/releases/download/${KEYCHAIN_VERSION}/keychain"

        echo "Downloading keychain ${KEYCHAIN_VERSION}..."
        mkdir -p "${HOME}/.local/bin"
        curl -fsSL -o "${HOME}/.local/bin/keychain" "${url}"
        chmod +x "${HOME}/.local/bin/keychain"
        echo "keychain ${KEYCHAIN_VERSION} installed to ~/.local/bin/keychain"
    else
        echo "Unsupported OS: $(uname)"
        return 1
    fi
}

function main() {
    install_keychain
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
