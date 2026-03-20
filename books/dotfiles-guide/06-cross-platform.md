---
title: "クロスプラットフォーム対応"
---

# クロスプラットフォーム対応

## この章で扱う課題

dotfiles を複数のマシンで共有していると、「同じ設定ファイルなのに、環境ごとに微妙に違う部分がある」という問題にぶつかります。たとえば:

- macOS と Linux で**パスが違う**（Homebrew のパス、フォントの配置先）
- デスクトップとサーバーで**必要なツールが違う**（サーバーに GUI ツールは不要）
- Ubuntu と他の Linux で**パッケージ名が違う**（`fd` vs `fdfind`）

「全部別々のリポジトリにする」のは管理が大変です。chezmoi では **1 つのリポジトリに全環境の設定をまとめつつ、テンプレートの条件分岐で環境ごとに出し分ける** ことでこの問題を解決しています。

ポイントは、分岐を**どの粒度で、どこに書くか**のルールを決めておくことです。場当たり的に `if` を入れていくとすぐにカオスになるので、この章ではこのリポジトリの分岐モデルとその配置ルールを解説します。

## 対象環境

この dotfiles は以下の 3 つの環境を想定しています。

| 環境           | OS     | system | 用途             |
| -------------- | ------ | ------ | ---------------- |
| macOS          | darwin | client | 開発用 PC        |
| Ubuntu Desktop | linux  | client | 開発用 PC        |
| Ubuntu Server  | linux  | server | リモートサーバー |

ここでの **client** と **server** は、自分が直接操作する手元のマシン（ノート PC・デスクトップ）か、SSH 等でリモート接続して使うマシンかという区分です。
server の方では、CUDA や HuggingFace などの実験を行うための設定ファイルやツールを追加しています。
client の方では、editor やターミナル関係の設定を追加しています。

## 3 層の分岐モデル

環境ごとの差異は 3 つのレベルで管理しています。

### 1. OS レベル — `.chezmoi.os`

最も大きな分岐です。macOS と Linux の違い（パッケージマネージャ、パス構造等）を吸収します。

```go
{{ if eq .chezmoi.os "darwin" }}
  macOS 固有の設定
{{ else if eq .chezmoi.os "linux" }}
  Linux 固有の設定
{{ end }}
```

### 2. System レベル — `.system`

同じ OS でも「デスクトップ」と「サーバー」で必要なツールが異なります。

```go
{{ if eq .system "client" }}
  GUI アプリ、ブラウザ連携等のデスクトップ向け設定
{{ else if eq .system "server" }}
  最小限のサーバー向け設定
{{ end }}
```

`.system` の値は `.chezmoi.yaml.tmpl` で決定されます:

- macOS → 自動的に `"client"`
- Linux → 初回セットアップ時に `promptString` でユーザーに確認

### 3. Distro レベル — `.chezmoi.osRelease.idLike`

Linux ディストリビューション固有の差異（パッケージ名の違い等）を吸収します。

```go
{{ if eq .chezmoi.osRelease.idLike "debian" }}
  apt-get install fd-find
{{ end }}
```

## 分岐の配置ルール

分岐の方法は対象によって異なります。この辺の使い分けは最初は分かりにくいですが、慣れると「この変更はどこに書けばいいか」がすぐ判断できるようになります。

### スクリプト — ディレクトリで分離

```
home/.chezmoiscripts/
├── common/                          # 全 OS 共通
│   └── run_once_after_01-install-mise.sh.tmpl
└── ubuntu/                          # Ubuntu 固有
    └── run_once_20-install-fd.sh.tmpl
```

OS 固有のスクリプトは `.chezmoiscripts/<os>/` に配置します。chezmoi は適切なスクリプトだけを実行します。

### インストールスクリプト — OS/system で分離

```
install/
├── common/                 # 全 OS 共通のインストール
│   └── mise.sh
└── ubuntu/
    └── common/             # Ubuntu の全 system 共通
        └── fd.sh
```

将来的には以下のような構造も可能です:

```
install/
├── common/
├── darwin/
│   ├── common/             # macOS 全体
│   └── client/             # macOS デスクトップのみ
└── ubuntu/
    ├── common/             # Ubuntu 全体
    ├── client/             # Ubuntu デスクトップのみ
    └── server/             # Ubuntu サーバーのみ
```

### エイリアス — OS 分岐なし

エイリアス（abbreviation）は OS による差異がないため、分岐せず全環境共通の 1 ファイルで管理しています。詳しくは [fish と fisher](09-fish-and-fisher) の章で解説します。

### テンプレート — `{{ if }}` で条件分岐

1 ファイル内で少しだけ分岐する場合は、テンプレートの条件分岐を使います。

```go
# .chezmoiscripts/ubuntu/run_once_20-install-fd.sh.tmpl
{{ if eq .chezmoi.os "linux" -}}
{{   if eq .chezmoi.osRelease.idLike "debian" -}}
{{     include "../install/ubuntu/common/fd.sh" }}
{{   end -}}
{{ end -}}
```

## config.fish.tmpl の条件分岐パターン

このリポジトリでは `config.fish.tmpl` 内で Go template の `{{ if }}` を使って OS や system による条件分岐を直接記述しています。

```fish
# config.fish.tmpl
{{ if eq .system "client" -}}
# client 環境のみ読み込む設定
set -x BROWSER firefox
{{- else if eq .system "server" -}}
# server 環境のみ読み込む設定
{{- end }}

{{ if eq .chezmoi.os "darwin" -}}
# macOS 固有の設定
eval "$(/opt/homebrew/bin/brew shellenv)"
{{- else if eq .chezmoi.os "linux" -}}
# Linux 固有の設定
{{- end }}
```

`config.fish.tmpl` は chezmoi がテンプレート展開して `~/.config/fish/config.fish` を生成します。OS や system の組み合わせごとに適切な内容が 1 つのファイルにまとまるため、別ファイルへの分割が不要でシンプルに管理できます。

## クロスプラットフォーム対応のコツ

### 1. 条件分岐は最小限に

可能な限り OS に依存しない設定を書き、必要な箇所だけ分岐するのが鉄則です。

```bash
# 良い例：コマンドの存在チェックで分岐
if command -v brew &> /dev/null; then
    eval "$(brew shellenv)"
fi

# 悪い例：OS 名で分岐（他のディストロで動かない）
if [ "$(uname)" = "Darwin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
```

`command -v` で存在チェックする方が汎用的で、将来の環境変更にも強いです。

### 2. mise で共通化

言語ランタイムや CLI ツールは [mise](https://mise.jdx.dev/) で管理すれば、OS に関係なく同じバージョンを使えます。OS ごとのパッケージマネージャの差異を吸収してくれるのが大きいですね。

### 3. Ubuntu の罠に注意

Ubuntu 固有の問題は最初ハマりがちです:

- `fd` が `fdfind` という名前でインストールされる → シンボリックリンクで対応
- `bat` が `batcat` という名前の場合がある → 同様にシンボリックリンク
- `apt` と `apt-get` の違い → スクリプトでは `apt-get` を使う（自動化向き）
