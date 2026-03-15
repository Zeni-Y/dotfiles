---
title: "開発ワークフロー"
---

# 開発ワークフロー

## dotfiles の変更サイクル

dotfiles の変更は以下のサイクルで行います。

```
edit → diff → apply → test → commit → push
```

### 1. edit — ソースファイルを編集

```bash
# chezmoi edit で編集（推奨）
chezmoi edit ~/.zshrc

# または直接ソースディレクトリで編集
chezmoi cd
vim dot_zshrc
```

### 2. diff — 差分を確認

```bash
# ソースと実際のファイルの差分を確認
chezmoi diff
```

意図しない変更がないか確認します。テンプレートの場合は展開後の結果が表示されます。

### 3. apply — 変更を適用

```bash
# dry-run で安全に確認
chezmoi apply --dry-run

# 適用
chezmoi apply
```

### 4. test — 動作確認

```bash
# 新しいシェルを起動して確認
zsh

# zsh の起動時間を確認
time zsh -i -c exit
```

### 5. commit & push

```bash
chezmoi cd
git add -A
git commit -m "feat: add new alias"
git push
```

## chezmoi diff / apply の使い分け

| コマンド | 用途 |
|---------|------|
| `chezmoi diff` | 変更内容の確認（読み取り専用） |
| `chezmoi apply --dry-run` | apply のシミュレーション |
| `chezmoi apply` | 変更の適用 |
| `chezmoi apply --verbose` | 適用内容を詳細表示 |

:::message
`chezmoi diff` は `apply` する前に必ず実行する習慣をつけましょう。特にテンプレートファイルの場合、意図しない展開結果になることがあります。
:::

## Makefile による自動化

[shunk031/dotfiles](https://github.com/shunk031/dotfiles) では Makefile でよく使うコマンドを自動化しています。

```makefile
.PHONY: apply diff update

apply:
	chezmoi apply

diff:
	chezmoi diff

update:
	chezmoi update

test:
	bats tests/

lint:
	shellcheck home/.chezmoiscripts/**/*.sh
```

Makefile を使うことで、複数コマンドの実行やテストの自動化が容易になります。

## watchexec で変更監視

[watchexec](https://github.com/watchexec/watchexec) を使うと、ファイル変更時に自動で `chezmoi apply` を実行できます。

```bash
# ソースディレクトリの変更を監視して自動適用
watchexec -w ~/.local/share/chezmoi/home -- chezmoi apply
```

設定ファイルを試行錯誤する際に便利です。

## Docker でクリーン環境テスト

新しいマシンでの `chezmoi init` が正しく動作するか、Docker で検証できます。

```dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl git sudo

# テスト用ユーザー作成
RUN useradd -m -s /bin/zsh testuser && \
    echo "testuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser

# dotfiles を適用
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply username
```

```bash
# ビルドして確認
docker build -t dotfiles-test .
docker run -it dotfiles-test zsh
```

クリーン環境での動作を確認することで、新しいマシンへの展開時のトラブルを事前に防げます。

## bats によるシェルスクリプトテスト

[bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System) は、シェルスクリプト用のテストフレームワークです。mise で管理しています。

```bash
# tests/test_aliases.bats
@test "ls alias uses eza" {
    source ~/.config/alias/common.sh
    run type ls
    [[ "$output" == *"eza"* ]]
}

@test "fd command is available" {
    run command -v fd
    [ "$status" -eq 0 ]
}
```

```bash
# テストの実行
bats tests/
```

## zsh 起動時間ベンチマーク

dotfiles のパフォーマンスを定量的に評価するには、zsh の起動時間を計測します。

```bash
# 基本的な計測
time zsh -i -c exit

# 10回計測して平均を取る
for i in {1..10}; do time zsh -i -c exit; done 2>&1 | grep real

# zprof でプロファイリング
# .zshrc の先頭に追加: zmodload zsh/zprof
# .zshrc の末尾に追加: zprof
zsh -i -c exit
```

zsh-defer を使用している場合、起動時間は通常 **100ms 以下** になるはずです。

## Conventional Commits

コミットメッセージは [Conventional Commits](https://www.conventionalcommits.org/) 形式を推奨します。

| プレフィックス | 用途 | 例 |
|--------------|------|-----|
| `feat:` | 新機能 | `feat: add fzf preview configuration` |
| `fix:` | バグ修正 | `fix: correct fd symlink path` |
| `docs:` | ドキュメント | `docs: update README` |
| `refactor:` | リファクタリング | `refactor: split plugins.toml` |
| `chore:` | その他 | `chore: update mise version` |

```bash
git commit -m "feat: add bat preview to fzf Ctrl+T"
```

## CI/CD (GitHub Actions)

GitHub Actions で dotfiles の CI を構築できます。

```yaml
# .github/workflows/test.yml
name: Test dotfiles
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    env:
      CI: true  # age 暗号化を無効化
    steps:
      - uses: actions/checkout@v4
      - name: Install chezmoi
        run: sh -c "$(curl -fsLS get.chezmoi.io)"
      - name: Apply dotfiles
        run: chezmoi init --apply --source .
      - name: Run tests
        run: bats tests/
```

`CI=true` 環境変数を設定することで、age 暗号化が無効化され、秘密鍵なしでもテストが実行できます。

## GitHub 連携と Zenn デプロイ

このリポジトリは GitHub と Zenn を連携しており、`books/` ディレクトリの内容が自動的に Zenn に反映されます。

```
dotfiles リポジトリ
├── home/          # chezmoi source（dotfiles 本体）
├── books/         # Zenn Book（この Book）
└── install/       # インストールスクリプト
```

dotfiles の管理とドキュメントの公開を1つのリポジトリで完結させています。
