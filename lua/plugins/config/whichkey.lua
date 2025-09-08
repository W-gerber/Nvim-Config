-- plugins/config/whichkey.lua
local ok, which_key = pcall(require, 'which-key')
if not ok then return end

-- Modern which-key setup (v3 style retains backwards compat but we clean duplicates)
which_key.setup({
  preset = 'modern', -- enables refined defaults; falls back gracefully if unsupported
  icons = { mappings = false },
})

-- Updated mapping spec uses nested tables with "name" for group names.
-- Flattened new-spec mappings (removes health warning)
which_key.add({
  { '<leader>a', group = 'Advanced Search' },
  { '<leader>as', '<cmd>Telescope live_grep<CR>', desc = 'Live Grep' },
  { '<leader>ar', function() require('spectre').open() end, desc = 'Spectre' },

  { '<leader>f', group = 'Files' },
  { '<leader>ff', '<cmd>Telescope find_files<CR>', desc = 'Find File' },
  { '<leader>ft', '<cmd>Neotree toggle<CR>', desc = 'Tree' },
  { '<leader>fb', '<cmd>Telescope buffers<CR>', desc = 'Buffers' },
  { '<leader>fr', '<cmd>Telescope oldfiles<CR>', desc = 'Recent' },

  { '<leader>g', group = 'Git' },
  { '<leader>gs', '<cmd>Gitsigns stage_hunk<CR>', desc = 'Stage Hunk' },
  { '<leader>gb', '<cmd>Gitsigns blame_line<CR>', desc = 'Blame' },
  { '<leader>gd', '<cmd>Gitsigns diffthis<CR>', desc = 'Diff' },
  { '<leader>gv', '<cmd>DiffviewOpen<CR>', desc = 'Diffview' },
  { '<leader>gc', '<cmd>Git commit<CR>', desc = 'Commit' },

  { '<leader>w', group = 'Workspace' },
  { '<leader>ws', '<cmd>SessionManager save_current_session<CR>', desc = 'Save Session' },
  { '<leader>wl', '<cmd>SessionManager load_session<CR>', desc = 'Load Session' },
  { '<leader>wp', '<cmd>Telescope projects<CR>', desc = 'Projects' },

  { '<leader>l', group = 'LSP' },
  { '<leader>ld', function() vim.diagnostic.open_float() end, desc = 'Diagnostics' },
  { '<leader>la', function() vim.lsp.buf.code_action() end, desc = 'Code Action' },
  { '<leader>lf', function() vim.lsp.buf.format({ async = true }) end, desc = 'Format' },
  { '<leader>lr', function() vim.lsp.buf.rename() end, desc = 'Rename' },
  { '<leader>lj', function() pcall(function() require('jdtls').start({}) end) end, desc = 'Start jdtls' },

  { '<leader>t', group = 'Tests' },
  { '<leader>tn', function() require('neotest').run.run() end, desc = 'Run Nearest' },
  { '<leader>tf', function() require('neotest').run.run({ suite = true }) end, desc = 'Run File' },
  { '<leader>ta', function() require('neotest').run.run(vim.fn.getcwd()) end, desc = 'Run All' },
})
