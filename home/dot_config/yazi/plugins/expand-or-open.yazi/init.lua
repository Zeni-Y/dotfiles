-- ディレクトリなら展開、ファイルなら開く（VSCodeファイルツリー風）
return {
    entry = function()
        local h = cx.active.current.hovered
        if not h then return end

        if h.cha.is_dir then
            ya.manager_emit("expand", {})
        else
            ya.manager_emit("open", {})
        end
    end,
}
