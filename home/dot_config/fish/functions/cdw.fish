function cdw --description "最新の gwq worktree に移動"
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo "Not inside a git repository."
        return 1
    end

    set -l moveto (gwq list --json | jq -r 'max_by(.created_at) | .path')
    if test -z "$moveto"
        echo "No recent gwq found."
        return 1
    end
    cd $moveto
end
