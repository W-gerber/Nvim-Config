-- plugins/config/neotest.lua
local present, neotest = pcall(require, 'neotest')
if not present then return end

local adapters = {}
pcall(function() adapters[#adapters+1] = require('neotest-python') end)
pcall(function() adapters[#adapters+1] = require('neotest-go') end)

neotest.setup({ adapters = adapters })
