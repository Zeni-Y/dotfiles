local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M.keys = {
  -- ============================================================
  -- ワークスペース
  -- ============================================================
  -- Leader + w: ワークスペース一覧（fuzzy finder）
  {
    key = "w",
    mods = "LEADER",
    action = act.ShowLauncherArgs({ flags = "WORKSPACES|LAUNCH_MENU_ITEMS" }),
  },
  -- Leader + W: 新規ワークスペースを名前付きで作成
  {
    key = "W",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "ワークスペース名を入力",
      action = wezterm.action_callback(function(win, pane, line)
        if line then
          wezterm.mux.spawn_window({ workspace = line })
        end
      end),
    }),
  },

  -- ============================================================
  -- タブ
  -- ============================================================
  -- Leader + c: 新規タブ
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  -- Leader + 1-5: タブ番号で直接移動
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
  -- Leader + ,: タブ名変更
  {
    key = ",",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "タブ名を入力",
      action = wezterm.action_callback(function(win, pane, line)
        if line then
          win:active_tab():set_title(line)
        end
      end),
    }),
  },
  -- Leader + x: 現在のタブを閉じる
  { key = "x", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },

  -- ============================================================
  -- コピー・検索
  -- ============================================================
  -- Leader + [: コピーモード（Vim キーバインド）
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  -- Leader + p: コマンドパレット
  { key = "p", mods = "LEADER", action = act.ActivateCommandPalette },

  -- ============================================================
  -- セッション保存・復元（resurrect plugin）
  -- ============================================================
  -- Leader + S: 現在のワークスペースを保存
  {
    key = "S",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
      local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
      resurrect.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  -- Leader + R: 保存済みセッションを復元
  {
    key = "R",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
      local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
      resurrect.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, "^([^/]+)")
        if type == "workspace" then
          local state = resurrect.load_state(id)
          resurrect.workspace_state.restore_workspace(state, { relative_cwd = true })
        end
      end)
    end),
  },

  -- ============================================================
  -- フォント・表示
  -- ============================================================
  { key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL|SHIFT", action = act.ResetFontSize },
  { key = "F11",  mods = "",         action = act.ToggleFullScreen },
}

return M
