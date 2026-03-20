---
title: "リファレンス"
---

# リファレンス

このチャプターはチートシート集です。複雑なコマンドやキーバインドは忘れやすいので、後から見返せるようにまとめています。

## このリポジトリのファイル一覧

### ソースファイルと配置先の対応

| ソースファイル                                    | 配置先                                                                    | 説明                            |
| ------------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------- |
| `home/dot_config/fish/config.fish.tmpl`           | `~/.config/fish/config.fish`                                              | fish shell 設定（テンプレート） |
| `home/dot_config/fish/fish_plugins`               | `~/.config/fish/fish_plugins`                                             | fisher プラグインリスト         |
| `home/dot_config/fish/conf.d/chezmoi-notify.fish` | `~/.config/fish/conf.d/chezmoi-notify.fish`                               | dotfiles 更新通知プラグイン     |
| `home/dot_vimrc`                                  | `~/.vimrc`                                                                | Vim 基本設定                    |
| `home/.chezmoi.yaml.tmpl`                         | `~/.config/chezmoi/chezmoi.yaml`                                          | chezmoi 設定                    |
| `home/.chezmoiignore`                             | —                                                                         | chezmoi 管理対象の除外設定      |
| `home/.chezmoiexternal.yaml.tmpl`                 | —                                                                         | 外部依存管理（Nerd Font 等）    |
| `home/dot_config/git/config.tmpl`                 | `~/.config/git/config`                                                    | Git 設定（テンプレート）        |
| `home/dot_config/git/ignore`                      | `~/.config/git/ignore`                                                    | グローバル gitignore            |
| `home/dot_config/starship.toml`                   | `~/.config/starship.toml`                                                 | starship プロンプト設定         |
| `home/dot_config/mise/config.toml`                | `~/.config/mise/config.toml`                                              | ランタイム設定                  |
| `home/dot_config/gwq/config.toml`                 | `~/.config/gwq/config.toml`                                               | gwq 設定                        |
| `home/dot_config/zed/settings.json`               | `~/.config/zed/settings.json`                                             | Zed エディタ設定                |
| `home/dot_config/zed/keymap.json`                 | `~/.config/zed/keymap.json` (WSL: `%APPDATA%\Zed\keymap.json` にもコピー) | Zed キーバインド設定            |

### カスタムコマンド

| ソースファイル                                                   | コマンド名                   | 説明                                  |
| ---------------------------------------------------------------- | ---------------------------- | ------------------------------------- |
| `home/dot_config/fish/functions/dev.fish`                        | `dev`                        | ghq + fzf でリポジトリ移動            |
| `home/dot_config/fish/functions/fgc.fish`                        | `fgc`                        | fzf で git ブランチチェックアウト     |
| `home/dot_config/fish/functions/cdgwq.fish`                      | `cdgwq`                      | gwq worktree を fzf で選択して移動    |
| `home/dot_config/fish/functions/cdw.fish`                        | `cdw`                        | 最新の gwq worktree に移動            |
| `home/dot_config/fish/functions/chezmoi-cd.fish`                 | `chezmoi-cd`                 | chezmoi ソースディレクトリに移動      |
| `home/dot_config/fish/functions/git-delete-merged-branches.fish` | `git-delete-merged-branches` | squash-merge 済みブランチを検出・削除 |
| `home/dot_config/fish/functions/uv-format.fish`                  | `uv-format`                  | ruff でフォーマット + リント          |

### スクリプト

| ファイル                                                                | 実行タイミング     | 内容                                |
| ----------------------------------------------------------------------- | ------------------ | ----------------------------------- |
| `.chezmoiscripts/common/run_once_after_01-install-mise.sh.tmpl`         | apply 後 1 回      | mise インストール                   |
| `.chezmoiscripts/common/run_once_after_02-install-fish.sh.tmpl`         | apply 後 1 回      | fish + fisher セットアップ          |
| `.chezmoiscripts/common/run_onchange_after_10-setup-zed-keymap.sh.tmpl` | keymap.json 変更時 | WSL → Windows に keymap.json を配置 |

### インストールスクリプト

| ファイル                       | 内容                                            |
| ------------------------------ | ----------------------------------------------- |
| `install/common/mise.sh`       | mise のインストールとツール展開                 |
| `install/common/fish.sh`       | fish shell のインストールと fisher セットアップ |
| `install/common/zed-keymap.sh` | WSL 環境で keymap.json を Windows 側に配置      |

### テンプレート部品

| ファイル                                                    | 内容                          |
| ----------------------------------------------------------- | ----------------------------- |
| `home/.chezmoitemplates/chezmoiignore.d/common`             | 全環境共通の ignore 設定      |
| `home/.chezmoitemplates/chezmoiignore.d/ubuntu/common`      | Ubuntu 共通の ignore 設定     |
| `home/.chezmoitemplates/chezmoiignore.d/ubuntu/client`      | Ubuntu client の ignore 設定  |
| `home/.chezmoitemplates/chezmoiignore.d/ubuntu/server`      | Ubuntu server の ignore 設定  |
| `home/.chezmoitemplates/chezmoiexternal.d/common.yaml.tmpl` | 全環境の外部依存（Nerd Font） |
| `home/.chezmoitemplates/chezmoiexternal.d/ubuntu.yaml.tmpl` | Ubuntu 固有の外部依存         |

### その他

| ファイル       | 内容                          |
| -------------- | ----------------------------- |
| `.chezmoiroot` | ソースルートを `home/` に設定 |
| `.gitignore`   | Git 除外設定                  |
| `README.md`    | リポジトリドキュメント        |
| `CLAUDE.md`    | 設計方針ドキュメント          |

