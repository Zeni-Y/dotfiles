---
title: "mise によるランタイム管理"
---

# mise によるランタイム管理

## mise とは

[mise](https://mise.jdx.dev/)（ミーズ）は、**言語ランタイムと CLI ツールを一元管理するツール**です。Rust 製で高速に動作します。

従来は言語ごとに専用のバージョンマネージャーを使う必要がありました:

| 言語 | 従来のツール |
|------|-------------|
| Node.js | [nvm](https://github.com/nvm-sh/nvm), [nodenv](https://github.com/nodenv/nodenv), [volta](https://volta.sh/) |
| Python | [pyenv](https://github.com/pyenv/pyenv) |
| Ruby | [rbenv](https://github.com/rbenv/rbenv), rvm |
| Go | [goenv](https://github.com/go-nv/goenv) |

mise はこれらを**1つのツールで置き換え**ます。言語ごとにバージョンマネージャーを覚えるのはめんどくさいので、mise で一元管理できるのはめちゃめちゃ助かります。

### asdf との違い

mise は [asdf](https://asdf-vm.com/) の後継的な位置づけです。asdf も複数言語のバージョン管理を1つのツールで行えますが、Shell 製で動作が遅く、shim 方式のためコマンド実行時にオーバーヘッドがありました。

| 特徴 | asdf | mise |
|------|------|------|
| 言語 | Shell | Rust |
| 速度 | 遅い | 速い |
| shims | 必要 | 不要（activate 方式） |
| 設定ファイル | .tool-versions | config.toml + .tool-versions |
| CLI ツール管理 | △ | ○ |
| npm パッケージ | × | ○ |

## mise の仕組み

config.toml の具体的な内容に入る前に、mise がどうやってツールのバージョンを切り替えているのかを理解しておきましょう。

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

shim 方式と違ってコマンド実行時のオーバーヘッドがないので、体感的にも速いです。

### trust モデル

mise は設定ファイルを初めて検出したとき、**明示的な trust が必要**です。

```bash
mise trust
```

これは、設定ファイルに含まれる hooks やタスクが任意のコードを実行できるため、セキュリティ上の理由からです。意図しない設定ファイルが実行されるのを防ぎます。

:::message
信頼できるリポジトリでのみ `mise trust` を実行してください。グローバル設定（`~/.config/mise/config.toml`）は自動的に信頼されます。
:::

## config.toml の構造

この仕組みを踏まえた上で、mise の設定ファイルを見ていきましょう。設定は `~/.config/mise/config.toml` に記述します。

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

mise は言語ランタイムだけでなく、CLI ツールも管理できます。これが本当に便利で、`apt` や `brew` に頼らずにツールを管理できます。

```toml
[tools]
age = "latest"
aws-cli = "latest"
bats = "latest"
bun = "latest"
chezmoi = "latest"
dotenvx = "latest"
eza = "latest"
gcloud = "latest"
gh = "latest"
ghq = "latest"
hugo-extended = "0.136.5"
jq = "latest"
uv = "latest"
yazi = "latest"
yq = "latest"
shellcheck = "latest"
shfmt = "latest"
```

これらのツールはすべて **mise レジストリ**（後述）に登録されているので、ツール名だけで書けます。

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
"github:d-kuro/gwq" = "latest"
"github:shuntaka9576/blocc" = "latest"
```

`github:` プレフィックスで GitHub Releases からバイナリを直接ダウンロードしてインストールできます。レジストリに登録されていないツールに使います。

### バックエンドの選び方

mise には複数のインストールバックエンドがあります。どれを使うかで安定性や速度が変わるので、使い分けの基準を整理しておきます。

| バックエンド | 書き方の例 | 特徴 |
|------------|-----------|------|
| レジストリ（デフォルト） | `eza = "latest"` | mise チームが検証済みのメタデータを使用。高速 |
| `github:` | `"github:owner/repo"` | GitHub Releases から直接ダウンロード |
| `npm:` | `"npm:pyright"` | npm パッケージとしてインストール |
| `cargo:` | `"cargo:tool"` | Rust の cargo でビルド・インストール |
| `pipx:` | `"pipx:tool"` | Python パッケージとしてインストール |
| `aqua:` | `"aqua:owner/repo"` | aqua レジストリを明示的に指定 |

**原則: レジストリに登録されているツールは、ツール名だけ（bare name）で書く。**

レジストリは mise が管理する [aqua レジストリ](https://mise-versions.jdx.dev/) ベースのインデックスで、ツール名とダウンロード元のマッピングが検証済みです。bare name で書くと mise がレジストリから最適なバックエンドを自動で選んでくれます。

`github:` バックエンドは、レジストリに登録されていないニッチなツールを補完する手段として使います。GitHub API のレート制限（認証なしだと 60 req/h）を受ける可能性がある点にも注意してください。

```bash
# ツールがレジストリに登録されているか確認する
mise registry | grep <tool-name>
```

## 設定オプション

```toml
[settings]
idiomatic_version_file_enable_tools = ["python"]
```

この設定により、Python は `.python-version` や `pyproject.toml` の `requires-python` からバージョンを読み取ることもできます。

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

新しいマシンで `chezmoi apply` を実行すると、以下の流れでツールが揃います。

```
chezmoi apply
  │
  ├─ 1. run_once_after_01-install-mise.sh が実行される
  │     → mise 本体がインストールされる（~/.local/bin/mise）
  │
  ├─ 2. mise install が実行される
  │     → config.toml に記述された全ツールがインストールされる
  │     → Go, Node, Python, Rust 等のランタイム
  │     → eza, bat, fd, jq 等の CLI ツール
  │     → Claude Code, pyright 等の npm パッケージ
  │
  └─ 3. 以降の run_once スクリプトで mise 経由のツールが使える
        → 例: fd-find のインストールスクリプトが mise の存在を前提にできる
```

新しいマシンで `chezmoi apply` を叩くだけで、言語ランタイムから CLI ツールまで全部揃います。

## ライフサイクル

### 初期セットアップ（初回のみ）

`chezmoi apply` で mise 自体のインストールと全ツールのインストールが自動的に行われます。手動での操作は不要です。

### 日常の操作

| やりたいこと | コマンド |
|------------|---------|
| インストール済みツールの一覧を見る | `mise ls` |
| 各ツールの現在のバージョンを確認する | `mise current` |
| 全ツールを最新に更新する | `mise upgrade` |
| 特定のツールを更新する | `mise upgrade node` |
| 設定ファイルを信頼する | `mise trust` |

### ツールを追加・変更したいとき

```bash
# 1. config.toml にツールを追記
chezmoi edit ~/.config/mise/config.toml

# 2. 適用してツールをインストール
chezmoi apply
mise install

# 3. 動作確認
mise current
```

`config.toml` を編集して `mise install` を実行するだけで新しいツールが使えるようになります。バージョンを変更したい場合も同様に `config.toml` を編集 → `mise install` の流れです。
