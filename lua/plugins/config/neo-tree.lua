-- plugins/config/neo-tree.lua
local present, neotree = pcall(require, 'neo-tree')
if not present then return end

require('neo-tree').setup({
  close_if_last_window = true,
  popup_border_style = 'rounded',
  enable_git_status = true,
  enable_diagnostics = true,
  window = {
    position = 'left',
    width = 35,
    mapping_options = { noremap = true, nowait = true },
  },
  filesystem = {
    filtered_items = { visible = false },
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
  },
})

-- Make floats transparent
vim.api.nvim_create_autocmd('FileType', { pattern = 'neo-tree', callback = function() vim.cmd('hi NeoTreeNormal guibg=NONE') end })
