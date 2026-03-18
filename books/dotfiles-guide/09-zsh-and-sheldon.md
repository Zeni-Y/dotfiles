---
title: "zsh と sheldon プラグイン管理"
---

# zsh と sheldon プラグイン管理

## この章で扱うこと

シェル環境を快適にするには、プラグイン（補完、ハイライト、履歴管理など）の導入が欠かせません。しかし、プラグインを何も考えずに入れていくと **シェルの起動が遅くなる** という問題が生まれます。

この章では、以下の2つの課題を解決する構成を解説します:

| 課題 | 解決するツール | アプローチ |
|------|--------------|-----------|
| プラグインの管理が煩雑 | **sheldon** | 設定ファイル（TOML）にプラグインを宣言的に定義。`.zshrc` から分離 |
| プラグインを増やすと起動が遅くなる | **zsh-defer** | プロンプト表示後にプラグインを遅延読み込み |

この2つの組み合わせにより、**プラグインを増やしても起動時間を 100ms 以下に保つ**ことが目標です。

## zsh とは

[zsh (Z Shell)](https://www.zsh.org/) は bash の上位互換シェルです。macOS では Catalina (10.15) 以降のデフォルトシェルになっています。

bash との主な違い:

| 機能 | bash | zsh |
|------|------|-----|
| 補完システム | 基本的 | 高度（compinit） |
| グロブ | 標準 | 拡張（`**/*.md` 等） |
| プロンプト | PS1 | PROMPT + テーマ |
| プラグイン | 少ない | 豊富なエコシステム |
| 配列 | 0始まり | 1始まり |

## sheldon とは

[sheldon](https://sheldon.cli.rs/) は **Rust 製の zsh プラグインマネージャー**です。sheldon の特徴は **「設定と実行の分離」** という設計です。プラグインの設定は `plugins.toml` に集約し、`.zshrc` は `eval "$(sheldon source)"` の一行だけ。`.zshrc` がプラグイン設定で肥大化しないのが sheldon の良さです。

### 他のプラグインマネージャーとの比較

| ツール | 言語 | 速度 | 設定形式 |
|--------|------|------|---------|
| [oh-my-zsh](https://ohmyz.sh/) | Shell | 遅い | .zshrc に直接記述 |
| [zinit](https://github.com/zdharma-continuum/zinit) | Shell | 速い | .zshrc に直接記述 |
| [antigen](https://github.com/zsh-users/antigen) | Shell | 遅い | .zshrc に直接記述 |
| **[sheldon](https://sheldon.cli.rs/)** | **Rust** | **速い** | **TOML ファイル** |

sheldon を選ぶ理由:
- **高速**: Rust 製で起動が速い
- **設定と実行の分離**: `plugins.toml` に設定を集約し、`.zshrc` はクリーンに保てる
- **遅延読み込み対応**: `zsh-defer` と組み合わせて高速起動を実現

### .zshrc の構成

```bash
# PATH の設定
typeset -gU path fpath
path=(
    $path
    /usr/local/{,s}bin(N-/)
    /usr/local/cuda/bin(N-/)
    ${HOME}/.local/bin(N-/)
    ${HOME}/.local/bin/common(N-/)
)
fpath=(
    $fpath
    ${HOME}/.local/bin/common(N-/)
)

# sheldon でプラグインを読み込み
eval "$(sheldon source)"
```

`.zshrc` の役割は **PATH の設定** と **sheldon の起動** だけです。starship（プロンプト）や mise（ランタイム管理）の初期化は sheldon の `plugins.toml` 側で管理しています。`.zshrc` がプラグイン設定で肥大化しないのが sheldon の設計の良さです。

zsh 起動時の処理の流れを整理するとこうなっています。

```
zsh 起動
  │
  ├─ 1. PATH / FPATH の設定（共通パスの登録）
  │
  └─ 2. sheldon source → plugins.toml を読み込み
        ├─ starship init zsh → プロンプトの初期化（即座に表示される）
        ├─ fzf キーバインド等（即座に有効化）
        ├─ zsh-defer 付きプラグイン（プロンプト表示後に遅延読み込み）
        │   → autosuggestions, syntax-highlighting, compinit 等
        └─ mise activate zsh → chpwd フックを登録
            → ディレクトリ移動時に PATH を動的に切り替え
```

## plugins.toml のテンプレート分割

sheldon の設定ファイルは `~/.config/sheldon/plugins.toml` です。このリポジトリでは、chezmoi のテンプレート機能を使って **common / client / server に分割管理**しています。

### 分割構成

```
dot_config/sheldon/
├── plugins.toml.tmpl          # エントリポイント（テンプレート）
└── plugin_sources/
    ├── common.toml             # 全環境共通プラグイン
    ├── client.toml             # デスクトップ / WSL 向け
    └── server.toml             # リモートサーバー向け
```

`plugins.toml.tmpl` が `{{ include }}` で各ファイルを結合します。`chezmoi apply` 時にテンプレートが処理され、最終的な `plugins.toml` が生成されます。

```go
{{ include "dot_config/sheldon/plugin_sources/common.toml" }}
{{- if eq .system "client" }}
{{ include "dot_config/sheldon/plugin_sources/client.toml" }}
{{- else if eq .system "server" }}
{{ include "dot_config/sheldon/plugin_sources/server.toml" }}
{{- else }}
{{   fail (printf "Unknown system type: %s" .system) }}
{{- end -}}
```

:::message
`plugin_sources/` ディレクトリは chezmoi のビルド時にのみ使用されるため、`.chezmoiignore` で除外しています。ホームディレクトリには最終的な `plugins.toml` だけが配置されます。
:::

### 分割の効果

| ファイル | 内容 |
|---------|------|
| `common.toml` | starship, zsh-defer, fzf, 補完, 言語環境, zsh-abbr 等 |
| `client.toml` | chezmoi-notify, client 用 PATH |
| `server.toml` | chezmoi-notify, server 用 PATH |

全環境で共通するプラグイン（starship, zsh-defer 等）は `common.toml` に集約し、環境固有の設定だけを `client.toml` / `server.toml` に分離しています。

### カスタムテンプレート

```toml
[templates]
defer = """
{{ hooks?.pre | nl }}
{% for file in files %}
zsh-defer source "{{ file }}"
{% endfor %}
{{ hooks?.post | nl }}
"""
```

この `defer` テンプレートが sheldon + zsh-defer の核心です。通常の `source` の代わりに `zsh-defer source` を使うことで、プラグインの読み込みをプロンプト表示**後**に遅延させます。`hooks` を使えば、プラグイン読み込みの前後にカスタム処理を追加できます。

### プラグインの定義

```toml
[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
apply = ["defer"]
```

`apply = ["defer"]` を指定すると、上で定義した `defer` テンプレートが適用されます。

## zsh-defer による遅延読み込み

### なぜ遅延読み込みが必要か

zsh の起動時間の大部分は**プラグインの読み込み**です。すべてのプラグインを同期的に読み込むと、シェル起動に数百ミリ秒〜数秒かかります。ターミナルを開くたびに待たされるのはストレスですよね。

[zsh-defer](https://github.com/romkatv/zsh-defer) を使うと:

```
通常:  [プラグインA読込] → [プラグインB読込] → [プロンプト表示]  (遅い)
defer: [プロンプト表示] → [プラグインA読込] → [プラグインB読込]  (速い)
```

プロンプトが先に表示されるため、体感的な起動時間が大幅に短縮されます。

### 遅延できないもの

一部の初期化は遅延させると問題が起きます:

- **starship**: プロンプト自体なので遅延不可
- **sheldon**: プラグインローダー自体なので遅延不可
- **fzf**: キーバインドの登録はプロンプト表示前に必要

## プラグイン解説

### zsh-autosuggestions

入力中にコマンド履歴から**補完候補をグレー表示**します。

```
$ git com_  ← ここまで入力すると
$ git commit -m "feat: "  ← 過去のコマンドが薄く表示される
```

→ キーで候補を確定できます。体感の認知度が低いですが、めちゃめちゃ便利です。

### zsh-completions

Docker, curl, systemd など多数のコマンドの**Tab 補完**を追加します。

### zsh-syntax-highlighting

コマンドラインの入力を**リアルタイムでシンタックスハイライト**します。

- 有効なコマンド → 緑色
- 無効なコマンド → 赤色
- ファイルパス → 下線

入力ミスにすぐ気づけるので非常に便利です。タイプミスした瞬間に赤くなるので、Enter を押す前に「あ、間違えた」と分かります。

### zsh-autopair

括弧やクォートを入力すると、**対応する閉じ記号を自動挿入**します。

```
( → ()    " → ""    [ → []    { → {}
```

### zsh-history-on-success

**成功したコマンドだけ**を履歴に保存します。タイプミスや失敗したコマンドで履歴が汚れるのを防ぎます。地味ですが、`Ctrl+R` で履歴検索するときに快適さが段違いです。

### zsh-you-should-use

エイリアスが定義されているコマンドを直接入力すると、**エイリアスの使用を提案**します。

```
$ git status
Found existing alias for "git status". You should use: "gs"
```

定義したエイリアスを忘れずに使えるようになります。せっかく設定したのに使い忘れるのはもったいないですからね。

### Oh My Zsh の部分読み込み

[Oh My Zsh](https://ohmyz.sh/) はフレームワーク全体ではなく、**必要な部分だけ**を sheldon 経由で読み込んでいます。

```toml
[plugins.oh-my-zsh]
github = "ohmyzsh/ohmyzsh"
apply = ["defer"]
use = [
    "lib/functions.zsh",
    "lib/completion.zsh",
    "lib/history.zsh",
    "lib/termsupport.zsh",
    "plugins/fzf/*.zsh",
]
```

`use` フィールドで必要なファイルだけを指定しています。Oh My Zsh の便利な機能は使いつつ、不要な読み込みを避ける必要十分なアプローチです。

### compinit の遅延初期化

zsh の補完システム `compinit` は起動時間のボトルネックになりがちです。sheldon の inline プラグインで遅延初期化しています。

```toml
[plugins.compinit]
inline = "autoload -Uz compinit && compinit"
apply = ["defer"]
```

### カスタムコマンド

```toml
[plugins.custom-commands]
local = "~/.local/bin/common"
apply = ["fpath"]
```

`~/.local/bin/common` にカスタム関数を配置し、`autoload` で必要な時だけ読み込みます。このリポジトリでは以下のカスタムコマンドが定義されています:

- `dev` — 開発用ユーティリティ（ghq + fzf でリポジトリ移動）
- `cdgwq` — gwq で管理されたリポジトリへの移動
- `cdw` — ワークスペースへの移動
- `uv-format` — Python コードのフォーマット

### 言語環境の設定

Go, Rust, Bun の環境変数も sheldon の inline プラグインとして管理しています。

```toml
[plugins.go]
inline = 'export GOPATH="$HOME/ghq" && path=("$GOPATH/bin" "$GOROOT/bin" $path)'
apply = ["defer"]

[plugins.rust]
inline = 'path=("$HOME/.cargo/bin" $path)'
apply = ["defer"]
```

すべて `defer` 付きで、プロンプト表示後に遅延設定されます。

### エイリアスと非追跡設定

```toml
[plugins.private-dotfiles]
inline = '''
function _private_dotfiles() {
    local filepath="${HOME}/.workrc"
    if [ -f "$filepath" ]; then
        source "$filepath"
    fi
}
zsh-defer _private_dotfiles
'''
```

`~/.workrc` が存在すれば読み込みます（Git 管理外の個人設定用）。詳しくはセキュリティと暗号化のチャプターで解説します。

## zsh-abbr — エイリアスの進化形

### abbreviation とは

[zsh-abbr](https://github.com/olets/zsh-abbr) は **fish shell 風の abbreviation（省略形）** を zsh に提供するプラグインです。

エイリアスとの最大の違いは、**入力時にフルコマンドに展開される**点です。

```
# エイリアスの場合
$ gs[Enter]  → git status が実行されるが、履歴には "gs" が残る

# abbreviation の場合
$ gs[Space]  → "git status" に展開される
$ git status[Enter]  → 履歴にも "git status" が残る
```

### abbreviation のメリット

| 比較項目 | エイリアス | abbreviation |
|---------|-----------|--------------|
| 履歴の可読性 | 省略形で残る | フルコマンドで残る |
| 他の環境での再現 | エイリアス定義が必要 | 履歴をコピペすればそのまま動く |
| コマンドの確認 | 実行するまで分からない | 展開されるので確認できる |

個人的に一番嬉しいのは、履歴にフルコマンドが残ることです。後から `history` を見返したときに何をやったかすぐ分かります。

### 設定ファイル

abbreviation は `~/.config/zsh-abbr/user-abbreviations` に定義します。

```bash
abbr "cz"="chezmoi"
abbr "gm"="git checkout $(git symbolic-ref refs/remotes/origin/HEAD | sed \"s@^refs/remotes/origin/@@\")"
abbr "ls"="eza --long --group --header --binary --time-style=long-iso --icons"
abbr "ll"="eza -la --long --group --header --binary --time-style=long-iso --icons"
```

sheldon での読み込み設定:

```toml
[plugins.zsh-abbr]
github = "olets/zsh-abbr"
apply = ['defer']
```

:::message
`gm` は `git symbolic-ref` でリモートのデフォルトブランチ（main や master）を自動判定し、チェックアウトします。リポジトリごとにデフォルトブランチが異なる場合でも対応できます。
:::

## chezmoi-notify — dotfiles 更新通知

### 概要

`chezmoi-notify` は、dotfiles リポジトリのリモートに未適用の更新がないかを**バックグラウンドで定期チェック**し、[starship](https://starship.rs/) プロンプトに通知を表示するカスタムプラグインです。

### 仕組み

```
[precmd フック] → 1時間経過? → [バックグラウンドで git fetch]
                                → 差分あり → キャッシュに件数を書き込み
                                → 差分なし → キャッシュを削除

[starship] → キャッシュを読み取り → プロンプト右側に表示
```

### プラグインのコード

```zsh
# ~/.config/zsh/plugins/chezmoi-notify/chezmoi-notify.plugin.zsh
function _check_chezmoi_update_async() {
    local check_interval=3600 # 1時間ごとにチェック
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/starship-chezmoi"
    local status_file="$cache_dir/count"
    local last_check_file="$cache_dir/last_check"

    [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

    local current_time=$(date +%s)
    local last_check=0
    [[ -f "$last_check_file" ]] && last_check=$(cat "$last_check_file")

    if ((current_time - last_check > check_interval)); then
        echo "$current_time" >| "$last_check_file"
        # バックグラウンドで実行（&| で切り離し）
        (
            if command -v chezmoi > /dev/null 2>&1; then
                chezmoi git -- fetch -q
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

autoload -Uz add-zsh-hook
add-zsh-hook precmd _check_chezmoi_update_async
```

### starship との連携

chezmoi-notify はキャッシュファイルに未適用の件数を書き込み、starship のカスタムコマンドモジュールがそれを読み取ってプロンプトに表示します。未適用の更新がある場合、プロンプトの右側に `dotfiles ⇣3` のように表示されます。

starship の設定詳細については [starship — クロスシェル対応のモダンプロンプト](10-starship) を参照してください。

### sheldon での読み込み

client.toml と server.toml の両方に定義しています。

```toml
[plugins.chezmoi-notify]
local = "~/.config/zsh/plugins/chezmoi-notify"
```

## ライフサイクル

### 初期セットアップ（初回のみ）

sheldon は `chezmoi apply` 時に自動インストールされます。`plugins.toml` も chezmoi が配置するので、手動でのセットアップは不要です。

```bash
chezmoi apply
# → sheldon がインストールされ、plugins.toml が配置される
# → 次回 zsh 起動時にプラグインが自動ダウンロードされる
```

### 日常の操作

| やりたいこと | コマンド |
|------------|---------|
| プラグインの状態を確認する | `sheldon lock --update` |
| プラグインをすべて再インストールする | `sheldon lock --update && sheldon source` |
| abbreviation を追加する | `abbr "gs"="git status"` （その後 `chezmoi add` で反映） |
| zsh の起動時間を確認する | `time zsh -i -c exit` |

### プラグインを追加・変更したいとき

```bash
# 1. plugin_sources/ の該当ファイルを編集
#    全環境共通なら common.toml、client のみなら client.toml
chezmoi cd
vim home/dot_config/sheldon/plugin_sources/common.toml

# 2. テンプレート展開後の結果を確認
chezmoi cat ~/.config/sheldon/plugins.toml

# 3. 適用して新しいシェルで動作確認
chezmoi apply
zsh
```
