-- Formatting front-end. conform picks the right formatter per filetype and
-- falls back to the language server when none is configured.
--
-- Binaries come from mason-tool-installer (see plugins/mason.lua) for the
-- languages this config installs by default; the rest resolve from PATH or a
-- project's own node_modules, which is what `prettierd`/`prettier` below rely
-- on. A formatter that isn't installed is skipped, not an error.
--
-- On `lsp_format` vs `lsp_fallback`: conform's option is `lsp_format`, whose
-- value is one of "never" | "fallback" | "prefer" | "first" | "last". The older
-- boolean `lsp_fallback = true` was removed, and passing it is what produces
--
--     Cannot assign boolean to conform.FormatOpts
--
-- from lua_ls. `lsp_format = "fallback"` is the same behaviour, spelled the way
-- the current API expects.

-- Formatters that routinely take longer than a save should block for: the
-- prettier family on a cold node start, and anything that boots a JVM or a
-- Python interpreter first. These filetypes are formatted *after* the write
-- instead, asynchronously, so saving never stalls the editor — conform writes
-- the result back and saves again once the formatter returns.
local SLOW_FILETYPES = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  css = true,
  scss = true,
  html = true,
  json = true,
  jsonc = true,
  yaml = true,
  markdown = true,
  java = true,
  cs = true,
  sql = true,
}

-- Synchronous formats get a short leash. A formatter that cannot finish in this
-- long is one that belongs in SLOW_FILETYPES, not one worth freezing a save for.
local SYNC_TIMEOUT_MS = 500

local function format_on_save(bufnr)
  if not vim.g.format_on_save then
    return nil
  end

  if SLOW_FILETYPES[vim.bo[bufnr].filetype] then
    return nil -- handled by format_after_save below
  end

  return { timeout_ms = SYNC_TIMEOUT_MS, lsp_format = "fallback" }
end

local function format_after_save(bufnr)
  if not vim.g.format_on_save then
    return nil
  end

  if not SLOW_FILETYPES[vim.bo[bufnr].filetype] then
    return nil -- already formatted synchronously
  end

  -- No timeout_ms: async formats are not bounded by one, and nothing is
  -- blocked while it runs.
  return { lsp_format = "fallback" }
end

return {
  "stevearc/conform.nvim",
  cmd = { "ConformInfo" },
  event = { "BufReadPre", "BufNewFile" },
  init = function()
    -- On by default; `<leader>cF` turns it off for a session spent in a repo
    -- that uses a different style. Set here rather than in `config` so the
    -- value exists before the first write triggers the plugin to load.
    if vim.g.format_on_save == nil then
      vim.g.format_on_save = true
    end
  end,
  keys = {
    {
      -- In visual mode conform formats the selection: `format()` reads the
      -- current mode and derives `range` from the marks itself, so one mapping
      -- covers whole-buffer and range formatting.
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
      mode = { "n", "v" },
      desc = "Format buffer / selection",
    },
    {
      -- Blocking variant, for when you want the file on disk formatted before
      -- the next command runs (a commit, a test run).
      "<leader>cw",
      function()
        require("conform").format({ async = false, timeout_ms = 5000, lsp_format = "fallback" })
        vim.cmd("write")
      end,
      desc = "Format and write",
    },
    {
      "<leader>cF",
      function()
        vim.g.format_on_save = not vim.g.format_on_save
        vim.notify("Format on save " .. (vim.g.format_on_save and "on" or "off"), vim.log.levels.INFO)
      end,
      desc = "Toggle format on save",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      java = { "google-java-format" },

      -- `stop_after_first` means "the first of these that is installed wins",
      -- so a project with prettierd gets the fast daemon and one without still
      -- formats via plain prettier.
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      jsonc = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },

      python = { "ruff_format", "black", stop_after_first = true },
      go = { "goimports", "gofmt" },
      rust = { "rustfmt" },
      nix = { "nixfmt" },
      cs = { "csharpier" },
      sql = { "sqlfluff" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      toml = { "taplo" },

      -- Trailing whitespace and stray final newlines, everywhere else.
      ["_"] = { "trim_whitespace", "trim_newlines" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    formatters = {
      shfmt = { prepend_args = { "-i", "2", "-ci" } },
    },
    format_on_save = format_on_save,
    format_after_save = format_after_save,
    -- A missing formatter is a non-event (see the note at the top); a broken
    -- one should say so.
    notify_on_error = true,
    notify_no_formatters = false,
  },
}
