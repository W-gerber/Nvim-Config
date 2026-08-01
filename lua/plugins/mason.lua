-- Mason: installs language servers and CLI tools into stdpath("data")/mason.
--
-- Split into three specs on purpose. mason.nvim itself only needs to exist when
-- you open its UI, but mason-lspconfig has to run during startup — it is what
-- calls `vim.lsp.enable()` for servers you have installed. While both lived in
-- one `cmd = { "Mason" }` spec, an installed server stayed dormant until you
-- happened to open the Mason window.
--
-- Repositories moved from `williamboman/*` to `mason-org/*` with Mason v2.

return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonLog" },
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        width = 0.8,
        height = 0.8,
        icons = {
          package_installed = "\u{f00c}", -- check
          package_pending = "\u{f0450}", -- arrow-down-circle
          package_uninstalled = "\u{f00d}", -- times
        },
      },
    },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    -- Loaded by plugins/lspconfig.lua (it lists this as a dependency), so the
    -- enable pass happens on the first real buffer rather than on :Mason.
    lazy = true,
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      -- Kept deliberately small: these two are what the config needs to edit
      -- itself and the current Java work. Everything else is one `:Mason`
      -- install away and is picked up automatically by `automatic_enable`,
      -- with settings already waiting in plugins/lspconfig.lua.
      ensure_installed = { "lua_ls", "jdtls" },

      -- v2 renamed `automatic_installation`; the old key was silently ignored.
      --
      -- `exclude` is not cosmetic. mason-lspconfig enables every installed
      -- package that nvim-lspconfig has a config for, and some formatters ship
      -- a nominal LSP mode: nvim-lspconfig has a `stylua` config (`stylua
      -- --lsp`), stylua is installed here as a *formatter* by
      -- mason-tool-installer, so every Lua buffer started a language server
      -- that exits 1 immediately —
      --
      --   Client stylua quit with exit code 1 and signal 0
      --
      -- on every file. conform calls the binary directly and is unaffected.
      automatic_enable = {
        exclude = { "stylua" },
      },
    },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      -- Formatters and linters that conform.nvim / nvim-lint shell out to.
      -- Only tools whose language is already set up here are listed, so a
      -- first launch doesn't download a toolchain you never asked for.
      ensure_installed = {
        "stylua", -- lua formatter
        "google-java-format", -- java formatter
        "shfmt", -- shell formatter
      },
      auto_update = false,
      run_on_start = true,
      start_delay = 3000, -- let the editor settle before hitting the network
      debounce_hours = 24,
    },
  },
}
