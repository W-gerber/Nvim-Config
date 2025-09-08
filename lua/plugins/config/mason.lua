-- plugins/config/mason.lua
local present, mason = pcall(require, 'mason')
if not present then return end

require('mason').setup({
	ui = { border = 'rounded' },
	-- On Windows some language servers (esp. heavy ones) may not be desired by default.
	-- Users can install them manually via :Mason.
})
local mlsp = require('mason-lspconfig')
mlsp.setup({
	automatic_installation = false, -- be explicit; reduce startup async noise on Windows
	ensure_installed = { 'lua_ls' }, -- keep minimal baseline; others optional
})

-- wire mason-null-ls if available
pcall(function()
	require('mason-null-ls').setup({
		automatic_installation = false,
		ensure_installed = { 'stylua', 'prettierd' }, -- lightweight defaults; go/python tools optional
	})
end)
