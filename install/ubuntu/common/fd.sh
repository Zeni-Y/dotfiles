#!/bin/bash

function install_fd() {
    if ! command -v fdfind &> /dev/null; then
        echo "Installing fd-find..."
        sudo apt-get update
        sudo apt-get install -y fd-find
    else
        echo "fd-find is already installed."
    fi

    # Ubuntu では fdfind という名前でインストールされるので
    # fd としても使えるようにシンボリックリンクを作成
    local link_path="${HOME}/.local/bin/fd"
    if [ ! -L "$link_path" ]; then
        mkdir -p "${HOME}/.local/bin"
        ln -s "$(which fdfind)" "$link_path"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fd
fi
