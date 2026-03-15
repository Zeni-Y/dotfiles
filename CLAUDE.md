# Dotfiles (chezmoi)

## Repository Structure

```
.chezmoiroot         # source root を home/ に設定
home/                # chezmoi source directory (= chezmoiroot)
  .chezmoi.yaml.tmpl # chezmoi config template (email, system, age encryption)
  .chezmoiscripts/   # chezmoi apply 時に実行されるスクリプト
    common/          # 全OS共通スクリプト
    ubuntu/          # Ubuntu固有スクリプト
  dot_zshrc          # ~/.zshrc
  dot_gitconfig      # ~/.gitconfig
  dot_config/
    sheldon/plugins.toml  # zsh プラグインマネージャ設定
    mise/config.toml      # ランタイムバージョン管理 (Go, Node, Python, Rust, etc.)
    alias/common.sh       # 共通エイリアス
install/             # .chezmoiscripts から include されるインストールスクリプト
  common/            # mise インストール等
  ubuntu/common/     # fd-find インストール等
```

## Key Conventions

### chezmoi naming rules
- `dot_` prefix → `.` (e.g., `dot_zshrc` → `~/.zshrc`)
- `.tmpl` suffix → Go template として処理
- `run_once_after_*` → chezmoi apply 後に一度だけ実行されるスクリプト
- `.chezmoiroot` で source root を `home/` に設定している

### Template data
`.chezmoi.yaml.tmpl` で以下のデータを定義:
- `email` — メールアドレス
- `system` — `client` or `server` (darwin は自動で `client`)

### Encryption
- age encryption を使用 (`~/.config/age/key.txt`)
- CI 環境 (`CI=true`) では暗号化を無効化

### Shell environment
- Shell: **zsh**
- Plugin manager: **sheldon** (zsh-defer による遅延読み込み)
- Prompt: **starship**
- Runtime manager: **mise**
- ls replacement: **eza**

## Common Commands

```bash
chezmoi apply          # dotfiles を適用
chezmoi diff           # 差分を確認
chezmoi add <file>     # ファイルを管理対象に追加
chezmoi edit <file>    # source ファイルを編集
chezmoi cd             # source directory に移動
chezmoi data           # template data を確認
```

## Rules for Editing

1. **ファイル追加時**: chezmoi の naming convention に従う (`dot_`, `.tmpl`, etc.)
2. **スクリプト追加時**: OS 固有のものは `.chezmoiscripts/<os>/` に、共通は `.chezmoiscripts/common/` に配置
3. **install スクリプト**: 再利用可能なインストールロジックは `install/` 以下に置き、`.chezmoiscripts` から `{{ include }}` で参照
4. **テンプレート**: OS やシステム種別で分岐が必要な場合は `.tmpl` を使い、`.chezmoi.yaml.tmpl` のデータを参照
5. **シェルスクリプト**: `#!/usr/bin/env bash` を使い、コメントは日本語で記述
6. **コミットメッセージ**: 日本語または英語、簡潔に変更内容を記述
