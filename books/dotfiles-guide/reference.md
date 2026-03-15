---
title: "リファレンス"
---

# リファレンス

## このリポジトリのファイル一覧

### ソースファイルと配置先の対応

| ソースファイル | 配置先 | 説明 |
|--------------|--------|------|
| `home/dot_zshrc` | `~/.zshrc` | zsh 設定 |
| `home/dot_gitconfig` | `~/.gitconfig` | Git 設定 |
| `home/.chezmoi.yaml.tmpl` | `~/.config/chezmoi/chezmoi.yaml` | chezmoi 設定 |
| `home/dot_config/sheldon/plugins.toml` | `~/.config/sheldon/plugins.toml` | プラグイン設定 |
| `home/dot_config/mise/config.toml` | `~/.config/mise/config.toml` | ランタイム設定 |
| `home/dot_config/alias/common.sh` | `~/.config/alias/common.sh` | エイリアス |

### スクリプト

| ファイル | 実行タイミング | 内容 |
|---------|--------------|------|
| `.chezmoiscripts/common/run_once_after_01-install-mise.sh.tmpl` | apply 後1回 | mise インストール |
| `.chezmoiscripts/ubuntu/run_once_20-install-fd.sh.tmpl` | apply 後1回 | fd-find インストール (Ubuntu) |

### インストールスクリプト

| ファイル | 内容 |
|---------|------|
| `install/common/mise.sh` | mise のインストールとツール展開 |
| `install/ubuntu/common/fd.sh` | fd-find のインストールとシンボリックリンク作成 |

### その他

| ファイル | 内容 |
|---------|------|
| `.chezmoiroot` | ソースルートを `home/` に設定 |
| `.gitignore` | Git 除外設定 |
| `README.md` | リポジトリドキュメント |
| `CLAUDE.md` | 設計方針ドキュメント |

## chezmoi コマンドチートシート

### 基本操作

```bash
chezmoi init <repo>        # リポジトリから初期化
chezmoi add <file>         # ファイルを管理対象に追加
chezmoi add --encrypt <f>  # 暗号化して追加
chezmoi edit <file>        # ソースファイルを編集
chezmoi diff               # 差分を確認
chezmoi apply              # 変更を適用
chezmoi apply --dry-run    # dry-run
chezmoi update             # リモートから更新して適用
```

### 情報確認

```bash
chezmoi data               # テンプレート変数を表示
chezmoi doctor             # 設定の健全性チェック
chezmoi managed            # 管理対象ファイル一覧
chezmoi cat <file>         # テンプレート展開後の内容を表示
chezmoi source-path <file> # ソースファイルのパスを表示
```

### ナビゲーション

```bash
chezmoi cd                 # ソースディレクトリに移動
chezmoi source-path        # ソースディレクトリのパスを表示
```

### テンプレート

```bash
chezmoi execute-template '{{ .chezmoi.os }}'  # テンプレートをテスト実行
chezmoi data | jq .                           # テンプレートデータを JSON で表示
```

## mise コマンドチートシート

```bash
mise install               # config.toml のツールをすべてインストール
mise install <tool>@<ver>  # 特定のツールをインストール
mise ls                    # インストール済みツール一覧
mise current               # 現在有効なバージョン
mise trust                 # 設定ファイルを信頼
mise env                   # 環境変数を表示
mise use <tool>@<ver>      # ツールのバージョンを設定
mise outdated              # 更新可能なツールを表示
mise upgrade               # ツールを更新
```

## sheldon コマンドチートシート

```bash
sheldon lock               # plugins.toml を解析してロックファイル生成
sheldon source             # プラグインのソースコードを出力
sheldon add <name> --github <repo>  # プラグインを追加
sheldon remove <name>      # プラグインを削除
```

## 参考リポジトリ

| リポジトリ | 特徴 |
|-----------|------|
| [shunk031/dotfiles](https://github.com/shunk031/dotfiles) | chezmoi + sheldon、.chezmoitemplates パターン |
| [twpayne/dotfiles](https://github.com/twpayne/dotfiles) | chezmoi 作者の dotfiles |
| [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) | macOS 設定の充実した dotfiles |

## 公式ドキュメントリンク

| ツール | URL |
|--------|-----|
| chezmoi | https://www.chezmoi.io/ |
| sheldon | https://sheldon.cli.rs/ |
| mise | https://mise.jdx.dev/ |
| starship | https://starship.rs/ |
| age | https://github.com/FiloSottile/age |
| fzf | https://github.com/junegunn/fzf |
| eza | https://github.com/eza-community/eza |
| bat | https://github.com/sharkdp/bat |
| fd | https://github.com/sharkdp/fd |
| ripgrep | https://github.com/BurntSushi/ripgrep |
| yazi | https://github.com/sxyazi/yazi |
| ghq | https://github.com/x-motemen/ghq |
| bats | https://github.com/bats-core/bats-core |
| Zenn | https://zenn.dev/ |

## Zenn Book の仕様

この Book は [Zenn の Book 機能](https://zenn.dev/zenn/articles/zenn-cli-guide) を使って公開しています。

### ディレクトリ構造

```
books/
└── dotfiles-guide/
    ├── config.yaml       # Book 設定
    ├── introduction.md   # Chapter 1
    ├── what-is-dotfiles.md
    └── ...
```

### config.yaml の仕様

```yaml
title: "本のタイトル"        # 必須
summary: "概要"             # 必須
topics: ["topic1"]          # 必須（1-5個）
published: true/false       # 公開設定
price: 0                    # 0 = 無料
toc_depth: 2                # 目次の深さ
chapters:                   # チャプター順序
  - chapter-slug
```

### チャプターの Frontmatter

```yaml
---
title: "チャプタータイトル"
---
```

各チャプターの Markdown ファイルには `title` を含む frontmatter が必須です。
