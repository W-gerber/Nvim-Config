-- plugins/config/cmp.lua
local present, cmp = pcall(require, 'cmp')
if not present then return end

local luasnip = require('luasnip')
local lspkind_ok, lspkind = pcall(require, 'lspkind')
if lspkind_ok then lspkind.init() end

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback) if cmp.visible() then cmp.select_next_item() elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump() else fallback() end end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback) if cmp.visible() then cmp.select_prev_item() elseif luasnip.jumpable(-1) then luasnip.jump(-1) else fallback() end end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'luasnip' } }, { { name = 'buffer' }, { name = 'path' } }),
  formatting = { format = lspkind_ok and lspkind.cmp_format({ with_text = true, maxwidth = 50 }) or nil },
})

-- Command-line completion (':' and '/' modes)
-- Provides LSP-like feel when entering Ex commands and searching.
-- Requires built-in cmdline & path sources (shipped with nvim-cmp).
-- NOTE: LSP servers do not attach to the command-line; this only supplies completion
-- for commands & paths via nvim-cmp sources. Ensure 'hrsh7th/cmp-cmdline' plugin is
-- added if not already (otherwise cmdline source won't exist).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } }),
})

cmp.setup.cmdline({'/', '?'}, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = { { name = 'buffer' } },
})
