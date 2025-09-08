-- plugins/config/mason-null-ls.lua
local present, mason_null_ls = pcall(require, 'mason-null-ls')
if not present then return end

mason_null_ls.setup({ automatic_installation = true, ensure_installed = { 'prettierd', 'stylua', 'eslint_d', 'gofmt', 'flake8' } })
