-- plugins/config/telescope.lua
local present, telescope = pcall(require, 'telescope')
if not present then return end

local actions = require('telescope.actions')
telescope.setup({
  defaults = {
    prompt_prefix = '🔍 ',
    selection_caret = ' ',
    layout_strategy = 'horizontal',
    layout_config = { preview_width = 0.55 },
    sorting_strategy = 'ascending',
    winblend = 20,
    border = true,
    mappings = { i = { ['<esc>'] = actions.close } },
  }
})

-- Load extensions if installed
pcall(telescope.load_extension, 'live_grep_args')
