---
title: "chezmoi 入門"
---

# chezmoi 入門

## chezmoi とは

chezmoi は Go 製の dotfiles マネージャーです。**ファイルのコピー**をベースとした管理方式で、テンプレートエンジンや暗号化機能を内蔵しています。

symlink ベースのツール（Stow など）との最大の違いは、**ソースファイルと実際の設定ファイルが独立している**点です。

```
# Stow: シンボリックリンク
~/.zshrc -> ~/dotfiles/zsh/.zshrc  (同一ファイル)

# chezmoi: コピー
~/dotfiles/home/dot_zshrc  →(apply)→  ~/.zshrc  (別々のファイル)
```

この方式により、ソースを編集しても `chezmoi apply` するまで実際の設定は変わりません。安全に編集・テストができます。

## インストール

```bash
# curl でインストール（公式推奨）
sh -c "$(curl -fsLS get.chezmoi.io)"

# mise でインストール（この dotfiles の方式）
mise install chezmoi

# Homebrew
brew install chezmoi
```

## 基本コマンド

### init — 初期化

```bash
# GitHub リポジトリから dotfiles を取得して初期化
chezmoi init https://github.com/username/dotfiles.git

# ローカルリポジトリで初期化
chezmoi init

# 既存の設定データを無視して再度プロンプトを表示
chezmoi init --data=false
```

`init` を実行すると、`~/.local/share/chezmoi` にソースディレクトリが作成されます。

`--data=false` を指定すると、既存の設定データ（`chezmoi.yaml` に保存済みの値）を無視して、`.chezmoi.yaml.tmpl` 内の `promptString` 等による対話プロンプトが再度表示されます。メールアドレスやシステム種別などの設定値を変更したい場合に便利です。

### add — ファイルを管理対象に追加

```bash
# ~/.zshrc を管理対象に追加
chezmoi add ~/.zshrc
# → ~/.local/share/chezmoi/dot_zshrc が作成される

# テンプレートとして追加
chezmoi add --template ~/.zshrc
```

### edit — ソースファイルを編集

```bash
# エディタでソースファイルを開く
chezmoi edit ~/.zshrc
```

### diff — 差分を確認

```bash
# ソースと実際のファイルの差分を表示
chezmoi diff
```

`apply` する前に必ず `diff` で変更内容を確認する習慣をつけましょう。

### apply — 変更を適用

```bash
# ソースの内容を実際のファイルに反映
chezmoi apply

# dry-run（実際には適用しない）
chezmoi apply --dry-run
```

### cd — ソースディレクトリに移動

```bash
# ソースディレクトリに移動
chezmoi cd
# → ~/.local/share/chezmoi に移動
```

### data — テンプレートデータの確認

```bash
# 利用可能なテンプレート変数を表示
chezmoi data
```

`.chezmoi.yaml.tmpl` で定義したカスタムデータや、ビルトイン変数（OS 情報等）を確認できます。

## ディレクトリ構造

chezmoi のソースディレクトリは通常 `~/.local/share/chezmoi` です。

### .chezmoiroot

このリポジトリでは `.chezmoiroot` ファイルで**ソースルートを `home/` に設定**しています。

```
# .chezmoiroot の内容
home
```

これにより、リポジトリ直下に `install/` や `memo/` などのディレクトリを置いても chezmoi に認識されません。chezmoi が管理するファイルは `home/` 以下のみです。

```
dotfiles/               # リポジトリルート
├── .chezmoiroot         # ソースルートを home/ に設定
├── CLAUDE.md            # プロジェクトドキュメント
├── README.md
├── install/             # インストールスクリプト（chezmoi 管理外）
│   ├── common/
│   └── ubuntu/
└── home/                # ← chezmoi のソースルート
    ├── .chezmoi.yaml.tmpl
    ├── .chezmoiscripts/
    ├── dot_zshrc
    ├── dot_gitconfig
    └── dot_config/
```

## Naming Convention

chezmoi はファイル名の**プレフィックス**と**サフィックス**で管理方法を制御します。

### プレフィックス

| プレフィックス | 意味 | 例 |
|--------------|------|-----|
| `dot_` | `.` に変換 | `dot_zshrc` → `~/.zshrc` |
| `private_` | パーミッション制限（0o600） | `private_dot_ssh/` → `~/.ssh/` |
| `executable_` | 実行権限付き | `executable_script.sh` → `script.sh` (chmod +x) |
| `symlink_` | シンボリックリンク | `symlink_link` → シンボリックリンクとして配置 |
| `empty_` | 空ファイルを作成 | `empty_dot_file` → 空の `.file` |

プレフィックスは**組み合わせ可能**です:

```
private_dot_ssh/             → ~/.ssh/ (パーミッション制限付き)
private_executable_dot_script → ~/.script (private + executable)
```

### サフィックス

| サフィックス | 意味 |
|------------|------|
| `.tmpl` | Go template として処理される |

```
dot_zshrc.tmpl → テンプレート処理後に ~/.zshrc として配置
```

### 実際のファイル対応表

このリポジトリの実際の対応を見てみましょう。

| ソースファイル | 配置先 |
|--------------|--------|
| `home/dot_zshrc` | `~/.zshrc` |
| `home/dot_gitconfig` | `~/.gitconfig` |
| `home/dot_config/sheldon/plugins.toml` | `~/.config/sheldon/plugins.toml` |
| `home/dot_config/mise/config.toml` | `~/.config/mise/config.toml` |
| `home/dot_config/alias/common.sh` | `~/.config/alias/common.sh` |
| `home/.chezmoi.yaml.tmpl` | `~/.config/chezmoi/chezmoi.yaml` |

:::message
`dot_config/` はディレクトリにも `dot_` プレフィックスが適用されます。`dot_config/sheldon/` は `~/.config/sheldon/` になります。
:::

## 基本的なワークフロー

```bash
# 1. 設定ファイルを編集したい
chezmoi edit ~/.zshrc

# 2. 差分を確認
chezmoi diff

# 3. 変更を適用
chezmoi apply

# 4. ソースディレクトリに移動してコミット
chezmoi cd
git add -A
git commit -m "feat: update zshrc"
git push
```

もしくは、直接ソースディレクトリで編集する方法もあります:

```bash
# ソースディレクトリに移動
chezmoi cd

# 直接ファイルを編集
vim dot_zshrc

# 差分確認 → 適用
chezmoi diff
chezmoi apply

# コミット
git add -A
git commit -m "feat: update zshrc"
git push
```
