function fgc --description "fzf で git branch をチェックアウト"
    git checkout (git for-each-ref refs/heads/ --format='%(refname:short)' | fzf)
end
