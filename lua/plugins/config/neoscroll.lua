-- plugins/config/neoscroll.lua
local ok, neoscroll = pcall(require, "neoscroll")
if not ok then return end

neoscroll.setup({
  mappings = {'<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb'},
  hide_cursor = true,
  stop_eof = false,          -- allow scrolling past last window line smoothly, prevents bounce
  use_local_scrolloff = true,
  respect_scrolloff = true,  -- keep context lines stable
  cursor_scrolls_alone = false,
  easing_function = nil,
  pre_hook = nil,
  post_hook = nil,
})

-- Optional: adjust general scrolloff for smoother feel
vim.opt.scrolloff = 5
