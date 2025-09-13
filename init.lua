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
pcall(require, "ui.neon_vomit")

  -- Friendly greeter notification (transparent bg, yellow text via notify highlights)
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- Only show message if not opening with files
    if vim.fn.argc() == 0 then
      vim.defer_fn(function()
          -- Rotate user-provided messages for the greeter
          local user = os.getenv('USERNAME') or os.getenv('USER') or 'user'
          local variants = {
            string.format("Welcome back, %s. The terminal missed your chaos. 🚀", user),
            "Breathe in, breathe out... now let’s write some bugs. 🧘‍♂️💻",
            "Remember: git commit > self doubt. Let’s code. ✅",
            "01101000 01100101 01111001 ... oh, just ‘hey’. 👾",
          }

          -- Deterministic-ish rotation per minute to avoid repeating on the same session
          local idx = (tonumber(os.date('%M')) or 0) % #variants + 1
          local msg = variants[idx]
          vim.notify(msg, vim.log.levels.INFO, { title = "Welcome", timeout = 2800 })
      end, 1000)
    end
  end,
})
