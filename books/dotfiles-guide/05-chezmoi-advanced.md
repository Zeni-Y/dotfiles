---
title: "chezmoi テンプレートと応用"
---

# chezmoi テンプレートと応用

## この章で扱うこと

前章では chezmoi の基本的な使い方（ソースとターゲットの分離、基本コマンド、ワークフロー）を学びました。この章では、chezmoi の応用機能を扱います。

### なぜ応用機能が必要なのか

dotfiles をただコピーするだけなら前章の知識で十分です。しかし、実際に運用していると以下のような課題にぶつかります:

1. **環境ごとに設定を変えたい** — macOS と Linux でパスが違う、client と server で読み込むプラグインが違う
2. **新しいマシンのセットアップを自動化したい** — chezmoi apply だけで必要なツールがすべてインストールされてほしい
3. **外部リソースを自動取得したい** — フォントやプラグインを GitHub から自動ダウンロードしたい
4. **設定ファイルが肥大化するのを防ぎたい** — 1ファイルに全環境の分岐を詰め込むと見通しが悪くなる

2 について補足します。前章で chezmoi が管理しているファイルを見ると、sheldon の `plugins.toml` や mise の `config.toml` といった**設定ファイル**は管理されていますが、sheldon や mise **そのもの**はインストールされません。chezmoi はあくまで dotfiles（設定ファイル）を配置するツールなので、ツール本体のインストールは守備範囲外です。新しいマシンで `chezmoi apply` すると設定ファイルは配置されるのに、肝心のツールが入っていない — この課題を `run_once` スクリプトで解決します。

chezmoi はこれらの課題を以下の仕組みで解決しています:

| 課題 | chezmoi の仕組み | このリポジトリでの活用 |
|------|-----------------|---------------------|
| 環境ごとの出し分け | **Go template** (`.tmpl` ファイル) | OS / system による条件分岐 |
| セットアップ自動化 | **`run_once` スクリプト** | mise, fd 等の自動インストール |
| 外部リソース取得 | **`.chezmoiexternal`** | Nerd Font の自動ダウンロード |
| 設定の分割管理 | **`.chezmoitemplates/`** | ignore / external の分割 |

### chezmoi apply の全体フロー

これらの仕組みがどのタイミングで動くのかを先に示しておきます。`chezmoi apply` を実行すると、以下の順番で処理が進みます:

```
chezmoi apply
  │
  ├─ 1. テンプレートデータの読み込み
  │     → .chezmoi.yaml.tmpl からカスタムデータを取得
  │     → ビルトイン変数（OS, hostname 等）を取得
  │
  ├─ 2. run_once_before_* スクリプトを実行（番号順）
  │     → 前提となるツールのインストール等
  │
  ├─ 3. ファイルの展開・配置
  │     → .tmpl ファイルはテンプレート展開してからコピー
  │     → encrypted_* は復号してから配置
  │     → .chezmoiexternal の外部リソースをダウンロード
  │     → .chezmoiignore に一致するファイルはスキップ
  │
  └─ 4. run_once_after_* スクリプトを実行（番号順）
        → mise install、sheldon インストール等
```

この全体フローを頭に入れた上で、各仕組みの詳細を見ていきましょう。

## Go template 基礎

