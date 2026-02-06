return {
  "s1n7ax/nvim-window-picker",
  name = "window-picker",
  version = "*",
  config = function()
    require("window-picker").setup({
      hint = "statusline-winbar",
      show_prompt = false,
      filter_rules = {
        include_current_win = true,
        autoselect_one = true,
        bo = {
          filetype = { "neo-tree", "neo-tree-popup", "notify", "noice" },
          buftype = { "terminal", "quickfix", "help" },
        },
      },
    })

    local function split_with_picker(cmd)
      local ok, picker = pcall(require, "window-picker")
      if ok and picker and picker.pick_window then
        local win = picker.pick_window()
        if win then
          pcall(vim.api.nvim_set_current_win, win)
        end
      end
      vim.cmd(cmd)
    end

    vim.keymap.set("n", "<leader>vs", function()
      split_with_picker("vsplit")
    end, { desc = "Vertical split (pick window)" })

    vim.keymap.set("n", "<leader>hs", function()
      split_with_picker("split")
    end, { desc = "Horizontal split (pick window)" })
  end,
}
