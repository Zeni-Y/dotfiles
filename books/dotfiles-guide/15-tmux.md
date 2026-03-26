---
title: "tmux でターミナルマルチプレクサ入門"
---

# tmux でターミナルマルチプレクサ入門

[ターミナル・シェル・エディタの基礎知識](./02-terminal-shell-editor)のチャプターでターミナルマルチプレクサの概要を紹介しました。この章では、筆者が使っている **tmux** を掘り下げて解説します。

## ターミナルマルチプレクサとは

ターミナルマルチプレクサは、**1 つのターミナルウィンドウの中に複数のペイン・ウィンドウ・セッションを作れる**ツールです。代表的なものに長い歴史を持つ **tmux** と、Rust 製の新しい選択肢である **Zellij** があります。

主なメリットは以下の通りです:

- **画面分割**: エディタ・サーバーログ・Git 操作を 1 画面で同時に確認
- **セッション維持**: SSH 接続が切れてもサーバー上のセッションが生き続ける
- **コンテキスト切り替え**: プロジェクトごとにセッションを分けて管理

## なぜ tmux を選ぶのか

tmux は **2007 年から続く成熟したツール**で、Linux/macOS 問わずほぼすべての環境で動作します。最大の強みはその**安定性・実績・豊富なエコシステム**です。

```
┌─────────────────────────────────────────────────────────────────┐
│ tmux (my-project)                                               │
│                                                                 │
│  ┌─── ウィンドウ 1: dev ──────────────────────────────────────┐ │
│  │                                                            │ │
│  │  ┌── ペイン 1 ──────────┬── ペイン 2 ─────────────────┐   │ │
│  │  │ $ nvim src/main.rs   │ $ cargo watch -x run          │   │ │
│  │  │                      │ Compiling myapp v0.1          │   │ │
│  │  │                      │ Running `target/debug/myapp`  │   │ │
│  │  ├──────────────────────┴──────────────────────────────┤   │ │
│  │  │ $ git log --oneline -5                               │   │ │
│  │  └──────────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  [1] dev  [2] server  [3] logs                ← ウィンドウ一覧  │
└─────────────────────────────────────────────────────────────────┘
```

### tmux と Zellij の比較

| 観点           | tmux                                 | Zellij                        |
| -------------- | ------------------------------------ | ----------------------------- |
| 歴史・安定性   | **2007 年〜。非常に成熟**            | 2021 年〜。活発に開発中       |
| 言語           | C                                    | Rust                          |
| 学習コスト     | 中程度（設定次第でかなり快適に）     | 低い（画面にヒントが出る）    |
| デフォルト設定 | 最小限。カスタマイズ前提             | すぐ使えるデフォルト          |
| プラグイン     | **TPM で豊富なプラグイン**           | WebAssembly ベースで拡張可能  |
| 設定ファイル   | `~/.config/tmux/tmux.conf`           | `~/.config/zellij/config.kdl` |
| セッション復元 | **tmux-resurrect + continuum**       | 組み込みで復元可能            |
| エコシステム   | **非常に豊富**                       | 成長中                        |
| サーバー環境   | **デフォルトで入っていることも多い** | 要インストール                |

:::message
tmux と Zellij はどちらも優秀なツールです。この dotfiles では **tmux** を採用しています。その理由はサーバー環境との親和性（デフォルトでインストール済みのことが多い）と、TPM による豊富なプラグインエコシステムです。
:::

## インストール

### Ubuntu / Debian

```bash
$ sudo apt-get install tmux
```

### macOS（Homebrew）

```bash
$ brew install tmux
```

### chezmoi での自動インストール

この dotfiles の `chezmoi apply` 実行時に tmux と TPM が自動でインストールされます:

```bash
# chezmoi apply を実行すると自動でインストールされる
$ chezmoi apply
```

インストール後、バージョンを確認しましょう:

```bash
$ tmux -V
# → tmux 3.4
```

:::message
tmux 3.1 以降で XDG Base Directory（`~/.config/tmux/tmux.conf`）に対応しています。この dotfiles では XDG パスを使用しています。
:::

