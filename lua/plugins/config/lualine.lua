-- plugins/config/lualine.lua
local ok, lualine = pcall(require, "lualine")
if not ok then return end

local colors = require("ui.colors")

lualine.setup({
  options = {
    theme = "tokyonight",
    section_separators = { left = '', right = '' },
    component_separators = { left = '', right = '' },
    globalstatus = true,
    icons_enabled = true,
  },
  sections = {
    lualine_a = { 
      { 'mode', 
        fmt = function(s) return s:sub(1,3) end,
        separator = { left = '' }, 
        right_padding = 2 
      } 
    },
    lualine_b = { 
      { 'filename', file_status = true, path = 1 } 
    },
    lualine_c = { 
      { 'diagnostics', sources = { 'nvim_lsp' } }
    },
    lualine_x = { 'branch' },
    lualine_y = { 'location' },
    lualine_z = { 
      { function() return "✨ " .. os.date('%H:%M') end,
        separator = { right = '' }, 
        left_padding = 2 
      }
    },
  },
})
