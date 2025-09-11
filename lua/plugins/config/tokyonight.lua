-- plugins/config/tokyonight.lua
local ok, tokyonight = pcall(require, "tokyonight")
if not ok then return end

local colors = require("ui.colors")

tokyonight.setup({
  style = "night",
  transparent = true,
  dim_inactive = false,
  terminal_colors = true,
  styles = { 
    comments = { italic = true },
    keywords = { bold = false },
    functions = {},
    variables = {},
  },
  on_colors = function(c)
    -- Inject neon accents for some groups
    c.cursorline = "NONE"
    c.vivid_cyan = colors.neon.cyan
    c.vivid_pink = colors.neon.hotpink
    c.vivid_lime = colors.neon.lime
  end,
  on_highlights = function(hl, c)
  hl.Normal = { bg = "NONE" }
  hl.Visual = { bg = colors.neon.cyan, fg = "#000000" }
  hl.CursorLine = { bg = "NONE" }
  hl.FloatBorder = { bg = "NONE", fg = colors.neon.purple }
  -- Neon VSCode-like mappings
  hl.Comment = { fg = "#7a7f8a", italic = true }
  hl.String = { fg = colors.neon.lime }
  hl.Keyword = { fg = colors.neon.hotpink }
  hl.Conditional = { fg = colors.neon.hotpink }
  hl.Repeat = { fg = colors.neon.hotpink }
  hl.Function = { fg = "#ffd866" } -- soft yellow
  hl.Method = { fg = "#ffd866" }
  hl.Variable = { fg = "#cfe7ff" }
  hl.Identifier = { fg = "#cfe7ff" }
  -- Diagnostics
  hl.DiagnosticError = { fg = colors.neon.hotpink }
  hl.DiagnosticWarn  = { fg = "#ff9e64" }
  hl.DiagnosticInfo  = { fg = colors.neon.cyan }
  hl.DiagnosticHint  = { fg = colors.neon.lime }
  end,
})

vim.cmd("colorscheme tokyonight")
