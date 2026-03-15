---
title: "クロスプラットフォーム対応"
---

# クロスプラットフォーム対応

## 対象環境

この dotfiles は以下の3つの環境を想定しています。

| 環境 | OS | system | 用途 |
|------|-----|--------|------|
| macOS | darwin | client | 開発用デスクトップ |
| Ubuntu Desktop | linux | client | 開発用デスクトップ |
| Ubuntu Server | linux | server | リモートサーバー |

## 3層の分岐モデル

環境ごとの差異は3つのレベルで管理しています。

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

分岐の方法は対象によって異なります。

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

### エイリアス — ファイルで分離

```
home/dot_config/alias/
└── common.sh               # 全環境共通のエイリアス
```

デスクトップのみで使うエイリアスは `client.sh`、サーバー専用は `server.sh` のように分離できます。

### テンプレート — `{{ if }}` で条件分岐

1ファイル内で少しだけ分岐する場合は、テンプレートの条件分岐を使います。

```go
# .chezmoiscripts/ubuntu/run_once_20-install-fd.sh.tmpl
{{ if eq .chezmoi.os "linux" -}}
{{   if eq .chezmoi.osRelease.idLike "debian" -}}
{{     include "../install/ubuntu/common/fd.sh" }}
{{   end -}}
{{ end -}}
```

## shunk031 パターン — sheldon plugins の OS 別分割

[shunk031/dotfiles](https://github.com/shunk031/dotfiles) では、sheldon の plugins.toml を `.chezmoitemplates/` で OS 別に分割しています。

```
.chezmoitemplates/
├── sheldon-common.toml      # 全 OS 共通プラグイン
├── sheldon-darwin.toml      # macOS 固有プラグイン
└── sheldon-linux.toml       # Linux 固有プラグイン
```

```go
# dot_config/sheldon/plugins.toml.tmpl
{{ template "sheldon-common.toml" . }}
{{ if eq .chezmoi.os "darwin" }}
{{ template "sheldon-darwin.toml" . }}
{{ else if eq .chezmoi.os "linux" }}
{{ template "sheldon-linux.toml" . }}
{{ end }}
```

このリポジトリでは plugins.toml を分割していませんが、プラグイン数が増えた場合に検討する価値があるパターンです。

## クロスプラットフォーム対応のコツ

### 1. 条件分岐は最小限に

可能な限り OS に依存しない設定を書き、必要な箇所だけ分岐します。

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

### 2. mise で共通化

言語ランタイムや CLI ツールは mise で管理すれば、OS に関係なく同じバージョンを使えます。

### 3. Ubuntu の罠に注意

Ubuntu 固有の問題:
- `fd` が `fdfind` という名前でインストールされる → シンボリックリンクで対応
- `bat` が `batcat` という名前の場合がある → 同様にシンボリックリンク
- `apt` と `apt-get` の違い → スクリプトでは `apt-get` を使う（自動化向き）
