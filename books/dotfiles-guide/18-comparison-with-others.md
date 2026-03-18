---
title: "他の chezmoi リポジトリとの比較"
---

# 他の chezmoi リポジトリとの比較

chezmoi を使った dotfiles 管理には「唯一の正解」はなく、リポジトリの規模や対象環境、チームか個人かによってアプローチが変わります。

このチャプターでは、chezmoi 作者である twpayne の dotfiles[^1] と、テスト可能な dotfiles 管理を実践している shunk031 の dotfiles[^2][^3] を比較しながら、当リポジトリの設計判断を振り返ります。

## 3つのリポジトリの概要

| | twpayne/dotfiles[^1] | shunk031/dotfiles[^2] | 当リポジトリ |
|---|---|---|---|
| **方針** | chezmoi の機能をフル活用した最小構成 | テスト可能性を重視した分離構成 | shunk031 ベースにシンプル化 |
| **対象 OS** | macOS / Linux / Windows | macOS / Ubuntu | Ubuntu (Linux) |
| **秘密管理** | 1Password CLI | age encryption | age encryption |
| **ブートストラップ** | `install.sh`（23行） | `setup.sh`（263行） | `install.sh`（190行） |
| **テスト** | なし | Bats + kcov（カバレッジ計測） | Docker による手動検証 |
| **シェル** | zsh (oh-my-zsh) | zsh / bash（system で分岐） | zsh (sheldon) |
| **プラグイン管理** | oh-my-zsh 内蔵 | sheldon | sheldon |

## ディレクトリ構成の比較

### twpayne — chezmoi ネイティブ構成

```
twpayne/dotfiles/
├── home/                        # chezmoi source root
│   ├── .chezmoi.toml.tmpl       # TOML 形式の設定
│   ├── .chezmoiexternal.toml.tmpl
│   ├── .chezmoiignore.tmpl
│   ├── .chezmoiscripts/
│   │   ├── darwin/
│   │   ├── linux/
│   │   └── windows/
│   └── dot_config/
├── install.sh                   # 最小ブートストラップ
└── README.md
```

特徴的なのは **`install/` ディレクトリがない**ことです。インストールロジックはすべて `.chezmoiscripts/` 内に直接記述されています。また `.chezmoitemplates/` も使っていません。chezmoi の機能だけでシンプルに完結させる方針ですね。

### shunk031 — テスト可能な分離構成

```
shunk031/dotfiles/
├── home/                        # chezmoi source root
│   ├── .chezmoi.yaml.tmpl
│   ├── .chezmoiscripts/
│   │   ├── common/
│   │   ├── macos/
│   │   └── ubuntu/
│   └── .chezmoitemplates/
│       ├── chezmoiexternal.d/
│       ├── chezmoiignore.d/
│       └── chezmoiscripts.d/
├── install/                     # テスト可能なインストールスクリプト
│   ├── common/
│   ├── macos/
│   └── ubuntu/
├── tests/                       # Bats テスト
│   ├── files/
│   └── install/
├── setup.sh                     # ブートストラップ
└── Makefile
```

`install/` にロジックを分離し、`.chezmoiscripts/` からは `{{ include }}` で参照する構成です。これにより `install/` 内のスクリプトを Bats で単体テストできます。テストファイルはソースのディレクトリ構造をミラーしています（`install/common/mise.sh` → `tests/install/common/mise.bats`）。

### 当リポジトリ — shunk031 ベースにシンプル化

```
Zeni-Y/dotfiles/
├── home/                        # chezmoi source root
│   ├── .chezmoi.yaml.tmpl
│   ├── .chezmoiscripts/
│   │   ├── common/
│   │   └── ubuntu/
│   └── .chezmoitemplates/
│       ├── chezmoiexternal.d/
│       └── chezmoiignore.d/
├── install/                     # インストールスクリプト
│   ├── common/
│   └── ubuntu/common/
├── docker/                      # テスト用 Docker 環境
├── install.sh                   # ブートストラップ
└── books/                       # この Zenn Book
```

shunk031 の `install/` + `{{ include }}` パターンを採用しつつ、macOS サポートと Bats テストは省略しています。代わりに Docker でクリーン環境での検証を行う方式です。

## ブートストラップの比較

### twpayne — 最小の install.sh

```bash
#!/bin/sh
set -e

if [ ! "$(command -v chezmoi)" ]; then
  bin_dir="$HOME/.local/bin"
  chezmoi="$bin_dir/chezmoi"
  if [ "$(command -v curl)" ]; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
  elif [ "$(command -v wget)" ]; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
else
  chezmoi=chezmoi
fi

script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
exec "$chezmoi" init --apply "--source=$script_dir"
```

