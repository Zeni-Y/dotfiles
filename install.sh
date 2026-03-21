#!/usr/bin/env bash
# 新しいマシンに dotfiles を展開するブートストラップスクリプト
#
# chezmoi init --apply だけではカバーできない以下の処理を担う:
#   - CI/TTY 環境の判定と --no-tty オプションの付与
#   - sudo セッションの維持（長時間のインストール中にタイムアウトさせない）
#   - ブートストラップ用 chezmoi バイナリの後始末
#
# Usage:
#   bash -c "$(curl -fsLS https://raw.githubusercontent.com/Zeni-Y/dotfiles/main/install.sh)"
#
# chezmoi init <user> を実行すると、リポジトリルートの install.sh を
# 自動検出・実行する仕組みがある。このファイル名は chezmoi の規約に従っている。
# 参考: https://www.chezmoi.io/user-guide/machines/general/

# -E: ERR トラップをサブシェルや関数にも伝播させる
# -e: コマンドが失敗したら即座にスクリプトを終了する
# -u: 未定義の変数を参照したらエラーにする
# -o pipefail: パイプラインの途中のコマンドが失敗しても検知する
set -Eeuo pipefail

# DOTFILES_DEBUG=1 で実行すると全コマンドのトレースが出力される（デバッグ用）
if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# shellcheck disable=SC2016
declare -r DOTFILES_LOGO='
         _       _    __ _ _
        | |     | |  / _(_) |
      __| | ___ | |_| |_ _| | ___  ___
     / _` |/ _ \| __|  _| | |/ _ \/ __|
    | (_| | (_) | |_| | | | |  __/\__ \
     \__,_|\___/ \__|_| |_|_|\___||___/

       *** dotfiles install script ***
       https://github.com/Zeni-Y/dotfiles
'

# GitHub リポジトリの URL（chezmoi init に渡す）
declare -r DOTFILES_REPO_URL="https://github.com/Zeni-Y/dotfiles"

# セットアップ対象のブランチ名（環境変数で上書き可能）
declare -r BRANCH_NAME="${BRANCH_NAME:-main}"

# ============================================================
# ユーティリティ関数
# ============================================================

# CI 環境かどうかを判定する
# GitHub Actions 等では CI=true が自動で設定される
function is_ci() {
    [ "${CI:-}" = "true" ]
}

# 標準入力が TTY（対話的な端末）に繋がっているかを判定する
# TTY = TeleTYpewriter の略で、ユーザーがキーボードから入力できる端末のこと
# ターミナルで直接実行した場合は true、パイプ経由（curl ... | bash）では false になる
function is_tty() {
    [ -t 0 ]
}

# CI 環境、またはパイプ経由の実行かを判定する
# どちらもユーザーがキーボードから入力できない（= TTY がない）状態
# chezmoi のプロンプトが使えないため、--no-tty が必要になる
function is_ci_or_not_tty() {
    is_ci || ! is_tty
}

function info() {
    printf "\033[0;34m[INFO]\033[0m %s\n" "$1"
}

function error() {
    printf "\033[0;31m[ERROR]\033[0m %s\n" "$1" >&2
    exit 1
}

# ============================================================
# sudo セッション維持
# ============================================================

# chezmoi apply 中に .chezmoiscripts が apt-get 等の sudo を使うコマンドを実行する
# インストールが長時間になると sudo のセッションがタイムアウトして再度パスワードを
# 求められるため、バックグラウンドで sudo のタイムスタンプを更新し続ける
function keepalive_sudo() {
    # 最初に sudo パスワードの入力を求める
    echo "Checking for \`sudo\` access which may request your password."
    sudo -v

    # 60秒ごとに sudo のタイムスタンプを更新する
    # kill -0 "$$" でこのスクリプトのプロセスが生きているか確認し、
    # 終了していたらバックグラウンドプロセスも終了する
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# ============================================================
# chezmoi によるセットアップ
# ============================================================

function run_chezmoi() {
    local bin_dir="${HOME}/.local/bin"

    # chezmoi 公式のインストーラスクリプトで バイナリをダウンロード
    # -b でインストール先ディレクトリを指定
    info "chezmoi をダウンロード中..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${bin_dir}"

    local chezmoi_cmd="${bin_dir}/chezmoi"

    if [ ! -x "${chezmoi_cmd}" ]; then
        error "chezmoi のダウンロードに失敗しました"
    fi

    # CI/非TTY 環境では --no-tty を付与して対話プロンプトを抑制する
    local no_tty_option=""
    if is_ci_or_not_tty; then
        no_tty_option="--no-tty"
    fi

    # chezmoi init: dotfiles リポジトリを clone し、設定ファイル（.chezmoi.yaml）を生成する
    # --force: 既存の設定があっても上書きする
    # --branch: clone するブランチを指定
    # --use-builtin-git true: システムに git がなくても chezmoi 内蔵の git で clone できる
    info "chezmoi init を実行中..."
    "${chezmoi_cmd}" init "${DOTFILES_REPO_URL}" \
        --force \
        --branch "${BRANCH_NAME}" \
        --use-builtin-git true \
        ${no_tty_option}

    # chezmoi apply: ソースディレクトリの内容をホームディレクトリに適用する
    # この中で .chezmoiscripts が実行され、mise, fish, starship 等がインストールされる
    info "chezmoi apply を実行中..."
    "${chezmoi_cmd}" apply ${no_tty_option}

    # ブートストラップ用 chezmoi バイナリを削除する
    # chezmoi apply で mise がインストールされ、mise 経由で chezmoi もインストールされるため
    # ダウンロードした chezmoi は不要になる（二重管理を防ぐ）
    info "ブートストラップ用 chezmoi を削除: ${chezmoi_cmd}"
    rm -fv "${chezmoi_cmd}"
}

# ============================================================
# オーケストレーション
# ============================================================

# sudo keepalive と chezmoi セットアップをまとめて実行する
function initialize_dotfiles() {
    if ! is_ci_or_not_tty; then
        # TTY がある（対話的な端末で実行している）場合のみ sudo keepalive を起動
        # CI 環境ではパスワードなし sudo が使えるため不要
        keepalive_sudo
    fi
    run_chezmoi
}

# ============================================================
# エントリポイント
# ============================================================

function main() {
    echo "${DOTFILES_LOGO}"

    initialize_dotfiles

    info "=== セットアップが完了しました ==="
    info "新しいシェルを起動すると設定が反映されます"
}

main
