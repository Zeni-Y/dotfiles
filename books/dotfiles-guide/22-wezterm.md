---
title: "WezTerm で作るリッチなターミナル環境"
---

# WezTerm で作るリッチなターミナル環境

[ターミナル・シェル・エディタの基礎知識](./02-terminal-shell-editor) のチャプターでターミナルエミュレータの概要を紹介しました。この章では、筆者が乗り換えた **WezTerm** を掘り下げて解説します。

対象環境は **Windows ネイティブ（PowerShell）** から SSH 経由でリモート Linux サーバーに接続し、そこで fish shell + Zellij + Neovim を使う構成です。WSL2 は使いません。

```
[Windows] WezTerm (PowerShell)
    └─ SSH ──→ [リモート Linux サーバー]
                   └─ Zellij (セッション管理)
                        └─ Neovim + LazyVim (編集)
                        └─ lazygit (Git 操作)
                        └─ yazi (ファイル管理)
```

## なぜ WezTerm を選ぶのか

### ターミナルエミュレータの比較

| 観点                   | Tabby    | Windows Terminal | Alacritty | WezTerm          |
| ---------------------- | -------- | ---------------- | --------- | ---------------- |
| GPU アクセラレーション | ✅       | ✅               | ✅        | ✅               |
| 設定言語               | GUI/JSON | JSON             | TOML      | **Lua**          |
| ワークスペース機能     | ❌       | ❌               | ❌        | **✅**           |
| Windows ネイティブ対応 | ✅       | ✅               | ✅        | ✅               |
| Zellij との相性        | 普通     | 普通             | 普通      | **良い**         |
| プラグインシステム     | ✅       | 限定的           | ❌        | **✅（Lua）**    |
| resurrect（状態復元）  | ❌       | ❌               | ❌        | **✅（plugin）** |
| True Color / Nerd Font | ✅       | ✅               | ✅        | ✅               |

### WezTerm を推す理由

**Lua による高い柔軟性**: 設定ファイルがプログラミング言語（Lua）なので、条件分岐・外部コマンド実行・動的な設定変更が自在にできます。JSON や TOML では表現しにくい「プロジェクトごとに接続先を切り替える」ような設定も簡潔に書けます。

**ワークスペース機能**: WezTerm 独自の「ワークスペース」は、タブやペインとは別の名前付き作業空間です。SSH 接続先ごとにワークスペースを作り、fuzzy finder で素早く切り替えられます。

**resurrect plugin**: ワークスペースの状態（タブ構成・カレントディレクトリ等）を自動保存し、再起動後も復元できます。

## インストール（Windows）

### winget でインストール

PowerShell または CMD で以下を実行します:

```powershell
winget install wez.wezterm
```

インストール後、バージョンを確認します:

```powershell
wezterm --version
# → wezterm 20240203-110809-5046fc22
```

### 設定ファイルの場所

WezTerm は以下の順でファイルを探します（Windows の場合）:

```
%USERPROFILE%\.config\wezterm\wezterm.lua   ← 推奨
%USERPROFILE%\.wezterm.lua
```

:::message
`%USERPROFILE%` は通常 `C:\Users\<ユーザー名>` です。PowerShell では `$env:USERPROFILE` で確認できます。
:::

### chezmoi での管理

この dotfiles リポジトリは Linux/macOS 主体ですが、WezTerm の設定も chezmoi で管理できます:

```
home/dot_config/wezterm/
  wezterm.lua    # メイン設定
  keybinds.lua   # キーバインド定義
```

`chezmoi apply` で `~/.config/wezterm/` に配置されます。Windows 上で chezmoi を使う場合も、`%USERPROFILE%\.config\wezterm\` として同じパスが機能します。

## リッチな UI の構築

設定ファイルは Lua なので、まず骨格を作り、徐々に拡張していきます。

### 設定ファイルの分割

```lua
-- ~/.config/wezterm/wezterm.lua
local wezterm = require("wezterm")
local keybinds = require("keybinds")  -- キーバインドを別ファイルに分離

local config = wezterm.config_builder()

-- === フォント ===
config.font = wezterm.font("FiraCode Nerd Font", { weight = "Regular" })
config.font_size = 13.0

-- === 外観 ===
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20  -- macOS のみ有効

-- タイトルバーを非表示にしてすっきりさせる
config.window_decorations = "RESIZE"

-- === タブバー ===
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

-- === キーバインド ===
config.leader = { key = "Space", mods = "CTRL|SHIFT", timeout_milliseconds = 2000 }
config.keys = keybinds.keys
config.key_tables = keybinds.key_tables

