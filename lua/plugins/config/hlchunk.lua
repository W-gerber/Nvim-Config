-- plugins/config/hlchunk.lua
local ok, hlchunk = pcall(require, 'hlchunk')
if not ok then return end

hlchunk.setup({
  chunk = { enable = true },
  indent = { enable = true },
  line_num = { enable = false },
  blank = { enable = false },
})
