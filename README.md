# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles リポジトリ。

## 前提ツール

| ツール | 用途 |
|--------|------|
| [chezmoi](https://www.chezmoi.io/) | dotfiles 管理 |
| [mise](https://mise.jdx.dev/) | ランタイムバージョン管理 |
| [sheldon](https://github.com/rossmacarthur/sheldon) | zsh プラグインマネージャ |
| [starship](https://starship.rs/) | プロンプト |
| [age](https://github.com/FiloSottile/age) | ファイル暗号化 |
| [zsh-abbr](https://zsh-abbr.olets.dev/) | エイリアスの代替（abbreviation） |

## セットアップ

### 新しいマシンへの初回セットアップ

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply zenimoto
```

chezmoi のインストールから dotfiles の取得・適用まで、このワンライナーですべて完了する。

初回実行時に以下の情報を対話的に聞かれる:
- **Email address** — git 等で使用するメールアドレス
- **System** — `client` (デスクトップ) or `server` (macOS は自動で `client`)

### age 暗号化の準備

暗号化ファイルを使用する場合:

```bash
mkdir -p ~/.config/age
# 既存の鍵をコピーするか、新規生成
age-keygen -o ~/.config/age/key.txt
```

## chezmoi を使った dotfiles 管理のライフサイクル

### 1. ファイルを管理対象に追加する

```bash
# 既存のファイルを chezmoi 管理下に置く
chezmoi add ~/.config/starship.toml

# テンプレートとして追加 (OS 分岐等が必要な場合)
chezmoi add --template ~/.bashrc

# 暗号化ファイルとして追加
chezmoi add --encrypt ~/.ssh/config
```

### 2. 設定を編集する

```bash
# chezmoi 経由で編集 (source ファイルを直接編集)
chezmoi edit ~/.zshrc

# または source directory で直接編集
chezmoi cd
vim dot_zshrc
```

### 3. 差分を確認する

```bash
# source と実際のファイルの差分を確認
chezmoi diff

# 適用内容のプレビュー (dry-run)
chezmoi apply --dry-run --verbose
```

### 4. 変更を適用する

```bash
# 全ファイルを適用
chezmoi apply

# 特定ファイルのみ適用
chezmoi apply ~/.zshrc

# 詳細出力付きで適用
chezmoi apply --verbose
```

### 5. 変更をコミット・プッシュする

```bash
chezmoi cd
git add -A
git commit -m "update zshrc"
git push
```

### 6. 別のマシンで変更を取り込む

```bash
# リモートから最新を取得して適用
chezmoi update

# 取得のみ (適用しない)
chezmoi git pull -- --rebase
chezmoi diff   # 差分を確認してから
chezmoi apply  # 適用
```

### 7. ドリフトを検出する

マシン上で直接編集してしまった場合:

```bash
# 差分を確認
chezmoi diff

# マシン上の変更を source に反映
chezmoi re-add

# または source 側の内容で上書き
chezmoi apply --force
```

## リポジトリ構成

```
.chezmoiroot              # source root を home/ に指定
.editorconfig             # エディタ共通設定
home/                     # chezmoi source directory
├── .chezmoi.yaml.tmpl    # chezmoi 設定テンプレート (email, system, is_wsl)
├── .chezmoiignore        # OS/system 別のファイル除外 (テンプレート合成)
├── .chezmoiexternal.yaml.tmpl  # 外部リソース自動DL (Nerd Fonts 等)
├── .chezmoitemplates/    # テンプレート分割用フラグメント
│   ├── chezmoiignore.d/  # ignore ルールの分割
│   └── chezmoiexternal.d/ # external ルールの分割
├── .chezmoiscripts/      # apply 時に実行されるスクリプト
│   ├── common/           # 全 OS 共通 (mise, sheldon, zed-keymap)
│   └── ubuntu/           # Ubuntu 固有
├── dot_zshrc             # → ~/.zshrc (PATH + sheldon source のみ)
├── dot_zprofile          # → ~/.zprofile (mise 初期化)
├── dot_vimrc             # → ~/.vimrc
└── dot_config/
    ├── git/
    │   ├── config.tmpl   # Git 設定 (テンプレート化)
    │   └── ignore        # グローバル gitignore
    ├── sheldon/
    │   ├── plugins.toml.tmpl  # テンプレート合成 (client/server 分岐)
    │   └── plugin_sources/    # プラグイン定義の分割
    │       ├── common.toml    # 共通プラグイン
    │       ├── client.toml    # client 用
    │       └── server.toml    # server 用
    ├── starship.toml     # プロンプト設定
    ├── mise/config.toml  # ランタイムバージョン管理
    ├── zsh-abbr/user-abbreviations  # abbreviation 定義
    ├── gwq/config.toml   # gwq worktree 管理
    ├── zed/              # Zed エディタ設定
    ├── zsh/plugins/chezmoi-notify/  # dotfiles 更新通知プラグイン
    └── alias/common.sh   # エイリアス (後方互換)
├── dot_local/bin/common/ # カスタムコマンド群
│   ├── dev              # ghq + fzf リポジトリ移動
│   ├── cdgwq            # gwq worktree 移動
│   ├── cdw              # 最新 worktree 移動
│   ├── fgc              # fzf git branch チェックアウト
│   ├── chezmoi-cd       # chezmoi ソース移動
│   ├── git-delete-merged-branches  # マージ済みブランチ削除
│   └── uv-format        # ruff format + check
install/                  # インストールスクリプト群
├── common/               # mise, sheldon, zed-keymap
└── ubuntu/common/        # fd-find 等
books/                    # Zenn Book
└── dotfiles-guide/       # chezmoi dotfiles 解説 Book
```

### chezmoi のファイル命名規則

| Prefix/Suffix | 意味 | 例 |
|---------------|------|-----|
| `dot_` | `.` に変換 | `dot_zshrc` → `.zshrc` |
| `private_` | パーミッション 0600 | `private_dot_ssh/` |
| `encrypted_` | age で暗号化 | `encrypted_private_dot_env` |
| `.tmpl` | Go テンプレートとして処理 | `.chezmoi.yaml.tmpl` |
| `executable_` | 実行権限付き | `executable_dev` |
| `run_once_` | 一度だけ実行するスクリプト | `run_once_install.sh` |
| `run_once_after_` | apply 後に一度だけ実行 | `run_once_after_01-install-mise.sh.tmpl` |
| `run_onchange_after_` | 内容変更時に実行 | `run_onchange_after_10-setup-zed-keymap.sh.tmpl` |

## カスタムコマンド

| コマンド | 機能 |
|---------|------|
| `dev` | ghq + fzf でリポジトリに移動、tmux セッション名をリネーム |
| `cdgwq` | gwq worktree を fzf で選択して移動 |
| `cdw` | 最新の gwq worktree に移動 |
| `fgc` | fzf で git branch をチェックアウト |
| `chezmoi-cd` | chezmoi ソースディレクトリに移動 |
| `git-delete-merged-branches` | squash-merge 済みブランチを削除 |
| `uv-format` | ruff format + ruff check を実行 |

## 管理ツール一覧

`mise` で管理しているツール (`dot_config/mise/config.toml`):

- **言語**: Go, Node.js (LTS), Rust, Python 3.12
- **CLI**: aws-cli, gcloud, jq, yq, uv, bun, eza, yazi, hugo
- **開発**: chezmoi, age, shellcheck, shfmt, pyright, bash-language-server
- **AI**: claude-code, codex
- **Git**: gh (GitHub CLI), ghq, gwq
