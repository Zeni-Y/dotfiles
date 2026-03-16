---
title: "Zed エディタ"
---

# Zed エディタ

[Zed](https://zed.dev/) は Rust 製の高速テキストエディタです。[Atom](https://github.com/atom/atom) の開発者が設計しており、パフォーマンスとコラボレーションを重視しています。

## なぜ Zed を使うのか

- **高速な起動と動作**: Rust 製で GPU レンダリングを採用。大規模ファイルでも快適に動作
- **AI 統合**: Claude や GPT との連携が組み込まれている
- **マルチプレイヤー編集**: リアルタイムでの共同編集に対応
- **Vim モード**: Vim キーバインドをネイティブサポート
- **ミニマルな UI**: 余計な要素がなく、コードに集中できる

筆者が Zed を選んだ理由は、VS Code よりも起動が速くて動作が軽いことです。必要な機能は揃っていて、余計なものが少ないのが好みに合っています。

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

1. Zed のコマンドパレット（`Ctrl + Shift + P`）を開く
2. `projects: open in wsl` を実行
3. 使用する WSL ディストリビューションを選択
4. フォルダを選択して開く

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

## AI アシスタント機能

Zed には AI アシスタントが組み込まれています。

### 設定

`settings.json` の `assistant` セクションでプロバイダとモデルを指定します。

```json
{
  "assistant": {
    "enabled": true,
    "default_model": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514"
    }
  }
}
```

### 使い方

| キー | 動作 |
|------|------|
| `Ctrl + Enter` | AI アシスタントパネルを開く |
| `Ctrl + Shift + Enter` | インラインアシスト（選択範囲を AI で変換） |

## 拡張機能

Zed は拡張機能（Extensions）でカスタマイズできます。`Ctrl + Shift + X` で拡張機能パネルを開けます。

### おすすめの拡張機能

- **言語サポート**: Python, Go, Rust, TypeScript 等の LSP 連携
- **テーマ**: Catppuccin, Gruvbox, Tokyo Night 等
- **Linter 連携**: ESLint, Ruff 等のツール連携

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
  ↓
~/.config/zed/keymap.json に配置（Linux / WSL 側）
  ↓
WSL を検出したら自動で %APPDATA%\Zed\keymap.json にもコピー
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
