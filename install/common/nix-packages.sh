#!/usr/bin/env bash

# flake.nix で定義した CLI ツールを nix profile でインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Nix の環境変数を読み込む（インストール直後は PATH が通っていない場合がある）
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

function main() {
    # chezmoi のソースディレクトリからリポジトリルートを特定
    # .chezmoiroot が home/ を指すため、source-path の親がリポジトリルート
    local dotfiles_dir
    dotfiles_dir="$(chezmoi source-path)/.."

    echo "Nix パッケージをインストール中..."
    echo "flake: ${dotfiles_dir}"

    # 既存のプロファイルがあればアップグレード、なければインストール
    if nix profile list | grep -q "dotfiles-packages"; then
        nix profile upgrade --all
    else
        nix profile install "path:${dotfiles_dir}"
    fi

    echo "Nix パッケージのインストールが完了しました"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
