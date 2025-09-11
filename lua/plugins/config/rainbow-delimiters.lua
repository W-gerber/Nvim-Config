-- plugins/config/rainbow-delimiters.lua
local ok, rainbow = pcall(require, 'rainbow-delimiters')
if not ok then return end

local colors = require('ui.colors')

vim.g.rainbow_delimiters = {
  highlight = {
    'RainbowDelimiterRed',
    'RainbowDelimiterYellow',
    'RainbowDelimiterBlue',
    'RainbowDelimiterOrange',
    'RainbowDelimiterGreen',
    'RainbowDelimiterViolet',
    'RainbowDelimiterCyan',
  },
}

-- Neon rainbow highlight groups
local function hl(group, spec) vim.api.nvim_set_hl(0, group, spec) end
hl('RainbowDelimiterRed', { fg = colors.neon.hotpink })
hl('RainbowDelimiterYellow', { fg = '#ffcc00' })
hl('RainbowDelimiterBlue', { fg = colors.neon.cyan })
hl('RainbowDelimiterOrange', { fg = '#ff9e64' })
hl('RainbowDelimiterGreen', { fg = colors.neon.lime })
hl('RainbowDelimiterViolet', { fg = colors.neon.purple })
hl('RainbowDelimiterCyan', { fg = '#7cecff' })
