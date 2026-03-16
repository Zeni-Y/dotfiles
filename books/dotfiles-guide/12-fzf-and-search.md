---
title: "fzf でインタラクティブ検索"
---

# fzf でインタラクティブ検索

## fzf とは

[fzf](https://github.com/junegunn/fzf) は汎用の**ファジーファインダー**です。「ファジー」の意味は、完全一致ではなく**部分一致や曖昧一致**で検索できることです。`readme` と入力するだけで `README.md` がヒットします。

### 設計思想: Unix パイプラインの延長

fzf の設計は非常にシンプルです。**標準入力から一覧を受け取り、ユーザーが選んだ結果を標準出力に返す**。それだけです。

```
何らかのコマンド  →  fzf（絞り込み・選択）  →  次のコマンド
```

この「入力 → フィルタ → 出力」のパイプライン設計のおかげで、**あらゆるコマンドと組み合わせて使える**のが fzf の強みです。

```bash
# 基本的な使い方：コマンドの出力を fzf に渡す
ls | fzf

# 選択した結果をコマンドに渡す
vim $(fzf)
```

fzf 単体では「絞り込み UI」でしかありません。しかし、**入力をどこから取るか**（fd, ghq, git branch...）と**出力をどこに渡すか**（vim, cd, git checkout...）の組み合わせ次第で、ファイル検索、リポジトリ移動、ブランチ切り替えなど、あらゆる操作がインタラクティブ検索になります。この章ではその組み合わせパターンを紹介していきます。

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

fzf がファイル一覧を取得する際のデフォルトコマンドです。`find` の代わりに [fd](https://github.com/sharkdp/fd) を使うことで:
- `.gitignore` に含まれるファイルを自動除外
- 隠しファイルも検索対象に含める（`--hidden`）
- シンボリックリンクをたどる（`--follow`）
- `.git` ディレクトリは除外（`--exclude .git`）

### FZF_CTRL_T_COMMAND

```bash
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
```

`Ctrl+T` キーバインドで使用するコマンドです。`FZF_DEFAULT_COMMAND` と同じ設定を共有しています。

### FZF_CTRL_T_OPTS

```bash
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(hidden|)'"
```

| オプション | 効果 |
|-----------|------|
| `--preview 'bat -n ...'` | 選択中のファイルを [bat](https://github.com/sharkdp/bat) でプレビュー表示 |
| `--bind 'ctrl-/:...'` | `Ctrl+/` でプレビューの表示/非表示を切り替え |

### FZF_ALT_C_COMMAND

```bash
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
```

`Alt+C` でディレクトリを検索して移動するためのコマンドです。`--type d` でディレクトリのみを対象にしています。

## キーバインド

fzf は [Oh My Zsh](https://ohmyz.sh/) の fzf プラグイン経由で以下のキーバインドを提供します。

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

個人的に一番使う fzf のキーバインドです。長いコマンドを覚えていなくても、断片的なキーワードで見つけられます。

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

`builtin cd` で zsh 組み込みの `cd` を呼び出し、成功したら `ls`（= eza abbreviation）を実行します。ディレクトリを移動するたびに内容が表示されるので、「今どこにいるか」がすぐ分かります。

## カスタム fzf スクリプト

このリポジトリでは fzf を活用した**カスタムコマンド**を `~/.local/bin/common/` に配置しています。sheldon の `autoload` で必要な時だけ読み込まれます。

### dev — ghq + fzf でリポジトリ移動

[ghq](https://github.com/x-motemen/ghq) で管理しているリポジトリを fzf で検索・選択して移動します。tmux 内で実行した場合、セッション名をリポジトリ名に自動リネームします。

```bash
$ dev
# → fzf が起動、リポジトリ一覧から選択
# → 選択したリポジトリに cd
# → tmux セッション名が "my-project" にリネーム
```

内部の実装:

```bash
function dev() {
    local moveto
    moveto=$(ghq list --full-path | fzf) || return 0
    cd -- "$moveto" || exit 1

    # tmux 内であればセッション名をリポジトリ名にリネーム
    if [[ -n ${TMUX} ]]; then
        local repo_name
        repo_name="${moveto##*/}"
        tmux rename-session "${repo_name//./-}"
    fi
}
```

### fgc — fzf で git ブランチチェックアウト

ローカルブランチを fzf で一覧表示し、選択したブランチにチェックアウトします。

```bash
$ fgc
# → ローカルブランチ一覧が fzf で表示
# → 選択したブランチに git checkout
```

```bash
function fgc() {
    git checkout "$(git for-each-ref refs/heads/ --format='%(refname:short)' | fzf)"
}
```

ブランチが多いリポジトリで、名前を正確に覚えていなくても素早く切り替えられます。

### cdgwq — gwq worktree を fzf で選択して移動

[gwq](https://github.com/d-kuro/gwq) で管理している worktree を fzf で選択して移動します。

```bash
$ cdgwq
# → gwq worktree 一覧が fzf で表示
# → 選択した worktree に cd
```

```bash
function cdgwq() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "Not inside a git repository."
        return 1
    fi
    moveto=$(gwq list --json | jq -r '.[].path' | fzf)
    cd $moveto
}
```

:::message
`dev` は ghq 管理下の全リポジトリから選択、`cdgwq` は現在のリポジトリの worktree から選択、という使い分けです。
:::

## まとめ

fzf 単体でも便利ですが、fd や bat と組み合わせることで真価を発揮します。

| 組み合わせ | 効果 |
|-----------|------|
| fd + fzf | 高速なファイル検索 + インタラクティブ選択 |
| bat + fzf | プレビュー付きファイル選択 |
| ghq + fzf | リポジトリ間の高速移動 |
| history + fzf | コマンド履歴のファジー検索 |

fzf のキーバインドは最初は覚えるのが大変ですが、上の表をチートシートとして手元に置いておけばすぐ慣れます。`Ctrl+R`（履歴検索）と `Ctrl+T`（ファイル検索）だけでも覚えておけば、日常的に使うことになると思います。
