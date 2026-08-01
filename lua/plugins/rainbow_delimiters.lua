return {
  -- Treesitter-based bracket colorization: nested (), {} and [] each get their
  -- own highlight group, so mismatched delimiters are visible at a glance.
  "hiphish/rainbow-delimiters.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    local ui = require("core.ui")

    -- Delimiter colors are pulled from the palette rather than linked to
    -- diagnostic groups. Linking meant every nested bracket in a healthy file
    -- was painted "error red", which reads as a warning it isn't.
    local function apply_rainbow_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl

      local levels = {
        RainbowDelimiterYellow = p.yellow,
        RainbowDelimiterViolet = p.purple,
        RainbowDelimiterBlue = p.blue,
        RainbowDelimiterOrange = p.orange,
        RainbowDelimiterGreen = p.green,
        RainbowDelimiterCyan = p.cyan,
        RainbowDelimiterRed = p.red,
      }

      for group, color in pairs(levels) do
        hl(0, group, { fg = color })
      end
    end

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
      -- Ordered brightest-first so the outermost pair is the most prominent.
      highlight = {
        "RainbowDelimiterYellow",
        "RainbowDelimiterViolet",
        "RainbowDelimiterBlue",
        "RainbowDelimiterOrange",
        "RainbowDelimiterGreen",
        "RainbowDelimiterCyan",
        "RainbowDelimiterRed",
      },
    }

    apply_rainbow_highlights()

    -- `ui.on_theme_change` covers both ColorScheme *and* `User ThemeSwitched`.
    -- Listening to ColorScheme alone missed every base46 theme switch, because
    -- base46 themes without a matching :colorscheme file never fire it.
    ui.on_theme_change(ui.create_augroup("RainbowDelimiterHighlights"), apply_rainbow_highlights)
  end,
}
