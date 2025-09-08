-- plugins/config/jdtls.lua
-- Enhanced Java LSP configuration with project detection
local ok, jdtls = pcall(require, 'jdtls')
if not ok then return end

-- Auto-attach to Java files with basic root detection
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local root_dir = require('jdtls.setup').find_root({'.gradlew', 'pom.xml', '.git', 'mvnw'})
    if root_dir then
      local config = {
        cmd = { 'jdtls' },
        root_dir = root_dir,
        settings = {
          java = {
            signatureHelp = { enabled = true },
            completion = { enabled = true },
          }
        }
      }
      jdtls.start_or_attach(config)
    end
  end,
})
