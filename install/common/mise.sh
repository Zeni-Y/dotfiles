#!/usr/bin/env bash

# mise のインストール（言語ランタイム管理用）
# CLI ツールは Nix で管理するため、mise は言語ランタイムと
# Nix で管理できないツールのみを担当

# set -Eeuo pipefail

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
    # npm パッケージは Node.js が必要なため、先に Node.js をインストール
    mise install node@lts
    mise install
}

function main() {
    install_mise
    run_mise_install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
