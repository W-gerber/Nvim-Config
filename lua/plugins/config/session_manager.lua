-- plugins/config/session_manager.lua
local present, session = pcall(require, 'session_manager')
if not present then return end

require('session_manager').setup({
  autoload_mode = require('session_manager.config').AutoloadMode.Disabled,
})