return config
```

```lua
-- ~/.config/wezterm/keybinds.lua
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M.keys = {
  -- ワークスペース切替
  { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
  -- 新規ワークスペース
  { key = "W", mods = "LEADER", action = act.PromptInputLine({
      description = "ワークスペース名を入力",
      action = wezterm.action_callback(function(win, pane, line)
        if line then
          wezterm.mux.spawn_window({ workspace = line })
        end
      end),
  })},
  -- タブ操作
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
  -- フォントサイズ
  { key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL|SHIFT", action = act.ResetFontSize },
  -- 全画面
  { key = "F11", mods = "", action = act.ToggleFullScreen },
  -- コピーモード
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  -- コマンドパレット
  { key = "p", mods = "LEADER", action = act.ActivateCommandPalette },
}

M.key_tables = {}

return M
```

### フォント

Nerd Font は Neovim のアイコン表示や starship のプロンプトに必要です。[Nerd Fonts 公式サイト](https://www.nerdfonts.com/font-downloads)からダウンロードしてインストールします。

おすすめ:

- **FiraCode Nerd Font** — プログラミングリガチャ付き
- **JetBrainsMono Nerd Font** — 視認性重視
- **Hack Nerd Font** — シンプルで読みやすい

### Windows へのインストール手順

1. zip を展開し、`.ttf` ファイルを全選択
2. 右クリック → **「すべてのユーザーのためにインストール」** を選択

:::message
「インストール」（ユーザー向け）でも動作しますが、WezTerm が管理者権限で動く場合に備えて「すべてのユーザー」を推奨します。
:::

zip の中には Regular・Bold・Italic など多数のバリアントが含まれます。最低限以下の 2 ファイルをインストールすれば動作します:

| ファイル名                     | 用途   |
| ------------------------------ | ------ |
| `FiraCodeNerdFont-Regular.ttf` | 通常体 |
| `FiraCodeNerdFont-Bold.ttf`    | 太字   |

`Mono` サフィックス付き（`FiraCodeNerdFontMono-*.ttf`）は文字幅が狭いバリアントです。WezTerm では通常の `FiraCodeNerdFont-*.ttf` を使う方が見た目が整います。

インストール後、WezTerm を再起動するとフォントが認識されます。

### カラースキーム

WezTerm には 300 以上のカラースキームが組み込まれています:

```lua
-- 使用可能なスキームの確認
-- https://wezfurlong.org/wezterm/colorschemes/index.html

config.color_scheme = "Catppuccin Mocha"   -- ダーク系
-- config.color_scheme = "Catppuccin Latte"  -- ライト系
-- config.color_scheme = "Tokyo Night"
-- config.color_scheme = "Gruvbox dark, hard (base16)"
```

### カスタムタブバー（三角形デザイン）

`wezterm.on` でタブバーの描画をカスタマイズできます:

```lua
-- wezterm.lua に追記
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
  local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

  local background = "#1e1e2e"
  local foreground = "#cdd6f4"
  local edge_background = "#181825"

  if tab.is_active then
    background = "#89b4fa"
    foreground = "#1e1e2e"
  elseif hover then
    background = "#313244"
    foreground = "#cdd6f4"
  end

  local title = tab.active_pane.title
  if #title > max_width - 4 then
    title = wezterm.truncate_right(title, max_width - 4) .. "…"
  end

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = background } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = " " .. title .. " " },
    { Background = { Color = edge_background } },
    { Foreground = { Color = background } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)
```

## ワークスペース管理（SSH・コンテナ切り替え）

### ワークスペースとは

WezTerm のワークスペースは、**タブやペインとは独立した名前付きの作業空間**です。

```
WezTerm
├── ワークスペース: "local"
│   └── タブ 1（PowerShell）
│
├── ワークスペース: "server-dev"
│   ├── タブ 1（SSH: dev.example.com）
│   └── タブ 2（SSH: dev.example.com）
│
└── ワークスペース: "docker-api"
    └── タブ 1（docker exec -it api-container fish）
