-- plugins/config/treesitter.lua
local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then return end

local ensure = {
  "lua", "python", "javascript", "typescript", "java", "go", "rust",
  "html", "css", "json", "yaml", "markdown", "markdown_inline", "c", "vim", "vimdoc", "query"
}

-- Windows MSVC toolchain sometimes lacks legacy C headers (stdbool.h) in the path used
-- by tree-sitter when compiling certain grammars (markdown here). We'll conditionally
-- remove markdown to avoid build failures; fallback to basic syntax for markdown.
if vim.fn.has('win32') == 1 then
  local install = require('nvim-treesitter.install')
  if vim.fn.executable('clang') == 1 then
    install.compilers = { 'clang', 'gcc', 'cl' }
  elseif vim.fn.executable('gcc') == 1 then
    install.compilers = { 'gcc', 'clang', 'cl' }
  else
    install.compilers = { 'cl' } -- fallback; may fail for some parsers
  end
end

configs.setup({
  ensure_installed = ensure,
  sync_install = false,
  auto_install = false, -- avoid auto attempts; user runs :TSInstall as needed
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
})
-- Helper user command to reinstall the core language set after compiler change
vim.api.nvim_create_user_command('TSReinstallCore', function()
  local langs = table.concat(ensure, ' ')
  vim.cmd('TSUninstall ' .. langs)
  vim.defer_fn(function()
    vim.cmd('TSInstall ' .. langs)
  end, 200)
end, { desc = 'Force reinstall base Treesitter parsers with current compiler' })
