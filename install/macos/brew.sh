#!/usr/bin/env bash

# Homebrew のインストール（macOS 用）
#
# 初期化直後の Mac には Homebrew も Xcode Command Line Tools も入っていないため、
# fish / tmux など brew 経由でインストールするツールより先にこのスクリプトを実行する。
#
# 公式インストーラが内部で xcode-select --install を走らせるため、Xcode CLT が
# 未インストールでも対応可能。既にインストール済みの場合は何もしない。

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Apple Silicon か Intel かで Homebrew のインストール先が異なる
# - Apple Silicon: /opt/homebrew
# - Intel:         /usr/local
function brew_prefix() {
    if [ "$(uname -m)" = "arm64" ]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

function install_xcode_clt() {
    # xcode-select -p が通れば CLT は既にインストール済み
    if xcode-select -p >/dev/null 2>&1; then
        return 0
    fi

    echo "Xcode Command Line Tools をインストールします..."
    # GUI ダイアログでインストールを開始する
    # Homebrew 公式インストーラも裏で同じことをしているが、先に済ませることで
    # インストール中にユーザーが別作業に移れる
    xcode-select --install || true

    # CLT のインストールが完了するまで待機
    until xcode-select -p >/dev/null 2>&1; do
        echo "Xcode Command Line Tools のインストール完了を待機中..."
        sleep 10
    done
    echo "Xcode Command Line Tools のインストールが完了しました"
}

function install_brew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew は既にインストール済みです: $(command -v brew)"
        return 0
    fi

    local prefix
    prefix="$(brew_prefix)"

    # Homebrew が実体を置くディレクトリが既に存在する場合は shellenv だけ実行
    if [ -x "${prefix}/bin/brew" ]; then
        echo "Homebrew を検出: ${prefix}/bin/brew"
        eval "$(${prefix}/bin/brew shellenv)"
        return 0
    fi

    echo "Homebrew をインストールします..."
    # NONINTERACTIVE=1: 公式インストーラが sudo パスワード以外のプロンプトを出さない
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # インストール直後は PATH に brew が無いため shellenv を反映
    eval "$(${prefix}/bin/brew shellenv)"
}

function main() {
    # macOS 以外では何もしない（防御的にガード）
    if [ "$(uname)" != "Darwin" ]; then
        return 0
    fi

    install_xcode_clt
    install_brew
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