たったこれだけです。CI 対応も sudo keepalive も暗号化ファイルの除外もありません。なぜなら twpayne は **秘密管理に 1Password CLI を使っている**ため、age のようなパスフレーズ入力の問題がそもそも発生しないからです。

もう1つ注目すべきは `--source=$script_dir` です。リポジトリを `git clone` して直接 `./install.sh` を実行した場合、そのディレクトリをソースとして使います。`chezmoi init <user>` 経由で実行された場合も、chezmoi がリポジトリを clone した先をソースとして渡してくれます。

### shunk031 — フル機能の setup.sh

shunk031 の setup.sh は 263 行あり、以下を担当しています。

- macOS / Linux の OS 判定と初期化（Homebrew インストール等）
- macOS 向けの高度な sudo keepalive（Keychain 経由）
- CI/非TTY 環境への対応（`--no-tty`、暗号化ファイル除外）
- private dotfiles の管理（別リポジトリからの `chezmoi init`）
- シェルの再起動（現在は無効化）

shunk031 の記事[^3]では、このブートストラップスクリプトの自動テストについても言及されています。GitHub Actions で毎週金曜日に定期実行し、OS アップデートや外部依存の変更で壊れていないかを監視する仕組みです。

### 当リポジトリ — 中間のアプローチ

当リポジトリの `install.sh` は shunk031 のアプローチをベースに、Ubuntu 単一環境向けにシンプル化したものです。

| 機能 | twpayne | shunk031 | 当リポジトリ |
|------|---------|----------|------------|
| chezmoi ダウンロード | あり | あり | あり |
| CI/非TTY 対応 | なし | あり | あり |
| sudo keepalive | なし | あり（macOS/Linux） | あり（Linux のみ） |
| 暗号化ファイル除外 | 不要（1Password） | あり | あり |
| ブートストラップ用バイナリ削除 | なし | あり | あり |
| macOS 対応 | 不要（別の仕組み） | あり | なし |
| private dotfiles | なし | あり（別リポジトリ） | なし |

## 秘密管理の比較

### twpayne — 1Password CLI

```go
// dot_ssh/private_id_rsa.tmpl
{{ onepasswordRead "op://Personal/SSH Key/private key" }}
```

1Password の CLI（`op`）と chezmoi の `onepasswordRead` テンプレート関数を組み合わせて、1Password のヴォールトから直接秘密情報を取得します。ローカルに秘密鍵のファイルを暗号化して保存する必要がないため、非常にクリーンです。

ただし、1Password のサブスクリプションと CLI のセットアップが前提になります。

### shunk031 / 当リポジトリ — age encryption

```yaml
# .chezmoi.yaml.tmpl
encryption: "age"
age:
  identity: "~/.config/age/key.txt"
  recipient: "age1..."
```

age の鍵ペアで暗号化し、パスフレーズ付きの秘密鍵（`.key.txt.age`）をリポジトリに含めます。新しいマシンでは `chezmoi apply` 時にパスフレーズを入力して秘密鍵を復号します。

1Password のような外部サービスに依存しないのがメリットですが、CI 環境では TTY がないためパスフレーズ入力ができず、暗号化ファイルの除外が必要になるという課題があります。

## テンプレート構成の比較

### twpayne — インライン構成

twpayne は `.chezmoitemplates/` を使わず、すべてのテンプレートロジックをインラインで記述しています。

```toml
# .chezmoi.toml.tmpl（TOML 形式）
{{ $email := "twpayne@gmail.com" }}
{{ if eq $hostname "zrh-mpl3s" }}
{{   $email = "tpayne@akamai.com" }}
{{   $work = true }}
{{ end }}
```

特徴的なのは **ホスト名ベースのフィーチャーフラグ** です。マシンごとに `personal`、`work`、`headless`、`ephemeral` などのフラグを定義し、テンプレート内でこれらのフラグに基づいて条件分岐します。

```go
{{ if not .ephemeral }}
  // 一時的なマシン（コンテナ、VM）では不要な設定
{{ end }}

{{ if .personal }}
  // 個人の秘密情報（1Password から取得）
{{ end }}
```

### shunk031 / 当リポジトリ — テンプレート分割

`.chezmoitemplates/` を使ってテンプレートを分割し、`{{ template }}` で合成します。

```yaml
# .chezmoiexternal.yaml.tmpl
{{ template "chezmoiexternal.d/common.yaml.tmpl" . }}
{{ if eq .chezmoi.os "darwin" }}
{{ template "chezmoiexternal.d/macos.yaml.tmpl" . }}
{{ end }}
```

