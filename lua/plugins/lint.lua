-- Linting for languages whose diagnostics don't come from a language server.
--
-- This is deliberately complementary to LSP rather than a replacement: where a
-- server already reports diagnostics (lua_ls, ts_ls, gopls, ...) adding a
-- linter just duplicates them. What is listed here are the tools that catch
-- what servers don't — shellcheck for shell, ruff's lint rules for Python,
-- markdownlint for prose, eslint for the project-level rules tsserver has no
-- opinion about.
--
-- Every linter is optional and none of them is checked in: `resolve()` below
-- drops any whose executable isn't on PATH, so a machine where you haven't run
-- `:Mason` yet lints with whatever it has and stays quiet about the rest.
--
-- How the results *look* is not configured here — nvim-lint publishes into
-- `vim.diagnostic`, which core/diagnostics.lua owns for every producer.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile", "BufWritePost" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      markdown = { "markdownlint" },
      dockerfile = { "hadolint" },
      yaml = { "yamllint" },
      python = { "ruff" },

      -- eslint_d is the daemon; plain eslint costs a node startup per lint,
      -- which is why only the daemon is listed. Both are project-local tools,
      -- so this is a no-op in a repo that doesn't use them.
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
    }

    -- ------------------------------------------------------------------
    -- Which linters can actually run
    -- ------------------------------------------------------------------

    -- `try_lint` reports a missing binary as an error notification, once per
    -- attempt — on every save, in every buffer of that filetype. Resolving the
    -- command up front and passing only the runnable ones keeps that quiet
    -- without hiding real failures.
    --
    -- Results are cached per linter, but only for the ones whose `cmd` is a
    -- fixed string: `executable()` hits the filesystem and this runs on
    -- TextChanged. A `cmd` that is a *function* resolves a project-local binary
    -- (eslint_d walks up looking for node_modules/.bin), so its answer depends
    -- on the current file and must not be remembered across buffers.
    local runnable = {}

    ---@param name string
    ---@return boolean
    local function is_runnable(name)
      if runnable[name] ~= nil then
        return runnable[name]
      end

      local linter = lint.linters[name]
      if type(linter) ~= "table" then
        runnable[name] = false
        return false
      end

      local cmd = linter.cmd

      if type(cmd) == "function" then
        local ok, resolved = pcall(cmd)
        return ok and type(resolved) == "string" and vim.fn.executable(resolved) == 1
      end

      runnable[name] = type(cmd) == "string" and vim.fn.executable(cmd) == 1

      return runnable[name]
    end

    --- Linters configured for `filetype` that are installed. Empty when the
    --- filetype has none, which is the signal not to lint at all.
    ---@param filetype string
    ---@return string[]
    local function resolve(filetype)
      local names = lint.linters_by_ft[filetype]
      if not names or vim.tbl_isempty(names) then
        return {}
      end

      return vim.tbl_filter(is_runnable, names)
    end

    -- A new tool installed mid-session (`:Mason`) should be picked up without a
    -- restart.
    vim.api.nvim_create_autocmd("User", {
      pattern = { "MasonToolsUpdateCompleted", "LazyReload" },
      group = vim.api.nvim_create_augroup("UserLintCacheReset", { clear = true }),
      callback = function() runnable = {} end,
    })

    -- ------------------------------------------------------------------
    -- When to lint
    -- ------------------------------------------------------------------

    --- Real, on-disk buffers of a filetype we have a linter for.
    ---@param buf integer
    ---@return boolean
    local function should_lint(buf)
      if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
        return false
      end

      -- Terminals, help, quickfix, Neo-tree, the dashboard: nothing to lint,
      -- and several of them have no file behind them at all.
      if vim.bo[buf].buftype ~= "" then
        return false
      end

      return #resolve(vim.bo[buf].filetype) > 0
    end

    local timer = assert(vim.uv.new_timer())
    local DEBOUNCE_MS = 300

    --- Lint `buf` after the debounce window, with only the linters that exist.
    ---@param buf integer
    local function try_lint(buf)
      timer:stop()
      timer:start(
        DEBOUNCE_MS,
        0,
        vim.schedule_wrap(function()
          -- The buffer can be gone, unloaded or a different filetype by the
          -- time the timer fires.
          if not should_lint(buf) then
            return
          end

          local names = resolve(vim.bo[buf].filetype)
          -- `lint.try_lint` reads the current buffer, so run it in the window
          -- showing `buf` — otherwise a debounced lint fired just before a
          -- buffer switch would attach its diagnostics to the wrong file.
          if vim.api.nvim_get_current_buf() ~= buf then
            return
          end

          lint.try_lint(names)
        end)
      )
    end

    local group = vim.api.nvim_create_augroup("UserLint", { clear = true })

    -- BufReadPost / BufEnter: lint what you are looking at, including buffers
    -- you come back to. BufWritePost: the canonical moment. InsertLeave and
    -- TextChanged (normal-mode edits only — TextChangedI would fire per
    -- keystroke) catch the rest, debounced.
    vim.api.nvim_create_autocmd({
      "BufReadPost",
      "BufEnter",
      "BufWritePost",
      "InsertLeave",
      "TextChanged",
    }, {
      group = group,
      callback = function(event) try_lint(event.buf) end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("UserLintCleanup", { clear = true }),
      callback = function()
        timer:stop()
        if not timer:is_closing() then
          timer:close()
        end
      end,
    })

    -- Manual lint, unfiltered: this one *should* complain about a missing
    -- binary, because you asked for it explicitly.
    vim.keymap.set("n", "<leader>cl", function()
      local names = lint.linters_by_ft[vim.bo.filetype]
      if not names or vim.tbl_isempty(names) then
        vim.notify("No linter configured for " .. vim.bo.filetype, vim.log.levels.INFO)
        return
      end

      lint.try_lint()
    end, { desc = "Lint buffer now", silent = true })
  end,
}
