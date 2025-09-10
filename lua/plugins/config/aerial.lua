-- plugins/config/aerial.lua
local ok, aerial = pcall(require, 'aerial')
if not ok then return end

aerial.setup({
  backends = { 'lsp', 'treesitter', 'markdown' },
  layout = { default_direction = 'right' },
})

-- Keymaps
vim.keymap.set('n', '<leader>o', '<cmd>AerialToggle!<CR>', { desc = 'Symbols outline' })
