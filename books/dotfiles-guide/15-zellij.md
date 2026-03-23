---
title: "Zellij でターミナルマルチプレクサ入門"
---

# Zellij でターミナルマルチプレクサ入門

[ターミナル・シェル・エディタの基礎知識](./02-terminal-shell-editor)のチャプターでターミナルマルチプレクサの概要を紹介しました。この章では、筆者が使っている **Zellij** を掘り下げて解説します。

## ターミナルマルチプレクサとは

ターミナルマルチプレクサは、**1 つのターミナルウィンドウの中に複数のペイン・タブ・セッションを作れる**ツールです。代表的なものに長い歴史を持つ **tmux** と、Rust 製の新しい選択肢である **Zellij** があります。

主なメリットは以下の通りです:

- **画面分割**: エディタ・サーバーログ・Git 操作を 1 画面で同時に確認
- **セッション維持**: SSH 接続が切れてもサーバー上のセッションが生き続ける
- **コンテキスト切り替え**: プロジェクトごとにセッションを分けて管理

## なぜ Zellij を選ぶのか

tmux も Zellij もどちらも優秀なターミナルマルチプレクサで、おすすめできるツールです。しかし、筆者は **Zellij** を推します。最大の理由は、**画面上に常にショートカットキーが表示されている**ことです。

```
┌─────────────────────────────────────────────────────────────────┐
│ Zellij (zellij-session)                                         │
│                                                                 │
│  ┌─── ペイン 1 ──────────┬─── ペイン 2 ─────────┐              │
│  │ $ vim src/main.rs     │ $ cargo watch -x run  │              │
│  │                       │ Compiling myapp v0.1  │              │
│  │                       │ Running `target/...`  │              │
│  ├───────────────────────┴──────────────────────┤              │
│  │ $ git log --oneline -5                        │              │
│  └───────────────────────────────────────────────┘              │
│                                                                 │
│ Tab 1 [main] | Tab 2 [server] | Tab 3 [docs]                   │
│ Ctrl+p <PANE> | Ctrl+t <TAB> | Ctrl+n <RESIZE> | Ctrl+s <SEARCH>│
│ ↑ 今どのモードで何のキーが使えるか、常に画面下部に表示される       │
└─────────────────────────────────────────────────────────────────┘
```

tmux では `Ctrl+b` のプレフィックスキーに続くキーバインドを**暗記する必要があります**。一方 Zellij は、モードに入ると使えるキーが画面下部のステータスバーにリアルタイムで表示されるため、**マニュアルを見なくても操作できます**。

### tmux と Zellij の比較

| 観点           | tmux                           | Zellij                           |
| -------------- | ------------------------------ | -------------------------------- |
| 歴史・安定性   | 2007 年〜。非常に成熟          | 2021 年〜。活発に開発中          |
| 言語           | C                              | Rust                             |
| 学習コスト     | 高い（キーバインド暗記が必要） | **低い（画面にヒントが出る）**   |
| デフォルト設定 | 最小限。カスタマイズ前提       | **すぐ使える良いデフォルト**     |
| プラグイン     | 限定的                         | **WebAssembly ベースで拡張可能** |
| 設定ファイル   | `~/.tmux.conf`                 | `~/.config/zellij/config.kdl`    |
| セッション復元 | 手動（tmux-resurrect 等）      | **組み込みで復元可能**           |
| エコシステム   | 非常に豊富                     | 成長中                           |

:::message
tmux は長年の実績があり、サーバー環境ではデフォルトでインストールされていることも多い定番ツールです。Zellij を推す理由はあくまで**初心者にとっての使いやすさ**と**モダンな設計思想**に基づいています。用途や環境に応じて使い分けるのがベストです。
:::

## インストール

### macOS（Homebrew）

```bash
$ brew install zellij
```

### Ubuntu / Debian

```bash
$ sudo apt install zellij
```

### Cargo（Rust）

```bash
$ cargo install --locked zellij
```

### お試し（インストール不要）

```bash
$ bash <(curl -L https://zellij.dev/launch)
```

インストール後、バージョンを確認しましょう:

```bash
$ zellij --version
# → zellij 0.41.2
```

## 基本概念: セッション・タブ・ペイン

Zellij は 3 層の階層構造を持っています:

```
セッション（Session）
├── タブ 1（Tab）
│   ├── ペイン A
│   └── ペイン B
├── タブ 2（Tab）
│   ├── ペイン C
│   ├── ペイン D
│   └── ペイン E（フローティング）
└── タブ 3（Tab）
    └── ペイン F
```

| 概念       | 説明                                       | tmux での対応 |
| ---------- | ------------------------------------------ | ------------- |
| セッション | 最上位の作業単位。プロジェクトごとに分ける | session       |
| タブ       | セッション内の画面切り替え単位             | window        |
| ペイン     | タブ内の分割された各領域                   | pane          |

## 基本操作

### モードベースのキーバインド

