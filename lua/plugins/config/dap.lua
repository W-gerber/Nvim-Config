-- plugins/config/dap.lua
local ok, dap = pcall(require, 'dap')
if not ok then return end

-- Example adapters can be expanded per language
-- Node/TS
if vim.fn.executable('node') == 1 then
  dap.adapters.node2 = {
    type = 'executable',
    command = 'node',
    args = { vim.fn.stdpath('data') .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
  }
  dap.configurations.typescript = {
    {
      name = 'Launch file',
      type = 'node2',
      request = 'launch',
      program = '${file}',
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
    },
  }
end