## 基本概念: セッション・ウィンドウ・ペイン

tmux は 3 層の階層構造を持っています:

```
セッション（Session）           ← プロジェクト単位
├── ウィンドウ 1（Window）      ← タブのようなもの
│   ├── ペイン A
│   └── ペイン B
├── ウィンドウ 2（Window）
│   ├── ペイン C
│   └── ペイン D
└── ウィンドウ 3（Window）
    └── ペイン E
```

| 概念       | 説明                                       | GUI での対応           |
| ---------- | ------------------------------------------ | ---------------------- |
| セッション | 最上位の作業単位。プロジェクトごとに分ける | ブラウザのプロファイル |
| ウィンドウ | セッション内の画面切り替え単位             | ブラウザのタブ         |
| ペイン     | ウィンドウ内の分割された各領域             | 画面分割               |

## プレフィックスキーとキーバインド

tmux のすべての操作は **プレフィックスキー** から始まります。この dotfiles では `Ctrl+t` をプレフィックスに設定しています。

```
操作の流れ:
  Ctrl+t  →  次のキー
  (プレフィックス)    (コマンド)
```

:::message
デフォルトの tmux はプレフィックスが `Ctrl+b` です。この dotfiles では `Ctrl+t` に変更しています。ターミナル上で `Ctrl+t` を使う他のツールとの競合に注意してください。
:::

## 基本操作

この dotfiles のカスタムキーバインドに基づいた操作一覧です。

### セッション操作

| キー・コマンド          | 操作                           |
| ----------------------- | ------------------------------ |
| `tmux new -s <name>`    | 名前付きセッションを作成       |
| `tmux ls`               | セッション一覧を表示           |
| `tmux attach -t <name>` | セッションにアタッチ           |
| `Prefix + d`            | セッションをデタッチ           |
| `Prefix + $`            | セッション名を変更             |
| `Prefix + s`            | セッション一覧を表示・切り替え |

### ウィンドウ操作

| キー                        | 操作                       |
| --------------------------- | -------------------------- |
| `Prefix + c`                | 新しいウィンドウを作成     |
| `Prefix + ,`                | ウィンドウ名を変更         |
| `Prefix + &` / `Prefix + X` | ウィンドウを閉じる         |
| `Prefix + n`                | 次のウィンドウに移動       |
| `Prefix + p`                | 前のウィンドウに移動       |
| `Prefix + 1〜9`             | 番号でウィンドウに直接移動 |
| `Prefix + Ctrl+h`           | 前のウィンドウ（カスタム） |
| `Prefix + Ctrl+l`           | 次のウィンドウ（カスタム） |

### ペイン操作

| キー               | 操作                               |
| ------------------ | ---------------------------------- |
| `Prefix + \|`      | ペインを左右に分割                 |
| `Prefix + -`       | ペインを上下に分割                 |
| `Prefix + h/j/k/l` | ペインのフォーカスを移動（vim 風） |
| `Prefix + H/J/K/L` | ペインをリサイズ（5 セル単位）     |
| `Prefix + x`       | ペインを閉じる                     |
| `Prefix + z`       | ペインをズームイン/アウト          |
| `Prefix + {` / `}` | ペインを左右に移動                 |
| `Prefix + q`       | ペイン番号を表示                   |

### 設定リロード

| キー         | 操作                   |
| ------------ | ---------------------- |
| `Prefix + r` | `tmux.conf` をリロード |

### コピーモード

| キー           | 操作                  |
| -------------- | --------------------- |
| `Prefix + [`   | コピーモードに入る    |
| `v`            | 選択開始（vi モード） |
| `Ctrl+v`       | 矩形選択              |
| `y`            | コピーしてモード終了  |
| `Escape`       | コピーモードを終了    |
| `Ctrl+u` / `d` | 半ページスクロール    |
| `g` / `G`      | 先頭 / 末尾へジャンプ |
| `/`            | 検索                  |
| `n` / `N`      | 次 / 前の検索結果     |