ファイルが大きくなりすぎるのを防ぎ、OS やシステム種別ごとの設定を独立したファイルで管理できます。

## インストールスクリプトの比較

### twpayne — .chezmoiscripts に直書き

```
.chezmoiscripts/
├── darwin/run_onchange_before_install-packages.sh.tmpl
├── linux/run_onchange_before_install-packages.sh.tmpl
└── windows/run_onchange_remove-bloat.ps1
```

インストールロジックを `.chezmoiscripts/` に直接書いています。`run_onchange_` を使っているのが特徴で、スクリプトの内容が変わったときだけ再実行されます（`run_once_` は初回のみ）。

### shunk031 — install/ に分離してテスト

```bash
# install/common/mise.sh
function install_mise() { ... }
function main() { install_mise; }

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
```

`if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` パターンにより、スクリプトを**直接実行**と **source で読み込み**の両方で使えます。Bats テストでは `source` でインストール関数を読み込んでテストし、`.chezmoiscripts/` からは `{{ include }}` で実行します。

shunk031 の記事[^3]では、この「関心の分離」と「テスト可能性」を dotfiles 管理の核心的なアプローチとして紹介しています。install スクリプトの単体テストに加え、kcov によるシェルスクリプトのカバレッジ計測まで行っている徹底ぶりです。

### 当リポジトリ — install/ に分離（テストなし）

shunk031 の `install/` + `{{ include }}` パターンを採用していますが、Bats テストは導入していません。代わりに Docker のクリーン環境で手動検証を行っています。

テストの自動化は将来的な課題ですが、個人の dotfiles としては Docker での検証で十分だと判断しています。

## 外部リソース管理の比較

### twpayne — .chezmoiexternal で自動更新

```toml
# .chezmoiexternal.toml.tmpl
[".local/bin/age"]
    type = "archive-file"
    url = {{ gitHubLatestReleaseAssetURL "FiloSottile/age" (printf "age-*-%s-%s.tar.gz" .chezmoi.os .chezmoi.arch) | quote }}
    path = "age"
```

`gitHubLatestReleaseAssetURL` テンプレート関数で GitHub Release の最新バージョンを自動取得しています。`refreshPeriod` を設定すれば定期的に更新もされます。chezmoi の機能をフル活用した方法ですね。

### shunk031 / 当リポジトリ — フォントのみ

`.chezmoiexternal` はフォント（Nerd Fonts）のダウンロードに限定して使っています。ツールのインストールは mise や apt-get に任せています。

## 学べるポイント

### twpayne から学べること

- **`install.sh` というファイル名の重要性** — chezmoi の規約に従うことで `chezmoi init <user>` だけでセットアップが完了する
- **フィーチャーフラグによる柔軟な分岐** — ホスト名ベースで `personal`/`work`/`ephemeral` 等を判定し、同じテンプレートから異なる設定を生成する
- **`run_onchange_` の活用** — スクリプトの内容が変わったときだけ再実行される仕組みで、冪等性を保ちつつ更新に追従する
- **`.chezmoiexternal` での自動バイナリ管理** — GitHub Release から最新バイナリを自動取得する

### shunk031 から学べること

- **`install/` への分離と `{{ include }}` パターン** — テスト可能なインストールスクリプトの設計
- **Bats + kcov による自動テスト** — シェルスクリプトの品質保証
- **CI での定期的なセットアップ検証** — 外部依存の変更を早期に検知
- **`.chezmoitemplates/` によるテンプレート分割** — 設定ファイルの肥大化を防ぐ

## まとめ

| 観点 | twpayne | shunk031 | 当リポジトリ |
|------|---------|----------|------------|
| 設計の軸 | chezmoi 機能の最大活用 | テスト可能性と関心の分離 | シンプルさと学習しやすさ |
| 向いている人 | chezmoi に精通した上級者 | チームや大規模 dotfiles | 個人で Ubuntu メインの人 |
| 複雑度 | 低（chezmoi に委ねる） | 高（テスト基盤込み） | 中 |

どのアプローチが正解というわけではなく、自分の環境や目的に合ったものを選ぶのが大事です。当リポジトリは shunk031 の設計パターンを土台にしつつ、twpayne の `install.sh` 規約も取り入れた構成になっています。

## 参考文献

[^1]: [twpayne/dotfiles](https://github.com/twpayne/dotfiles)
[^2]: [shunk031/dotfiles](https://github.com/shunk031/dotfiles)
[^3]: [テスト可能な dotfiles 管理：chezmoi による開発環境構築 — shunk031](https://zenn.dev/shunk031/articles/testable-dotfiles-management-with-chezmoi)
