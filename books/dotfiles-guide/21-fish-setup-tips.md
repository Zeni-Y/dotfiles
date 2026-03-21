---
title: "fish セットアップの知見とトラブルシューティング"
---

# fish セットアップの知見とトラブルシューティング

## この章で扱うこと

chezmoi で fish 環境を構築する過程で、いくつかのハマりどころに遭遇しました。fish 自体の設定は[「fish と fisher プラグイン管理」](09-fish-and-fisher)で、起動パフォーマンスは[「fish 起動パフォーマンスの計測と改善」](20-fish-performance)で解説していますが、この章では**セットアップ時に踏んだ落とし穴と、その解決策**を実践的にまとめます。

| 課題                                    | 原因                                              | 解決策                                     |
| --------------------------------------- | ------------------------------------------------- | ------------------------------------------ |
| chezmoi apply 後に fish が見つからない  | mise 管理の fish が PATH に未登録                 | done.sh で自動的に fish へ切り替え         |
| ログインシェルが bash のまま            | chsh で fish を設定していない                     | install スクリプトで自動設定               |
| mise install で npm パッケージが失敗    | Node.js より先に npm パッケージを解決しようとする | Node.js を明示バージョンで先にインストール |
| Docker 環境で permission denied         | volume mount で親ディレクトリが root 所有になる   | USER 切替後にディレクトリを事前作成        |
| GitHub API レート制限でインストール失敗 | mise が GitHub API を叩きすぎる                   | GITHUB_TOKEN を mise に転送                |

## chezmoi apply 後に fish が「見つからない」問題

### 症状

`chezmoi apply` が完了した直後、`fish` コマンドを実行しても `command not found` になります。

```bash
$ fish
bash: fish: command not found
```

### 原因

fish は mise 経由でインストールされます。`chezmoi apply` を実行している bash セッションでは mise の shims ディレクトリが PATH に入っていないため、mise 管理のバイナリが見えません。

```
~/.local/share/mise/installs/fish/3.x.x/bin/fish   ← 実体はここ
~/.local/share/mise/shims/fish                       ← shim（PATH に入っていれば使える）
```

### 解決策: done.sh による自動切り替え

当リポジトリでは、`chezmoi apply` の最後に実行されるスクリプト（`install/common/done.sh`）で**自動的に fish へ切り替え**ています。

```bash
#!/usr/bin/env bash
# chezmoi apply 完了メッセージ
cat <<'EOF'

==========================================
  chezmoi apply completed successfully!
==========================================
EOF

# chezmoi apply 完了後、自動で fish shell に切り替え
exec ~/.local/bin/mise x -- fish
```

ポイントは `exec` と `mise x --` の組み合わせです。

| 要素                | 役割                                                        |
| ------------------- | ----------------------------------------------------------- |
| `exec`              | 現在の bash プロセスを fish で置き換える（bash に戻らない） |
| `mise x --`         | mise の環境を一時的にセットアップしてコマンドを実行する     |
| `~/.local/bin/mise` | mise 自体はフルパスで呼ぶ（PATH に頼らない）                |

`mise x -- fish` は `mise activate` せずに一時的に mise 管理のツールを実行できるコマンドです。PATH を汚さずに fish を起動できます。

### chezmoi スクリプトとの連携

このスクリプトは chezmoi の `run_once_after_99-done.sh.tmpl` から呼ばれます。`99` のプレフィックスで**全スクリプトの最後に実行**されることを保証しています。

```bash
# home/.chezmoiscripts/common/run_once_after_99-done.sh.tmpl
{{ include "../../install/common/done.sh" }}
```

## ログインシェルを fish に自動設定する

### 課題

`chezmoi apply` のたびに fish に切り替わるのは良いのですが、**次回ログイン時**（SSH、コンソール、新しいターミナルセッション）にはまた bash に戻ってしまいます。ログインシェルを fish に変更する必要があります。

### chsh の制約