Zellij は **Vim に似たモード切替方式**を採用しています。まず目的のモードに入り、そこで操作を行います。全モードのキーバインドは画面下部に表示されるので、暗記不要です。

### よく使う操作一覧

#### ペイン操作（`Ctrl+p` でペインモード）

| キー                  | 操作                           |
| --------------------- | ------------------------------ |
| `n`                   | 新しいペインを開く             |
| `d`                   | ペインを下に分割               |
| `r`                   | ペインを右に分割               |
| `x`                   | フォーカス中のペインを閉じる   |
| `f`                   | ペインをフルスクリーン切り替え |
| `w`                   | フローティングペインの切り替え |
| `h` / `j` / `k` / `l` | フォーカスを移動（← ↓ ↑ →）    |

#### タブ操作（`Ctrl+t` でタブモード）

| キー      | 操作                 |
| --------- | -------------------- |
| `n`       | 新しいタブを作成     |
| `x`       | 現在のタブを閉じる   |
| `r`       | タブ名を変更         |
| `h` / `l` | 前 / 次のタブに移動  |
| `1`〜`9`  | 番号でタブに直接移動 |

#### セッション操作（`Ctrl+o` でセッションモード）

| キー | 操作                                       |
| ---- | ------------------------------------------ |
| `d`  | セッションをデタッチ（バックグラウンドに） |
| `w`  | セッションマネージャを開く                 |

#### リサイズ（`Ctrl+n` でリサイズモード）

| キー                  | 操作               |
| --------------------- | ------------------ |
| `h` / `j` / `k` / `l` | ペインサイズを変更 |
| `+` / `-`             | サイズを増減       |

#### その他

| キー     | 操作          |
| -------- | ------------- |
| `Ctrl+s` | 検索モード    |
| `Ctrl+q` | Zellij を終了 |

:::message
`Esc` キーでいつでもノーマルモードに戻れます。モードが分からなくなったらとりあえず `Esc` を押しましょう。
:::

## セッション管理

### セッションの作成と切り替え

```bash
# 名前付きセッションを作成
$ zellij -s myproject

# 既存セッションの一覧を表示
$ zellij ls
# → myproject [Created ... ago]
# → another-project [Created ... ago]

# セッションにアタッチ（再接続）
$ zellij attach myproject
# または短縮形
$ zellij a myproject
```

### セッション復元（Session Resurrection）

Zellij の特徴的な機能の一つが**セッション復元**です。tmux では `tmux-resurrect` などの外部プラグインが必要ですが、Zellij は組み込みで対応しています。

```bash
# 終了したセッションも含めて一覧表示
$ zellij ls

# 終了したセッションを復元
$ zellij attach myproject --force-run-commands
```

ペインの構造・実行中のコマンド・スクロール履歴まで復元されるため、PC を再起動しても作業を続けられます。

## レイアウト

Zellij のレイアウト機能を使うと、**開発環境のペイン構成を KDL ファイルで定義**して一発で再現できます。

### レイアウトファイルの例

```kdl
// ~/.config/zellij/layouts/dev.kdl
layout {
    // メインの開発タブ
    tab name="code" focus=true {
        pane split_direction="vertical" {
            pane command="vim" {
                args "."
            }
            pane split_direction="horizontal" {
                pane command="cargo" {
                    args "watch" "-x" "run"
                }
                pane  // 空のシェル
            }
        }
    }
    // Git 操作用タブ
    tab name="git" {
        pane command="lazygit"
    }
    // ログ監視用タブ
    tab name="logs" {
        pane command="tail" {
            args "-f" "logs/app.log"
        }
    }
}
```

### レイアウトの使い方

```bash
# レイアウトを指定してセッションを開始
$ zellij --layout dev

# セッション名も付ける
$ zellij -s myproject --layout dev
```

レイアウトを活用すると、プロジェクトを開くたびに同じ環境がすぐに立ち上がります。

## プラグインシステム

Zellij は **WebAssembly（WASM）ベースのプラグインシステム**を持っています。

- **サンドボックス化**: プラグインは隔離されたメモリ空間で動作するため安全
- **クラッシュ耐性**: プラグインがクラッシュしても Zellij 本体は影響を受けない
- **言語対応**: 現在は Rust が公式サポート。WASI 対応言語なら理論上は利用可能

デフォルトで以下のプラグインが組み込まれています:

| プラグイン        | 説明                             |
| ----------------- | -------------------------------- |
| `status-bar`      | 画面下部のキーバインドヒント表示 |
| `tab-bar`         | タブの一覧表示                   |
| `strider`         | ファイルツリーブラウザ           |
| `session-manager` | セッション管理 UI                |

## 設定ファイル

Zellij の設定は KDL（KDL Document Language）形式で記述します。

```bash
# デフォルト設定を出力
$ zellij setup --dump-config > ~/.config/zellij/config.kdl
```

### 設定例

