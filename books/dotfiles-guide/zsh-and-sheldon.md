---
title: "zsh と sheldon プラグイン管理"
---

# zsh と sheldon プラグイン管理

## zsh とは

zsh (Z Shell) は bash の上位互換シェルです。macOS では Catalina (10.15) 以降のデフォルトシェルになっています。

bash との主な違い:

| 機能 | bash | zsh |
|------|------|-----|
| 補完システム | 基本的 | 高度（compinit） |
| グロブ | 標準 | 拡張（`**/*.md` 等） |
| プロンプト | PS1 | PROMPT + テーマ |
| プラグイン | 少ない | 豊富なエコシステム |
| 配列 | 0始まり | 1始まり |

## sheldon とは

sheldon は **Rust 製の zsh プラグインマネージャー**です。

### 他のプラグインマネージャーとの比較

| ツール | 言語 | 速度 | 設定形式 |
|--------|------|------|---------|
| oh-my-zsh | Shell | 遅い | .zshrc に直接記述 |
| zinit | Shell | 速い | .zshrc に直接記述 |
| antigen | Shell | 遅い | .zshrc に直接記述 |
| **sheldon** | **Rust** | **速い** | **TOML ファイル** |

sheldon を選ぶ理由:
- **高速**: Rust 製で起動が速い
- **設定と実行の分離**: `plugins.toml` に設定を集約し、`.zshrc` はクリーンに保てる
- **遅延読み込み対応**: `zsh-defer` と組み合わせて高速起動を実現

### .zshrc の構成

```bash
# starship プロンプトの初期化
eval "$(starship init zsh)"

# sheldon でプラグインを読み込み
eval "$(sheldon source)"

# mise でランタイムを管理
eval "$(/home/zenimoto/.local/bin/mise activate zsh)"
```

たった3行の `eval` で、プロンプト・プラグイン・ランタイムがすべて初期化されます。設定の詳細は各ツールの設定ファイルに分離されています。

## plugins.toml の構造

sheldon の設定ファイルは `~/.config/sheldon/plugins.toml` です。

### カスタムテンプレート

```toml
[templates]
defer = "{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}"
```

この `defer` テンプレートが sheldon + zsh-defer の核心です。通常の `source` の代わりに `zsh-defer source` を使うことで、プラグインの読み込みをプロンプト表示**後**に遅延させます。

### プラグインの定義

```toml
[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
apply = ["defer"]
```

`apply = ["defer"]` を指定すると、上で定義した `defer` テンプレートが適用されます。

## zsh-defer による遅延読み込み

### なぜ遅延読み込みが必要か

zsh の起動時間の大部分は**プラグインの読み込み**です。すべてのプラグインを同期的に読み込むと、シェル起動に数百ミリ秒〜数秒かかります。

zsh-defer を使うと:

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

→ キーで候補を確定できます。

### zsh-completions

Docker, curl, systemd など多数のコマンドの**Tab 補完**を追加します。

### zsh-syntax-highlighting

コマンドラインの入力を**リアルタイムでシンタックスハイライト**します。

- 有効なコマンド → 緑色
- 無効なコマンド → 赤色
- ファイルパス → 下線

入力ミスにすぐ気づけるので非常に便利です。

### zsh-autopair

括弧やクォートを入力すると、**対応する閉じ記号を自動挿入**します。

```
( → ()    " → ""    [ → []    { → {}
```

### zsh-history-on-success

**成功したコマンドだけ**を履歴に保存します。タイプミスや失敗したコマンドで履歴が汚れるのを防ぎます。

### zsh-you-should-use

エイリアスが定義されているコマンドを直接入力すると、**エイリアスの使用を提案**します。

```
$ git status
Found existing alias for "git status". You should use: "gs"
```

定義したエイリアスを忘れずに使えるようになります。

### Oh My Zsh の部分読み込み

Oh My Zsh はフレームワーク全体ではなく、**必要な部分だけ**を sheldon 経由で読み込んでいます。

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

`use` フィールドで必要なファイルだけを指定しています。これにより Oh My Zsh の便利な機能は使いつつ、不要な読み込みを避けています。

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

- `dev` — 開発用ユーティリティ
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
[plugins.common-alias]
local = "~/.config/alias"
use = ["common.sh"]
apply = ["defer"]

[plugins.private-dotfiles]
inline = '[[ -f ~/.workrc ]] && source ~/.workrc'
apply = ["defer"]
```

- `common-alias`: `~/.config/alias/common.sh` からエイリアスを読み込み
- `private-dotfiles`: `~/.workrc` が存在すれば読み込み（Git 管理外の個人設定用）