Linux の `chsh` コマンドでログインシェルを変更するには、そのシェルが `/etc/shells` に登録されている必要があります[^1]。mise でインストールした fish は `/etc/shells` に登録されていないため、そのままでは `chsh` が拒否します。

```bash
$ chsh -s ~/.local/share/mise/shims/fish
chsh: /home/user/.local/share/mise/shims/fish is an invalid shell
```

### 解決策: install スクリプトでの自動設定

`install/common/fish.sh` に `setup_login_shell()` 関数を追加し、fisher のセットアップ後に自動実行しています。

```bash
function setup_login_shell() {
    local fish_path
    fish_path="$HOME/.local/share/mise/shims/fish"

    # /etc/shells に未登録なら追加
    if ! grep -qxF "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # ログインシェルを fish に変更
    sudo chsh -s "$fish_path" "$USER"
}
```

処理の流れ:

1. **`/etc/shells` への登録**: `grep -qxF` で完全一致検索し、未登録の場合のみ `sudo tee -a` で追記
2. **ログインシェルの変更**: `sudo chsh -s` でユーザーのログインシェルを変更

`sudo` が必要な理由は、`/etc/shells` はシステムファイルであり、一般ユーザーには書き込み権限がないためです。`chsh` も他のユーザー（`$USER` 指定時）のシェルを変更するには root 権限が必要です。

:::message
**mise shims パスを使う理由**

`/usr/local/bin/fish` ではなく `~/.local/share/mise/shims/fish` を登録しているのは、fish のバイナリが mise で管理されているためです。mise のバージョン切り替えは shim 経由で透過的に行われるので、shim パスを登録しておけば mise で fish をアップデートしても `/etc/shells` を更新する必要がありません。
:::

### 2 つの自動化の関係

| タイミング         | 仕組み                             | 目的                             |
| ------------------ | ---------------------------------- | -------------------------------- |
| chezmoi apply 直後 | `done.sh` が `exec mise x -- fish` | 今すぐ fish を使い始める         |
| 次回ログイン以降   | `setup_login_shell()` で chsh      | ログインシェルとして fish を使う |

この 2 つが組み合わさることで、初回の `chezmoi apply` から以降のログインまで、一貫して fish が使える環境になります。

## mise の Node.js 循環依存を回避する

### 症状

`mise install` を実行すると、npm パッケージのバージョン解決で警告が大量に出ます。

```
WARN  No npm found for resolution. npm packages may not be able to be resolved.
```

### 原因

mise の `config.toml` には Node.js と npm パッケージの両方が定義されています。

```toml
[tools]
node = "lts"
"npm:bash-language-server" = "latest"
"npm:pyright" = "latest"
"npm:@anthropic-ai/claude-code" = "latest"
```

mise が `config.toml` を読み込む際、npm パッケージのバージョンを解決するために npm コマンドが必要です。しかし Node.js（npm を含む）はまだインストールされていません。鶏と卵の問題です。

```
config.toml を読む
  → npm パッケージのバージョンを解決したい
    → npm が必要
      → Node.js がまだインストールされていない
        → 警告
```

### 解決策: Node.js を明示バージョンで先にインストール

`install/common/mise.sh` で、`mise install`（config.toml 全体のインストール）の前に Node.js を単独でインストールします。

```bash
function run_mise_install() {
    # npm パッケージは Node.js が必要なため、config.toml を参照せず直接インストール
    mise install node@lts
    mise install
}
```

`mise install node` ではなく `mise install node@lts` とバージョンを明示するのがポイントです。`mise install node`（バージョン指定なし）は config.toml からバージョンを読み取ろうとし、その過程で npm パッケージの解決も走ってしまいます。`node@lts` と明示することで config.toml を参照せずに直接インストールが始まります。

:::message alert
**`mise install node` vs `mise install node@lts`**

| コマンド                | 動作                                                                                                       |
| ----------------------- | ---------------------------------------------------------------------------------------------------------- |
| `mise install node`     | config.toml の `[tools]` セクションから node のバージョンを読み取る。この過程で npm パッケージの解決も走る |
| `mise install node@lts` | config.toml を参照せず、LTS バージョンを直接インストールする                                               |

