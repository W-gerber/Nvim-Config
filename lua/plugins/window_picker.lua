-- Pick a target window before splitting, instead of guessing.
--
-- This spec previously had no load trigger at all. With `defaults.lazy = true`
-- in init.lua that meant it was never loaded, so <leader>vs / <leader>hs simply
-- did nothing. The `keys` below both declare the mappings and load the plugin.

local function pick()
  local ok, picker = pcall(require, "window-picker")
  if not ok or not picker.pick_window then
    return nil
  end

  return picker.pick_window()
end

local function split_with_picker(command)
  local win = pick()
  if win then
    pcall(vim.api.nvim_set_current_win, win)
  end

  vim.cmd(command)
end

return {
  "s1n7ax/nvim-window-picker",
  name = "window-picker",
  main = "window-picker",
  version = "*",
  keys = {
    { "<leader>vs", function() split_with_picker("vsplit") end, desc = "Vertical split (pick window)" },
    { "<leader>hs", function() split_with_picker("split") end, desc = "Horizontal split (pick window)" },
    {
      "<leader>wp",
      function()
        local win = pick()
        if win then
          pcall(vim.api.nvim_set_current_win, win)
        end
      end,
      desc = "Jump to window",
    },
  },
  opts = {
    hint = "floating-big-letter",
    show_prompt = false,
    filter_rules = {
      include_current_win = false,
      autoselect_one = true,
      bo = {
        filetype = { "neo-tree", "neo-tree-popup", "notify", "noice" },
        buftype = { "terminal", "quickfix", "help" },
      },
    },
  },
}