:::message
コピーモードはデフォルトの tmux と同じ `Prefix + [` です。vi キーバインドを設定しているので、Vim ユーザーはすぐに慣れられます。
:::

## セッション管理

### セッションの作成と切り替え

```bash
# 名前付きセッションを作成してアタッチ
$ tmux new-session -s myproject

# すでに tmux の中にいる場合（:new-session コマンド）
$ tmux new -s another-project -d   # -d でデタッチ状態で作成

# セッション一覧を表示
$ tmux list-sessions
# → main: 2 windows (created Thu Jan  1 12:00:00 2026) [220x50]
# → myproject: 1 window (created Thu Jan  1 12:01:00 2026) [220x50]

# セッションにアタッチ（再接続）
$ tmux attach-session -t myproject
# または短縮形
$ tmux a -t myproject

# 直前のセッションにアタッチ
$ tmux a
```

### セッション切り替え（tmux 内から）

```
Prefix + s         → インタラクティブなセッション一覧（j/k で選択、Enter で切り替え）
Prefix + $         → 現在のセッション名を変更
Prefix + d         → デタッチ（バックグラウンドに移行）
```

### ショートカットとして fish 関数を使う

```fish
# ~/.config/fish/functions/t.fish
# t <session>: tmux セッションに接続（なければ作成）
function t
    set name (test -n "$argv[1]" && echo $argv[1] || echo "main")
    tmux new-session -A -s $name
end
```

これで `t myproject` と入力するだけで、セッションがなければ作成し、あれば接続できます。

## TPM とプラグイン

### TPM（Tmux Plugin Manager）のセットアップ

TPM はプラグインの管理ツールです。この dotfiles では `chezmoi apply` 時に自動インストールされます。

```bash
# 手動でインストールする場合
$ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### プラグインの操作

tmux を起動した状態で以下のキーを使います:

| キー             | 操作                     |
| ---------------- | ------------------------ |
| `Prefix + I`     | プラグインをインストール |
| `Prefix + U`     | プラグインを更新         |
| `Prefix + Alt+u` | 不要なプラグインを削除   |

### 導入プラグイン一覧

この dotfiles では以下のプラグインを使っています:

| プラグイン                           | 説明                                          |
| ------------------------------------ | --------------------------------------------- |
| `tmux-plugins/tpm`                   | プラグインマネージャ本体                      |
| `tmux-plugins/tmux-sensible`         | 多くの人が有効にする基本設定をまとめたもの    |
| `tmux-plugins/tmux-resurrect`        | セッションの手動保存・復元                    |
| `tmux-plugins/tmux-continuum`        | セッションの自動保存・起動時自動復元          |
| `tmux-plugins/tmux-prefix-highlight` | プレフィックス押下時にステータスバーで通知    |
| `catppuccin/tmux`                    | Catppuccin Mocha テーマ（WezTerm と色合わせ） |

## セッション保存・復元

### tmux-resurrect

`tmux-resurrect` はセッションの構造（ウィンドウ/ペイン構成・カレントディレクトリ・実行コマンド）を保存・復元します。

```
保存: Prefix + Ctrl+s   → ~/.local/share/tmux/resurrect/ に保存
復元: Prefix + Ctrl+r   → 最後に保存した状態に復元
```

### tmux-continuum

`tmux-continuum` は resurrect を自動化します:

- **自動保存**: 15 分ごとに自動で保存
- **自動復元**: tmux 起動時に最後の状態を自動復元

```tmux
# tmux.conf の設定（この dotfiles では設定済み）
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'
```

PC 再起動後に tmux を起動するだけで、前回の作業環境が自動的に復元されます。

## 設定ファイルの解説

この dotfiles の `tmux.conf` の主要な設定を解説します。

### プレフィックスキー

```tmux
unbind C-b          # デフォルトの Ctrl+b を無効化
set -g prefix C-t   # Ctrl+t をプレフィックスに設定
bind C-t send-prefix  # Ctrl+t × 2 で端末にそのまま送信
```

### ウィンドウ・ペイン番号

```tmux
set -g base-index 1        # ウィンドウ番号を 1 から（0 ではなく）
setw -g pane-base-index 1  # ペイン番号も 1 から
set -g renumber-windows on # ウィンドウを消したとき番号を詰める
```

数字キー `Prefix + 1` が最初のウィンドウを指すようになり、直感的に操作できます。

### 色の設定

```tmux
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
```

`Tc` フラグで True Color（24 ビットカラー）が有効になります。Neovim やスターシップのプロンプトが正しい色で表示されます。

### vi キーバインド

```tmux
setw -g mode-keys vi
```

コピーモードで Vim のキーバインドが使えるようになります。

### ペイン分割キー

```tmux
bind | split-window -hc "#{pane_current_path}"
bind - split-window -vc "#{pane_current_path}"
```

`|` で左右分割、`-` で上下分割。`#{pane_current_path}` により、現在のディレクトリを引き継いで新しいペインが開きます。

