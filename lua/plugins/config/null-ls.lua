-- plugins/config/null-ls.lua
-- plugins/config/null-ls.lua
-- Robust null-ls setup with safe existence checks & deprecated API avoidance.
-- NOTE: null-ls has moved to none-ls upstream; this config keeps compatibility.
local ok, null_ls = pcall(require, 'null-ls')
if not ok then return end

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics

-- Helper to include a builtin only if its underlying executable exists.
local function with_exec(builtin)
  if not builtin then return nil end
  local exe = builtin._opts and builtin._opts.command or builtin._opts and builtin._opts.cmd
  -- Fallback: many builtins expose filetypes; we attempt common command mapping.
  if not exe and builtin.name then exe = builtin.name end
  if exe and vim.fn.executable(exe) == 0 then return nil end
  return builtin
end

local sources = {
  with_exec(formatting.prettierd),
  with_exec(formatting.stylua),
  with_exec(diagnostics.eslint_d),
  with_exec(formatting.gofmt), -- Will be skipped if Go toolchain absent
  with_exec(diagnostics.flake8),
}

-- Filter out nils (missing executables)
local filtered = {}
for _, src in ipairs(sources) do if src then table.insert(filtered, src) end end

null_ls.setup({
  sources = filtered,
  on_init = function(new_client, _)
    -- Prefer built-in formatting API if available
    if new_client.supports_method('textDocument/formatting') then
      -- no-op placeholder; actual formatting invoked via vim.lsp.buf.format()
    end
  end,
  -- Use newer Neovim API (>=0.8) calling style via vim.lsp.buf.format()
})

-- Provide a :Format command that safely calls the new API.
vim.api.nvim_create_user_command('Format', function()
  local buf = vim.api.nvim_get_current_buf()
  vim.lsp.buf.format({ async = true, bufnr = buf })
end, { desc = 'Format current buffer via LSP/null-ls' })
