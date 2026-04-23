# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles リポジトリ。

## 前提ツール

| ツール                                           | 用途                      |
| ------------------------------------------------ | ------------------------- |
| [chezmoi](https://www.chezmoi.io/)               | dotfiles 管理             |
| [mise](https://mise.jdx.dev/)                    | ランタイムバージョン管理  |
| [fish](https://fishshell.com/)                   | シェル                    |
| [fisher](https://github.com/jorgebucaran/fisher) | fish プラグインマネージャ |
| [starship](https://starship.rs/)                 | プロンプト                |

## セットアップ

### 新しいマシンへの初回セットアップ

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Zeni-Y
```

chezmoi のインストールから dotfiles の取得・適用まで、このワンライナーですべて完了する。

初回実行時に以下の情報を対話的に聞かれる:

- **Email address** — git 等で使用するメールアドレス
- **System** — `client` (デスクトップ) or `server` (macOS は自動で `client`)

### macOS での初回セットアップ

初期化直後の Mac でも上記ワンライナーだけでセットアップが完了する。内部で以下が自動実行される:

1. **Xcode Command Line Tools** — git や cc が入っていなければ GUI インストーラを起動
2. **Homebrew** — `/opt/homebrew` (Apple Silicon) または `/usr/local` (Intel) にインストール
3. **fish** — `brew install fish` でインストールし、`/etc/shells` 登録とログインシェル変更
4. **tmux** — `brew install tmux` と TPM (Tmux Plugin Manager) のセットアップ
5. **mise** — ランタイム/ツール一式を `dot_config/mise/config.toml` に従ってインストール

macOS では以下の挙動が Linux と異なる:

- Git の認証ヘルパは `osxkeychain` を利用（Linux は `credentialStore = cache`）
- Nerd Fonts は `~/Library/Fonts` に配置（Linux は `~/.local/share/fonts`）
- `system` プロンプトは自動で `client` になる（macOS で server 運用は想定していない）

## chezmoi を使った dotfiles 管理のライフサイクル

### 1. ファイルを管理対象に追加する

```bash
# 既存のファイルを chezmoi 管理下に置く
chezmoi add ~/.config/starship.toml

# テンプレートとして追加 (OS 分岐等が必要な場合)
chezmoi add --template ~/.bashrc
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

## Docker でのテスト

Docker を使ってクリーンな Ubuntu 環境で dotfiles の適用をテストできる。`CI=true` が設定されるため対話プロンプトはスキップされる。

```bash
# コンテナを起動（初回はイメージを自動ビルド）
make docker

# イメージをキャッシュなしで再ビルド
make docker-rebuild
```

コンテナ内ではリポジトリがマウントされているので、`chezmoi init --apply` でセットアップを試せる。

```bash
# コンテナ内で実行
make init     # chezmoi init --apply --verbose
make update   # chezmoi apply --verbose
make reset    # run_once スクリプトの実行状態をリセット（再実行可能にする）
make diff     # chezmoi diff
make data     # chezmoi data（テンプレート変数の確認）
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
│   ├── common/           # 全 OS 共通 (mise, fish, tmux, zed-keymap)
│   └── macos/            # macOS 専用 (brew)
├── dot_vimrc             # → ~/.vimrc
└── dot_config/
    ├── git/
    │   ├── config.tmpl   # Git 設定 (テンプレート化)
    │   └── ignore        # グローバル gitignore
    ├── fish/             # fish shell 設定
    │   ├── config.fish.tmpl  # メイン設定 (テンプレート)
    │   ├── fish_plugins      # fisher プラグインリスト
    │   ├── conf.d/           # 自動読み込み設定
    │   └── functions/        # カスタムコマンド
    ├── starship.toml     # プロンプト設定
    ├── mise/config.toml  # ランタイムバージョン管理
    ├── gwq/config.toml   # gwq worktree 管理
    └── zed/              # Zed エディタ設定
├── dot_local/bin/common/ # ユーティリティスクリプト
│   └── fish-time        # fish 起動プロファイリングツール
install/                  # インストールスクリプト群
├── common/               # 全 OS 共通 (mise, fish, tmux, zed-keymap, done)
└── macos/                # macOS 専用 (brew)
books/                    # Zenn Book
└── dotfiles-guide/       # chezmoi dotfiles 解説 Book
```

### chezmoi のファイル命名規則

| Prefix/Suffix         | 意味                       | 例                                               |
| --------------------- | -------------------------- | ------------------------------------------------ |
| `dot_`                | `.` に変換                 | `dot_config` → `.config`                         |
| `private_`            | パーミッション 0600        | `private_dot_ssh/`                               |
| `.tmpl`               | Go テンプレートとして処理  | `.chezmoi.yaml.tmpl`                             |
| `executable_`         | 実行権限付き               | `executable_dev`                                 |
| `run_once_`           | 一度だけ実行するスクリプト | `run_once_install.sh`                            |
| `run_once_after_`     | apply 後に一度だけ実行     | `run_once_after_01-install-mise.sh.tmpl`         |
| `run_onchange_after_` | 内容変更時に実行           | `run_onchange_after_10-setup-zed-keymap.sh.tmpl` |

## カスタムコマンド

fish functions (`dot_config/fish/functions/`) として実装:

| コマンド                     | 機能                                                      |
| ---------------------------- | --------------------------------------------------------- |
| `dev`                        | ghq + fzf でリポジトリに移動、tmux セッション名をリネーム |
| `cdgwq`                      | gwq worktree を fzf で選択して移動                        |
| `cdw`                        | 最新の gwq worktree に移動                                |
| `fgc`                        | fzf で git branch をチェックアウト                        |
| `chezmoi-cd`                 | chezmoi ソースディレクトリに移動                          |
| `git-delete-merged-branches` | squash-merge 済みブランチを削除                           |
| `uv-format`                  | ruff format + ruff check を実行                           |

シェルスクリプト (`dot_local/bin/common/`) として実装:

| コマンド    | 機能                                  |
| ----------- | ------------------------------------- |
| `fish-time` | fish shell 起動プロファイリングツール |

## 管理ツール一覧

`mise` で管理しているツール (`dot_config/mise/config.toml`):

- **言語**: Go, Node.js (LTS), Rust, Python 3.12
- **シェル / ターミナル**: fish-shell, starship, yazi
- **パッケージマネージャ**: bun, uv
- **Git**: chezmoi, gh (GitHub CLI), ghq, gwq
- **クラウド / インフラ**: aws-cli, gcloud
- **データ処理**: jq, yq
- **セキュリティ**: age, dotenvx
- **Lint / フォーマッタ**: shellcheck, shfmt
- **ファイル / ディレクトリ**: eza, fd
- **Web / ドキュメント**: hugo-extended, blocc
- **テスト**: bats
- **AI**: claude-code, codex
- **LSP / 開発ツール**: pyright, bash-language-server
- **ネットワーク**: fast-cli