## 実践的なワークフロー

### 1. プロジェクトごとにセッションを分ける

```bash
# プロジェクト A を開始
$ tmux new -s project-a
(tmux 内で作業)

# デタッチ: Prefix + d
# プロジェクト B に切り替え
$ tmux new -s project-b

# プロジェクト A に戻る
$ tmux a -t project-a
```

### 2. 開発環境の標準ペイン構成

```
┌───────────────────────────────────────────────┐
│  Neovim（左: 70%）    │  ビルド/テスト（右上）  │
│                       │  cargo watch -x test   │
│                       ├────────────────────────│
│                       │  lazygit（右下）        │
└───────────────────────────────────────────────┘
```

```bash
# セッション作成
$ tmux new -s dev

# Neovim を開く（メインペイン）
$ nvim .

# Prefix + | で右に分割 → ビルドコマンド
# Prefix + - で下に分割 → lazygit
```

### 3. SSH リモートサーバーでの活用

```
SSH 接続が切れたとき:

tmux なし:  PC ──✕── サーバー → 実行中のプロセスが終了
tmux あり:  PC ──✕── サーバー → セッションは生き続ける
            PC ──再接続──→ tmux a で復帰
```

サーバー上で長時間タスク（ビルド・学習・データ処理など）を実行するときに絶大な効果を発揮します。

### 4. SSH agent forwarding を維持する

tmux のセッション維持機能には一つ落とし穴があります。**SSH agent forwarding が切れる**問題です。

SSH 接続するたびに `/tmp/ssh-XXXX/agent.PID` のような一時ソケットが作られ、環境変数 `SSH_AUTH_SOCK` がそのパスを指します。しかし tmux セッション内の環境変数は**最初の SSH 接続時のまま更新されない**ため、デタッチ → SSH 再接続 → アタッチすると、古いソケットパス（既に削除済み）を参照してしまいます。

```
1 回目の SSH 接続:
  SSH_AUTH_SOCK=/tmp/ssh-abc123/agent.1000  ← tmux セッションに記憶される

SSH 切断 → /tmp/ssh-abc123/ は削除される

2 回目の SSH 接続:
  SSH_AUTH_SOCK=/tmp/ssh-xyz789/agent.2000  ← 新しいソケット
  しかし tmux 内はまだ /tmp/ssh-abc123/agent.1000 を見ている → エラー
```

```bash
# tmux 再アタッチ後に発生する典型的なエラー
$ ssh-add -l
Error connecting to agent: No such file or directory
```

#### 解決策: 固定パスのシンボリックリンク

`~/.ssh/ssh_auth_sock` という固定パスにシンボリックリンクを作り、常に最新のソケットを指すようにします。

```fish
# ~/.config/fish/conf.d/ssh-agent-relay.fish

if set -q SSH_AUTH_SOCK; and test "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock"
    # 実際のソケットが存在する場合のみシンボリックリンクを更新
    if test -S "$SSH_AUTH_SOCK"
        mkdir -p $HOME/.ssh
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
    end
    set -gx SSH_AUTH_SOCK "$HOME/.ssh/ssh_auth_sock"
end
```

