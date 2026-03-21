# Dotfiles (chezmoi)

## Design Philosophy

1. **パフォーマンス重視**: fish shell の高速な起動と組み込み機能を活用
2. **冪等性**: スクリプトは何度実行しても同じ結果になるように設計（`run_once_*` の活用）
3. **テンプレート分割**: `install/` に再利用可能なロジックを分離し `{{ include }}` で結合。1 ファイルの肥大化を防ぐ
4. **クロスプラットフォーム**: OS (`darwin`/`linux`) × system (`client`/`server`) の組み合わせで分岐管理
5. **セキュリティ**: SSH agent forwarding を活用。`.workrc.fish` 等の非追跡ファイルで個人設定を分離
6. **Rust ベースモダンツール**: starship, mise, eza 等の高速ツールを積極採用

## Repository Structure

```
.chezmoiroot         # source root を home/ に設定
home/                # chezmoi source directory (= chezmoiroot)
  .chezmoi.yaml.tmpl # chezmoi config template (email, system)
  .chezmoiscripts/   # chezmoi apply 時に実行されるスクリプト
    common/          # 全OS共通スクリプト
    ubuntu/          # Ubuntu固有スクリプト
  dot_gitconfig      # ~/.gitconfig
  dot_config/
    fish/              # fish shell 設定
      config.fish.tmpl # メイン設定（テンプレート）
      fish_plugins     # fisher プラグインリスト
      conf.d/          # 自動読み込み設定
      functions/       # fish functions（カスタムコマンド）
    starship.toml      # プロンプト設定
    mise/config.toml   # ランタイムバージョン管理 (Go, Node, Python, Rust, etc.)
install/             # .chezmoiscripts から include されるインストールスクリプト
  common/            # mise, fish インストール等
  ubuntu/common/     # Ubuntu 固有インストール等
books/               # Zenn Book
  dotfiles-guide/    # chezmoi dotfiles 解説 Book
```

## Key Conventions

### chezmoi naming rules

- `dot_` prefix → `.` (e.g., `dot_config` → `~/.config`)
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

3 層の分岐で管理:

1. **OS レベル**: `.chezmoi.os` (`darwin` / `linux`)
2. **System レベル**: `.system` (`client` / `server`)
3. **Distro レベル**: `.chezmoi.osRelease.idLike` (`debian` 等)

分岐の配置ルール:
| 対象 | 分岐方法 |
|------|----------|
| スクリプト | `.chezmoiscripts/<os>/` ディレクトリで分離 |
| インストール | `install/<os>/<system or common>/` で分離 |
| エイリアス | `config.fish.tmpl` 内で `abbr` / `alias` で定義 |
| テンプレート | `.tmpl` 内で `{{ if }}` 条件分岐 |

### SSH

- SSH agent forwarding を利用し、秘密鍵・公開鍵は chezmoi で管理しない
- `authorized_keys` のみ平文で管理（`private_dot_ssh/private_authorized_keys`）
- client（ローカル PC）を新しくする場合は都度秘密鍵と公開鍵を作成

### Shell environment

- Shell: **fish**
- Plugin manager: **fisher**
- Prompt: **starship**
- Runtime manager: **mise**
- ls replacement: **eza**

### fish shell 構成

- `config.fish.tmpl` — メイン設定（PATH, 環境変数, エイリアス, プラグイン初期化）
- `conf.d/` — 自動読み込み設定（chezmoi-notify 等）
- `functions/` — カスタムコマンド（dev, cdgwq, cdw, fgc 等）
- `fish_plugins` — fisher で管理するプラグインリスト

fish の組み込み機能で zsh プラグイン相当を実現:

- シンタックスハイライト: 組み込み
- オートサジェスチョン: 組み込み
- オートペア: `jorgebucaran/autopair.fish`
- 成功時のみ履歴記録: `meaningful-ooo/sponge`

abbr と alias の使い分け:

- `abbr` — 実行時にコマンドラインで展開表示される。展開後が短いコマンドに使用
- `alias` — 展開せずそのまま実行される。展開後が長くなるコマンド（`eza` のオプション列等）に使用

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
6. **fish functions**: `~/.config/fish/functions/` に 1 関数 1 ファイルで配置
7. **冪等性**: インストールスクリプトは既にインストール済みの場合はスキップするように設計
8. **セキュリティ**: 認証情報は `.env` やパスワードを平文でコミットしない。SSH は agent forwarding を利用し、秘密鍵は chezmoi で管理しない
9. **コミットメッセージ**: Conventional Commits 形式を推奨 (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:` 等)
10. **`fish -c` 禁止（フォークボム防止）**: fish の設定ファイル（`config.fish`, `conf.d/`, `functions/`）およびインストールスクリプトから `fish -c "..."` でサブシェルを起動してはならない。`fish -c` は `config.fish` を再帰的に読み込み、プロセスが無限増殖するフォークボムを引き起こす。代替手段:
    - 外部コマンド実行: `command <cmd>` を使う（fish サブシェルを経由しない）
    - バックグラウンド処理: `command sh -c '...'` を使う（POSIX sh は fish config を読み込まない）
    - fisher セットアップ等でどうしても fish が必要な場合: `fish --no-config -c '...'` を使う
    - 参考: コミット `0273501` で keychain の同様のバグを修正済み
