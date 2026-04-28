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

# mise が node などのダウンロード署名検証に gpg を使うため、Linux で gnupg が
# 入っていない場合は事前にインストールする（最小構成の Ubuntu コンテナ等で必要）
function ensure_gnupg_linux() {
    if [ "$(uname)" != "Linux" ]; then
        return 0
    fi
    if command -v gpg-agent &>/dev/null; then
        return 0
    fi
    if ! command -v apt-get &>/dev/null; then
        echo "apt-get が見つかりません。gnupg を手動でインストールしてください"
        return 0
    fi
    if ! command -v sudo &>/dev/null; then
        echo "sudo が見つからないため、gnupg のインストールをスキップします"
        return 0
    fi
    if ! sudo -n true 2>/dev/null; then
        echo "gnupg のインストールには sudo が必要です。"
        read -r -p "sudo を使って gnupg をインストールしますか？ [y/N] " answer
        case "$answer" in
            [yY] | [yY][eE][sS]) ;;
            *)
                echo "gnupg のインストールをスキップします"
                return 0
                ;;
        esac
    fi
    echo "gnupg を apt からインストールします（mise の署名検証に必要）..."
    sudo apt-get update -q
    sudo apt-get install -y gnupg
}

function run_mise_install() {
    # mise install 中の gpg 署名検証で gpg-agent が必要になる
    ensure_gnupg_linux
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
