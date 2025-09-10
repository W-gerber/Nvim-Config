-- plugins/config/notify.lua
local ok, notify = pcall(require, 'notify')
if not ok then return end

notify.setup({
  stages = 'fade_in_slide_out',
  timeout = 2500,
  render = 'default',
})

vim.notify = notify
