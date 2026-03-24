#!/usr/bin/env bash

# fisher プラグインマネージャのインストール

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# mise でインストールした fish を PATH に通す
eval "$(~/.local/bin/mise activate bash)"

function setup_login_shell() {
    # sudo が存在しない環境ではスキップ
    if ! command -v sudo &>/dev/null; then
        echo "sudo が見つからないため、ログインシェルの設定をスキップします"
        return 0
    fi

    # passwordless sudo が使えない場合は対話的に確認
    if ! sudo -n true 2>/dev/null; then
        echo "ログインシェルを fish に変更するには sudo が必要です。"
        read -r -p "sudo を使ってログインシェルを設定しますか？ [y/N] " answer
        case "$answer" in
            [yY] | [yY][eE][sS]) ;;
            *)
                echo "ログインシェルの設定をスキップします"
                return 0
                ;;
        esac
    fi

    local fish_path
    fish_path="$HOME/.local/bin/fish-login"  # mise shim の代わりにラッパーを使用

    # /etc/shells に未登録なら追加
    if ! grep -qxF "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # ログインシェルを fish ラッパーに変更
    sudo chsh -s "$fish_path" "$USER"
}

function main() {
    # fisher プラグインのインストール/更新
    #
    # フォークボムについて:
    #   `fish -c` のフォークボムは「fish 設定ファイル内で fish -c を呼ぶ」場合に発生する。
    #   このスクリプトは bash スクリプトであり、bash → fish の呼び出しは再帰しないため安全。
    #   （config.fish が fisher update を呼ぶことはないため）
    #
    # --no-config を使わない理由:
    #   --no-config では fisher がインストール履歴を認識できず "conflicting files" エラーになる。
    #   通常の fish として起動することで、fisher が既存ファイルを正しく管理できる。
    fish -c '
        # fisher が未インストールなら curl からインストール
        if not functions -q fisher
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            fisher install jorgebucaran/fisher
        end

        # fish_plugins に基づいて全プラグインをインストール/更新
        fisher update
    '
    setup_login_shell
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
