-- plugins/config/noice.lua
local ok, noice = pcall(require, 'noice')
if not ok then return end

noice.setup({
  presets = { bottom_search = true, command_palette = true, long_message_to_split = true },
  lsp = { signature = { enabled = true }, hover = { enabled = true } },
})
