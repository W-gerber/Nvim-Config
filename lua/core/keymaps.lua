-- core/keymaps.lua
local keymap = vim.keymap

-- Keep old mappings but move to grouped leader keys
keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search" })
keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })

-- Telescope shortcuts
keymap.set('n', '<leader>ff', ':Telescope find_files<CR>', { desc = 'Find files' })
keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>', { desc = 'Live grep' })
keymap.set('n', '<leader>fb', ':Telescope buffers<CR>', { desc = 'Open buffers' })

-- Git
keymap.set('n', '<leader>gs', ':Gitsigns stage_hunk<CR>', { desc = 'Stage hunk' })

-- LSP convenience
keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { desc = 'Goto definition' })
keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', { desc = 'Hover' })

-- Smooth scroll: use neoscroll if available
local ok = pcall(require, 'neoscroll')
if ok then
	-- neoscroll provides good defaults; no extra mappings needed
else
	-- fallback simple mappings
	keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Page down and center' })
	keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Page up and center' })
end

return {}
