#!/usr/bin/env zsh

# chezmoi-notify: dotfiles の更新を非同期でチェックし starship に通知するプラグイン

zmodload zsh/datetime

function _check_chezmoi_update_async() {
    local check_interval=3600 # 1時間ごとにチェック
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/starship-chezmoi"
    local status_file="$cache_dir/count"
    local last_check_file="$cache_dir/last_check"

    [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

    local current_time=$EPOCHSECONDS
    local last_check=0
    [[ -f "$last_check_file" ]] && last_check=$(<"$last_check_file")

    if ((current_time - last_check > check_interval)); then
        echo "$current_time" >| "$last_check_file"

        # バックグラウンドで実行
        (
            if command -v chezmoi > /dev/null 2>&1; then
                chezmoi git -- fetch -q

                # リモートとの差分コミット数を取得
                local count=$(chezmoi git -- rev-list --count HEAD..origin/main 2> /dev/null)

                if [[ "$count" -gt 0 ]]; then
                    echo "$count" >| "$status_file"
                else
                    rm -f "$status_file"
                fi
            fi
        ) &|
    fi
}

# precmd フックに登録（プロンプト表示直前に実行）
autoload -Uz add-zsh-hook
add-zsh-hook precmd _check_chezmoi_update_async
