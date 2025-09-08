-- init.lua - bootstrap lazy.nvim and load modular config
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Core (settings includes provider disabling & Ls fallback)
require("core.settings")
require("core.keymaps")
require("core.autocmds")

-- Plugins (lazy.nvim will load modules under lua/plugins)
require("plugins.init")

-- UI (themes/highlights) applied after plugins to ensure color groups exist
pcall(require, "ui.theme")

-- Helpful message with enhanced styling
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- Only show message if not opening with files
    if vim.fn.argc() == 0 then
      vim.defer_fn(function()
        vim.notify(" Tokyo Neon Skyline IDE loaded successfully! ", vim.log.levels.INFO, {
          title = "Neovim Ready",
          timeout = 3000,
        })
      end, 1000)
    end
  end,
})
