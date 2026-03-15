#!/usr/bin/env bash

# WSL 環境の場合、keymap.json を Windows 側の %APPDATA%\Zed\ にコピーする

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

function get_windows_appdata() {
    # Windows の %APPDATA% パスを WSL パスに変換
    local win_appdata
    win_appdata="$(cmd.exe /C 'echo %APPDATA%' 2>/dev/null | tr -d '\r')"
    wslpath -u "${win_appdata}"
}

function main() {
    if ! is_wsl; then
        echo "WSL 環境ではないためスキップします"
        return 0
    fi

    local appdata_path
    appdata_path="$(get_windows_appdata)"
    local zed_dir="${appdata_path}/Zed"
    local src="${HOME}/.config/zed/keymap.json"

    if [ ! -f "${src}" ]; then
        echo "keymap.json が見つかりません: ${src}"
        return 1
    fi

    # Windows 側の Zed ディレクトリを作成
    mkdir -p "${zed_dir}"

    # keymap.json をコピー
    cp "${src}" "${zed_dir}/keymap.json"
    echo "keymap.json を配置しました: ${zed_dir}/keymap.json"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
