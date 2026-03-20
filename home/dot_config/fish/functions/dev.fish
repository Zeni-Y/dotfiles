function dev --description "ghq + fzf でリポジトリに移動し、tmux セッション名をリネーム"
    set -l selected_path (ghq list --full-path | fzf)
    or return

    test -n "$selected_path"; or return 1
    cd $selected_path

    # tmux 内であればセッション名をリポジトリ名にリネーム
    if set -q TMUX
        set -l repo_name (basename $selected_path)
        tmux rename-session (string replace -a '.' '-' $repo_name)
    end
end
