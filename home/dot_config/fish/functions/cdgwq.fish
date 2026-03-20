function cdgwq --description "gwq worktree を fzf で選択して移動"
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo "Not inside a git repository."
        return 1
    end
    set -l moveto (gwq list --json | jq -r '.[].path' | fzf)
    or return
    cd $moveto
end
