return {
  "akinsho/toggleterm.nvim",
  version = "*",
  cmd = { "ToggleTerm", "TermExec" },
  keys = {
    { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    { [[<c-\>]], "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
  },
  config = function()
    require("toggleterm").setup({
      insert_mappings = false,  -- we handle mappings via keys above
      terminal_mappings = false,
      start_in_insert = true,
      persist_mode = true,
      persist_size = true,
      shade_terminals = false,
      direction = "horizontal",
      size = 15,
    })

    -- Escape from terminal insert mode (double-Esc avoids conflicts with TUI apps)
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
  end,
}
