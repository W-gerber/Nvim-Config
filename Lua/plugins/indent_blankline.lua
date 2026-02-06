return {
  -- Indentation guides (VS Code-like indent lines) + current scope highlight.
  -- Requirements:
  -- - Vertical indent lines for each level
  -- - Highlight the current scope subtly
  -- - Do NOT clutter empty lines
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {
    indent = {
      char = "│",
      highlight = "IblIndent",
    },
    scope = {
      enabled = true,
      show_start = false,
      show_end = false,
      highlight = "IblScope",
    },
    whitespace = {
      remove_blankline_trail = true,
    },
    exclude = {
      filetypes = {
        "alpha",
        "help",
        "neo-tree",
        "TelescopePrompt",
        "TelescopeResults",
        "TelescopePreview",
        "lazy",
        "mason",
        "notify",
      },
      buftypes = { "terminal", "nofile", "prompt" },
    },
  },
  config = function(_, opts)
    -- Use theme-provided colors by linking to existing highlight groups.
    vim.api.nvim_set_hl(0, "IblIndent", { link = "LineNr" })
    vim.api.nvim_set_hl(0, "IblScope", { link = "CursorLineNr" })

    require("ibl").setup(opts)

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "IblIndent", { link = "LineNr" })
        vim.api.nvim_set_hl(0, "IblScope", { link = "CursorLineNr" })
      end,
    })
  end,
}
