---
title: "mise によるランタイム管理"
---

# mise によるランタイム管理

## mise とは

mise（ミーズ）は、**言語ランタイムと CLI ツールを一元管理するツール**です。Rust 製で高速に動作します。

従来は言語ごとに専用のバージョンマネージャーを使う必要がありました:

| 言語 | 従来のツール |
|------|-------------|
| Node.js | nvm, nodenv, volta |
| Python | pyenv, virtualenv |
| Ruby | rbenv, rvm |
| Go | goenv |

mise はこれらを**1つのツールで置き換え**ます。さらに、asdf と互換性のあるプラグインシステムを持ちつつ、Rust 製で高速に動作します。

### asdf との違い

mise は asdf の後継的な位置づけです。

| 特徴 | asdf | mise |
|------|------|------|
| 言語 | Shell | Rust |
| 速度 | 遅い | 速い |
| shims | 必要 | 不要（activate 方式） |
| 設定ファイル | .tool-versions | config.toml + .tool-versions |
| CLI ツール管理 | △ | ○ |
| npm パッケージ | × | ○ |

## config.toml の構造

mise の設定は `~/.config/mise/config.toml` に記述します。

### 言語ランタイム

```toml
[tools]
go = "latest"
node = "lts"
rust = "latest"
python = "3.12"
```

- `"latest"` — 最新安定版
- `"lts"` — 最新の LTS (Long Term Support) 版
- `"3.12"` — 特定バージョンを指定

### CLI ツール

mise は言語ランタイムだけでなく、CLI ツールも管理できます。

```toml
[tools]
age = "latest"
"aqua:aws/aws-cli" = "latest"
bats = "latest"
bun = "latest"
chezmoi = "latest"
eza = "latest"
jq = "latest"
"pipx:dotenvx" = "latest"
"aqua:GoogleCloudPlatform/cloud-sdk" = "latest"
"cargo:hugo-extended" = "0.136.5"
uv = "latest"
yazi = "latest"
yq = "latest"
shellcheck = "latest"
shfmt = "latest"
```

ツールのインストール元:
- **デフォルト**: mise の内蔵バックエンド
- **`aqua:`**: aqua レジストリからインストール（AWS CLI, gcloud 等）
- **`pipx:`**: Python パッケージとしてインストール
- **`cargo:`**: Rust の cargo からビルド・インストール

### npm パッケージ

```toml
[tools]
"npm:@anthropic-ai/claude-code" = "latest"
"npm:@openai/codex" = "latest"
"npm:bash-language-server" = "latest"
"npm:pyright" = "latest"
"npm:fast-cli" = "latest"
```

`npm:` プレフィックスで npm パッケージをグローバルにインストールできます。Node.js がインストールされていれば自動的に使えます。

### GitHub リリース

```toml
[tools]
"aqua:x-motemen/ghq" = "latest"
"aqua:d-kuro/gwq" = "latest"
"aqua:cli/cli" = "latest"
"aqua:shuntaka9576/blocc" = "latest"
```

GitHub リリースからバイナリを直接ダウンロードしてインストールします。

## 設定オプション

```toml
[settings]
idiomatic_version_file_enable_tools = ["python"]
```

この設定により、Python は `.python-version` や `pyproject.toml` の `requires-python` からバージョンを読み取ることもできます。

## mise の仕組み

### activate 方式

mise は shim ファイルではなく、**シェルの hook で PATH を動的に変更**する方式を採用しています。

```bash
# .zshrc で activate
eval "$(mise activate zsh)"
```

`mise activate` はシェルの `chpwd` フック（ディレクトリ移動時に呼ばれる関数）を登録します。ディレクトリを移動するたびに、そのディレクトリの `.tool-versions` や `config.toml` を読み取り、PATH を更新します。

```
~/project-a/  (Node 18)  →  cd  →  ~/project-b/  (Node 20)
      ↑ PATH に Node 18 を設定           ↑ PATH に Node 20 を設定
```

### trust モデル

mise は設定ファイルを初めて検出したとき、**明示的な trust が必要**です。

```bash
mise trust
```

これは、設定ファイルに含まれる hooks やタスクが任意のコードを実行できるため、セキュリティ上の理由からです。意図しない設定ファイルが実行されるのを防ぎます。

:::message
信頼できるリポジトリでのみ `mise trust` を実行してください。グローバル設定（`~/.config/mise/config.toml`）は自動的に信頼されます。
:::

## 基本コマンド

```bash
# 設定されたツールをすべてインストール
mise install

# 特定のツールをインストール
mise install node@20

# インストール済みツールの一覧
mise ls

# ツールのバージョンを確認
mise current

# 設定ファイルを信頼
mise trust

# 環境変数を確認
mise env
```

## chezmoi との連携

このリポジトリでは、`chezmoi apply` 時に mise を自動インストールするスクリプトを用意しています。

```bash
# install/common/mise.sh
function install_mise() {
    local version="2026.2.21"
    curl https://mise.run | MISE_VERSION="${version}" sh
    eval "$(~/.local/bin/mise activate bash)"
}

function run_mise_install() {
    mise install
}
```

chezmoi apply の流れ:
1. `run_once_after_01-install-mise.sh` で mise をインストール
2. `mise install` で config.toml に記述された全ツールをインストール
3. 以降の `run_once` スクリプトで mise 経由のツールが使える
