#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

export MISE_INSTALL_PATH="${HOME}/.local/bin/mise"

# GITHUB_TOKEN が設定されていれば mise にも渡す（GitHub API レート制限回避）
if [ -n "${GITHUB_TOKEN:-}" ]; then
    export MISE_GITHUB_TOKEN="${GITHUB_TOKEN}"
fi

function install_mise() {
    curl https://mise.run | sh
    eval "$(~/.local/bin/mise activate bash)"
}

function run_mise_install() {
    # config.toml を信頼済みにしておかないとインタラクティブプロンプトが出る
    mise trust --yes "${HOME}/.config/mise/config.toml"
    # npm パッケージは Node.js が必要なため、config.toml を参照せず直接インストール
    mise use --global node@lts
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