初回セットアップ時は `node@lts` の明示指定が安全です。2 回目以降（Node.js がインストール済み）は `mise install` だけで問題ありません。
:::

## Docker 環境での permission denied

### 症状

Docker コンテナ内で `chezmoi apply` を実行すると、`~/.local/bin` の作成で permission denied が発生します。

```
mkdir /home/zenimoto/.local/bin: permission denied
```

### 原因

Docker の volume mount が原因です。Makefile がホストディレクトリをコンテナの `~/.local/share/chezmoi` にマウントする際、Docker デーモンは存在しない親ディレクトリ（`.local`, `.local/share`）を **root 権限で** 作成します。

```
~/.local/              ← root:root（Docker が作成）
  └── share/           ← root:root（Docker が作成）
      └── chezmoi/     ← volume mount（正常）
```

`USER` ディレクティブで非 root ユーザーに切り替えていても、volume mount のディレクトリ作成は Docker デーモンの操作なので root で実行されます。結果として、ユーザーが `~/.local/bin` を作ろうとすると、親の `~/.local` が root 所有のため失敗します。

### 解決策: USER 切替後にディレクトリを事前作成

Dockerfile で `USER` に切り替えた直後、WORKDIR の前に必要なディレクトリを作成します。

```dockerfile
USER $USERNAME

# volume mount より先にディレクトリをユーザー権限で作成
RUN mkdir -p ~/.local/bin ~/.local/share/chezmoi ~/.local/share/fonts

WORKDIR /home/$USERNAME/.local/share/chezmoi
```

USER 切替後に `mkdir` するため、ディレクトリはそのユーザーの所有で作成されます。Docker の volume mount 時には既にディレクトリが存在するため、root による再作成は発生しません。

:::message
**root で mkdir → chown より USER 後に mkdir が良い理由**

```dockerfile
# NG: root で作って chown する（冗長）
RUN mkdir -p /home/$USERNAME/.local && chown -R $USERNAME:$USER_GID /home/$USERNAME/.local
USER $USERNAME

# OK: USER 後に作る（シンプル）
USER $USERNAME
RUN mkdir -p ~/.local/bin ~/.local/share/chezmoi
```

後者の方がシンプルで、UID/GID の指定ミスのリスクもありません。
:::

## GitHub API レート制限への対処

### 症状

Docker 環境や CI で mise のインストール中にツールのダウンロードが失敗します。

```
error: GitHub API rate limit exceeded
```

### 原因

mise は多くのツール（eza, starship, jq, shfmt, gh 等）を GitHub Releases からダウンロードします。GitHub API には認証なしのリクエストに対して 1 時間あたり 60 回のレート制限があります[^2]。30 以上のツールをまとめてインストールする当リポジトリの構成では、この制限に容易に到達します。

### 解決策: GITHUB_TOKEN を mise に転送

`install/common/mise.sh` で環境変数を変換しています。

```bash
# GITHUB_TOKEN が設定されていれば mise にも渡す（GitHub API レート制限回避）
if [ -n "${GITHUB_TOKEN:-}" ]; then
    export MISE_GITHUB_TOKEN="${GITHUB_TOKEN}"
fi
```

mise は `MISE_GITHUB_TOKEN` 環境変数を認識し、GitHub API リクエストに認証ヘッダーを付与します。認証済みリクエストのレート制限は 1 時間あたり 5,000 回です。

### Docker での GITHUB_TOKEN の渡し方

Makefile で `--env` オプションを使ってホストの環境変数をコンテナに転送します。

```makefile
docker:
	docker run \
	    --env GITHUB_TOKEN \
	    ...
```

`--env GITHUB_TOKEN`（値なし）はホスト側の `GITHUB_TOKEN` 環境変数をそのままコンテナに転送します。未設定の場合は何も渡されないため、ローカル開発では影響ありません。

GitHub Actions では `GITHUB_TOKEN` がデフォルトで利用可能なため、CI 環境では特別な設定なしにレート制限を回避できます。

