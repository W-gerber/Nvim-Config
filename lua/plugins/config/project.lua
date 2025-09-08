-- plugins/config/project.lua
local present, project = pcall(require, 'project_nvim')
if not present then return end

require('project_nvim').setup({
  detection_methods = { 'lsp', 'pattern' },
  patterns = { '.git', 'package.json', 'Makefile' },
})

-- telescope integration
pcall(require, 'telescope').load_extension('projects')
