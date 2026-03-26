#!/usr/bin/env bash
# tmux と TPM（Tmux Plugin Manager）のインストール

set -euo pipefail

# tmux のインストール
function install_tmux() {
    if command -v tmux > /dev/null 2>&1; then
        echo "tmux は既にインストール済みです: $(tmux -V)"
        return
    fi

    echo "tmux をインストール中..."

    if command -v apt-get > /dev/null 2>&1; then
        sudo apt-get install -y tmux
    elif command -v brew > /dev/null 2>&1; then
        brew install tmux
    else
        echo "警告: 対応するパッケージマネージャが見つかりません" >&2
        echo "tmux を手動でインストールしてください: https://github.com/tmux/tmux/wiki/Installing" >&2
        return 1
    fi

    echo "tmux のインストールが完了しました: $(tmux -V)"
}

# TPM（Tmux Plugin Manager）のインストール
function install_tpm() {
    local tpm_dir="${HOME}/.tmux/plugins/tpm"

    if [ -d "${tpm_dir}" ]; then
        echo "TPM は既にインストール済みです"
        return
    fi

    echo "TPM をインストール中..."
    git clone https://github.com/tmux-plugins/tpm "${tpm_dir}"
    echo "TPM のインストールが完了しました"
    echo "tmux を起動後、prefix + I でプラグインをインストールしてください"
}

function main() {
    install_tmux
    install_tpm
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