この仕組みは以下のように動作します:

1. **SSH 接続時**: 新しいシェルが起動し、`conf.d/` のスクリプトが実行される。実際のソケットへのシンボリックリンクを `~/.ssh/ssh_auth_sock` に作成し、`SSH_AUTH_SOCK` を固定パスに書き換える
2. **tmux 内のシェル**: `SSH_AUTH_SOCK` は固定パス `~/.ssh/ssh_auth_sock` を指しているため、シンボリックリンクの先が更新されれば自動的に新しいソケットに到達する
3. **再アタッチ後**: 新しい SSH 接続時にシンボリックリンクが更新済みなので、tmux 内の古いシェルからも `ssh-add -l` が正常に動作する

### 5. よく使う tmux コマンドのまとめ

```
セッション操作:
  tmux                  → 新しいセッションを開始
  tmux new -s <name>    → 名前付きセッションを開始
  tmux ls               → セッション一覧
  tmux a                → 直前のセッションにアタッチ
  tmux a -t <name>      → 指定セッションにアタッチ
  tmux kill-session -t <name>  → セッションを削除

プレフィックス内操作（Prefix = Ctrl+t）:
  Prefix + d    → デタッチ
  Prefix + s    → セッション一覧・切り替え
  Prefix + c    → 新規ウィンドウ
  Prefix + ,    → ウィンドウ名変更
  Prefix + 1-9  → ウィンドウ直接移動
  Prefix + |    → 左右分割
  Prefix + -    → 上下分割
  Prefix + h/j/k/l → ペイン移動
  Prefix + z    → ペインズーム
  Prefix + [    → コピーモード
  Prefix + r    → 設定リロード
  Prefix + Ctrl+s → セッション保存（resurrect）
  Prefix + Ctrl+r → セッション復元（resurrect）
```

## chezmoi での管理

この dotfiles では tmux 設定を chezmoi で管理しています:

```
home/dot_config/tmux/
  tmux.conf      # メイン設定
```

`chezmoi apply` で `~/.config/tmux/tmux.conf` に配置されます。

### 設定変更の反映

```bash
# chezmoi でファイルを編集
$ chezmoi edit ~/.config/tmux/tmux.conf

# 変更を適用
$ chezmoi apply

# tmux 内で設定をリロード（Prefix + r）
```

## トラブルシューティング

### プラグインが動作しない

TPM のインストールを確認します:

```bash
$ ls ~/.tmux/plugins/tpm
# ディレクトリが存在するか確認

# TPM を手動インストール
$ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

tmux を起動後、`Prefix + I` でプラグインをインストールします。

### 色がおかしい

```bash
# ターミナルが True Color に対応しているか確認
$ printf '\033[38;2;255;100;0mTRUECOLOR\033[0m\n'
# オレンジ色のテキストが表示されれば OK
```

WezTerm は True Color に対応しているので、通常は問題ありません。

### Neovim で `escape-time` の警告が出る

`tmux.conf` で `set -sg escape-time 10` が設定されているか確認します。Neovim は 0 か 10 を推奨しています。

## 参考リンク

- [tmux 公式 GitHub](https://github.com/tmux/tmux) — ソースコード・Wiki・リリースノート
- [tmux Wiki: Installing](https://github.com/tmux/tmux/wiki/Installing) — 各 OS へのインストール手順
- [TPM: Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) — プラグインマネージャ
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — セッション保存・復元
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) — 自動保存・復元
- [catppuccin/tmux](https://github.com/catppuccin/tmux) — Catppuccin テーマ
- [shunk031/dotfiles](https://github.com/shunk031/dotfiles) — この設定を参考にした dotfiles
- [MIT: The Missing Semester — Command-line Environment](https://missing.csail.mit.edu/2020/command-line/)（[日本語訳](https://missing-semester-jp.github.io/2020/command-line/)）— ターミナルマルチプレクサの基礎概念
