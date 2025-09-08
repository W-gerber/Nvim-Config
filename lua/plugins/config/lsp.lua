-- plugins/config/lsp.lua
local present, lspconfig = pcall(require, 'lspconfig')
if not present then return end

local ok_mason, mason_lspconfig = pcall(require, 'mason-lspconfig')
local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if cmp_ok then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

local on_attach = function(client, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  bufmap('n', 'gd', vim.lsp.buf.definition, 'Goto definition')
  bufmap('n', 'K', vim.lsp.buf.hover, 'Hover')
  bufmap('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
  bufmap('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
  -- Unify old formatting mappings by providing <leader>lf which-key entry (see whichkey.lua) and command.
  vim.api.nvim_buf_create_user_command(bufnr, 'LspFormat', function()
    vim.lsp.buf.format({ async = true })
  end, { desc = 'Format buffer with attached LSP(s)' })
end

-- Ensure mason installed servers are setup
if ok_mason then
  mason_lspconfig.setup_handlers({
    function(server_name)
      lspconfig[server_name].setup({ on_attach = on_attach, capabilities = capabilities })
    end,
  })
end

-- Helper commands to surface LSP status (useful when :checkhealth run outside an attached buffer)
vim.api.nvim_create_user_command('LspStatus', function()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify('No LSP attached to current buffer (ft=' .. vim.bo.filetype .. ')', vim.log.levels.WARN)
    return
  end
  local lines = { 'Active LSP clients for buffer ' .. vim.api.nvim_get_current_buf() .. ':' }
  for _, c in ipairs(clients) do
    table.insert(lines, ('  • %s (id=%d)'):format(c.name, c.id))
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'LspStatus' })
end, { desc = 'Show LSP clients attached to current buffer' })

vim.api.nvim_create_user_command('LspAll', function()
  local clients = vim.lsp.get_active_clients()
  if #clients == 0 then
    vim.notify('No active LSP clients', vim.log.levels.WARN)
    return
  end
  local lines = { 'All active LSP clients:' }
  for _, c in ipairs(clients) do
    table.insert(lines, ('  • %s (id=%d)'):format(c.name, c.id))
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'LspAll' })
end, { desc = 'Show all active LSP clients across buffers' })
