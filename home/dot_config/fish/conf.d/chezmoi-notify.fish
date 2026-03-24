# chezmoi-notify: dotfiles の更新を非同期でチェックし starship に通知するプラグイン

function _check_chezmoi_update --on-event fish_prompt
    set -l check_interval 3600
    set -l cache_dir (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $HOME/.cache)/starship-chezmoi
    set -l status_file $cache_dir/count
    set -l last_check_file $cache_dir/last_check

    test -d $cache_dir; or mkdir -p $cache_dir

    set -l current_time (date +%s)
    set -l last_check 0
    if test -f $last_check_file
        set last_check (cat $last_check_file)
    end

    if test (math "$current_time - $last_check") -gt $check_interval
        echo $current_time >$last_check_file

        # バックグラウンドで実行（fish -c はフォークボムになるため sh -c を使用）
        command sh -c '
            if command -v chezmoi >/dev/null 2>&1; then
                chezmoi git -- fetch -q 2>/dev/null
                count=$(chezmoi git -- rev-list --count HEAD..origin/main 2>/dev/null)
                if [ "$count" -gt 0 ] 2>/dev/null; then
                    echo "$count" > "'"$status_file"'"
                else
                    rm -f "'"$status_file"'"
                fi
            fi
        ' &
        disown
    end
end