```

一つのウィンドウで複数のワークスペースを切り替えることも、ワークスペースごとに別ウィンドウを開くこともできます。

### SSH 接続をワークスペースで管理

キーバインドから SSH ワークスペースを一発で開く設定例:

```lua
-- keybinds.lua に追記
{ key = "s", mods = "LEADER", action = wezterm.action_callback(function(win, pane)
    -- 接続先を fuzzy finder で選ぶ
    win:perform_action(act.InputSelector({
        action = wezterm.action_callback(function(win, pane, id, label)
            if label then
                -- 接続先ごとにワークスペースを作成
                local _, _, window = wezterm.mux.spawn_window({
                    workspace = label,
                    args = { "ssh", id },
                })
                window:gui_window():focus()
            end
        end),
        title = "SSH 接続先を選択",
        choices = {
            { id = "dev.example.com",  label = "dev-server" },
            { id = "prod.example.com", label = "prod-server" },
            { id = "192.168.1.100",    label = "local-vm" },
        },
    }), pane)
end)},
```

### Docker コンテナへの接続

```lua
{ key = "d", mods = "LEADER", action = wezterm.action_callback(function(win, pane)
    win:perform_action(act.InputSelector({
        action = wezterm.action_callback(function(win, pane, id, label)
            if label then
                local _, _, window = wezterm.mux.spawn_window({
                    workspace = label,
                    args = { "docker", "exec", "-it", id, "fish" },
                })
                window:gui_window():focus()
            end
        end),
        title = "コンテナを選択",
        choices = {
            { id = "my-api-container",  label = "api" },
            { id = "my-db-container",   label = "db" },
        },
    }), pane)
end)},
```

:::message
SSH config (`~/.ssh/config`) でホスト名のエイリアスを設定しておくと、`args = { "ssh", "dev" }` のように短く書けます。
:::

### fuzzy finder でワークスペースを切り替える

```lua
{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
```

`Leader + w` を押すと、現在のワークスペース一覧がファジー検索できる UI で表示されます。

## 再起動後の復元（resurrect plugin）

WezTerm はプラグインを Lua から直接読み込めます。`resurrect.wezterm` を使うと、ワークスペースの状態（タブ構成・カレントディレクトリ等）を自動保存し、PC 再起動後も復元できます。

### セットアップ

```lua
-- wezterm.lua
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- 15 秒ごとに自動保存
resurrect.state_manager.periodic_save({ interval_seconds = 15, save_workspaces = true, save_windows = true, save_tabs = true })

-- イベントハンドラ: セッション保存・復元のショートカット
wezterm.on("gui-startup", function(cmd)
  -- 起動時に最後の状態を復元（任意）
  -- resurrect.resurrect_last_save()
end)
```

```lua
-- keybinds.lua に追記
-- Leader + S: 現在のワークスペースを保存
{ key = "S", mods = "LEADER", action = wezterm.action_callback(function(win, pane)
    resurrect.save_state(resurrect.workspace_state.get_workspace_state())
    resurrect.window_wrangler.save_window(win)
end)},
-- Leader + R: 保存済みセッションを復元
{ key = "R", mods = "LEADER", action = wezterm.action_callback(function(win, pane)
    resurrect.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, "^([^/]+)")
        if type == "workspace" then
            local state = resurrect.load_state(id)
            resurrect.workspace_state.restore_workspace(state, { relative_cwd = true })
        end
    end)
end)},
```

保存データは `~/.local/share/wezterm/resurrect/` に JSON 形式で格納されます。

## Zellij との衝突を避けるキーバインド設計

### 衝突が起きる原因

Zellij は `Ctrl+p`, `Ctrl+t`, `Ctrl+n`, `Ctrl+o`, `Ctrl+s` をモード切替に使います。WezTerm のデフォルトキーバインドと重複すると、SSH 先の Zellij にキーが届かない問題が発生します。

### 解決策: LEADER キーにまとめる

WezTerm の操作を `LEADER` キー（`Ctrl+Shift+Space`）でまとめることで、`Ctrl` 単体のショートカットはすべて Zellij に委ねられます。

```lua
-- LEADER キーの定義
config.leader = { key = "Space", mods = "CTRL|SHIFT", timeout_milliseconds = 2000 }
```

`Ctrl+Shift+Space` は Zellij では使わないキーなので、安全に LEADER として使えます。

### キーバインド対応表

| 操作               | WezTerm ショートカット | Zellij との関係                   |
| ------------------ | ---------------------- | --------------------------------- |
| ワークスペース切替 | `Leader + w`           | 競合なし                          |
| 新規ワークスペース | `Leader + W`           | 競合なし                          |
| SSH 接続           | `Leader + s`           | 競合なし                          |
| 新規タブ           | `Leader + c`           | Zellij の `Ctrl+t` とは別レイヤー |
| タブ切替（番号）   | `Leader + 1-5`         | 競合なし                          |
| コピーモード       | `Leader + [`           | 競合なし                          |
| コマンドパレット   | `Leader + p`           | Zellij の `Ctrl+p` とは別レイヤー |
| フォントサイズ拡大 | `Ctrl+Shift++`         | 競合なし                          |
| フォントサイズ縮小 | `Ctrl+Shift+-`         | 競合なし                          |
| 全画面切替         | `F11`                  | 競合なし                          |
| セッション保存     | `Leader + S`           | 競合なし                          |
| セッション復元     | `Leader + R`           | 競合なし                          |

:::message
Zellij が動いている間、`Ctrl+p` などのキーは WezTerm ではなく Zellij が受け取ります。WezTerm 側では `Ctrl+Shift+*` か `Leader + *` のみ使うようにすると混乱が起きません。
:::

## よく使うキーボードショートカット一覧

### コピーモード（Vim キーバインド）

`Leader + [` でコピーモードに入ります。Vim と同じキーでスクロール・選択ができます。

| キー        | 操作                           |
| ----------- | ------------------------------ |
| `h/j/k/l`   | カーソル移動                   |
| `Ctrl+u/d`  | 半ページスクロール             |
| `v`         | ビジュアル選択開始             |
| `V`         | 行選択                         |
| `y`         | ヤンク（コピー）してモード終了 |
| `q` / `Esc` | コピーモード終了               |
| `/`         | 前方検索                       |
| `?`         | 後方検索                       |

### クイックセレクト

`Ctrl+Shift+Space`（デフォルト）を押すと、画面上の URL・ファイルパス・数字等がハイライトされ、対応するキーを押すだけでクリップボードにコピーできます。マウス不要でターミナル上のテキストを素早く取得できる便利機能です。

### URL オープン

テキスト中の URL にマウスオーバーして `Ctrl+Click` でブラウザが開きます。キーボードのみで行うには、クイックセレクトモードから URL を選択します。

### タブ名変更

```lua
{ key = ",", mods = "LEADER", action = act.PromptInputLine({
    description = "タブ名を入力",
    action = wezterm.action_callback(function(win, pane, line)
        if line then
            win:active_tab():set_title(line)
        end
    end),
})},
```

## Neovim + LazyVim で Python 開発

SSH 先で Neovim + LazyVim を使う場合、WezTerm 側で以下を確認します。

### True Color サポートの確認

```lua
-- wezterm.lua（デフォルトで有効だが明示的に設定）
config.term = "xterm-256color"
```

SSH 先の Neovim に以下を設定します（`~/.config/nvim/lua/config/options.lua` 等）:

```lua
vim.opt.termguicolors = true
```

ターミナルで確認する場合:

```bash
# True color サポートの確認（24 ビットカラーが表示されれば OK）
$ printf '\033[38;2;255;100;0mTRUECOLOR\033[0m\n'
```

### Nerd Font アイコンの確認

```bash
# Nerd Font のアイコンが文字化けしないか確認
$ echo "\ue0b0 \ue0b2 \uf015 \uf07b"
#
```

文字化けする場合は、WezTerm のフォント設定で Nerd Font を使っているか確認してください。

### クリップボード統合

SSH 先の Neovim から Windows のクリップボードを使うには、ローカル側（Windows）で `win32yank.exe` をインストールするか、OSC52 エスケープシーケンスを使います。

WezTerm は OSC52 をサポートしているため、SSH 先の Neovim から直接 Windows クリップボードにコピーできます:

```lua
-- Neovim: ~/.config/nvim/lua/config/options.lua
vim.opt.clipboard = "unnamedplus"
```

```lua
-- neovim の clipboard プロバイダに OSC52 を使う設定
-- LazyVim では extras の "editor.mini" に含まれる場合あり
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}
```

:::message
WezTerm の OSC52 サポートはデフォルトで有効です。SSH 先から `pbcopy` や `xclip` なしにクリップボードが使えます。
:::

### LazyVim の Python 設定

LazyVim で Python 開発を始めるには、`:LazyExtras` から `lang.python` を有効化します。pyright（LSP）と ruff（リンター/フォーマッター）が自動で設定されます。

```
:LazyExtras
→ lang.python を有効化
→ :Lazy sync
```

## Zellij レイアウトテンプレート（開発環境一発展開）

### 4 ペイン構成のレイアウト

以下の構成を KDL テンプレートとして定義します:

```
┌───────────────────────────────────────────────┐
│ yazi (ファイルツリー) │  Neovim (編集)           │
│  25%                  │  50%                    │
├───────────────────────┤                         │
│ Claude Code           ├─────────────────────────│
│  25% (下半分)          │ lazygit (Git UI)         │
│                        │  25% (下半分)            │
└───────────────────────────────────────────────┘
```

```kdl
// ~/.config/zellij/layouts/dev.kdl
layout {
    tab name="dev" focus=true {
        pane split_direction="vertical" {
            // 左カラム（25%）
            pane split_direction="horizontal" size="25%" {
                pane command="yazi" {
                    size "50%"
                }
                pane {
                    size "50%"
                    // Claude Code などのコマンドを起動
                    // command "claude"
                }
            }
            // 中央カラム（50%）
            pane command="nvim" {
                size "50%"
                args "."
            }
            // 右カラム（25%）
            pane split_direction="horizontal" size="25%" {
                pane {
                    size "50%"
                    // 空のシェル（サーバー起動など用）
                }
                pane command="lazygit" {
                    size "50%"
                }
            }
        }
    }
}
```

### レイアウトの使い方

```bash
# レイアウトを指定してセッションを開始
$ zellij --layout dev

# セッション名も付ける（プロジェクト名を指定すると管理しやすい）
$ zellij -s myproject --layout dev
```

### chezmoi での管理

```
home/dot_config/zellij/
  layouts/
    dev.kdl    # 開発用レイアウト
```

`chezmoi add ~/.config/zellij/layouts/dev.kdl` でリポジトリに追加できます。

## chezmoi での WezTerm 設定管理

### ファイル配置

```
home/dot_config/wezterm/
  wezterm.lua    # メイン設定
  keybinds.lua   # キーバインド定義
```

`chezmoi apply` で `~/.config/wezterm/` に配置されます。

### Windows での注意点

Windows 上で chezmoi を使う場合、パスは `%USERPROFILE%\.config\wezterm\` になります。chezmoi は Windows でも動作しますが、この dotfiles リポジトリは Linux/macOS 主体で設計されているため、Windows での chezmoi 運用は補足的な位置づけです。

手動でシンボリックリンクを作成する方法もあります（PowerShell で管理者権限が必要）:

```powershell
# PowerShell（管理者として実行）
New-Item -ItemType SymbolicLink `
    -Path "$env:USERPROFILE\.config\wezterm" `
    -Target "C:\path\to\your\dotfiles\home\dot_config\wezterm"
```

### WezTerm 設定のデバッグ

設定ファイルに構文エラーがあると、WezTerm は起動時にエラーを表示します:

```lua
-- デバッグログを有効化（開発時のみ）
-- wezterm.log_info("デバッグ情報: " .. some_variable)
```

`Ctrl+Shift+L` でデバッグオーバーレイを開くと、設定読み込みのログを確認できます。

## まとめ

WezTerm を導入した構成全体を振り返ります:

```
[Windows] WezTerm
├── フォント: FiraCode Nerd Font
├── カラースキーム: Catppuccin Mocha
├── 半透明背景
├── LEADER = Ctrl+Shift+Space（Zellij と競合なし）
├── ワークスペース: SSH 接続先・Docker コンテナごとに分離
└── resurrect plugin: 状態を自動保存

[SSH 先 Linux サーバー]
├── Zellij（セッション管理・画面分割）
│   └── dev.kdl レイアウト（yazi/Neovim/lazygit）
├── Neovim + LazyVim（Python 開発）
│   └── OSC52 でクリップボード統合
└── fish + chezmoi dotfiles
```

**運用フロー**:

1. WezTerm を起動 → `Leader + s` で SSH 接続先を選択
2. 接続先ごとのワークスペースが自動作成
3. SSH 先で `zellij --layout dev` を実行
4. 4 ペイン構成（yazi・Neovim・シェル・lazygit）が一発展開
5. `Leader + w` で別のワークスペース（別の接続先）に切り替え

Zellij の Ctrl キーバインドと WezTerm の LEADER キーを明確に分離することで、ショートカットの競合なしに両者をフル活用できます。

## 参考リンク

- [WezTerm 公式ドキュメント](https://wezfurlong.org/wezterm/) — 設定リファレンス・チュートリアル
- [WezTerm GitHub リポジトリ](https://github.com/wez/wezterm) — ソースコード・Issues
- [resurrect.wezterm](https://github.com/MLFlexer/resurrect.wezterm) — セッション復元プラグイン
- [Catppuccin for WezTerm](https://github.com/catppuccin/wezterm) — Catppuccin カラースキームの WezTerm 向け設定
- [Zellij ドキュメント: Layouts](https://zellij.dev/documentation/creating-a-layout) — KDL レイアウト定義の詳細
- [LazyVim ドキュメント](https://www.lazyvim.org/) — LazyVim の設定・Extras 一覧
