return {
  -- Indentation guides plus a highlighted current scope. Empty lines stay
  -- clean: guides there add noise without adding information.
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPre", "BufNewFile" },
  main = "ibl",
  opts = {
    indent = {
      char = "\u{2502}", -- │
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
        "checkhealth",
        "dashboard",
        "help",
        "lazy",
        "man",
        "mason",
        "neo-tree",
        "notify",
        "TelescopePrompt",
        "TelescopeResults",
        "TelescopePreview",
        "trouble",
      },
      buftypes = { "terminal", "nofile", "prompt", "quickfix" },
    },
  },
  config = function(_, opts)
    local ui = require("core.ui")

    -- Guides sit just above the background; the active scope picks up the
    -- theme accent so "which block am I in" is answerable at a glance.
    local function apply_ibl_highlights()
      local p = ui.palette()
      vim.api.nvim_set_hl(0, "IblIndent", { fg = ui.blend(p.muted, p.bg, 0.35) })
      vim.api.nvim_set_hl(0, "IblWhitespace", { fg = ui.blend(p.muted, p.bg, 0.35) })
      vim.api.nvim_set_hl(0, "IblScope", { fg = ui.blend(p.accent, p.bg, 0.75) })
    end

    apply_ibl_highlights()
    require("ibl").setup(opts)

    -- ColorScheme alone missed every base46 theme switch; on_theme_change also
    -- listens for `User ThemeSwitched`.
    ui.on_theme_change(ui.create_augroup("IblHighlights"), apply_ibl_highlights)
  end,
}
