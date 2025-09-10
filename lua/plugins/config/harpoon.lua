-- plugins/config/harpoon.lua
local ok, harpoon = pcall(require, 'harpoon')
if not ok then return end

local harpoon_mark = require('harpoon.mark')
local harpoon_ui = require('harpoon.ui')

harpoon:setup({})

vim.keymap.set('n', "<leader>ha", harpoon_mark.add_file, { desc = 'Harpoon add file' })
vim.keymap.set('n', "<leader>hh", harpoon_ui.toggle_quick_menu, { desc = 'Harpoon menu' })
