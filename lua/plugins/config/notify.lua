-- plugins/config/notify.lua
local ok, notify = pcall(require, 'notify')
if not ok then return end

local colors = require('ui.colors').neon
local yellow = '#ffd866' -- alpha's yellow (lime-yellow vibe)

notify.setup({
  stages = 'fade_in_slide_out',
  timeout = 2500,
  render = 'default',
  top_down = false,
  -- Must be an RGB hex or a group with a bg color; use black for transparency math
  background_colour = '#000000',
})

vim.notify = notify

-- Match notify highlights to neon palette
vim.api.nvim_set_hl(0, 'NotifyINFOBorder', { fg = colors.hotpink, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyINFOTitle', { fg = yellow, bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'NotifyINFOIcon', { fg = yellow, bg = 'NONE' })

vim.api.nvim_set_hl(0, 'NotifyWARNBorder', { fg = colors.hotpink, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyWARNTitle', { fg = yellow, bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'NotifyWARNIcon', { fg = yellow, bg = 'NONE' })

vim.api.nvim_set_hl(0, 'NotifyERRORBorder', { fg = colors.purple, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyERRORTitle', { fg = yellow, bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'NotifyERRORIcon', { fg = yellow, bg = 'NONE' })

vim.api.nvim_set_hl(0, 'NotifyDEBUGBorder', { fg = colors.lime, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyDEBUGTitle', { fg = yellow, bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'NotifyDEBUGIcon', { fg = yellow, bg = 'NONE' })

-- Ensure only text is colored (transparent bg) across message bodies
vim.api.nvim_set_hl(0, 'NotifyINFOBody', { fg = yellow, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyWARNBody', { fg = yellow, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyERRORBody', { fg = yellow, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyDEBUGBody', { fg = yellow, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NotifyTRACEBody', { fg = yellow, bg = 'NONE' })
