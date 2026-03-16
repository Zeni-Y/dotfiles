---
title: "Zed エディタ"
---

# Zed エディタ

[Zed](https://zed.dev/) は Rust 製の高速テキストエディタです。[Atom](https://github.com/atom/atom) の開発者が設計しており、パフォーマンスとコラボレーションを重視しています。

## エディタ比較 — なぜ Zed を選んだのか

コードエディタの選択肢は増えています。ここでは主要なエディタと Zed を比較し、筆者が Zed を選んだ理由を整理します。

### 主要エディタの比較

| | **Zed** | **VS Code** | **Cursor** |
|------|---------|-------------|------------|
| **基盤技術** | Rust + GPUI（ネイティブ） | Electron（Web ベース） | Electron（VS Code フォーク） |
| **起動時間** | 約 0.1〜0.2 秒 | 約 1〜2 秒 | 約 2〜3 秒 |
| **メモリ使用量** | 約 100〜200 MB | 約 700 MB〜1.2 GB | 約 500〜800 MB |
| **レンダリング** | GPU アクセラレーション（120fps） | Chromium レンダリング | Chromium レンダリング |
| **AI 機能** | エージェントパネル、インラインアシスト、Edit Prediction | GitHub Copilot 等の拡張機能 | AI ネイティブ（Tab 補完、エージェント） |
| **拡張機能** | 1,000+ | 60,000+ | VS Code 互換 |
| **コラボレーション** | ネイティブ（CRDT ベース、音声チャット付き） | Live Share 拡張 | なし |
| **価格** | 無料・OSS（Pro プランあり） | 無料 | 無料枠あり（Pro $20/月） |

### Zed の強み

- **圧倒的なパフォーマンス**: Electron ベースのエディタと比べて起動が 10 倍速く、メモリ消費が 75% 少ない[^7]。大規模ファイルや長時間の開発セッションでもストレスがない
- **AI がエディタの中核にある**: AI 機能が後付けの拡張ではなく、エディタ本体に統合されている。エージェントがファイルの読み書き・ターミナル実行・Web 検索までこなせる
- **ネイティブコラボレーション**: CRDT ベースのリアルタイム共同編集がビルトイン。セットアップに数秒しかかからない

### Zed の弱み

- **拡張機能エコシステムは発展途上**: VS Code の 60,000+ に対して 1,000+ 。ニッチな言語やツールのサポートが不足することがある
- **AI の成熟度**: Cursor は Tab 補完の精度やマルチエージェント並列実行で一歩先を行く
- **Windows サポートはまだ新しい**: macOS / Linux が主要ターゲット。Windows 版は 2024 年末にリリースされたばかり

### 筆者が Zed を選んだ理由

筆者が VS Code から Zed に移行した一番の理由は**メモリ消費量とレンダリング速度**です。VS Code は拡張機能を入れていくと簡単に 1GB を超えるメモリを消費し、大きなプロジェクトで明らかにもたつくことがありました。Zed に切り替えてからは、同じプロジェクトが 200MB 以下で動作し、スクロールやファイル切り替えも GPU レンダリングのおかげで体感が全く違います。

AI 機能も決め手のひとつです。Cursor も検討しましたが、「AI のためにエディタの軽さを犠牲にする」のは本末転倒に感じました。Zed は軽量なまま AI エージェント機能を備えているので、パフォーマンスと AI の両方を妥協せずに使えます。拡張機能の数は VS Code に及びませんが、普段使いに必要な言語サポートは揃っているので、実用上困ることはほぼありません。

## インストール

### macOS

```bash
# Homebrew でインストール（安定版）
brew install --cask zed

# プレビュー版
brew install --cask zed@preview
```

### Linux

```bash
# 公式インストールスクリプト（安定版）
curl -f https://zed.dev/install.sh | sh

# 特定のバージョンを指定
curl -f https://zed.dev/install.sh | ZED_VERSION=0.216.0 sh

# プレビュー版
curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh

# アンインストール
zed --uninstall
```

### Windows

```powershell
# winget でインストール
winget install -e --id ZedIndustries.Zed
```

または [Zed 公式サイト](https://zed.dev/download) から直接ダウンロードできます。

**システム要件:**
- DirectX 11 対応 GPU（2012年以降の PC であればほぼ対応）
- 最新の GPU ドライバ（NVIDIA / AMD / Intel / Qualcomm）
- x64（Intel, AMD）または Arm64（Qualcomm）プロセッサ

### WSL での利用

WSL 環境では、Zed は **Windows 側にインストール** して使用します。WSL 内のファイルには Zed のリモート開発機能でアクセスします。

```
[Windows ホスト]          [WSL (Ubuntu)]
Zed エディタ  ──接続──→  プロジェクトファイル
                          言語サーバー (LSP)
                          ターミナル
                          ~/.config/zed/settings.json
```

**WSL プロジェクトを開く手順:**

```
1. Ctrl + Shift + P でコマンドパレットを開く
      ↓
2. 「projects: open in wsl」を入力・実行
      ↓ WSL ディストリビューション一覧が表示される
3. 使用するディストリビューション（Ubuntu-24.04 等）を選択
      ↓ WSL 内のフォルダ一覧が表示される
4. フォルダを選択して開く
      ↓ WSL 側のファイルが Zed で編集可能になる
```

**WSL 利用時の注意点:**

- Windows 側の Zed から WSL 内のファイルを直接編集できる
- 言語サーバー、タスク、ターミナル、AI 機能はすべて WSL 側で動作する
- WSL 側にも `~/.config/zed/settings.json` を配置して設定をカスタマイズできる
- chezmoi で WSL 内の設定を管理すれば、ネイティブ Linux と同じ設定を共有可能

## 設定ファイルの配置先

OS によって設定ファイルの配置先が異なります。

| OS | 設定ディレクトリ | 設定ファイル |
|----|-----------------|-------------|
| macOS | `~/.zed/` | `~/.zed/settings.json` |
| Linux / WSL | `~/.config/zed/` | `~/.config/zed/settings.json` |
| Windows | `%APPDATA%\Zed\` | `%APPDATA%\Zed\settings.json` |

chezmoi で管理する場合、Linux / WSL 環境では `home/dot_config/zed/` に配置します。

```
home/dot_config/zed/
├── settings.json    # エディタ設定
└── keymap.json      # キーバインド設定
```

### settings.json

このリポジトリでは以下の設定を管理しています。

```jsonc
{
  // AI エージェント設定
  "agent": {
    "default_model": {
      "provider": "zed.dev",
      "model": "claude-sonnet-4-6",
      "enable_thinking": true,
      "effort": "high"
    }
  },
  // WSL 接続設定
  "wsl_connections": [
    {
      "distro_name": "Ubuntu-24.04",
      "projects": [{ "paths": ["/home/user"] }]
    }
  ],
  // SSH 接続設定
  "ssh_connections": [
    {
      "host": "my-server",
      "projects": [{ "paths": ["/home/user"] }]
    }
  ],
  // テレメトリ
  "telemetry": { "diagnostics": true, "metrics": false },
  // エディタ表示設定
  "base_keymap": "VSCode",
  "current_line_highlight": "all",
  "cursor_shape": "block",
  "cursor_blink": true,
  "colorize_brackets": true,
  "show_edit_predictions": true,
  "ensure_final_newline_on_save": true,
  "tab_bar": { "show": false },
  "minimap": { "show": "never" },
  // フォント設定
  "buffer_font_family": "Consolas",
  "buffer_font_fallbacks": ["Hack Nerd Font", "monospace"],
  "buffer_font_size": 15,
  "ui_font_size": 16,
  // テーマ設定
  "theme": {
    "mode": "dark",
    "light": "One Light",
    "dark": "One Dark"
  },
  // 自動保存
  "autosave": {
    "after_delay": { "milliseconds": 1000 }
  },
  // プロジェクトパネル
  "project_panel": {
    "auto_reveal_entries": false,
    "auto_fold_dirs": true,
    "indent_size": 6
  },
  // ターミナル設定
  "terminal": {
    "font_family": "JetBrainsMono Nerd Font",
    "line_height": "standard"
  }
}
```

**主な設定項目:**

| 設定 | 説明 |
|------|------|
| `agent` | AI エージェントのプロバイダ・モデル・思考モード設定 |
| `wsl_connections` | WSL ディストリビューションとプロジェクトパス |
| `ssh_connections` | SSH リモートサーバーの接続設定 |
| `base_keymap` | ベースキーマップ（`VSCode` 等） |
| `autosave` | 一定時間後に自動保存 |
| `buffer_font_family` / `buffer_font_fallbacks` | エディタフォントとフォールバック |
| `terminal.font_family` | ターミナルフォント |
| `theme` | ライト / ダークモードのテーマ |
| `project_panel` | プロジェクトパネルの表示設定 |

### keymap.json

カスタムキーバインドを管理します。

```json
[
  {
    "context": "Editor",
    "bindings": {
      "ctrl-shift-k": "editor::DeleteLine",
      "ctrl-shift-d": "editor::DuplicateLineDown"
    }
  },
  {
    "context": "Terminal",
    "bindings": {
      "ctrl-t": "workspace::NewTerminal"
    }
  }
]
```

## Vim モード

Zed は Vim キーバインドをネイティブでサポートしています。`settings.json` で `"vim_mode": true` を設定するだけで有効化できます。

### 対応している Vim 機能

- **ノーマルモード**: `h`, `j`, `k`, `l`, `w`, `b`, `e`, `0`, `$` 等の移動
- **ビジュアルモード**: `v`, `V`, `ctrl-v` での選択
- **オペレーター**: `d`, `c`, `y`, `>`, `<` 等
- **テキストオブジェクト**: `iw`, `aw`, `i"`, `a(` 等
- **検索**: `/`, `?`, `n`, `N`
- **マーク**: `m` + 文字でマーク設定、`'` + 文字でジャンプ

## 主要なキーバインド

キーバインドの一覧はリファレンスチャプターにもチートシートとしてまとめていますので、そちらも合わせてどうぞ。

### ファイル操作

| キー | 動作 |
|------|------|
| `Ctrl + P` | ファイルを素早く開く |
| `Ctrl + Shift + P` | コマンドパレット |
| `Ctrl + S` | ファイルを保存 |
| `Ctrl + W` | タブを閉じる |
| `Ctrl + G` | 指定行へジャンプ |

### 編集

| キー | 動作 |
|------|------|
| `Ctrl + D` | 同じ単語を追加選択 |
| `Ctrl + Shift + L` | 同じ単語をすべて選択 |
| `Ctrl + Shift + K` | 行を削除 |
| `Alt + Up/Down` | 行を移動 |
| `Alt + Shift + Up/Down` | 行を複製 |
| `Ctrl + /` | コメントトグル |

### パネル

| キー | 動作 |
|------|------|
| `Ctrl + B` | サイドバートグル |
| `Ctrl + J` | ターミナルトグル |
| `Ctrl + Shift + F` | プロジェクト内検索 |
| `Ctrl + Shift + E` | ファイルエクスプローラ |
| `Ctrl + \` | エディタを分割 |

### コード操作

| キー | 動作 |
|------|------|
| `F2` | シンボルのリネーム |
| `F12` | 定義へジャンプ |
| `Shift + F12` | 参照を表示 |
| `Ctrl + .` | コードアクション |

## AI 機能

Zed の AI 機能は拡張ではなくエディタ本体に統合されています。コードの生成・リファクタリング・質問・デバッグまで、エディタから離れずに AI と協業できます。

### AI 機能の全体像

Zed の AI は主に 4 つの機能で構成されています。

```
┌─────────────────────────────────────────────────────────┐
│ Agent Panel      │ 対話型のエージェント。ファイル編集・   │
│                  │ ターミナル実行・Web検索まで自律的に実行 │
├──────────────────┼──────────────────────────────────────┤
│ Inline Assistant │ 選択範囲をプロンプトで変換。           │
│                  │ マルチカーソル対応                     │
├──────────────────┼──────────────────────────────────────┤
│ Edit Prediction  │ キー入力ごとにリアルタイムで           │
│                  │ コード補完を提案（Tab で採用）         │
├──────────────────┼──────────────────────────────────────┤
│ Text Threads     │ エディタ内でのチャット。               │
│                  │ 通常のテキスト編集操作がそのまま使える │
└──────────────────┴──────────────────────────────────────┘
```

### 設定

`settings.json` の `agent` セクションでプロバイダとモデルを指定します。

```jsonc
{
  "agent": {
    "default_model": {
      "provider": "zed.dev",        // Zed Pro, anthropic, openai, google, ollama 等
      "model": "claude-sonnet-4-6"
    },
    // Edit Prediction のプロバイダ（デフォルトは Zeta）
    "edit_prediction_provider": "zeta",
    // インラインアシストで複数モデルの結果を比較
    "inline_alternatives": [
      { "provider": "zed.dev", "model": "gpt-4o-mini" }
    ]
  }
}
```

**利用方法は 2 つ:**
1. **Zed Pro**（月額サブスクリプション）: 設定不要ですぐに使える
2. **自分の API キー**: Anthropic、OpenAI、Google 等のキーを設定して利用

### Agent Panel（エージェントパネル）

Zed の AI の中核です。コマンドパレットから `agent: new thread` を実行するか、ステータスバーの ✨ アイコンをクリックして開きます。

**エージェントができること:**
- プロジェクト内のファイルを読み書き
- ターミナルコマンドの実行
- Web 検索
- 診断情報（エラー・警告）の参照
- MCP サーバー経由の外部ツール連携

| 操作 | キー |
|------|------|
| 新しいスレッド | `agent: new thread`（コマンドパレット） |
| 最近のスレッド一覧 | `Ctrl + Shift + J` |
| スレッド履歴 | `Ctrl + Shift + H` |
| モデル切り替え | `Ctrl + Alt + /` |
| 変更のレビュー | `Ctrl + Shift + R` |
| ツールプロファイル切り替え | `Shift + Tab` |

**コンテキストの追加**: メッセージ入力中に `@` を入力すると、ファイル・ディレクトリ・コードシンボル・過去のスレッド・画像などをコンテキストとして追加できます。

**ツールプロファイル:**

| プロファイル | 説明 |
|------------|------|
| **Write** | ファイル編集・ターミナル実行など全ツールを許可 |
| **Ask** | 読み取り専用。コードの質問や調査に |
| **Minimal** | ツールなし。一般的な会話に |

**チェックポイント**: エージェントがファイルを編集するたびにチェックポイントが作成されます。「Restore Checkpoint」ボタンで編集前の状態に戻せるので、安心して試行錯誤できます。

### Inline Assistant（インラインアシスト）

コードを選択して `Ctrl + Enter` を押すと、プロンプトを入力してその場でコードを変換できます。マルチカーソルで使うと、各カーソル位置に同じプロンプトが同時に適用されるのがすごくないですか？

```
1. コードを選択（または行にカーソルを置く）
     ↓
2. Ctrl + Enter でプロンプト入力欄が表示
     ↓
3. 「この関数にエラーハンドリングを追加して」等と入力
     ↓
4. AI がその場でコードを書き換え
```

ターミナルパネルでも動作するので、「このコマンドを fish シェル用に変換して」のような使い方もできます。

### Edit Prediction（コード予測）

キー入力のたびにリアルタイムでコード補完を提案してくれます。デフォルトのプロバイダは Zed が開発したオープンソースモデル **Zeta** で、GitHub Copilot や Supermaven も選択できます。`Tab` で提案を採用します。

Inline Assistant が「指示してから変換」なのに対し、Edit Prediction は「自動で先回りして提案」するイメージです。

### Text Threads（テキストスレッド）

エディタのバッファ内で AI とチャットできる機能です。通常のテキスト編集操作（マルチカーソル、検索置換等）がそのまま使えるのが特徴です。ただし、Text Threads からはファイルの自律的な編集はできません。コードの質問や調査に向いています。

### 外部エージェント連携

Zed は **Agent Client Protocol (ACP)** を通じて外部の CLI エージェントを統合できます。Claude Code（Claude Agent）、Gemini CLI、Codex などをエージェントパネルから直接利用可能です。

## コードの実行とデバッグ

VS Code では `Ctrl + R, Ctrl + R` でファイルを実行したり、F5 でデバッグを開始できますよね。Zed では**タスク**、**REPL**、**デバッガ**の 3 つの仕組みでこれを実現します。

### タスクでファイルを実行する

VS Code の「Run Python File」に相当する機能は、Zed では**タスク**で実現します。`Ctrl + Shift + R` でタスクピッカーを開き、実行するタスクを選択します。

**Python ファイルの実行タスク:**

`~/.config/zed/tasks.json` に以下を追加します。

```json
[
  {
    "label": "Python: Run File",
    "command": "python3",
    "args": ["$ZED_FILE"],
    "tags": ["python-test"]
  },
  {
    "label": "Python: Run File (uv)",
    "command": "uv",
    "args": ["run", "python", "$ZED_FILE"]
  }
]
```

| 操作 | キー |
|------|------|
| タスクピッカーを開く | `Ctrl + Shift + R` |
| 直近のタスクを再実行 | `editor: spawn nearest task` |
| タスクコマンドを編集してから実行 | タスクモーダルで `Tab` → 編集 → `Enter` |
| 修正付きワンショット実行 | `Alt + Enter` |

:::message
タスク変数 `$ZED_FILE` は現在開いているファイルのパスに、`$ZED_SYMBOL` はカーソル位置のシンボル名に展開されます。テスト実行時に「この関数だけテストする」のような使い方ができます。
:::

### REPL（対話的実行）

Python のコードを部分的に実行して結果を確認したい場合は、**REPL** が便利です。Jupyter カーネルを利用して、エディタ内でコードをインタラクティブに実行できます。

```
1. Python ファイルを開く
     ↓
2. 実行したいコードを選択（またはセルを定義）
     ↓
3. Ctrl + Shift + Enter で実行
     ↓
4. 結果がインラインで表示される
```

**セルの定義**: `# %%` コメントでコードをセルに分割できます。Jupyter Notebook のセルと同じ感覚で使えます。

```python
# %% データの読み込み
import pandas as pd
df = pd.read_csv("data.csv")

# %% 集計
df.groupby("category").sum()
```

**セットアップ**: Python 環境に `ipykernel` がインストールされている必要があります。

```bash
uv add ipykernel
# または
pip install ipykernel
```

### デバッガ

Zed には **Debug Adapter Protocol (DAP)** ベースのデバッガが組み込まれています[^8]。VS Code の F5 デバッグと同じ感覚で使えます。

**クイック起動**: `F4`（または `debugger: start`）を押すだけで、Zed がプロジェクトの言語を自動検出してデバッグ構成を提案してくれます。Python、Rust、Go、JavaScript 等に対応しています。

**Python のデバッグ構成**: プロジェクトルートに `.zed/debug.json` を作成します。

```json
[
  {
    "adapter": "Debugpy",
    "label": "Python: Debug Current File",
    "request": "launch",
    "program": "$ZED_FILE"
  },
  {
    "adapter": "Debugpy",
    "label": "Python: Debug with Args",
    "request": "launch",
    "program": "main.py",
    "args": ["--verbose"]
  }
]
```

:::message
`.vscode/launch.json` が既にある場合、`.zed/debug.json` がなければ Zed はそちらを読み込みます。VS Code からの移行がスムーズにできます。
:::

**デバッグ操作:**

| 操作 | キー |
|------|------|
| デバッグ開始 | `F4` / `debugger: start` |
| デバッグパネル表示 | `Ctrl + Shift + D` |
| ブレークポイント設定 | 行番号の左をクリック |
| ステップオーバー | `F10` |
| ステップイン | `F11` |
| ステップアウト | `Shift + F11` |
| 続行 | `F5` |

**ブレークポイントの種類**: 行番号を右クリックすると、条件付きブレークポイント（特定条件のときだけ停止）やログポイント（停止せずにログ出力）も設定できます。

**インライン値表示**: デバッグ中に変数の値がコード行の横にインラインで表示されます。Python、Rust、Go で対応しています。

### VS Code との対応表

| VS Code | Zed | 補足 |
|---------|-----|------|
| `Ctrl + R, Ctrl + R`（Run File） | `Ctrl + Shift + R` → タスク選択 | `tasks.json` でカスタマイズ |
| `F5`（デバッグ開始） | `F4` | `.zed/debug.json` で構成 |
| `F9`（ブレークポイント） | 行番号クリック | 条件付き・ログポイント対応 |
| `Ctrl + Shift + D`（デバッグパネル） | `Ctrl + Shift + D` | 同じキー |
| Jupyter Notebook | REPL（`Ctrl + Shift + Enter`） | `# %%` セル対応 |
| Run and Debug サイドバー | タスクピッカー + デバッグパネル | — |

## 拡張機能

Zed は拡張機能（Extensions）でカスタマイズできます。`Ctrl + Shift + X` で拡張機能パネルを開けます。VS Code ほどのエコシステムはまだありませんが、言語サポート・テーマ・ツール連携を中心に 1,000 以上の拡張機能が公開されています。

### おすすめの拡張機能

#### テーマ・アイコン

| 拡張機能 | 説明 |
|---------|------|
| **Catppuccin** | パステルカラーの人気テーマ。落ち着いた色合いで目が疲れにくい |
| **Catppuccin Icons** | Catppuccin に合わせたファイルアイコンテーマ |
| **Aura Theme** | ダークテーマの定番。GitHub Stars 数トップクラス |
| **Flexoki** | 「インクのような」配色のテーマ。コードにも散文にも合う |
| **One Dark** / **One Light** | Atom 由来の定番テーマ（Zed にもビルトイン） |

アイコンテーマは `icon theme selector: toggle` で切り替えられます。タブにファイルアイコンを表示するには `"tabs": { "file_icons": true }` を `settings.json` に追加します。

#### 言語サポート

Zed は多くの言語の LSP 連携をビルトインで備えていますが、追加の言語は拡張機能でサポートされます。

| 拡張機能 | 説明 |
|---------|------|
| **Python** | Pyright / Ruff 連携 |
| **Go** | gopls 連携 |
| **Rust** | rust-analyzer 連携（ビルトイン） |
| **TypeScript** | tsserver 連携（ビルトイン） |
| **Biome** | JavaScript / TypeScript の高速フォーマッタ・リンタ連携 |
| **Prisma** | Prisma スキーマのシンタックスハイライトと LSP |
| **TOML (Tombi)** | TOML ファイルのフォーマッタ / リンタ / LSP |

#### ツール連携

| 拡張機能 | 説明 |
|---------|------|
| **Discord Presence** | Discord のリッチプレゼンスに現在の作業状況を表示 |
| **MCP Server 拡張** | AI エージェントに外部ツール連携を追加（ファイル操作、Web 検索等） |

:::message
拡張機能の人気度は [awesome-zed-extensions](https://github.com/alanisme/awesome-zed-extensions) で GitHub Stars 順に確認できます。
:::

## 便利な機能（Hidden Gems）

Zed にはコマンドパレットから呼び出せる強力な機能が多数あります。公式ブログの「Hidden Gems」シリーズ[^1]で紹介されているものを中心に、知っておくと便利な機能をまとめます。

### マルチバッファ編集

Zed の最も強力な機能のひとつが**マルチバッファ**です。プロジェクト内検索（`Ctrl + Shift + F`）の結果はマルチバッファとして表示され、**検索結果をそのまま直接編集**できます。変更は元のファイルに即座に反映されるので、複数ファイルにまたがるリネームやリファクタリングがとても快適です。

| 操作 | キー |
|------|------|
| 同じ単語を追加選択 | `Ctrl + D` |
| すべての一致を選択 | `Ctrl + Shift + L` |
| 選択範囲をマルチバッファに集約 | コマンドパレット → `editor: open selections in multibuffer` |
| マルチバッファから元ファイルへジャンプ | 区切り行をクリック / `editor: open excerpts` |

### テキスト操作

コマンドパレットから呼び出せるテキスト変換コマンドが豊富にあります。変数名のリネーム時に命名規則を変換したいときなどにめちゃめちゃ便利です。

**ケース変換:**

| コマンド | 変換例 |
|---------|--------|
| `editor: convert to snake case` | `myVariable` → `my_variable` |
| `editor: convert to upper camel case` | `my_variable` → `MyVariable` |
| `editor: convert to lower camel case` | `my_variable` → `myVariable` |
| `editor: convert to kebab case` | `myVariable` → `my-variable` |
| `editor: convert to upper case` | `hello` → `HELLO` |
| `editor: convert to title case` | `hello world` → `Hello World` |

**行操作:**

| コマンド | 動作 |
|---------|------|
| `editor: sort lines case insensitive` | 行をアルファベット順にソート |
| `editor: unique lines case insensitive` | 重複行を削除 |
| `editor: reverse lines` | 行の順序を反転 |
| `editor: join lines` | 複数行を1行に結合 |

### マルチカーソルの応用

`Ctrl + D` で同じ単語を追加選択していくのは基本ですが、さらに強力な使い方があります。

| 操作 | キー / コマンド |
|------|----------------|
| 正規表現で一括選択 | 検索バーで正規表現モードを有効化 → `Alt + Enter` |
| 選択範囲を行ごとに分割 | `editor: split selection into lines` |
| 列選択（矩形選択） | `Alt + Shift + ドラッグ` |
| 上下にカーソルを追加 | `editor: add selection above` / `below` |

### クリップボードとの差分比較

コードを比較したいときに便利な機能です。片方のコードをコピーし、もう片方を選択した状態で `editor: diff clipboard with selection` を実行すると、2つのコードの差分がハイライト表示されます。リファクタリングで「何が変わったか」を確認するのに最適です。

### 設定プロファイル

`settings profile selector: toggle` で設定プロファイルを切り替えられます。たとえば「プレゼン用」プロファイルでフォントサイズを大きくしたり、「執筆用」プロファイルで Zen モードにしたりと、シーンに応じた設定を素早く適用できます。

### タスクシステム

Zed にはタスクランナーが組み込まれています。`~/.config/zed/tasks.json` にタスクを定義して、キーボードから素早く実行できます。

```json
[
  {
    "label": "Run current test",
    "command": "pytest",
    "args": ["$ZED_FILE", "-x", "-v"],
    "tags": ["python-test"]
  }
]
```

| 操作 | 説明 |
|------|------|
| `editor: spawn nearest task` | カーソル位置に最も近いタスク（テスト等）を実行 |
| タスクモーダルで `Tab` | コマンドを展開して実行前に編集できる |
| `Alt + Enter` | ワンショットタスクとして修正付きで実行 |

テストを繰り返し実行しながら開発するときは `editor: spawn nearest task` がとても快適です。

### アウトライン表示

`Ctrl + Shift + O` でファイルのアウトライン（関数・クラス一覧）を表示できます。検索クエリに**スペースを含める**と、コンテキストキーワードでフィルタできるのがポイントです。たとえば Rust なら `pub fn` で公開関数だけに絞り込めます。

### ペイン分割のコツ

| 操作 | キー |
|------|------|
| 右にペイン分割 | `Ctrl + K` → `→` |
| 下にペイン分割 | `Ctrl + K` → `↓` |
| ファイルを新しいペインで開く | `Ctrl` を押しながらファイルを選択 |
| 定義ジャンプを新しいペインで開く | `Alt + Ctrl + クリック` |

### その他の便利機能

- **フォーカス時自動保存**: `"autosave": "on_focus_change"` でエディタとターミナルを行き来するだけで自動保存
- **コピー＆トリム**: 右クリックメニューの「Copy and Trim」で余分な空白を除去してコピー
- **ファイル比較**: プロジェクトパネルで2つのファイルを選択 → 右クリック →「Compare marked files」
- **SendKeystrokes**: キーバインドにマクロのようなキー入力列を割り当て可能
- **action::Sequence**: 複数のアクションを1つのキーバインドにチェーンできる（例: 全ドックを閉じる → 不要タブを閉じる → センターレイアウト）

## chezmoi での管理

### 設定ファイルの追加

```bash
# 設定ファイルを chezmoi の管理対象に追加
chezmoi add ~/.config/zed/settings.json
chezmoi add ~/.config/zed/keymap.json
```

これにより `home/dot_config/zed/` 以下にソースファイルが作成されます。

### このリポジトリのファイル構成

```
home/dot_config/zed/
├── settings.json    # エディタ設定
└── keymap.json      # キーバインド設定
```

chezmoi は `~/.config/zed/` に設定ファイルを配置します。WSL 環境では、追加で Windows 側の `%APPDATA%\Zed\` にも keymap.json を自動配置するスクリプトが動作します。

### WSL での keymap.json 自動配置

WSL 環境では Zed が Windows 側で動作するため、keymap.json は Windows の `%APPDATA%\Zed\keymap.json` にも配置する必要があります。このリポジトリでは `run_onchange_after_` スクリプトで自動化しています。

```
chezmoi apply
  │
  ├─ 1. ~/.config/zed/keymap.json に配置（Linux / WSL 側）
  │
  └─ 2. run_onchange_after スクリプトが実行される
        ├─ /proc/version を確認 → WSL 環境か判定
        ├─ WSL なら cmd.exe 経由で %APPDATA% のパスを取得
        └─ wslpath で Windows パスに変換し、keymap.json をコピー
           → %APPDATA%\Zed\keymap.json が更新される
```

スクリプトは `keymap.json` の内容が変わるたびに再実行されます（`run_onchange_` による制御）。

```bash
# install/common/zed-keymap.sh（抜粋）
function is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

function get_windows_appdata() {
    local win_appdata
    win_appdata="$(cmd.exe /C 'echo %APPDATA%' 2>/dev/null | tr -d '\r')"
    wslpath -u "${win_appdata}"
}
```

### OS ごとの設定分岐

macOS と Linux でキーバインドが異なる場合は、テンプレート（`.tmpl`）を使って分岐できます。

```
{{- if eq .chezmoi.os "darwin" -}}
"cmd-shift-k": "editor::DeleteLine"
{{- else -}}
"ctrl-shift-k": "editor::DeleteLine"
{{- end -}}
```

macOS では設定ファイルが `~/.zed/` に配置されるため、パスが異なる点に注意してください。macOS も管理する場合は `home/dot_zed/` ディレクトリも用意する必要があります。

## VS Code からの移行

VS Code から Zed への移行で知っておくべきポイント:

| VS Code | Zed |
|---------|-----|
| `settings.json` | `~/.config/zed/settings.json` |
| `keybindings.json` | `~/.config/zed/keymap.json` |
| 拡張機能マーケット | Extensions パネル |
| 統合ターミナル | `Ctrl + J` |
| Remote SSH | SSH リモート開発対応 |
| Remote WSL | `projects: open in wsl` コマンド |

Zed は VS Code に比べて拡張機能のエコシステムは発展途上ですが、エディタ本体のパフォーマンスとビルトイン機能の完成度が高いのが特徴です。必要な機能が揃っていて動作が速い、というシンプルな良さがあります。

## ライフサイクル

### 初期セットアップ（初回のみ）

```bash
# Linux / WSL の場合
curl -f https://zed.dev/install.sh | sh

# macOS の場合
brew install --cask zed
```

`chezmoi apply` で `settings.json` と `keymap.json` が自動配置されるので、インストール後すぐに自分の設定で使い始められます。

### 日常の操作

| やりたいこと | キー / コマンド |
|------------|---------------|
| ファイルを素早く開く | `Ctrl + P` |
| コマンドパレット | `Ctrl + Shift + P` |
| プロジェクト内検索 | `Ctrl + Shift + F` |
| ターミナルを開く | `Ctrl + J` |
| AI アシスタント | `Ctrl + Enter` |
| WSL プロジェクトを開く | コマンドパレット → `projects: open in wsl` |

### 設定を変更したいとき

```bash
# 1. chezmoi 経由で設定ファイルを編集
chezmoi edit ~/.config/zed/settings.json

# 2. 差分を確認して適用
chezmoi diff
chezmoi apply
# → WSL 環境では keymap.json が Windows 側にも自動コピーされる

# 3. Zed を再起動（設定によってはホットリロードされる）
```

### 拡張機能を追加したいとき

`Ctrl + Shift + X` で拡張機能パネルを開き、検索・インストールします。拡張機能の設定は `settings.json` に追記されるので、`chezmoi add` で管理対象に含めればほかのマシンにも反映できます。

## 参考文献

[^1]: [Hidden Gems シリーズ — Zed Blog](https://zed.dev/blog/hidden-gems-team-edition-part-1)（Part 1〜3）
[^2]: [Text Manipulation Kung Fu — Zed Blog](https://zed.dev/blog/text-manipulation)
[^3]: [Zed ドキュメント — Key Bindings](https://zed.dev/docs/key-bindings)
[^4]: [Zed ドキュメント — Multibuffers](https://zed.dev/docs/multibuffers)
[^5]: [Zed ドキュメント — Extensions](https://zed.dev/docs/extensions)
[^6]: [awesome-zed-extensions（GitHub Stars ランキング）](https://github.com/alanisme/awesome-zed-extensions)
[^7]: [Zed Editor vs VS Code 2025: Performance Benchmarks — Markaicode](https://markaicode.com/vs/zed-editor-vs-vs-code/)
[^8]: [The Debugger is Here — Zed Blog](https://zed.dev/blog/debugger)
[^9]: [Zed ドキュメント — AI Overview](https://zed.dev/docs/ai/overview)
[^10]: [Zed ドキュメント — Agent Panel](https://zed.dev/docs/ai/agent-panel)
[^11]: [Zed ドキュメント — Running & Testing](https://zed.dev/docs/running-testing)
[^12]: [Zed ドキュメント — Debugger](https://zed.dev/docs/debugger)