chezmoi は Go の [`text/template`](https://pkg.go.dev/text/template) パッケージをテンプレートエンジンとして使用します。`.tmpl` サフィックスが付いたファイルはテンプレートとして処理されます。

### 基本構文

```go
{{ /* コメント */ }}
{{ .chezmoi.os }}           {{/* 変数の参照 */}}
{{ if eq .chezmoi.os "linux" }}...{{ end }}  {{/* 条件分岐 */}}
{{ include "path/to/file" }}  {{/* ファイルの取り込み */}}
```

Go template は独自の構文を持っているので、初見だと戸惑うかもしれません。よく使う要素をまとめておきます。

#### `{{ }}` — テンプレートの境界

`{{ }}` で囲まれた部分だけがテンプレートとして処理されます。それ以外はそのまま出力されます。シェルスクリプトや YAML の中に Go template を埋め込む形になるので、「ここからここまでがテンプレートの指示ですよ」という目印です。

```yaml
# {{ }} の外はそのまま出力される
data:
    email: {{ $email | quote }}  ← この部分だけテンプレート処理
```

#### `.`（ドット） — データへのアクセス

`.` は「現在のデータのルート」を表します。テンプレートに渡されたデータ（テンプレートデータ）の起点です。`.chezmoi.os` は「データのルート → chezmoi → os」とたどってアクセスしています。

```go
{{ .chezmoi.os }}    {{/* ビルトイン変数: "linux" や "darwin" */}}
{{ .email }}         {{/* カスタムデータ: .chezmoi.yaml.tmpl で定義した値 */}}
```

JavaScript でいう `data.chezmoi.os` のようなものですが、Go template では `data` の部分が `.` になります。

#### `$変数名 :=` — 変数の宣言と代入

`:=` は「新しい変数を作って値を入れる」構文です。`=` は「既存の変数に値を入れ直す」です。

```go
{{- $email := "" -}}         {{/* 新しい変数 $email を作り、空文字で初期化 */}}
{{- $email = .email -}}      {{/* 既存の $email に値を代入し直す */}}
```

`$` が付いているのはテンプレート内のローカル変数で、`.` で始まるデータ変数と区別するためです。

#### `| quote` — パイプと関数

`|` は Unix のパイプと同じ発想で、左の値を右の関数に渡します。`quote` は文字列を安全にクォート（`"..."` で囲む）する chezmoi 組み込みの関数です。

```go
{{ $email | quote }}
{{/* $email が user@example.com なら → "user@example.com" と出力される */}}
```

YAML では特殊文字（`@`, `:` 等）を含む値はクォートが必要です。`quote` を使うことで、どんな値でも安全に YAML に埋め込めます。手動で `"{{ $email }}"` と書くこともできますが、値自体にクォートが含まれる場合に壊れるので、`quote` を使うのが安全です。

### 空白制御

`{{-` と `-}}` を使うと、前後の空白（改行含む）を除去できます。

```go
{{- if eq .chezmoi.os "linux" }}
Linux の設定
{{- end }}
```

これは chezmoi のテンプレートでは非常に重要です。空白制御を忘れると、出力ファイルに不要な空行が入ってしまいます。最初のうちはハマりがちなポイントなので、`chezmoi cat <file>` でテンプレート展開後の結果を確認しながら書くのがおすすめです。

## .chezmoi.yaml.tmpl — データ定義

前章で触れた**カスタムデータ**（テンプレート内で `.email`, `.system` のように参照できるユーザー定義の変数）は、このファイルで定義します。「この環境は client なのか server なのか」「メールアドレスは何か」といった、環境ごとに異なる値をここで一元管理し、各テンプレートから参照する仕組みです。

このリポジトリでは `.chezmoi.yaml.tmpl` でカスタムデータを定義しています。

```yaml
{{- $email := "" -}}
{{- if hasKey . "email" -}}
{{-   $email = .email -}}
{{- else -}}
{{-   $email = promptString "Email address" -}}
{{- end -}}

{{- $system := "" -}}
{{- if hasKey . "system" -}}
{{-   $system = .system -}}
{{- else if eq .chezmoi.os "darwin" -}}
{{    $system = "client" -}}
{{- else -}}
{{-   $system = promptString "System (client or server)" -}}
{{- end -}}

data:
    email: {{ $email | quote }}
    system: {{ $system | quote }}
```

ポイント:
- `hasKey` で既に設定済みか確認し、なければ `promptString` でユーザーに入力を求める
- macOS は自動的に `client` に設定される
- `| quote` で YAML の値を安全にクォートする

定義したデータはテンプレート内で `.email`, `.system` として参照できます。初回 `chezmoi init` で対話的に値を聞かれて、以降は保存された値が使われる仕組みです。

## テンプレート変数

chezmoi が自動的に提供するビルトイン変数:

| 変数 | 値の例 | 説明 |
|------|--------|------|
| `.chezmoi.os` | `"linux"`, `"darwin"` | OS 種別 |
| `.chezmoi.osRelease.id` | `"ubuntu"`, `"debian"` | ディストリビューション ID |
| `.chezmoi.osRelease.idLike` | `"debian"` | 互換ディストリビューション |
| `.chezmoi.hostname` | `"myhost"` | ホスト名 |
| `.chezmoi.username` | `"user"` | ユーザー名 |
| `.chezmoi.homeDir` | `"/home/user"` | ホームディレクトリ |

```bash
# 利用可能な変数を確認
chezmoi data
```

「テンプレートが展開されない」「条件分岐が意図通りにならない」というときは、まず `chezmoi data` で変数の値を確認するのが鉄板です。

## run_once スクリプト

chezmoi では `.chezmoiscripts/` 以下にスクリプトを配置して、`chezmoi apply` 時に自動実行できます。新しいマシンのセットアップを自動化するのに使わない手はないですね。冒頭の全体フローで示した通り、スクリプトはファイル展開の前後で実行されます。

### スクリプトの種類

| プレフィックス | 実行タイミング |
|--------------|--------------|
| `run_once_before_` | apply の**前**に1度だけ |
| `run_once_after_` | apply の**後**に1度だけ |
| `run_before_` | apply の前に**毎回** |
| `run_after_` | apply の後に**毎回** |

### 実行順序の制御

ファイル名に番号を付けて、同じフェーズ内での実行順序を制御します。

```
.chezmoiscripts/
├── common/
│   └── run_once_after_01-install-mise.sh.tmpl    # after の中で最初に実行
└── ubuntu/
    └── run_once_20-install-fd.sh.tmpl             # mise の後に実行
```

番号が小さいほど先に実行されます。このリポジトリでは:
- `01` — mise のインストール（他のツールの前提）
- `20` — fd-find のインストール（mise が必要）

依存関係を番号で表現しているので、後から見返しても実行順序がすぐ分かります。

### 実際のスクリプト例

```bash
# .chezmoiscripts/common/run_once_after_01-install-mise.sh.tmpl
{{ include "../install/common/mise.sh" }}
```

```bash
# .chezmoiscripts/ubuntu/run_once_20-install-fd.sh.tmpl
{{ if eq .chezmoi.os "linux" -}}
{{   if eq .chezmoi.osRelease.idLike "debian" -}}
{{     include "../install/ubuntu/common/fd.sh" }}
{{   end -}}
{{ end -}}
```

## install/ ディレクトリと {{ include }} パターン

このリポジトリの特徴的なパターンは、**インストールロジックを `install/` ディレクトリに分離**していることです。

```
.chezmoiscripts/（いつ・何を実行するか）
  └── run_once_after_01-install-mise.sh.tmpl
        │
        │ {{ include }} で参照
        ↓
install/（どうやってインストールするか）
  ├── common/
  │   └── mise.sh          # mise インストールスクリプト
  └── ubuntu/
      └── common/
          └── fd.sh         # fd-find インストールスクリプト
```

`.chezmoiscripts/` からは `{{ include }}` で参照します。

```go
{{ include "../install/common/mise.sh" }}
```

**なぜ分離するのか:**

1. **再利用性**: 同じインストールスクリプトを複数のスクリプトから参照できる
2. **テスト可能性**: `install/` 以下のスクリプトは単体で実行・テストできる
3. **見通し**: `.chezmoiscripts/` は「何をいつ実行するか」、`install/` は「どうやるか」を分離

### 冪等なインストールスクリプト

インストールスクリプトは**何度実行しても同じ結果になる**ように設計します。これがすごく大事です。

```bash
# install/ubuntu/common/fd.sh
function install_fd() {
    # 既にインストール済みならスキップ
    if ! command -v fdfind &> /dev/null; then
        echo "Installing fd-find..."
        sudo apt-get update
        sudo apt-get install -y fd-find
    else
        echo "fd-find is already installed."
    fi

    # シンボリックリンクの作成（存在チェック付き）
    local link_path="${HOME}/.local/bin/fd"
    if [ ! -L "$link_path" ]; then
        mkdir -p "${HOME}/.local/bin"
        ln -s "$(which fdfind)" "$link_path"
    fi
}
```

:::message
`command -v` で既にインストール済みかチェックし、`if [ ! -L ]` でシンボリックリンクの存在を確認しています。これにより2回目以降の実行では何も行いません。
:::

## .chezmoitemplates/ による分割管理

`.chezmoitemplates/` ディレクトリにテンプレートの部品を配置すると、`{{ template "name" . }}` で呼び出せます。[shunk031/dotfiles](https://github.com/shunk031/dotfiles) で活用されているパターンを参考に、このリポジトリでも `.chezmoiignore` と `.chezmoiexternal.yaml.tmpl` の分割管理に採用しています。

### `.d` ディレクトリの命名規則

`chezmoiignore.d/` や `chezmoiexternal.d/` のように末尾に `.d` が付いたディレクトリ名は、**Linux/Unix の慣習的な命名パターン**です。`.d` は "directory" の略で、「このディレクトリ内のファイルを集めて、1つの設定として統合する」ことを意味します。

Linux システムでも同じパターンが広く使われています:

- `/etc/cron.d/` — cron 設定の断片を格納
- `/etc/apt/sources.list.d/` — APT ソースの断片を格納
- `/etc/sudoers.d/` — sudoers 設定の断片を格納

chezmoi でもこの慣習に従い、1つの設定ファイルの内容を**複数ファイルに分割**して管理しています。

### テンプレート構成パターン

```
home/
├── .chezmoitemplates/
│   ├── chezmoiignore.d/
│   │   ├── common                   # 全環境で除外するファイル
│   │   └── ubuntu/
│   │       ├── common               # Ubuntu 共通で除外
│   │       ├── client               # client 環境で除外
│   │       └── server               # server 環境で除外
│   └── chezmoiexternal.d/
│       ├── common.yaml.tmpl         # 全環境の外部依存
│       └── ubuntu.yaml.tmpl         # Ubuntu 固有の外部依存
├── .chezmoiignore                   # テンプレートを結合
└── .chezmoiexternal.yaml.tmpl       # テンプレートを結合
```

### 呼び出し側の書き方

`.chezmoiignore` では `{{ template }}` でテンプレートを結合します。

```go
{{ template "chezmoiignore.d/common" . }}
{{ if eq .chezmoi.os "linux" -}}
{{   template "chezmoiignore.d/ubuntu/common" . }}
{{   if eq .system "client" -}}
{{     template "chezmoiignore.d/ubuntu/client" . }}
{{   else if eq .system "server" -}}
{{     template "chezmoiignore.d/ubuntu/server" . }}
{{   end -}}
{{ end -}}
```

OS と system の組み合わせで除外ファイルを切り替えています。各テンプレートには除外対象のパスだけを記述します。

```
# chezmoiignore.d/common
.config/sheldon/plugin_sources

# chezmoiignore.d/ubuntu/client
.local/bin/server

# chezmoiignore.d/ubuntu/server
.local/bin/client
```

`{{ include }}` との違い:
- `{{ include }}` — ファイルパスを指定（相対パス可）
- `{{ template }}` — `.chezmoitemplates/` 内のファイル名を指定

## .chezmoiexternal.yaml.tmpl — 外部依存管理

外部リポジトリやアーカイブを chezmoi で管理できます。このリポジトリでは **Nerd Font の自動ダウンロード**に活用しています。

### Nerd Font の自動インストール

[eza](https://github.com/eza-community/eza) のアイコン表示など、Nerd Font が必要なツールのために、`chezmoi apply` 時に自動的にフォントをダウンロードします。

```yaml
# .chezmoitemplates/chezmoiexternal.d/common.yaml.tmpl
{{ $fontsPath := ".local/share/fonts" -}}
"{{ $fontsPath }}/Hack":
  type: "archive"
  url: {{ gitHubLatestReleaseAssetURL "ryanoasis/nerd-fonts" "Hack.zip" | quote }}
  refreshPeriod: "720h"
```

`chezmoi apply` 時に以下の流れで処理されます。

```
chezmoi apply
  ↓ .chezmoiexternal.yaml.tmpl を読み込み
  ↓ gitHubLatestReleaseAssetURL で GitHub リリースの最新 URL を取得
  ↓ Hack.zip をダウンロード・展開
  ↓ ~/.local/share/fonts/Hack/ にフォントファイルが配置される
  ↓ 30日後（refreshPeriod: "720h"）に再度更新チェック
```

`chezmoi apply` するだけで Nerd Font がインストールされるのはめちゃめちゃ便利です。

### パイプラインでクロスプラットフォーム対応

macOS と Linux の両方に対応する場合、**パイプライン構文で OS ごとのパスを切り替える**テクニックが便利です。

```go
{{ $fontsPath := .chezmoi.os | replace "darwin" "Library/Fonts" | replace "linux" ".local/share/fonts" -}}
"{{ $fontsPath }}/Hack":
  type: "archive"
  url: {{ gitHubLatestReleaseAssetURL "ryanoasis/nerd-fonts" "Hack.zip" | quote }}
  refreshPeriod: "720h"
```

処理の流れ:

1. `.chezmoi.os` → OS 名を取得（`"darwin"` or `"linux"`）
2. `| replace "darwin" "Library/Fonts"` → macOS なら `"Library/Fonts"` に置換
3. `| replace "linux" ".local/share/fonts"` → Linux なら `".local/share/fonts"` に置換

`|`（パイプ）は Unix のパイプと同じ発想で、前の出力を次の関数の**最後の引数**として渡します。`if/else` を使わずにワンライナーで OS 分岐できる便利なテクニックです。

:::message
このリポジトリでは Linux 専用なので `$fontsPath` を直接指定していますが、将来 macOS にも対応する場合はこのパターンが活用できます。
:::

### テンプレート分割による管理

`.chezmoiexternal.yaml.tmpl` も `.chezmoitemplates/` で分割管理しています。

```go
# .chezmoiexternal.yaml.tmpl
{{ template "chezmoiexternal.d/common.yaml.tmpl" . }}
{{ if (and (eq .chezmoi.os "linux") (eq .chezmoi.osRelease.idLike "debian")) -}}
{{   template "chezmoiexternal.d/ubuntu.yaml.tmpl" . }}
{{ end -}}
```

OS ごとに必要な外部依存を分離し、条件分岐で結合しています。

## .chezmoiignore — OS 別 ignore

`.chezmoiignore` で特定のファイルを chezmoi の管理対象から除外できます。テンプレートも使えるので、OS ごとに除外するファイルを変えられます。

このリポジトリでは `.chezmoitemplates/chezmoiignore.d/` に分割して管理しています（前述の `.chezmoitemplates/` パターン）。

### 実用例: sheldon plugin_sources の除外

sheldon の `plugin_sources/` ディレクトリはビルド時に `plugins.toml.tmpl` から `{{ include }}` で結合されるため、ホームディレクトリへの配置は不要です。`.chezmoiignore` で除外します。

```
# chezmoiignore.d/common
.config/sheldon/plugin_sources
```

### 実用例: system による bin ディレクトリの分離

client 環境では server 用スクリプトを除外し、server 環境では client 用スクリプトを除外します。

```
# chezmoiignore.d/ubuntu/client
.local/bin/server

# chezmoiignore.d/ubuntu/server
.local/bin/client
```

これにより、同じリポジトリで client/server 両方のスクリプトを管理しつつ、各環境に必要なファイルだけを配置できます。