## chezmoi コマンドチートシート

### 基本操作

```bash
chezmoi init <repo>        # リポジトリから初期化
chezmoi init --data=false  # 既存データを無視して再度プロンプト表示
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

## fisher コマンドチートシート

```bash
fisher install <plugin>    # プラグインをインストール
fisher remove <plugin>     # プラグインを削除
fisher update              # 全プラグインを更新
fisher list                # インストール済みプラグインの一覧
```

## fzf キーバインドチートシート

| キーバインド | 効果                               |
| ------------ | ---------------------------------- |
| `Ctrl+T`     | ファイル検索（bat プレビュー付き） |
| `Ctrl+R`     | コマンド履歴検索                   |
| `Alt+C`      | ディレクトリ検索 → cd              |
| `Ctrl+/`     | プレビューの表示/非表示切り替え    |

## Zed キーバインドチートシート

### ファイル・ナビゲーション

| キー               | 動作                 |
| ------------------ | -------------------- |
| `Ctrl + P`         | ファイルを素早く開く |
| `Ctrl + Shift + P` | コマンドパレット     |
| `Ctrl + G`         | 指定行へジャンプ     |
| `Ctrl + Shift + O` | シンボルへジャンプ   |
| `Ctrl + Tab`       | タブの切り替え       |

### 編集

| キー                    | 動作                 |
| ----------------------- | -------------------- |
| `Ctrl + D`              | 同じ単語を追加選択   |
| `Ctrl + Shift + L`      | 同じ単語をすべて選択 |
| `Ctrl + Shift + K`      | 行を削除             |
| `Alt + Up/Down`         | 行を移動             |
| `Alt + Shift + Up/Down` | 行を複製             |
| `Ctrl + /`              | コメントトグル       |

### パネル・表示

| キー               | 動作                   |
| ------------------ | ---------------------- |
| `Ctrl + B`         | サイドバートグル       |
| `Ctrl + J`         | ターミナルトグル       |
| `Ctrl + Shift + F` | プロジェクト内検索     |
| `Ctrl + Shift + E` | ファイルエクスプローラ |
| `Ctrl + \`         | エディタを分割         |

### コード操作

| キー          | 動作               |
| ------------- | ------------------ |
| `F2`          | シンボルのリネーム |
| `F12`         | 定義へジャンプ     |
| `Shift + F12` | 参照を表示         |
| `Ctrl + .`    | コードアクション   |

### AI アシスタント

| キー                   | 動作                        |
| ---------------------- | --------------------------- |
| `Ctrl + Enter`         | AI アシスタントパネルを開く |
| `Ctrl + Shift + Enter` | インラインアシスト          |

### WSL 連携

| キー                                         | 動作                   |
| -------------------------------------------- | ---------------------- |
| `Ctrl + Shift + P` → `projects: open in wsl` | WSL プロジェクトを開く |

## 参考リポジトリ

| リポジトリ                                                          | 特徴                          |
| ------------------------------------------------------------------- | ----------------------------- |
| [shunk031/dotfiles](https://github.com/shunk031/dotfiles)           | chezmoi テンプレートパターン  |
| [twpayne/dotfiles](https://github.com/twpayne/dotfiles)             | chezmoi 作者の dotfiles       |
| [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) | macOS 設定の充実した dotfiles |

## 公式ドキュメントリンク

| ツール                                           | URL                                    |
| ------------------------------------------------ | -------------------------------------- |
| [chezmoi](https://www.chezmoi.io/)               | https://www.chezmoi.io/                |
| [fish](https://fishshell.com/)                   | https://fishshell.com/                 |
| [fisher](https://github.com/jorgebucaran/fisher) | https://github.com/jorgebucaran/fisher |
| [mise](https://mise.jdx.dev/)                    | https://mise.jdx.dev/                  |
| [starship](https://starship.rs/)                 | https://starship.rs/                   |
| [age](https://github.com/FiloSottile/age)        | https://github.com/FiloSottile/age     |
| [fzf](https://github.com/junegunn/fzf)           | https://github.com/junegunn/fzf        |
| [eza](https://github.com/eza-community/eza)      | https://github.com/eza-community/eza   |
| [bat](https://github.com/sharkdp/bat)            | https://github.com/sharkdp/bat         |
| [fd](https://github.com/sharkdp/fd)              | https://github.com/sharkdp/fd          |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | https://github.com/BurntSushi/ripgrep  |
| [yazi](https://github.com/sxyazi/yazi)           | https://github.com/sxyazi/yazi         |
| [ghq](https://github.com/x-motemen/ghq)          | https://github.com/x-motemen/ghq       |
| [gwq](https://github.com/d-kuro/gwq)             | https://github.com/d-kuro/gwq          |
| [bats](https://github.com/bats-core/bats-core)   | https://github.com/bats-core/bats-core |
| [Zed](https://zed.dev/)                          | https://zed.dev/                       |
| [Zenn](https://zenn.dev/)                        | https://zenn.dev/                      |

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
title: "本のタイトル" # 必須
summary: "概要" # 必須
topics: ["topic1"] # 必須（1-5個）
published: true/false # 公開設定
price: 0 # 0 = 無料
toc_depth: 2 # 目次の深さ
chapters: # チャプター順序
  - chapter-slug
```

### チャプターの Frontmatter

```yaml
---
title: "チャプタータイトル"
---
```

各チャプターの Markdown ファイルには `title` を含む frontmatter が必須です。