```kdl
// ~/.config/zellij/config.kdl

// テーマ設定
theme "catppuccin-mocha"

// デフォルトレイアウトの指定
default_layout "compact"

// マウスサポートを有効化
mouse_mode true

// コピー時の動作
copy_on_select true

// ペインフレームの表示
pane_frames true

// スクロールバッファサイズ
scroll_buffer_size 50000
```

:::details キーバインドのカスタマイズ例

```kdl
// Ctrl+g でロック解除してから操作するプリセットに変更
// （他のターミナルアプリとキーが衝突する場合に便利）
keybinds {
    // ノーマルモードのカスタマイズ
    normal {
        bind "Alt h" { MoveFocusOrTab "Left"; }
        bind "Alt l" { MoveFocusOrTab "Right"; }
        bind "Alt j" { MoveFocus "Down"; }
        bind "Alt k" { MoveFocus "Up"; }
    }
}
```

:::

## 実践的なワークフロー

### 1. プロジェクトごとにセッションを分ける

```bash
# プロジェクト A の作業を開始
$ zellij -s project-a --layout dev

# 一旦離れる（デタッチ: Ctrl+o → d）

# プロジェクト B に切り替え
$ zellij -s project-b --layout dev

# プロジェクト A に戻る
$ zellij a project-a
```

### 2. SSH リモートサーバーでの活用

```
SSH 接続が切れたとき:

Zellij なし:  PC ──✕── サーバー → 実行中のプロセスが終了
Zellij あり:  PC ──✕── サーバー → セッションは生き続ける
              PC ──再接続──→ zellij attach で復帰
```

リモートサーバーでの長時間タスク（ビルド、データ処理など）を安心して実行できます。

### 3. SSH agent forwarding を維持する

Zellij のセッション維持機能には一つ落とし穴があります。**SSH agent forwarding が切れる**問題です。

SSH 接続するたびに `/tmp/ssh-XXXX/agent.PID` のような一時ソケットが作られ、環境変数 `SSH_AUTH_SOCK` がそのパスを指します。しかし Zellij セッション内の環境変数は**最初の SSH 接続時のまま更新されない**ため、デタッチ → SSH 再接続 → アタッチすると、古いソケットパス（既に削除済み）を参照してしまいます。

```
1回目の SSH 接続:
  SSH_AUTH_SOCK=/tmp/ssh-abc123/agent.1000  ← Zellij セッションに記憶される

SSH 切断 → /tmp/ssh-abc123/ は削除される

2回目の SSH 接続:
  SSH_AUTH_SOCK=/tmp/ssh-xyz789/agent.2000  ← 新しいソケット
  しかし Zellij 内はまだ /tmp/ssh-abc123/agent.1000 を見ている → エラー
```

```bash
# Zellij 再アタッチ後に発生する典型的なエラー
$ ssh-add -l
Error connecting to agent: No such file or directory

$ git push  # SSH 署名やリモート接続も失敗する
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
2. **Zellij 内のシェル**: `SSH_AUTH_SOCK` は固定パス `~/.ssh/ssh_auth_sock` を指しているため、シンボリックリンクの先が更新されれば自動的に新しいソケットに到達する
3. **再アタッチ後**: 新しい SSH 接続時にシンボリックリンクが更新済みなので、Zellij 内の古いシェルからも `ssh-add -l` が正常に動作する

```
~/.ssh/ssh_auth_sock → /tmp/ssh-xyz789/agent.2000（常に最新）
                        ↑ SSH 接続のたびに ln -sf で更新
```

:::message
`conf.d/` に置いたスクリプトは `config.fish` より前に自動で読み込まれます。`SSH_AUTH_SOCK` が既に固定パスの場合はスキップするため、Zellij 内で新しいペインを開いたときの二重処理も防いでいます。
:::

### 4. セッションマネージャの活用

`Ctrl+o` → `w` でセッションマネージャが開きます。ここから:

- 既存セッションの一覧を確認
- セッションの切り替え
- 新しいセッションの作成

が GUI ライクな操作で行えます。

## 参考リンク

- [Zellij 公式サイト](https://zellij.dev/) — 機能紹介・チュートリアル・ドキュメントが充実
- [Zellij GitHub リポジトリ](https://github.com/zellij-org/zellij) — ソースコード・Issues・Discussions
- [Zellij ドキュメント: Keybindings](https://zellij.dev/documentation/keybindings) — 全キーバインドのリファレンス
- [Zellij ドキュメント: Layouts](https://zellij.dev/documentation/creating-a-layout) — レイアウト定義の詳細
- [Zellij ドキュメント: Plugins](https://zellij.dev/documentation/plugins) — プラグイン開発ガイド
- [MIT: The Missing Semester — Command-line Environment](https://missing.csail.mit.edu/2020/command-line/)（[日本語訳](https://missing-semester-jp.github.io/2020/command-line/)）— ターミナルマルチプレクサの基礎概念
