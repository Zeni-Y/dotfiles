---
title: "モダン CLI ツール群"
---

# モダン CLI ツール群

従来の Unix コマンドを置き換える、Rust 製を中心としたモダン CLI ツールを紹介します。これらはすべて mise で管理しています。

## eza — ls の代替

[eza](https://github.com/eza-community/eza) は `ls` の代替ツールです。カラー表示、アイコン、Git ステータスの表示に対応しています。

### エイリアス設定

```bash
# ~/.config/zsh-abbr/user-abbreviations
abbr ls="eza --long --group --header --binary --time-style=long-iso --icons"
abbr ll="eza -la --long --group --header --binary --time-style=long-iso --icons"
```

### 主なオプション

| オプション | 効果 |
|-----------|------|
| `--long` | 詳細表示（パーミッション、サイズ等） |
| `--group` | グループ名を表示 |
| `--header` | ヘッダー行を表示 |
| `--binary` | ファイルサイズを二進数表記（KiB 等） |
| `--time-style=long-iso` | ISO 8601 形式の日時表示 |
| `--icons` | ファイルタイプのアイコンを表示 |
| `--git` | Git ステータスを表示 |
| `--tree` | ツリー表示 |

### ls との違い

- **カラー表示**: ファイルタイプごとに色分け
- **アイコン**: ファイル拡張子に応じたアイコン表示
- **Git 連携**: 変更・追加・無視ファイルのステータス表示
- **ヘッダー**: 各列の意味が分かるヘッダー行

## bat — cat の代替

[bat](https://github.com/sharkdp/bat) は `cat` の代替ツールです。シンタックスハイライトと行番号を表示します。

```bash
# 通常の使い方
bat README.md

# 特定の言語としてハイライト
bat --language=json data.txt

# 行番号なしで表示（cat と同じ出力）
bat --plain file.txt
```

### 主な特徴

- **シンタックスハイライト**: 200以上の言語に対応
- **行番号**: 自動表示
- **Git 連携**: 変更行をマーキング
- **ページャー**: 長いファイルは自動的にページャーで表示
- **fzf との連携**: プレビュー表示に最適

## fd — find の代替

[fd](https://github.com/sharkdp/fd) は `find` の代替ツールです。シンプルな構文で高速にファイルを検索します。

```bash
# ファイル名で検索
fd readme

# 拡張子で絞り込み
fd -e md

# 隠しファイルも含めて検索
fd --hidden pattern

# 特定のディレクトリ以下を検索
fd pattern src/
```

### find との比較

```bash
# find: 構文が複雑
find . -name "*.md" -not -path "./.git/*"

# fd: シンプル
fd -e md
```

fd の利点:
- **直感的な構文**: `fd pattern` だけで検索開始
- **高速**: 並列処理で高速検索
- **スマートなデフォルト**: `.gitignore` を自動的に尊重、隠しファイルはデフォルトで除外
- **カラー出力**: 検索結果を見やすく表示

### Ubuntu での注意点

Ubuntu では `fd` ではなく `fdfind` という名前でインストールされます。このリポジトリではインストールスクリプトでシンボリックリンクを作成しています。

```bash
# install/ubuntu/common/fd.sh
ln -s "$(which fdfind)" "${HOME}/.local/bin/fd"
```

## ripgrep — grep の代替

[ripgrep (rg)](https://github.com/BurntSushi/ripgrep) は `grep` の代替ツールです。再帰検索がデフォルトで、非常に高速です。

```bash
# カレントディレクトリ以下を再帰検索
rg "TODO"

# 特定のファイルタイプに限定
rg "import" --type py

# 大文字小文字を無視
rg -i "error"

# ファイル名のみ表示
rg -l "pattern"
```

### grep との比較

- **速度**: 大規模リポジトリでも高速
- **デフォルト再帰**: `-r` 不要
- **`.gitignore` 対応**: 無視ファイルを自動スキップ
- **Unicode 対応**: デフォルトで UTF-8 をサポート

## starship — プロンプトカスタマイズ

[starship](https://starship.rs/) は Rust 製のクロスシェルプロンプトです。bash, zsh, fish 等で共通の設定が使えます。

```bash
# .zshrc での初期化
eval "$(starship init zsh)"
```

### 主な特徴

- **高速**: Rust 製で応答が速い
- **情報表示**: Git ブランチ、言語バージョン、実行時間等を自動表示
- **クロスシェル**: 1つの設定ファイルで bash/zsh/fish に対応
- **カスタマイズ**: `~/.config/starship.toml` で表示内容を設定

### 表示される情報の例

```
~/projects/myapp on  main [!?] via  v20.10.0 via 🐍 v3.12
❯
```

- ディレクトリパス
- Git ブランチ名とステータス
- Node.js / Python 等のバージョン（プロジェクトに応じて自動検出）

## yazi — ターミナルファイルマネージャ

[yazi](https://github.com/sxyazi/yazi) は Rust 製のターミナルファイルマネージャです。

### 主な特徴

- **高速**: 非同期 I/O で大量のファイルも快適に操作
- **プレビュー**: テキスト、画像、PDF 等のプレビュー表示
- **Vim キーバインド**: hjkl での移動
- **プラグインシステム**: Lua でカスタマイズ可能

## ghq / gwq — リポジトリ管理

### ghq

[ghq](https://github.com/x-motemen/ghq) は Git リポジトリを一定のルールで管理するツールです。

```bash
# リポジトリをクローン（~/ghq/github.com/user/repo に配置）
ghq get https://github.com/user/repo

# 管理下のリポジトリ一覧
ghq list

# fzf と組み合わせてリポジトリに移動
cd $(ghq list --full-path | fzf)
```

ghq は `GOPATH` と同じ `~/ghq` ディレクトリにリポジトリを整理します。

```
~/ghq/
├── github.com/
│   ├── user/repo-a/
│   └── user/repo-b/
└── gitlab.com/
    └── user/repo-c/
```

### gwq

[gwq](https://github.com/d-kuro/gwq) は **git worktree を ghq スタイルで管理**するツールです。ghq と同じディレクトリ構造で worktree を作成・管理できます。

#### git worktree とは

通常の git では1つのリポジトリに1つの作業ディレクトリですが、worktree を使うと**同じリポジトリの異なるブランチを複数のディレクトリで同時に開ける**ようになります。

```bash
# 通常: ブランチ切り替えが必要
git checkout feature-a  # 作業中断
git checkout feature-b  # 別の作業

# worktree: 並行作業が可能
~/ghq/.../repo=feature-a/   # feature-a で作業中
~/ghq/.../repo=feature-b/   # 同時に feature-b で作業
```

#### gwq の設定

```toml
# ~/.config/gwq/config.toml
[worktree]
auto_mkdir = true
basedir = '~/ghq'

[naming]
template = '{{.Host}}/{{.Owner}}/{{.Repository}}={{.Branch}}'

[naming.sanitize_chars]
'/' = '-'
':' = '-'

[finder]
preview = true

[ui]
icons = true
tilde_home = true
```

`naming.template` で worktree のディレクトリ命名規則を定義しています。`=` でリポジトリ名とブランチ名を区切る形式です。

#### gwq + Claude Code の連携

gwq は Claude Code（AI コーディングアシスタント）と組み合わせて、**複数のタスクを並列実行**できます。

```toml
[claude]
config_dir = '~/.config/gwq/claude'
executable = 'claude'
max_development_tasks = 2
max_parallel = 3

[claude.worktree]
auto_create_worktree = true
```

#### 基本的な使い方

```bash
# worktree の一覧
gwq list

# worktree の作成
gwq create feature-branch

# fzf で worktree を選択して移動（cdgwq コマンド）
cdgwq

# 最新の worktree に移動（cdw コマンド）
cdw
```

## なぜモダンツールを使うのか

これらのツールに共通する特徴:

1. **Rust 製で高速**: 従来の C 製ツールよりも高速な場合が多い
2. **スマートなデフォルト**: `.gitignore` の尊重、カラー出力等
3. **人間に優しい出力**: アイコン、色、フォーマットが見やすい
4. **mise で一括管理**: バージョン管理も容易

既存のコマンドと共存できるので、エイリアスで置き換えて段階的に移行できます。
