---
title: "dotfiles とは何か"
---

# dotfiles とは何か

## dotfiles の正体

Unix 系 OS では、`.` で始まるファイルやディレクトリは「隠しファイル」として扱われます。`ls` コマンドでは表示されず、`ls -a` で初めて見えるファイルです。

```bash
$ ls -a ~
.  ..  .bashrc  .gitconfig  .ssh  .zshrc  Documents  Downloads
```

これらの隠しファイルの多くは、各種ツールやシェルの**設定ファイル**です。これらを総称して **dotfiles** と呼びます。

代表的な dotfiles:

| ファイル | 役割 |
|---------|------|
| `~/.zshrc` | zsh シェルの設定 |
| `~/.bashrc` | bash シェルの設定 |
| `~/.gitconfig` | Git の設定 |
| `~/.ssh/config` | SSH の接続設定 |
| `~/.config/` | XDG Base Directory に準拠した各種設定 |

## なぜ dotfiles を管理するのか

### 1. マシン間での環境共有

新しいマシンをセットアップするとき、すべての設定を1からやり直すのは非効率です。dotfiles を Git で管理しておけば、`git clone` するだけで同じ環境を再現できます。

### 2. バックアップ

マシンが壊れた場合でも、dotfiles がリモートリポジトリにあれば設定を失いません。

### 3. 再現性

「このマシンではこの設定にしたはず」という曖昧な記憶に頼らず、バージョン管理された正確な設定を保持できます。

### 4. 変更履歴の追跡

Git で管理することで「いつ、何を、なぜ変えたか」の履歴が残ります。設定を壊してしまっても、簡単に以前の状態に戻せます。

## 管理手法の比較

dotfiles の管理には様々なアプローチがあります。

### 手動コピー

最もシンプルな方法。設定ファイルを USB メモリや cloud storage で手動コピーします。

```bash
# やることは単純だが...
cp ~/.zshrc /backup/
cp ~/.gitconfig /backup/
```

**問題点**: ファイルの同期が手作業、どちらが最新か分からなくなる、漏れが発生する。

### symlink 管理 (GNU Stow)

dotfiles を1つのディレクトリにまとめ、シンボリックリンクで配置する方法です。

```bash
# stow でシンボリックリンクを作成
$ tree dotfiles/
dotfiles/
├── zsh/
│   └── .zshrc
└── git/
    └── .gitconfig

$ cd dotfiles && stow zsh git
# ~/.zshrc -> dotfiles/zsh/.zshrc (symlink)
```

**利点**: シンプルで理解しやすい
**問題点**: テンプレート機能がない、マシンごとの差異に対応しにくい

### dotbot

YAML で管理対象と配置先を定義するツールです。

```yaml
# install.conf.yaml
- link:
    ~/.zshrc: zsh/.zshrc
    ~/.gitconfig: git/.gitconfig
- shell:
    - [brew bundle, "Install Homebrew packages"]
```

**利点**: 宣言的な設定、インストールスクリプトと統合可能
**問題点**: テンプレート機能が弱い

### chezmoi（この Book で採用）

テンプレートエンジン、暗号化、クロスプラットフォーム対応を備えた本格的な dotfiles マネージャーです。

```bash
# ファイルをコピーして管理（symlink ではない）
$ chezmoi add ~/.zshrc
$ chezmoi edit ~/.zshrc
$ chezmoi apply
```

**利点**:
- Go template によるテンプレート機能
- age / GPG による暗号化
- OS / マシンごとの条件分岐
- ファイルのコピーベース（symlink の問題を回避）
- スクリプトによる自動セットアップ

**この Book では chezmoi を使った管理方法を詳しく解説していきます。**

:::message
chezmoi は「シェモア」と読むそうです（僕はずっとチェズモイと読んでました:hugging_face:。日本人相手なら逆にチェズモイって呼んだ方が伝わりそうでもある）。
フランス語で「私の家」を意味する "chez moi" に由来しているそうです。

:::

## 管理手法の選び方

| 要件 | 手動 | Stow | dotbot | chezmoi |
|------|:----:|:----:|:------:|:-------:|
| シンプルさ | ○ | ○ | △ | △ |
| テンプレート | × | × | △ | ○ |
| 暗号化 | × | × | × | ○ |
| クロスプラットフォーム | × | △ | △ | ○ |
| 自動セットアップ | × | × | ○ | ○ |
| 学習コスト | 低 | 低 | 中 | 中 |

1〜2台のマシンでシンプルに管理するなら **Stow**、複数の OS やマシンをまたいで管理するなら **chezmoi** がおすすめです。
