-- plugins/config/dropbar.lua
local ok, dropbar = pcall(require, 'dropbar')
if not ok then return end

dropbar.setup({})
