return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<c-\>]],
      insert_mappings = true,
      terminal_mappings = true,
      start_in_insert = true,
      persist_mode = true,
      persist_size = true,
      shade_terminals = false,
      direction = "horizontal",
      size = 15,
    })

    vim.keymap.set("n", "<leader>to", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
    vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
  end,
}
