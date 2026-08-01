return {
  -- Full Neovim API completion and docs while editing this config: lazydev
  -- teaches lua_ls about the runtime and about plugin types on demand, which is
  -- far cheaper (and more accurate) than pointing `workspace.library` at
  -- everything up front.
  "folke/lazydev.nvim",
  ft = "lua",
  cmd = "LazyDev",
  opts = {
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "lazy.nvim", words = { "LazySpec" } },
      { path = "snacks.nvim", words = { "Snacks" } },
    },
  },
}
