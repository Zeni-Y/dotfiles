#!/usr/bin/env bash

# fish のインストールと fisher プラグインマネージャのセットアップ

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_fish_linux() {
    if ! command -v apt-get &>/dev/null; then
        echo "apt-get が見つかりません。fish を手動でインストールしてください"
        return 0
    fi

    # sudo が存在しない環境ではスキップ
    if ! command -v sudo &>/dev/null; then
        echo "sudo が見つからないため、fish のインストールをスキップします"
        return 0
    fi

    # passwordless sudo が使えない場合は対話的に確認
    if ! sudo -n true 2>/dev/null; then
        echo "fish のインストールには sudo が必要です。"
        read -r -p "sudo を使って fish をインストールしますか？ [y/N] " answer
        case "$answer" in
            [yY] | [yY][eE][sS]) ;;
            *)
                echo "fish のインストールをスキップします"
                return 0
                ;;
        esac
    fi

    echo "fish を PPA からインストールします..."
    sudo apt-add-repository -y ppa:fish-shell/release-4
    sudo apt-get update -q
    sudo apt-get install -y fish
}

function install_fish_darwin() {
    # chezmoiscript は別プロセスで実行されるため、事前スクリプトで brew をインストールしても
    # PATH に反映されていない。代表的な場所を順に探して shellenv を読み込む。
    if ! command -v brew &>/dev/null; then
        for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            if [ -x "${brew_bin}" ]; then
                eval "$(${brew_bin} shellenv)"
                break
            fi
        done
    fi

    if ! command -v brew &>/dev/null; then
        echo "brew が見つかりません。Homebrew を先にインストールしてください"
        return 1
    fi

    echo "fish を Homebrew からインストールします..."
    brew install fish
}

function install_fish() {
    if command -v fish &>/dev/null; then
        echo "fish はすでにインストール済みです: $(command -v fish)"
        return 0
    fi

    case "$(uname)" in
        Linux)
            install_fish_linux
            ;;
        Darwin)
            install_fish_darwin
            ;;
        *)
            echo "サポート外の OS です。fish を手動でインストールしてください"
            return 0
            ;;
    esac
}

function setup_login_shell() {
    # fish の実パスを動的に取得（Linux: /usr/bin/fish, macOS: /opt/homebrew/bin/fish など）
    local fish_path
    fish_path="$(command -v fish || true)"
    if [ -z "${fish_path}" ]; then
        echo "fish が見つからないため、ログインシェルの設定をスキップします"
        return 0
    fi

    # /etc/shells への追記と chsh は sudo が必要
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

    # /etc/shells に未登録なら追加
    if ! grep -qxF "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # 既にログインシェルが fish なら chsh は不要（Mac の DirectoryService などで無駄な書き換えを避ける）
    # dscl は macOS 専用、getent は Linux/glibc 系専用なので OS で分岐する
    # （pipefail 有効下で存在しないコマンドが exit 127 を返すとスクリプト全体が落ちるため）
    local current_shell=""
    case "$(uname)" in
        Darwin)
            if command -v dscl &>/dev/null; then
                current_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}' || true)"
            fi
            ;;
        Linux)
            if command -v getent &>/dev/null; then
                current_shell="$(getent passwd "$(id -un)" | cut -d: -f7 || true)"
            fi
            ;;
    esac
    if [ "${current_shell}" = "${fish_path}" ]; then
        echo "ログインシェルは既に fish です: ${fish_path}"
        return 0
    fi

    # ログインシェルを fish に変更
    sudo chsh -s "$fish_path" "$(id -un)"
}

function main() {
    install_fish

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
    if ! command -v fish &>/dev/null; then
        echo "fish が見つからないため、fisher のセットアップをスキップします"
        return 0
    fi

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
