-- plugins/config/noice.lua
local ok, noice = pcall(require, 'noice')
if not ok then return end

local colors = require('ui.colors').neon
local yellow = '#ffd866' -- match alpha's yellow (lime-yellow)

noice.setup({
  -- Pretty cmdline and messages
  cmdline = {
    view = 'cmdline_popup',
    format = {
      cmdline = { icon = '', lang = 'vim' },
      search_down = { icon = ' ' },
      search_up = { icon = ' ' },
      filter = { icon = '󰛵' },
      lua = { icon = '' },
      help = { icon = '󰮥' },
      input = { icon = '' },
    },
  },
  messages = {
    enabled = true,
    view = 'mini',
    view_error = 'notify',
    view_warn = 'notify',
    view_history = 'split',
    view_search = 'virtualtext',
  },
  popupmenu = { enabled = true, backend = 'nui' },
  lsp = {
    progress = { enabled = true },
    signature = { enabled = true },
    hover = { enabled = true },
    message = { enabled = true },
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
      ['cmp.entry.get_documentation'] = true,
    },
  },
  presets = {
    bottom_search = true,          -- bottom cmdline for / and ?
    command_palette = true,        -- position cmdline and popupmenu together
    long_message_to_split = true,  -- long messages to split
    inc_rename = true,             -- integrates with inc-rename
    lsp_doc_border = true,         -- border on hover/signature
  },
  views = {
    cmdline_popup = {
      position = {
        row = '90%',
        col = '50%'
      },
      size = {
        width = 60,
        height = 'auto',
      },
      border = {
        style = 'rounded',
        padding = { 0, 1 },
      },
      win_options = {
        winhighlight = table.concat({
          'Normal:NoiceCmdline',
          'FloatBorder:NoiceCmdlineBorder',
          'Search:NoiceCmdlineIcon',
        }, ','),
      },
    },
    popupmenu = {
      border = { style = 'rounded' },
      win_options = { winhighlight = 'Normal:NoicePopup,FloatBorder:NoicePopupBorder' },
    },
    hover = {
      border = { style = 'rounded' },
      win_options = { winhighlight = 'Normal:NoicePopup,FloatBorder:NoicePopupBorder' },
    },
    mini = {
      win_options = { winhighlight = 'Normal:NoiceMini' },
    },
  },
  routes = {
    -- Skip some noisy messages
    { filter = { event = 'msg_show', kind = 'search_count' }, opts = { skip = true } },
    { filter = { event = 'msg_show', kind = 'echo' }, opts = { skip = false } },
  },
})

-- Highlight groups to match the neon colorway
vim.api.nvim_set_hl(0, 'NoiceCmdline', { fg = yellow, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NoiceCmdlineBorder', { fg = colors.hotpink, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NoiceCmdlineIcon', { fg = yellow, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NoicePopup', { fg = yellow, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NoicePopupBorder', { fg = colors.hotpink, bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NoiceMini', { fg = yellow, bg = 'NONE' })

