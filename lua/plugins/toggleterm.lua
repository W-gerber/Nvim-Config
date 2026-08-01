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
      insert_mappings = false, -- we handle mappings via keys above
      terminal_mappings = false,
      start_in_insert = true,
      persist_mode = true,
      persist_size = true,
      shade_terminals = false,
      direction = "horizontal",
      size = 15,
      float_opts = { border = "rounded" },
      highlights = {
        Normal = { link = "Normal" },
        NormalFloat = { link = "NormalFloat" },
        FloatBorder = { link = "FloatBorder" },
      },
    })
    -- The terminal-mode escape (<Esc><Esc>) is global; see Lua/core/keymaps.lua.
  end,
}
