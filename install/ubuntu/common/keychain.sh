#!/usr/bin/env bash
set -Eeuo pipefail

install_keychain() {
    if ! command -v keychain >/dev/null 2>&1; then
        echo "Installing keychain..."
        sudo apt-get update
        sudo apt-get install -y keychain
    else
        echo "keychain is already installed."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_keychain
fi
