local wezterm = require("wezterm")
local keybinds = require("keybinds")

local config = wezterm.config_builder()

-- === フォント ===
config.font = wezterm.font("FiraCode Nerd Font", { weight = "Regular" })
config.font_size = 13.0

-- === 外観 ===
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.9

-- タイトルバーを非表示（リサイズハンドルは残す）
config.window_decorations = "RESIZE"

-- === タブバー ===
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

-- === スクロール ===
config.scrollback_lines = 10000

-- === キーバインド ===
-- LEADER: Ctrl+Shift+Space（Zellij のキーと競合しない）
config.leader = { key = "Space", mods = "CTRL|SHIFT", timeout_milliseconds = 2000 }
config.keys = keybinds.keys

-- === カスタムタブバー（三角形デザイン）===
wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
  local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

  local bg = "#1e1e2e"
  local fg = "#cdd6f4"
  local edge = "#181825"

  if tab.is_active then
    bg = "#89b4fa"
    fg = "#1e1e2e"
  elseif hover then
    bg = "#313244"
    fg = "#cdd6f4"
  end

  local title = tab.active_pane.title
  if #title > max_width - 4 then
    title = wezterm.truncate_right(title, max_width - 4) .. "…"
  end

  return {
    { Background = { Color = edge } },
    { Foreground = { Color = bg } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = " " .. title .. " " },
    { Background = { Color = edge } },
    { Foreground = { Color = bg } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

-- === resurrect plugin（セッション自動保存）===
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
resurrect.periodic_save({
  interval_seconds = 15,
  save_workspaces = true,
  save_windows = true,
})

return config
