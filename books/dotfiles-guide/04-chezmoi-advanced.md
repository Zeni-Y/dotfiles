---
title: "chezmoi テンプレートと応用"
---

# chezmoi テンプレートと応用

## Go template 基礎

chezmoi は Go の `text/template` パッケージをテンプレートエンジンとして使用します。`.tmpl` サフィックスが付いたファイルはテンプレートとして処理されます。

### 基本構文

```go
{{ /* コメント */ }}
{{ .chezmoi.os }}           {{/* 変数の参照 */}}
{{ if eq .chezmoi.os "linux" }}...{{ end }}  {{/* 条件分岐 */}}
{{ include "path/to/file" }}  {{/* ファイルの取り込み */}}
```

### 空白制御

`{{-` と `-}}` を使うと、前後の空白（改行含む）を除去できます。

```go
{{- if eq .chezmoi.os "linux" }}
Linux の設定
{{- end }}
```

これは chezmoi のテンプレートでは非常に重要です。空白制御を忘れると、出力ファイルに不要な空行が入ります。

## .chezmoi.yaml.tmpl — データ定義

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

定義したデータはテンプレート内で `.email`, `.system` として参照できます。

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

## run_once スクリプト

chezmoi では `.chezmoiscripts/` 以下にスクリプトを配置して、`chezmoi apply` 時に自動実行できます。

### スクリプトの種類

| プレフィックス | 実行タイミング |
|--------------|--------------|
| `run_once_before_` | apply の**前**に1度だけ |
| `run_once_after_` | apply の**後**に1度だけ |
| `run_before_` | apply の前に**毎回** |
| `run_after_` | apply の後に**毎回** |

### 実行順序の制御

ファイル名に番号を付けて実行順序を制御します。

```
.chezmoiscripts/
├── common/
│   └── run_once_after_01-install-mise.sh.tmpl    # 最初に実行
└── ubuntu/
    └── run_once_20-install-fd.sh.tmpl             # 後で実行
```

番号が小さいほど先に実行されます。このリポジトリでは:
- `01` — mise のインストール（他のツールの前提）
- `20` — fd-find のインストール（mise が必要）

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
install/
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

インストールスクリプトは**何度実行しても同じ結果になる**ように設計します。

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

eza のアイコン表示など、Nerd Font が必要なツールのために、`chezmoi apply` 時に自動的にフォントをダウンロードします。

```yaml
# .chezmoitemplates/chezmoiexternal.d/common.yaml.tmpl
{{ $fontsPath := ".local/share/fonts" -}}
"{{ $fontsPath }}/Hack":
  type: "archive"
  url: {{ gitHubLatestReleaseAssetURL "ryanoasis/nerd-fonts" "Hack.zip" | quote }}
  refreshPeriod: "720h"
```

ポイント:
- `gitHubLatestReleaseAssetURL` で GitHub リリースの最新アセット URL を自動取得
- `refreshPeriod: "720h"`（30日）で定期的に更新チェック
- `type: "archive"` で ZIP を自動展開してフォントディレクトリに配置

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
