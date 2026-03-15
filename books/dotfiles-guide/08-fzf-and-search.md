---
title: "fzf でインタラクティブ検索"
---

# fzf でインタラクティブ検索

## fzf とは

[fzf](https://github.com/junegunn/fzf) は汎用の**ファジーファインダー**です。標準入力から受け取った一覧を、インタラクティブに絞り込んで選択できます。

```bash
# 基本的な使い方：コマンドの出力を fzf に渡す
ls | fzf

# 選択した結果をコマンドに渡す
vim $(fzf)
```

「ファジー」の意味は、完全一致ではなく**部分一致や曖昧一致**で検索できることです。`readme` と入力するだけで `README.md` がヒットします。

## 環境変数による設定

このリポジトリの `.zshrc` では以下の環境変数を設定しています。

### FZF_DEFAULT_OPTS

```bash
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
```

| オプション | 効果 |
|-----------|------|
| `--height 40%` | ターミナルの下部 40% を使って表示 |
| `--layout=reverse` | 結果を上から下に表示（デフォルトは下から上） |
| `--border` | 枠線を表示 |

### FZF_DEFAULT_COMMAND

```bash
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
```

fzf がファイル一覧を取得する際のデフォルトコマンドです。`find` の代わりに `fd` を使うことで:
- `.gitignore` に含まれるファイルを自動除外
- 隠しファイルも検索対象に含める（`--hidden`）
- シンボリックリンクをたどる（`--follow`）
- `.git` ディレクトリは除外（`--exclude .git`）

### FZF_CTRL_T_COMMAND

```bash
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
```

`Ctrl+T` キーバインドで使用するコマンド。`FZF_DEFAULT_COMMAND` と同じ設定を共有しています。

### FZF_CTRL_T_OPTS

```bash
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(hidden|)'"
```

| オプション | 効果 |
|-----------|------|
| `--preview 'bat -n ...'` | 選択中のファイルを bat でプレビュー表示 |
| `--bind 'ctrl-/:...'` | `Ctrl+/` でプレビューの表示/非表示を切り替え |

### FZF_ALT_C_COMMAND

```bash
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
```

`Alt+C` でディレクトリを検索して移動するためのコマンドです。`--type d` でディレクトリのみを対象にしています。

## キーバインド

fzf は Oh My Zsh の fzf プラグイン経由で以下のキーバインドを提供します。

### Ctrl+T — ファイル検索

現在のカーソル位置にファイルパスを挿入します。

```bash
$ vim [Ctrl+T]
# → fzf が起動、ファイルを選択
$ vim src/main.go
```

bat によるプレビューが表示されるので、ファイルの中身を確認しながら選択できます。

### Ctrl+R — コマンド履歴検索

過去に実行したコマンドをファジー検索します。

```bash
$ [Ctrl+R]
# → 履歴から検索
$ docker compose up -d  # 過去のコマンドが入力される
```

### Alt+C — ディレクトリ移動

ディレクトリをファジー検索して `cd` します。

```bash
$ [Alt+C]
# → ディレクトリを選択
$ cd src/components/  # 選択したディレクトリに移動
```

## fd + fzf の組み合わせ

fd と fzf を組み合わせることで、高速かつ柔軟なファイル検索が実現します。

```bash
# 特定の拡張子のファイルを検索して開く
fd -e py | fzf | xargs vim

# 特定のディレクトリ以下を検索
fd . src/ | fzf
```

`FZF_DEFAULT_COMMAND` に fd を設定しているので、`Ctrl+T` でも fd の恩恵を受けられます。

## bat + fzf でプレビュー付き検索

`FZF_CTRL_T_OPTS` に `--preview 'bat -n --color=always {}'` を設定しているため、`Ctrl+T` でファイルを選択する際に**シンタックスハイライト付きのプレビュー**が表示されます。

```
┌──────────────────────────────────────────────┐
│ > src/main.go                                │
│   src/config.go                              │
│   src/handler.go                             │
├──────────────────────────────────────────────┤
│  1 │ package main                            │
│  2 │                                         │
│  3 │ import (                                │
│  4 │     "fmt"                               │
│  5 │     "net/http"                          │
│  6 │ )                                       │
└──────────────────────────────────────────────┘
```

`Ctrl+/` でプレビューの表示/非表示を切り替えられます。

## カスタム cd 関数

このリポジトリでは `cd` コマンドをカスタマイズして、ディレクトリ移動時に自動で `ls` を実行しています。

```bash
# .zshrc
cd() {
  builtin cd "$@" && ls
}
```

`builtin cd` で zsh 組み込みの `cd` を呼び出し、成功したら `ls`（= eza エイリアス）を実行します。これによりディレクトリを移動するたびに内容が表示されます。

## ghq + fzf でリポジトリ移動

sheldon の plugins.toml で定義されているカスタムコマンド `cdgwq` は、gwq/ghq で管理しているリポジトリを fzf で選択して移動する関数です。

```bash
# ghq + fzf の典型的なパターン
cd $(ghq list --full-path | fzf)
```

このパターンを関数化することで、数十〜数百のリポジトリから瞬時に目的のリポジトリに移動できます。

## まとめ

fzf 単体でも便利ですが、fd や bat と組み合わせることで真価を発揮します。

| 組み合わせ | 効果 |
|-----------|------|
| fd + fzf | 高速なファイル検索 + インタラクティブ選択 |
| bat + fzf | プレビュー付きファイル選択 |
| ghq + fzf | リポジトリ間の高速移動 |
| history + fzf | コマンド履歴のファジー検索 |
