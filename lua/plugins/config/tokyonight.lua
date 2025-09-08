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
    keywords = { bold = true },
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
  end,
})

vim.cmd("colorscheme tokyonight")
