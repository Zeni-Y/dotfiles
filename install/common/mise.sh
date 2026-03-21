#!/usr/bin/env bash

# set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

export MISE_INSTALL_PATH="${HOME}/.local/bin/mise"

function install_mise() {
    curl https://mise.run | sh
    eval "$(~/.local/bin/mise activate bash)"
}

function run_mise_install() {
    # npm パッケージは Node.js が必要なため、先に Node.js をインストール
    mise install node
    mise install
}

function uninstall_mise() {
    rm "${MISE_INSTALL_PATH}"
}

function main() {
    install_mise
    run_mise_install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
