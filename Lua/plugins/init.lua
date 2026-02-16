-- Aggregate Lazy.nvim plugin specs

local plugins = {
  require("plugins.base46"),
  require("plugins.web_devicons"),
  require("plugins.notify"),
  require("plugins.treesitter"),
  require("plugins.rainbow_delimiters"),
  require("plugins.indent_blankline"),
  require("plugins.treesitter_context"),
  require("plugins.autopairs"),
  require("plugins.flash"),
  require("plugins.trouble"),
  require("plugins.todo_comments"),
  require("plugins.mason"),
  require("plugins.lspconfig"),
  require("plugins.copilot"),
  require("plugins.copilot_chat"),
  require("plugins.cmp"),
  require("plugins.alpha"),
  require("plugins.lualine"),
  require("plugins.smear_cursor"),
  require("plugins.noice"),
  require("plugins.session_manager"),
  require("plugins.window_picker"),
  require("plugins.neo_tree"),
  require("plugins.telescope"),
  require("plugins.toggleterm"),
  require("plugins.gitsigns"),
  -- require("plugins.barbar"),  -- Disabled in favor of custom tabline
  require("plugins.lazygit"),
  require("plugins.which_key"),
}

-- Extend with colorscheme plugins (this module returns a list).
vim.list_extend(plugins, require("plugins.colorschemes"))

return plugins
