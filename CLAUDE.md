# Dotfiles (chezmoi)

## Design Philosophy

1. **パフォーマンス重視**: zsh-defer による遅延読み込みで起動時間を最小化
2. **冪等性**: スクリプトは何度実行しても同じ結果になるように設計（`run_once_*` の活用）
3. **テンプレート分割**: `install/` に再利用可能なロジックを分離し `{{ include }}` で結合。1ファイルの肥大化を防ぐ
4. **クロスプラットフォーム**: OS (`darwin`/`linux`) × system (`client`/`server`) の組み合わせで分岐管理
5. **セキュリティ**: age encryption で秘密情報を暗号化管理。`.workrc` 等の非追跡ファイルで個人設定を分離
6. **Rust ベースモダンツール**: sheldon, starship, mise, eza 等の高速ツールを積極採用

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
books/               # Zenn Book
  dotfiles-guide/    # chezmoi dotfiles 解説 Book
```

## Key Conventions

### chezmoi naming rules
- `dot_` prefix → `.` (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_` prefix → パーミッション制限付き (e.g., `private_dot_ssh/`)
- `executable_` prefix → 実行権限付きファイル
- `symlink_` prefix → シンボリックリンクとして管理
- `.tmpl` suffix → Go template として処理
- `run_once_before_*` → chezmoi apply 前に一度だけ実行
- `run_once_after_*` → chezmoi apply 後に一度だけ実行
- スクリプトは番号で実行順序を制御 (e.g., `run_once_after_01-*`, `run_once_20-*`)
- `.chezmoiroot` で source root を `home/` に設定している

### Template data
`.chezmoi.yaml.tmpl` で以下のデータを定義:
- `email` — メールアドレス
- `system` — `client` or `server` (darwin は自動で `client`)

テンプレート内で使えるビルトイン変数:
- `.chezmoi.os` — `darwin` / `linux`
- `.chezmoi.osRelease.id` — `ubuntu`, `debian` 等
- `.chezmoi.osRelease.idLike` — `debian` 等

### Template composition
テンプレートを分割して `{{ include }}` で結合するパターンを使用:
```
# .chezmoiscripts/common/run_once_after_01-install-mise.sh.tmpl
{{ include "../install/common/mise.sh" }}
```
- インストールロジックは `install/` に分離し、`.chezmoiscripts/` から include
- 将来的に `.chezmoitemplates/` を活用してさらに分割可能

### OS/System branching
3層の分岐で管理:
1. **OS レベル**: `.chezmoi.os` (`darwin` / `linux`)
2. **System レベル**: `.system` (`client` / `server`)
3. **Distro レベル**: `.chezmoi.osRelease.idLike` (`debian` 等)

分岐の配置ルール:
| 対象 | 分岐方法 |
|------|----------|
| スクリプト | `.chezmoiscripts/<os>/` ディレクトリで分離 |
| インストール | `install/<os>/<system or common>/` で分離 |
| エイリアス | `alias/common.sh`, `alias/client.sh` 等ファイルで分離 |
| テンプレート | `.tmpl` 内で `{{ if }}` 条件分岐 |

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

1. **ファイル追加時**: chezmoi の naming convention に従う (`dot_`, `private_`, `executable_`, `symlink_`, `.tmpl`)
2. **スクリプト追加時**: OS 固有のものは `.chezmoiscripts/<os>/` に、共通は `.chezmoiscripts/common/` に配置。番号で実行順序を制御
3. **install スクリプト**: 再利用可能なインストールロジックは `install/` 以下に置き、`.chezmoiscripts` から `{{ include }}` で参照
4. **テンプレート**: OS やシステム種別で分岐が必要な場合は `.tmpl` を使い、`.chezmoi.yaml.tmpl` のデータを参照
5. **シェルスクリプト**: `#!/usr/bin/env bash` を使い、コメントは日本語で記述
6. **冪等性**: インストールスクリプトは既にインストール済みの場合はスキップするように設計
7. **セキュリティ**: 秘密鍵や認証情報は `private_` prefix + age encryption で管理。`.env` やパスワードを平文でコミットしない
8. **コミットメッセージ**: Conventional Commits 形式を推奨 (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:` 等)
