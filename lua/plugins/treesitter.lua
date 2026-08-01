-- Treesitter, plus the structural text objects and motions built on it.
--
-- Two plugins with two different config styles, which is worth knowing before
-- editing this file. nvim-treesitter is pinned to `master` and is configured
-- the classic way, through `require("nvim-treesitter.configs").setup(opts)`.
-- nvim-treesitter-textobjects tracks `main`, which is a full rewrite: its
-- modules moved from `nvim-treesitter.textobjects.*` to
-- `nvim-treesitter-textobjects.*`, it no longer reads a `textobjects` key out
-- of nvim-treesitter's options, and it declares no keymaps of its own.
--
-- Passing it the old nested `textobjects = { select = ..., move = ... }` table
-- fails silently — nvim-treesitter ignores keys it doesn't own — so every text
-- object and motion below is set explicitly further down instead.

-- Selection text objects, as `{ lhs, query, description }`.
local SELECT = {
  { "af", "@function.outer", "a function" },
  { "if", "@function.inner", "inner function" },
  { "ac", "@class.outer", "a class" },
  { "ic", "@class.inner", "inner class" },
  { "aa", "@parameter.outer", "an argument" },
  { "ia", "@parameter.inner", "inner argument" },
  { "ai", "@conditional.outer", "a conditional" },
  { "ii", "@conditional.inner", "inner conditional" },
  { "al", "@loop.outer", "a loop" },
  { "il", "@loop.inner", "inner loop" },
  { "a/", "@comment.outer", "a comment" },
}

-- Motions, as `{ suffix, query, noun }` — each becomes a `]x` / `[x` pair.
--
-- Class motions use `]C`/`[C`, not `]c`/`[c`: the lowercase pair is Vim's
-- native "next change" and belongs to gitsigns here.
local MOVE = {
  { "f", "@function.outer", "function" },
  { "C", "@class.outer", "class" },
  { "a", "@parameter.inner", "argument" },
}

return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  cmd = { "TSUpdate", "TSInstall", "TSInstallInfo", "TSModuleInfo" },
  dependencies = {
    -- Structural text objects: `vif` (inner function), `dac` (a class), and
    -- the `]f` / `[f` style motions below.
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  opts = {
    -- Parsers for the languages this config is themed and tooled for. Anything
    -- outside this list still works: `auto_install` fetches it on first open.
    ensure_installed = {
      -- Neovim / config
      "lua",
      "luadoc",
      "vim",
      "vimdoc",
      "query",

      -- Shell + data formats
      "bash",
      "regex",
      "json",
      "jsonc",
      "yaml",
      "toml",
      "xml",
      "sql",
      "dockerfile",

      -- Git
      "diff",
      "git_config",
      "git_rebase",
      "gitcommit",
      "gitignore",

      -- Prose
      "markdown",
      "markdown_inline",

      -- Web
      "html",
      "css",
      "scss",
      "javascript",
      "jsdoc",
      "typescript",
      "tsx",

      -- General purpose
      "c",
      "c_sharp",
      "go",
      "gomod",
      "java",
      "python",
      "rust",
    },
    auto_install = true,
    highlight = {
      enable = true,
      -- Running the legacy regex syntax engine alongside Treesitter doubles the
      -- highlighting work and lets the two disagree about colors.
      additional_vim_regex_highlighting = false,
      -- Treesitter highlighting on a minified bundle is pathologically slow.
      disable = function(_, buf)
        local max_filesize = 200 * 1024
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        return ok and stats and stats.size > max_filesize
      end,
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

    local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
    if not ok then
      return
    end

    textobjects.setup({
      select = { lookahead = true }, -- jump forward to the next object if not inside one
      move = { set_jumps = true }, -- so <C-o> comes back
    })

    local select = require("nvim-treesitter-textobjects.select")
    local move = require("nvim-treesitter-textobjects.move")
    local swap = require("nvim-treesitter-textobjects.swap")
    local repeatable = require("nvim-treesitter-textobjects.repeatable_move")

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
    end

    -- Text objects. Visual and operator-pending only: `af` in normal mode is
    -- not a motion, and mapping it there would shadow nothing useful anyway.
    for _, entry in ipairs(SELECT) do
      local lhs, query, desc = entry[1], entry[2], entry[3]
      map({ "x", "o" }, lhs, function() select.select_textobject(query, "textobjects") end, desc)
    end

    -- Motions. `move.goto_*` is already wrapped in the plugin's
    -- `make_repeatable_move`, so `;` / `,` below pick these up for free.
    for _, entry in ipairs(MOVE) do
      local suffix, query, noun = entry[1], entry[2], entry[3]
      map(
        { "n", "x", "o" },
        "]" .. suffix,
        function() move.goto_next_start(query, "textobjects") end,
        "Next " .. noun
      )
      map(
        { "n", "x", "o" },
        "[" .. suffix,
        function() move.goto_previous_start(query, "textobjects") end,
        "Previous " .. noun
      )
    end

    -- Reorder arguments without retyping them.
    map("n", "<leader>cs", function() swap.swap_next("@parameter.inner") end, "Swap argument next")
    map(
      "n",
      "<leader>cS",
      function() swap.swap_previous("@parameter.inner") end,
      "Swap argument previous"
    )

    -- `;` / `,` repeat the motions above. flash.nvim leaves these keys alone on
    -- purpose (see the note on `modes.char.keys` in plugins/flash.lua): its own
    -- `f`/`t` motions repeat with clever-f, so the repeat pair is free for the
    -- structural motions, which have no other way to repeat.
    map({ "n", "x", "o" }, ";", repeatable.repeat_last_move_next, "Repeat last motion forward")
    map({ "n", "x", "o" }, ",", repeatable.repeat_last_move_previous, "Repeat last motion backward")
  end,
}
