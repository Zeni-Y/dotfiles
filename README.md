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

## セットアップ

### 新しいマシンへの初回セットアップ

```bash
# chezmoi をインストール (mise 経由または公式スクリプト)
sh -c "$(curl -fsLS get.chezmoi.io)"

# dotfiles を取得して適用
chezmoi init <github-username> --apply
```

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
home/                     # chezmoi source directory
├── .chezmoi.yaml.tmpl    # chezmoi 設定テンプレート
├── .chezmoiscripts/      # apply 時に実行されるスクリプト
│   ├── common/           # 全 OS 共通
│   └── ubuntu/           # Ubuntu 固有
├── dot_zshrc             # → ~/.zshrc
├── dot_gitconfig         # → ~/.gitconfig
└── dot_config/
    ├── sheldon/
    │   └── plugins.toml  # zsh プラグイン設定
    ├── mise/
    │   └── config.toml   # ランタイムバージョン管理
    └── alias/
        └── common.sh     # 共通エイリアス
install/                  # インストールスクリプト群
├── common/               # mise インストール等
└── ubuntu/common/        # fd-find インストール等
```

### chezmoi のファイル命名規則

| Prefix/Suffix | 意味 | 例 |
|---------------|------|-----|
| `dot_` | `.` に変換 | `dot_zshrc` → `.zshrc` |
| `private_` | パーミッション 0600 | `private_dot_ssh/` |
| `encrypted_` | age で暗号化 | `encrypted_private_dot_env` |
| `.tmpl` | Go テンプレートとして処理 | `.chezmoi.yaml.tmpl` |
| `run_once_` | 一度だけ実行するスクリプト | `run_once_install.sh` |
| `run_once_after_` | apply 後に一度だけ実行 | `run_once_after_01-install-mise.sh.tmpl` |

## 管理ツール一覧

`mise` で管理しているツール (`dot_config/mise/config.toml`):

- **言語**: Go, Node.js (LTS), Rust, Python 3.12
- **CLI**: aws-cli, gcloud, jq, yq, uv, bun, eza, yazi, hugo
- **開発**: chezmoi, age, shellcheck, shfmt, pyright, bash-language-server
- **AI**: claude-code, codex
- **Git**: gh (GitHub CLI), ghq, gwq
