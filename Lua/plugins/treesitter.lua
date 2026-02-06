return {
  "nvim-treesitter/nvim-treesitter",
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
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
