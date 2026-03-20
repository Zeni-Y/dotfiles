function git-delete-merged-branches --description "squash-merge 済みのブランチを検出して削除"
    if not git rev-parse --is-inside-work-tree &>/dev/null
        return 0
    end

    set -l default_branch (LC_ALL=C git remote show origin | sed -n '/HEAD branch/s/.*: //p')

    git checkout -q $default_branch

    for branch in (git for-each-ref refs/heads/ --format='%(refname:short)')
        set -l merge_base (git merge-base $default_branch $branch)
        set -l tree_commit (git commit-tree (git rev-parse "$branch^{tree}") -p $merge_base -m _)
        set -l cherry (git cherry $default_branch $tree_commit)
        if string match -q -- '-*' $cherry
            git branch -D $branch
        end
    end
end
