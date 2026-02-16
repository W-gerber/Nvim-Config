return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  opts = {
    -- Treesitter provides better syntax highlighting and structural awareness.
    -- Keep this list focused on common languages to avoid unnecessary parsers.
    ensure_installed = {
      -- Neovim / config
      "lua",
      "vim",
      "vimdoc",
      "query",

      -- Shell + common text formats
      "bash",
      "regex",
      "json",
      "yaml",
      "toml",
      "markdown",
      "markdown_inline",

      -- Web
      "html",
      "css",
      "javascript",
      "typescript",

      -- General purpose
      "python",

      -- Your current focus
      "java",
    },
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
