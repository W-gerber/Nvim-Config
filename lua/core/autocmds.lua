-- core/autocmds.lua
-- Small centralized autocmds for UI polish

-- Transparent background on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("hi Normal guibg=NONE")
  end,
})

-- Keep some plugin windows transparent
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "neo-tree", "TelescopePrompt", "alpha" },
  callback = function()
    vim.cmd("hi Normal guibg=NONE")
  end,
})

return {}