## fisher のインメモリ読み込みパターン

fisher のインストールは一見シンプルですが、いくつかの制約を考慮した設計になっています。

```bash
fish --no-config -c '
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher update
'
```

### なぜファイルに保存しないのか

fisher.fish を `~/.config/fish/functions/fisher.fish` にダウンロードしてから `source` する方法もありますが、このリポジトリではパイプで直接メモリに読み込んでいます。理由は、`fisher update` の実行中に fisher 自身がそのファイルを管理・更新するためです。事前にファイルとして存在すると競合が起きる可能性があります。

### なぜ `--no-config` が必要なのか

`fish -c '...'` は通常の fish 起動と同様に `config.fish` を読み込みます。セットアップ途中で `config.fish` を読み込むと、まだ存在しないツール（starship 等）の初期化でエラーが出たり、最悪の場合フォークボムが発生します。`--no-config` で config.fish の読み込みをスキップすることで、クリーンな状態で fisher だけを実行できます。

詳しくは[「fish と fisher プラグイン管理」の「fish -c フォークボムに注意」セクション](09-fish-and-fisher)を参照してください。

### なぜ bash スクリプトから fish を呼ぶのか

fisher は fish のプラグインマネージャなので、`fisher update` は fish 上で実行する必要があります。しかし、chezmoi のスクリプト（`.chezmoiscripts`）は bash で書かれています。そこで bash スクリプト内から `fish --no-config -c '...'` で fish を一時的に起動し、fisher の処理だけを行っています。

```
chezmoi apply (bash)
  → run_once_after_10-install-fish.sh (bash)
    → install/common/fish.sh (bash)
      → fish --no-config -c 'curl ... | source; fisher update' (fish)
```

## セットアップの全体フロー

ここまでの知見を踏まえた、fish 環境が構築される全体の流れです。

```
chezmoi apply 開始
  │
  ├─ run_once_after_01: mise インストール
  │   └─ Node.js を node@lts で先にインストール → mise install
  │
  ├─ run_once_after_10: fish & fisher セットアップ
  │   ├─ mise activate bash で fish を PATH に追加
  │   ├─ fish --no-config -c 'fisher update'
  │   └─ setup_login_shell() で chsh
  │
  ├─ chezmoi がテンプレートを展開
  │   └─ config.fish.tmpl → ~/.config/fish/config.fish
  │
  └─ run_once_after_99: done.sh
      ├─ 完了メッセージ表示
      └─ exec mise x -- fish（自動切り替え）
```

## まとめ

fish のセットアップで遭遇しやすい問題とその対策を一覧にまとめます。

| 問題                        | 根本原因                                      | 対策                                 | 該当ファイル             |
| --------------------------- | --------------------------------------------- | ------------------------------------ | ------------------------ |
| fish が見つからない         | mise の PATH が未設定                         | `exec mise x -- fish` で切り替え     | `install/common/done.sh` |
| ログインシェルが bash       | chsh 未実行                                   | `/etc/shells` 登録 + `chsh`          | `install/common/fish.sh` |
| npm パッケージ警告          | Node.js 未インストール時に config.toml を解析 | `mise install node@lts` を先行実行   | `install/common/mise.sh` |
| Docker で permission denied | volume mount が root でディレクトリ作成       | USER 後に `mkdir -p`                 | `Dockerfile`             |
| GitHub API レート制限       | 認証なしで API を叩きすぎ                     | `GITHUB_TOKEN` → `MISE_GITHUB_TOKEN` | `install/common/mise.sh` |
| fisher 競合                 | fisher.fish を事前配置すると更新と競合        | curl → source でインメモリ読み込み   | `install/common/fish.sh` |
| フォークボム                | `fish -c` が config.fish を再帰読み込み       | `fish --no-config -c` を使う         | `install/common/fish.sh` |

## 参考文献

[^1]: [chsh(1) — Linux manual page](https://man7.org/linux/man-pages/man1/chsh.1.html)
[^2]: [GitHub REST API — Rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)
