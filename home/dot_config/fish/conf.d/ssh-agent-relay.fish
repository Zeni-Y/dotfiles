# ssh-agent-relay: SSH agent forwarding を Zellij 等のマルチプレクサで維持する
#
# SSH 接続時に SSH_AUTH_SOCK を固定パスのシンボリックリンク経由にすることで、
# セッション再アタッチ後も agent forwarding が機能するようにする

if set -q SSH_AUTH_SOCK; and test "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock"
    # 実際のソケットが存在する場合のみシンボリックリンクを更新
    if test -S "$SSH_AUTH_SOCK"
        mkdir -p $HOME/.ssh
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
    end
    set -gx SSH_AUTH_SOCK "$HOME/.ssh/ssh_auth_sock"
end
