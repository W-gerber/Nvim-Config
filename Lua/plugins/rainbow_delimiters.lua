return {
  -- Treesitter-based rainbow delimiters (VS Code-like bracket colorization)
  -- Nested (), {}, [] get different highlight groups.
  "hiphish/rainbow-delimiters.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    -- Link rainbow groups to existing theme-highlight groups (no hard-coded colors)
    local hl = vim.api.nvim_set_hl
    hl(0, "RainbowDelimiterRed", { link = "DiagnosticError" })
    hl(0, "RainbowDelimiterYellow", { link = "DiagnosticWarn" })
    hl(0, "RainbowDelimiterBlue", { link = "DiagnosticInfo" })
    hl(0, "RainbowDelimiterOrange", { link = "String" })
    hl(0, "RainbowDelimiterGreen", { link = "Function" })
    hl(0, "RainbowDelimiterViolet", { link = "Type" })
    hl(0, "RainbowDelimiterCyan", { link = "Constant" })

    -- Configure rainbow-delimiters
    local ok, rainbow = pcall(require, "rainbow-delimiters")
    if not ok then
      return
    end

    vim.g.rainbow_delimiters = {
      strategy = {
        [""] = rainbow.strategy["global"],
        vim = rainbow.strategy["local"],
      },
      query = {
        [""] = "rainbow-delimiters",
        lua = "rainbow-blocks",
      },
      highlight = {
        "RainbowDelimiterRed",
        "RainbowDelimiterYellow",
        "RainbowDelimiterBlue",
        "RainbowDelimiterOrange",
        "RainbowDelimiterGreen",
        "RainbowDelimiterViolet",
        "RainbowDelimiterCyan",
      },
    }

    -- Re-apply links on colorscheme changes
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        hl(0, "RainbowDelimiterRed", { link = "DiagnosticError" })
        hl(0, "RainbowDelimiterYellow", { link = "DiagnosticWarn" })
        hl(0, "RainbowDelimiterBlue", { link = "DiagnosticInfo" })
        hl(0, "RainbowDelimiterOrange", { link = "String" })
        hl(0, "RainbowDelimiterGreen", { link = "Function" })
        hl(0, "RainbowDelimiterViolet", { link = "Type" })
        hl(0, "RainbowDelimiterCyan", { link = "Constant" })
      end,
    })
  end,
}
