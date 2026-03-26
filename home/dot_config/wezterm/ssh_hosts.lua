-- SSH 接続先リスト（環境に合わせて編集）
-- launch_menu 経由でシステムの ssh.exe を使うため、
-- Windows SSH agent（OpenSSH）と正しく連携できる。
--
-- 例:
-- { label = "SSH: dev-server", args = { "ssh", "user@192.168.1.100" } },
-- { label = "SSH: myserver",   args = { "ssh", "myserver" } },  -- ~/.ssh/config のエイリアス使用可
return {
  -- { label = "SSH: <name>", args = { "ssh", "<user@host>" } },
}
