-- plugins/init.lua
-- Central plugin spec using lazy.nvim

local has_lazy, lazy = pcall(require, "lazy")
if not has_lazy then
  vim.notify("lazy.nvim not installed - plugins won't be loaded", vim.log.levels.WARN)
  return
end

local plugins = {
  -- Theme & core UI
  { 'folke/tokyonight.nvim', priority = 1000 },
  { 'nvim-tree/nvim-web-devicons' },

  -- File explorer (neo-tree fully replaces any legacy nvim-tree usage)
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = { 'nvim-lua/plenary.nvim', 'MunifTanjim/nui.nvim', 'nvim-tree/nvim-web-devicons' },
    cmd = 'Neotree',
    keys = { { '<leader>e', '<cmd>Neotree toggle<cr>', desc = 'Explorer' } },
  },

  -- Status / buffers
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
  { 'akinsho/bufferline.nvim', version = '*', dependencies = { 'nvim-tree/nvim-web-devicons' } },

  -- Dashboard (alpha only; removed any duplicate/alternate dashboards)
  { 'goolord/alpha-nvim', event = 'VimEnter' },

  -- Essentials
  { 'nvim-lua/plenary.nvim', lazy = true },

  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'Telescope',
    keys = {
      { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
      { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live grep' },
      { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
      { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'Recent files' },
    },
  },

  -- Treesitter
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate', event = { 'BufReadPost', 'BufNewFile' } },

  -- LSP & tooling (minimal ensure_installed moved to mason.lua)
  { 'williamboman/mason.nvim', cmd = 'Mason' },
  { 'williamboman/mason-lspconfig.nvim', dependencies = { 'mason.nvim' } },
  { 'neovim/nvim-lspconfig', event = { 'BufReadPre', 'BufNewFile' } },

  -- Completion
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
  'hrsh7th/cmp-cmdline', -- for : and / completion
      'onsails/lspkind.nvim',
    },
  },

  -- UX / Git / Project
  { 'lewis6991/gitsigns.nvim', event = 'BufReadPre' },
  { 'folke/which-key.nvim', event = 'VeryLazy' },
  { 'Shatur/neovim-session-manager', cmd = 'SessionManager' },
  { 'ahmedkhalf/project.nvim', event = 'VeryLazy' },
  { 'tpope/vim-fugitive', cmd = { 'Git', 'Gread', 'Gwrite', 'Gdiffsplit' } },
  { 'sindrets/diffview.nvim', dependencies = { 'nvim-lua/plenary.nvim' }, cmd = 'DiffviewOpen' },

  -- Language specific
  { 'mfussenegger/nvim-jdtls', ft = 'java' },

  -- Visual enhancements
  { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', event = 'BufReadPost', opts = {} },
  { 'karb94/neoscroll.nvim', event = 'BufReadPost' },
  { 'windwp/nvim-autopairs', event = 'InsertEnter' },

  -- Search / navigation
  { 'nvim-pack/nvim-spectre', cmd = 'Spectre' },
  { 'folke/trouble.nvim', cmd = 'Trouble' },

  -- Formatting & linting (null-ls; safe checks inside config file)
  { 'jose-elias-alvarez/null-ls.nvim', event = 'BufReadPre' },
  { 'jayp0521/mason-null-ls.nvim', dependencies = { 'mason.nvim', 'null-ls.nvim' } },
  { 'folke/neodev.nvim', ft = 'lua' },

  -- Testing
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-neotest/neotest-python',
      'nvim-neotest/neotest-go',
    },
    cmd = 'Neotest',
  },
}

lazy.setup(plugins, {
  performance = { rtp = { disabled_plugins = { 'gzip', 'tarPlugin', 'tohtml', 'tutor' } } },
  rocks = { enabled = false }, -- Disable LuaRocks integration (Windows noise + unused)
})

-- Try to load small per-plugin configs if present
pcall(require, "plugins.config.tokyonight")
pcall(require, "plugins.config.alpha") -- only dashboard retained
pcall(require, "plugins.config.lualine")
pcall(require, "plugins.config.bufferline")
pcall(require, "plugins.config.neo-tree")
pcall(require, "plugins.config.telescope")
pcall(require, "plugins.config.treesitter")
pcall(require, "plugins.config.gitsigns")
pcall(require, "plugins.config.whichkey")
pcall(require, "plugins.config.mason")
pcall(require, "plugins.config.lsp")
pcall(require, "plugins.config.cmp")
pcall(require, "plugins.config.session_manager")
pcall(require, "plugins.config.project")
pcall(require, "plugins.config.null-ls")
pcall(require, "plugins.config.mason-null-ls")
pcall(require, "plugins.config.neodev")
pcall(require, "plugins.config.neotest")
pcall(require, "plugins.config.diffview")
pcall(require, "plugins.config.jdtls")
pcall(require, "plugins.config.neoscroll")
pcall(require, "plugins.config.autopairs")

return {}
