-- Lualine bubbles theme with neon transparency
local ok_theme, theme = pcall(require, "theme")
local neon = (ok_theme and theme and theme.neon) or {
  cyan        = "#00d7ff",
  hotpink     = "#ff2d95",
  lime        = "#b7ff3a",
  purple      = "#9d7cff",
  orange      = "#ff9e1b",
  white       = "#ffffff",
  gray        = "#808080",
  neon_yellow = "#CFFF04",
  light_purple = "#d6afff",
  blue        = "#1e90ff",
  bg          = "#080808",
}

local colors = {
  hotpink     = neon.hotpink,
  neon_yellow = neon.neon_yellow,
  cyan        = neon.cyan,
  red         = "#ff5189",
  black       = neon.bg or "#080808",
  white       = "#c6c6c6",
  grey        = "#303030",
}

local bubbles_theme = {
  normal = {
    a = { fg = colors.black, bg = colors.hotpink }, -- hotpink for normal mode
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  insert = { 
    a = { fg = colors.black, bg = colors.neon_yellow }, -- neon yellow for insert
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  visual = { 
    a = { fg = colors.black, bg = colors.cyan }, -- cyan for visual
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  replace = { 
    a = { fg = colors.black, bg = colors.red }, -- red for replace
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  inactive = {
    a = { fg = colors.white, bg = "NONE" },
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
}

require('lualine').setup {
  options = {
    theme = bubbles_theme,
    section_separators = { left = '', right = '' }, -- no half-circles
    component_separators = '',
    globalstatus = true, -- full-width statusline
  },
  sections = {
    lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
    lualine_b = { 'filename', 'branch' },
    lualine_c = { '%=' },
    lualine_x = {
      function()
        local ok, ts = pcall(require, "theme_switcher")
        if ok then
          return " " .. ts.current_display()
        end
        return ""
      end,
    },
    lualine_y = { 'filetype', 'progress' },
    lualine_z = { { 'location', separator = { right = '' }, left_padding = 2 } },
  },
  inactive_sections = {
    lualine_a = { 'filename' },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = { 'location' },
  },
  tabline = {},
  extensions = {},
}

-- Ensure transparency (reapplied on ColorScheme)
local function apply_statusline_transparency()
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = colors.white })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", fg = colors.grey })
end

apply_statusline_transparency()

local sl_group = vim.api.nvim_create_augroup("StatuslineTransparency", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = sl_group,
  callback = apply_statusline_transparency,
})
vim.cmd("hi LualineReplace guibg=NONE")
vim.cmd("hi LualineCommand guibg=NONE")
